/// A stamp has one durable, measurable goal. Progress is derived from saved
/// scored flights, so retrying a save cannot award anything twice.
enum SkyStamp {
  firstWings('First wings', 'Finish your first scored flight.', 1),
  onTheDot('On the dot', 'Fly 10 perfect passes along the aiming marks.', 10),
  starChaser('Star chaser', 'Collect 50 stars in Star Trail.', 50),
  constellation(
    'Constellation',
    'Collect 12 stars in one unbroken streak.',
    12,
  ),
  skyCaptain('Sky captain', 'Clear 25 gates in one Classic flight.', 25),
  trailblazer('Trailblazer', 'Complete three 60-second Star Trails.', 3),
  flockTogether('Flock together', 'Unlock all four feathered friends.', 4),
  bothWings('Both wings', 'Try scored flights with both movement controls.', 2);

  const SkyStamp(this.title, this.description, this.target);
  final String title, description;
  final int target;
}

class StampProgress {
  const StampProgress(this.stamp, this.current);
  final SkyStamp stamp;
  final int current;
  bool get earned => current >= stamp.target;
  double get fraction => (current / stamp.target).clamp(0.0, 1.0);
  int get remaining => (stamp.target - current).clamp(0, stamp.target);
}
