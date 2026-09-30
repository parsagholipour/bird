import 'dart:math' as math;

/// Touch rush paths (rules version 32).
///
/// Between bosses the course hands over to a short run of sprint rings,
/// breakable rubble and bats, with danger from one side. A wildfire chases
/// from behind, a skyfall drops meteors from above, an eruption blasts lava
/// up from below and a swarm of bats streams in from ahead. Ring sprints
/// outrun the fire and the lava and smash through the meteors and the swarm.
enum RushPathKind {
  wildfire('Wildfire', 'Outran the wildfire'),
  skyfall('Skyfall', 'Survived the skyfall'),
  eruption('Eruption', 'Beat the eruption'),
  swarm('Swarm', 'Plowed through the swarm');

  const RushPathKind(this.title, this.escape);
  final String title;

  /// Names an escape in replay highlights and the escape banner.
  final String escape;
}

enum RushPhase { approach, running, escaped }

/// Flying through a ring starts a ring sprint, or extends the current one
/// without a dip, so a chain of rings holds top speed.
class SprintRing {
  SprintRing({required this.x, required this.y});
  double x;
  final double y;
  bool collected = false;
  double? collectedAt;
  static const radius = .062, pickupRadius = .08;
}

/// Screen position with a world velocity: each step also subtracts the
/// course scroll, so a meteor drifts back as fast as the bird flies.
class Meteor {
  Meteor({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.aimed,
  });
  double x, y;
  final double vx, vy;
  final bool aimed;
  double age = 0;
  static const radius = .044;
}

/// A vent under the route. It rumbles once a cruising bird is
/// [Rush.ventFuse] seconds away and blows a lava plume up past the route
/// just as that bird arrives. A faster bird sets it off behind itself.
class LavaVent {
  LavaVent({required this.x, required this.top});
  double x;

  /// Height the full plume reaches.
  final double top;
  double? rumbledAt, eruptedAt;
  double? get fuseEndsAt =>
      rumbledAt == null ? null : rumbledAt! + Rush.ventFuse;
  bool get rumbling => rumbledAt != null && eruptedAt == null;

  /// How much of the plume stands at [elapsed], from 0 to 1. The plume
  /// shoots up in [Rush.plumeRise] and sinks over [Rush.plumeFall].
  double plume(double elapsed) {
    final at = eruptedAt;
    if (at == null) return 0;
    final age = elapsed - at;
    if (!(age >= 0 && age < Rush.plumeSeconds)) return 0;
    double smooth(double t) {
      final x = t.clamp(0.0, 1.0);
      return x * x * (3 - 2 * x);
    }

    return math.min(
      smooth(age / Rush.plumeRise),
      smooth((Rush.plumeSeconds - age) / Rush.plumeFall),
    );
  }

  /// Top of the plume's hit box at [elapsed]; 1 when nothing stands.
  double plumeTop(double elapsed) => 1 - (1 - top) * plume(elapsed);
  static const width = .10;
}

/// A bat streaming down the ring route toward the bird, [lane] off the
/// route, through the barrier openings. A ram smashes it; otherwise it
/// hurts like any bat. A flock the Ember Dragon calls has no [route] and
/// holds the [height] it was released at.
class SwarmBat {
  SwarmBat({
    required this.x,
    required this.y,
    this.route,
    required this.lane,
    required this.phase,
  }) : height = y;
  double x, y;
  final RushPath? route;
  final double height, lane, phase;
  double age = 0;
  static const radius = .036;
}

class RushPath {
  RushPath({
    required this.kind,
    required this.number,
    required this.startDistance,
    required this.endDistance,
    required this.resumeDistance,
    required this.heights,
  });
  final RushPathKind kind;
  final int number;

  /// World positions of the bird ([FlightSimulation.distance] plus its x)
  /// where the run starts and where it has escaped.
  final double startDistance, endDistance;

  /// Course distance where ordinary passages can spawn behind the final
  /// barrier.
  final double resumeDistance;

  /// The route's height through each beat, plus the final barrier's gap.
  final List<double> heights;
  double get exitCenter => heights.last;

  /// Height of the ring route at a world x: level through a beat's stars,
  /// ring and bat, then easing to the next beat's height at its barrier.
  double routeY(double worldX) {
    final along = (worldX - startDistance) / Rush.beatLength;
    if (along <= 0) return heights.first;
    final beat = along.floor();
    if (beat >= heights.length - 1) return heights.last;
    final local = (along - beat) * Rush.beatLength;
    final t = ((local - Rush.batAt) / (Rush.barrierAt - Rush.batAt)).clamp(
      0.0,
      1.0,
    );
    return heights[beat] + (heights[beat + 1] - heights[beat]) * t;
  }

  RushPhase phase = RushPhase.approach;
  bool warned = false, resumed = false, hurt = false;
  double? startedAt, escapedAt;

  /// World x of the wildfire's leading edge.
  double fireDistance = double.negativeInfinity;
  double meteorIn = 0, flockIn = 0;

  /// [catches] counts the fire and lava burning the bird.
  int meteors = 0, flocks = 0, catches = 0, rings = 0, bonus = 0;
  bool get holdsSpawns => !resumed;
}

abstract final class Rush {
  /// Draws the next kind from [bag], refilled with every kind in a shuffled
  /// order, so each round runs all of them. A round never opens with [last].
  static RushPathKind nextKind(
    List<RushPathKind> bag,
    math.Random random,
    RushPathKind? last,
  ) {
    if (bag.isEmpty) {
      bag
        ..addAll(RushPathKind.values)
        ..shuffle(random);
      if (bag.last == last) bag.insert(0, bag.removeLast());
    }
    return bag.removeLast();
  }

  /// The first run follows the opening gates; later ones sit midway between
  /// bosses. A boss waits for a run in progress.
  static const firstAt = 22.0, afterBoss = 18.0;
  static const bossLead = 18.0, bossDelayAfter = 8.0;
  static const beats = 6, beatLength = 1.15;

  /// Offsets within a beat.
  static const ringAt = .58, batAt = .78, barrierAt = .92;
  static const barrierWidth = .16, barrierGap = .36;
  static const clearance = .45, warningLead = 1.6, exitClearance = .9;

  /// The fire gains a quarter of course speed and starts with its flames at
  /// the left edge. A ring sprint drags it along [fireMaxGap] behind, still
  /// licking the edge, instead of losing it. A catch knocks it off screen,
  /// which buys a hurt bird several seconds' relief.
  static const fireChase = 1.25, fireStartGap = .40;
  static const fireMaxGap = .46, fireKnockback = .75;
  static const burnOutSeconds = 1.6;

  /// Aimed meteors cross the ring route where the bird would be after
  /// [meteorLead] seconds at its current speed. The rest fall at random
  /// heights. A sprint's bow wave reaches [ramReach] beyond the bird, both
  /// for meteors and for the barriers it breaks.
  static const meteorInterval = .8, meteorLead = 1.25;
  static const meteorDrift = .40, meteorTop = -.35, firstMeteorDelay = .5;
  static const ramReach = .04;

  /// Every beat after the first has a vent among its stars, so a missed
  /// ring is what leaves the bird cruising into one. A plume stands
  /// [ventOver] above the route, but never above [ventCeiling], so there is
  /// always room to hop over it.
  static const ventAt = .30, ventFuse = 1.0, ventOver = .08;
  static const ventCeiling = .30;

  /// A bird this far past a rumbling vent sets it off at once, so a
  /// sprinter sees the blast go up just behind it.
  static const ventBehind = .15;
  static const plumeSeconds = .8, plumeRise = .10, plumeFall = .25;

  /// Flocks of [flockSize] bats alternate between the route and one side
  /// of it, so no lane stays safe. A ring sprint's bow wave reaches the side
  /// lane too. A slower run meets more flocks.
  static const flockInterval = 1.4, flockSize = 3, flockSpacing = .11;
  static const flockLane = .11, swarmSpeed = .50, firstFlockDelay = .3;
  static const smashPoints = 2, meteorPoints = 1, batPoints = 1;
  static const escapeBonus = 10, flawlessBonus = 10;
}
