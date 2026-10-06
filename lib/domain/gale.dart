import 'dart:math' as math;

/// Gales (rules version 33).
///
/// Once the Dusk Empress falls, a gale blows through before the next boss.
/// Walls stop, a tailwind speeds the course up, and debris flies straight at
/// the bird from ahead. An exclamation mark at the right edge of the screen
/// shows each piece's height before it comes into view.
enum GalePhase { approach, blowing, weathered }

class Gale {
  Gale({required this.number, required this.startDistance, this.fury = 0})
    : assert(fury >= 0 && fury <= maxFury);
  final int number;

  /// How many steps harder than the first gale this one blows (rules
  /// version 65, [FlightSimulation.risingGalesRulesVersion]). Each endless
  /// gale after the first adds a step, up to [maxFury]: it blows longer,
  /// the tailwind is stronger, gusts come quicker and pair more often, and
  /// the debris flies faster. Fury 0 is every gale before 65, every first
  /// endless gale and every campaign gale.
  final int fury;

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
  double boost(double elapsed) => 1 + (peak - 1) * wind(elapsed);

  /// How long this gale blows, its strongest course speed multiplier and
  /// how fast its debris flies, all rising with [fury].
  double get blowSeconds => seconds + furySeconds * fury;
  double get peak => peakBoost + furyBoost * fury;
  double get debrisSpeed => GaleDebris.baseSpeed + furySpeed * fury;

  /// Seconds between gusts: they come quicker as the gale goes on, and
  /// quicker still in a fiercer gale.
  double gustInterval(double blowingFor) {
    final start = gustStart - furyGust * fury;
    final end = gustEnd - furyGust * fury;
    return start + (end - start) * (blowingFor / blowSeconds).clamp(0.0, 1.0);
  }

  /// Whether gust number [gust] (from 0) sends a pair. The first gale
  /// pairs odd gusts; a fiercer one pairs two gusts in three, and from
  /// fury 2 every gust but the first.
  bool pairs(int gust) => switch (fury) {
    0 => gust.isOdd,
    1 => gust % 3 != 0,
    _ => gust > 0,
  };

  /// The first gale waits this long after the Dusk Empress leaves, so a few
  /// ordinary walls come first. The usual rush path follows the gale.
  static const afterBoss = 12.0, rushAfter = 8.0;

  /// A warning banner leads the start by [warningLead] of course distance,
  /// and the start sits [clearance] past the last wall.
  static const warningLead = 1.2, clearance = .45;
  static const seconds = 13.0, peakBoost = 1.6;
  static const riseSeconds = 1.2, fallSeconds = 1.5;

  /// What each step of [fury] adds, up to [maxFury] steps. At full fury a
  /// gale blows 19 seconds at 1.9x, gusts every 0.96 s easing to 0.61 s,
  /// and its debris flies at 1.35 plus course speed.
  static const maxFury = 3;
  static const furySeconds = 2.0, furyBoost = .1, furySpeed = .15;
  static const furyGust = .08;

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
    this.speed = baseSpeed,
  });
  double x;
  final double y;

  /// How fast it flies on top of the course scroll: [baseSpeed], or faster
  /// from a fiercer gale ([Gale.debrisSpeed]).
  final double speed;

  /// Which piece of debris it is and how it tumbles. The rules never read
  /// them.
  final int shape;
  final double spin;
  double age = 0;
  double? hitAt;
  bool dodged = false;

  static const radius = .05, baseSpeed = .9;

  /// Seconds between the warning and the piece coming into view.
  static const warningSeconds = .9;

  /// Where a piece flying at [speed] starts so it enters the screen after
  /// [warningSeconds] at the given course scroll.
  static double launchX(
    double viewportWidth,
    double scroll, {
    double speed = baseSpeed,
  }) => viewportWidth + radius + (speed + scroll) * warningSeconds;

  /// Seconds until the piece enters a screen [viewportWidth] wide at the
  /// given scroll; 0 once it is in view.
  double entersIn(double viewportWidth, double scroll) =>
      math.max(0, (x - viewportWidth - radius) / (speed + scroll));
}
