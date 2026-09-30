/// A campaign level's finish line (rules version 41). Ordinary passages stop
/// short of it, the way they stop for a gale, and a bird that crosses it
/// completes the level. It has no collision.
class FinishLine {
  FinishLine({required this.worldX, required this.x}) : laidX = x;

  /// World position where the bird crosses: the course distance flown plus
  /// [FlightSimulation.birdX].
  final double worldX;

  /// Screen x; it scrolls with the course and reaches the bird as it
  /// crosses.
  double x;

  /// Screen x where the line was laid. A boss level's victory glide fills
  /// its share of the route line from here. Presentation only.
  final double laidX;
  double? crossedAt;
  bool get crossed => crossedAt != null;

  /// The last passage is at least this far before the line.
  static const clearance = .45;

  /// After a boss level's boss flies off, the line is laid this far past the
  /// right edge of the screen, for a short victory glide.
  static const afterBoss = .2;

  /// Where a boss level's route line marks the boss: the run-up fills this
  /// share of the line and the victory glide the rest.
  static const bossMark = .85;
}
