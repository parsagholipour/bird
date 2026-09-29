import 'dart:math' as math;

/// The line the bird has just flown, in viewport heights. Points keep their
/// world distance rather than a screen x, so each stays where the bird really
/// was while the sky scrolls. Presentation only: physics, RNG and the replay
/// journal never read it, and replaying the journal rebuilds it after a seek.
class FlightPath {
  /// Flown length kept behind the bird, measured along the path.
  static const reach = .32;
  static const _spacing = .004;
  final List<({double distance, double y})> _points = [];

  /// Newest point first.
  Iterable<({double distance, double y})> get recent => _points.reversed;

  /// Length flown along the path up to its newest point, so trail marks can
  /// stay where they were dropped while the path itself slides away.
  double get flown => _flown;
  double _flown = 0;

  void record(double distance, double y) {
    final point = (distance: distance, y: y);
    if (_points.isNotEmpty) {
      final gap = _gap(_points.last, point);
      if (gap < _spacing) return;
      _flown += gap;
    }
    _points.add(point);
    var kept = 0.0;
    for (var i = _points.length - 1; i > 0; i--) {
      kept += _gap(_points[i], _points[i - 1]);
      if (kept >= reach) {
        _points.removeRange(0, i - 1);
        return;
      }
    }
  }

  static double _gap(
    ({double distance, double y}) a,
    ({double distance, double y}) b,
  ) {
    final dx = a.distance - b.distance, dy = a.y - b.y;
    return math.sqrt(dx * dx + dy * dy);
  }
}
