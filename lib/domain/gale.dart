import 'dart:math' as math;

/// Gales (rules version 33).
///
/// Once the Dusk Empress falls, a gale blows through before the next boss.
/// Walls stop, a tailwind speeds the course up, and debris flies straight at
/// the bird from ahead. An exclamation mark at the right edge of the screen
/// shows each piece's height before it comes into view.
enum GalePhase { approach, blowing, weathered }

class Gale {
  Gale({required this.number, required this.startDistance});
  final int number;

  /// World position of the bird ([FlightSimulation.distance] plus its x)
  /// where the wind rises. The last wall is behind the bird by then.
  final double startDistance;

  GalePhase phase = GalePhase.approach;
  bool warned = false, hurt = false;
  double? startedAt, weatheredAt;
  double gustIn = 0;
  int gusts = 0, hits = 0, dodges = 0, bonus = 0;

  /// Ordinary passages hold until the wind has done its work.
  bool get holdsSpawns => phase != GalePhase.weathered;

  /// How hard the tailwind blows at [elapsed], from 0 to 1. It rises when
  /// the bird reaches the start and eases back once the gale is weathered.
  double wind(double elapsed) => switch (phase) {
    GalePhase.approach => 0,
    GalePhase.blowing => _smooth((elapsed - startedAt!) / riseSeconds),
    GalePhase.weathered => 1 - _smooth((elapsed - weatheredAt!) / fallSeconds),
  };

  /// Course speed multiplier at [elapsed].
  double boost(double elapsed) => 1 + (peakBoost - 1) * wind(elapsed);

  /// Seconds between gusts: they come quicker as the gale goes on.
  double gustInterval(double blowingFor) =>
      gustStart +
      (gustEnd - gustStart) * (blowingFor / seconds).clamp(0.0, 1.0);

  /// The first gale waits this long after the Dusk Empress leaves, so a few
  /// ordinary walls come first. The usual rush path follows the gale.
  static const afterBoss = 12.0, rushAfter = 8.0;

  /// A warning banner leads the start by [warningLead] of course distance,
  /// and the start sits [clearance] past the last wall.
  static const warningLead = 1.2, clearance = .45;
  static const seconds = 13.0, peakBoost = 1.6;
  static const riseSeconds = 1.2, fallSeconds = 1.5;

  /// Gusts stop [calmSeconds] before the end, so the last pieces clear the
  /// screen as the wind drops.
  static const firstGust = .5, gustStart = 1.2, gustEnd = .85;
  static const calmSeconds = 1.6;

  /// Odd gusts send a second piece [pairSpread] or more away from the one
  /// aimed at the bird, closing off one way out. Pieces fly at heights
  /// between [top] and [bottom].
  static const pairSpread = .30, pairSpreadRange = .14;
  static const top = .12, bottom = .88;

  static const dodgePoints = 1, weatherBonus = 10, flawlessBonus = 10;

  static double _smooth(double t) {
    final x = t.clamp(0.0, 1.0);
    return x * x * (3 - 2 * x);
  }
}

/// A piece of debris flying straight at the bird along its lane. Its x is a
/// screen position; it closes at [speed] plus the course scroll, so the
/// warning always leaves the same time before it appears at the edge.
class GaleDebris {
  GaleDebris({
    required this.x,
    required this.y,
    required this.shape,
    required this.spin,
  });
  double x;
  final double y;

  /// Which piece of debris it is and how it tumbles. The rules never read
  /// them.
  final int shape;
  final double spin;
  double age = 0;
  double? hitAt;
  bool dodged = false;

  static const radius = .05, speed = .9;

  /// Seconds between the warning and the piece coming into view.
  static const warningSeconds = .9;

  /// Where a piece starts so it enters the screen after [warningSeconds]
  /// at the given course scroll.
  static double launchX(double viewportWidth, double scroll) =>
      viewportWidth + radius + (speed + scroll) * warningSeconds;

  /// Seconds until the piece enters a screen [viewportWidth] wide at the
  /// given scroll; 0 once it is in view.
  double entersIn(double viewportWidth, double scroll) =>
      math.max(0, (x - viewportWidth - radius) / (speed + scroll));
}
