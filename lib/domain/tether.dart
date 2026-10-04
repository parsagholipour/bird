import 'dart:math' as math;

import 'flight_path.dart';

/// One bird of a flight, in viewport heights on screen. A solo flight flies
/// one; a co-op flight flies two, roped together ([Tether]) or not, and a
/// duel flies two rivals ([CoopMode.duel]).
class FlightBird {
  FlightBird({required this.homeX}) : x = homeX;

  /// Where the bird cruises on screen. A solo bird never leaves it.
  final double homeX;
  double x, y = .5;

  /// Screen speeds in viewport heights per second; positive is down and
  /// forward.
  double velocity = 0, vx = 0;
  double lastFlapAt = double.negativeInfinity;
  int flaps = 0;
  double lastSprintAt = double.negativeInfinity;
  int sprints = 0;

  /// Share of this bird's ammo reserve left, from 0 to 1.
  double ammo = 1;
  double? chargeStartedAt;

  /// Reserve at the moment the current press started.
  double? chargeAmmo;
  double lastShotAt = double.negativeInfinity;
  int shots = 0;

  /// The line this bird has just flown. Presentation only.
  final FlightPath flightPath = FlightPath();

  /// Hearts, shield and hit recovery. A solo or team flight keeps them on
  /// its first bird for everyone; each bird of a duel has its own.
  int hearts = 3;
  bool shield = true;
  double invulnerableUntil = 0;

  /// The latest hit recovery's whole length. Presentation only.
  double recoverySeconds = 1.5;

  /// Stars this bird has collected. A duel bird's own stars charge its
  /// shield.
  int stars = 0;

  /// A duel bird's mystery boxes opened, and the hits its rocks, star power
  /// and sent attacks landed on its rival.
  int boxesOpened = 0, hitsLanded = 0;

  /// Until when a duel bird's star power lasts ([BoxPrize.starPower]).
  double starPowerUntil = double.negativeInfinity;

  /// When a duel bird lost its last heart, or null while it flies.
  double? downAt;
}

/// How a co-op flight's two birds fly together (rules version 42): tied
/// with the [Tether] rope, or each on its own. A [duel] flies them against
/// each other instead.
enum CoopMode {
  roped,
  free,

  /// Two rivals, each with its own hearts, fight over mystery boxes until
  /// one is knocked out ([Duel]).
  duel;

  String get title => switch (this) {
    roped => 'Roped',
    free => 'No rope',
    duel => '1 v 1',
  };

  /// Whether the players fly as one team, sharing hearts and score.
  bool get team => this != duel;
}

/// Co-op tuning (rules version 42).
///
/// Two birds of equal weight share one rope. It goes slack while they are
/// close and stops them at [length]. When it snaps taut it takes out the
/// speed pulling them apart and shares it between them, so a bird that
/// flaps alone lifts its partner at half the speed and climbs a quarter as
/// high; two flaps together climb as high as a solo bird. A sprinting bird
/// surges ahead of its place and drags its partner, and the course speeds
/// up by the pair's average boost, half as much as when both sprint.
///
/// Without the rope ([CoopMode.free]) each bird flies on its own: nothing
/// holds them together and nothing drags, but their bodies still [bump].
abstract final class Tether {
  /// Player 1's bird cruises this far behind the solo bird's column, and
  /// player 2's this far ahead of it.
  static const spread = .10;

  /// The farthest apart the two birds' centres can get.
  static const length = .30;

  /// The closest their centres come before the birds bump.
  static const contact = .09;

  /// The spring that brings each bird back to its place in the formation,
  /// critically damped so it settles without swinging.
  static const stiffness = 30.0, damping = 11.0;

  /// How far ahead of its place a sprinting bird surges at the burst's peak.
  static const sprintLead = .26;

  /// Moves [bird] toward its place, [surge] (0 to 1) of [sprintLead] ahead.
  static void cruise(FlightBird bird, double surge, double dt) {
    final target = bird.homeX + sprintLead * surge;
    bird.vx += (stiffness * (target - bird.x) - damping * bird.vx) * dt;
    bird.x += bird.vx * dt;
  }

  /// Holds the birds within the rope and apart from each other ([bump]).
  /// Each moves half the correction, and the speed along the rope that
  /// would pull them further apart is shared out: the inelastic collision
  /// of two equal weights. Returns that shared speed while the rope is
  /// pulling, otherwise 0. Presentation reads it as tension.
  static double bind(FlightBird a, FlightBird b) {
    final dx = b.x - a.x, dy = b.y - a.y;
    final distance = math.sqrt(dx * dx + dy * dy);
    if (distance > length) {
      final nx = dx / distance, ny = dy / distance;
      final excess = (distance - length) / 2;
      a
        ..x += nx * excess
        ..y += ny * excess;
      b
        ..x -= nx * excess
        ..y -= ny * excess;
      final apart = (b.vx - a.vx) * nx + (b.velocity - a.velocity) * ny;
      if (apart <= 0) return 0;
      _share(a, b, nx, ny, apart / 2);
      return apart;
    }
    bump(a, b);
    return 0;
  }

  /// Keeps the birds' bodies apart: closer than [contact], each moves half
  /// the overlap away and their closing speed is shared out.
  static void bump(FlightBird a, FlightBird b) {
    final dx = b.x - a.x, dy = b.y - a.y;
    final distance = math.sqrt(dx * dx + dy * dy);
    if (distance < contact) {
      // Level birds that meet head on part along the formation.
      final (nx, ny) = distance > 1e-9
          ? (dx / distance, dy / distance)
          : (1.0, 0.0);
      final push = (contact - distance) / 2;
      a
        ..x -= nx * push
        ..y -= ny * push;
      b
        ..x += nx * push
        ..y += ny * push;
      final closing = (b.vx - a.vx) * nx + (b.velocity - a.velocity) * ny;
      if (closing < 0) _share(a, b, nx, ny, closing / 2);
    }
  }

  static void _share(
    FlightBird a,
    FlightBird b,
    double nx,
    double ny,
    double k,
  ) {
    a
      ..vx += nx * k
      ..velocity += ny * k;
    b
      ..vx -= nx * k
      ..velocity -= ny * k;
  }
}
