part of 'game_rules.dart';

/// Steam geysers (rules version 43, `LevelPlan.steam`; spec
/// `reports/03-steam-geysers.md` section 2). A vent takes the place of the
/// wall on its slot's passage; its state is a pure function of the route
/// clock, so a cruising bird, a sprinting one and a bird in a gale's tailwind
/// all meet the same vent in the same state. Gated by
/// [FlightSimulation.supportsSteamGeysers] at the call sites.
///
/// The hot burst of a hop vent scalds a bird whose circle touches its column
/// (shield, then a heart; the usual 1.5 s recovery). The cool billow of any
/// vent lifts a bird inside it, and a ride vent pays 2 points for a lift of
/// a quarter second; a hop vent cleared unscathed pays 1. A ram never smashes
/// steam. Vents are cleared at a boss's arrival.
extension SteamRules on FlightSimulation {
  SteamGeyser? _geyserOf(LevelRoute route, int slot) {
    for (final geyser in route.geysers) {
      if (geyser.slot == slot) return geyser;
    }
    return null;
  }

  /// Lays the vent of [geyser] on the slot passage whose leading edge is at
  /// [x]: the plume's top from the slot's own [centre] and the previous
  /// gate's [before], three stars on an arc above it (none inside a plume).
  /// The passage itself has already drawn everything a gate draws.
  void _layVent(SteamGeyser geyser, double x, double centre, double before) {
    final route = this.route!;
    final ordinal = route.geysers
        .where((g) => g.slot < geyser.slot && g.kind == SteamKind.hop)
        .length;
    final top = SteamCycle.top(
      geyser.kind,
      centre: centre,
      previous: before,
      ordinal: ordinal,
    );
    final at = x + SteamGeyser.centreOffset;
    steamVents.add(SteamVent(geyser: geyser, x: at, top: top));
    starsLaid += 3;
    final arc = top - SteamCycle.starsAbove;
    final trio = supportsStarTrios
        ? StarTrio(x: at + SteamCycle.starsX[1], y: arc)
        : null;
    if (trio != null) starTrios.add(trio);
    for (var i = 0; i < 3; i++) {
      stars.add(
        SkyStar(
          x: at + SteamCycle.starsX[i],
          y: arc + SteamCycle.starsDY[i],
          trio: trio,
          trioSlot: i,
        ),
      );
    }
  }

  /// One simulation step of every vent, after the bird and the gates have
  /// moved: scroll with the course, count edges near the bird, scald, lift.
  void _advanceSteam(double dt) {
    if (steamVents.isEmpty) return;
    final now = routeSeconds;
    for (final vent in steamVents) {
      // Exact: the vent sits where its route position is, whatever the speed.
      vent.x = vent.geyser.x - distance;
      _steamEdges(vent, now);
      _steamScald(vent, now);
      _steamLift(vent, now, dt);
      _steamPassed(vent);
    }
    steamVents.removeWhere((vent) => vent.x < SteamCycle.vanishX);
  }

  /// Counts each hiss and burst once for every vent the bird passes: the
  /// cycle it arrives in (cycle 0 of the vent's clock, which the route
  /// places there), while the vent is near enough for the audio to hear.
  /// The ambient cycles before and after are the scenery's.
  void _steamEdges(SteamVent vent, double now) {
    final heard = flock.any((bird) {
      final away = vent.x - bird.x;
      return away >= -SteamCycle.earshotBehind &&
          away <= SteamCycle.earshotAhead;
    });
    if (!heard) return;
    final geyser = vent.geyser;
    final cycle = ((now - geyser.burstAt + SteamCycle.hiss) / SteamCycle.period)
        .floor();
    if (cycle != 0) return;
    switch (geyser.phaseAt(now)) {
      case SteamPhase.hiss when cycle > vent.hissCycle:
        vent.hissCycle = cycle;
        steamHisses++;
      case SteamPhase.burst when cycle > vent.burstCycle:
        vent.burstCycle = cycle;
        steamBursts++;
      default:
        break;
    }
  }

  /// The hot burst of a hop vent: a circle against the standing plume's
  /// column, from its top to the vent's mouth. A ride vent's steam is soft.
  /// Every bird of a flock is tested; the one that is touched is hurt.
  void _steamScald(SteamVent vent, double now) {
    if (vent.kind != SteamKind.hop) return;
    final top = vent.plumeTop(now);
    if (top >= vent.mouth) return;
    const half = SteamCycle.hitHalfWidth, radius = FlightSimulation.birdRadius;
    for (final bird in flock) {
      final dx = bird.x - bird.x.clamp(vent.x - half, vent.x + half);
      final dy = bird.y - bird.y.clamp(top, vent.mouth);
      if (dx * dx + dy * dy > radius * radius) continue;
      vent.touched = true;
      if (viewing(bird, () => elapsed < invulnerableUntil)) continue;
      vent.scalded = true;
      steamScalds++;
      _hurt(bird);
    }
  }

  /// The cool billow lifts a bird inside it (never above the plume's top, a
  /// flap still wins), and a ride vent pays once it has lifted long enough.
  void _steamLift(SteamVent vent, double now, double dt) {
    final env = vent.liftAt(now);
    if (env <= 0) return;
    var lifted = false;
    for (final bird in flock) {
      if ((vent.x - bird.x).abs() > SteamCycle.liftHalfWidth) continue;
      final lift = SteamCycle.liftFor(env, bird.y, vent.top);
      if (lift <= 0) continue;
      if (bird.velocity > -lift) bird.velocity = -lift;
      lifted = true;
    }
    if (!lifted) return;
    vent.lifted += dt;
    if (vent.kind == SteamKind.ride &&
        !vent.rode &&
        vent.lifted >= SteamCycle.rideSeconds) {
      vent.rode = true;
      steamRides++;
      score += SteamCycle.ridePoints;
    }
  }

  /// A hop vent the bird (the rearmost bird of a flock) has flown past
  /// without once touching its column.
  void _steamPassed(SteamVent vent) {
    if (vent.passed ||
        vent.x + SteamCycle.hitHalfWidth + FlightSimulation.birdRadius >=
            _rearX) {
      return;
    }
    vent.passed = true;
    if (vent.kind == SteamKind.hop && !vent.touched) {
      steamClears++;
      score += SteamCycle.hopPoints;
    }
  }
}
