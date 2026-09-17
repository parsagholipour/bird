/// The activity controls the bird; the course defines the arcade objective.
/// Stable names are stored in SQLite and replay journals.
enum FlightCourse {
  classic,
  starTrail,
  skyCourier,
  cloudCruise;

  bool get relaxed => this == cloudCruise;
  bool get collectsStars => this == starTrail || this == cloudCruise;
  bool get timed => this == starTrail || this == skyCourier;
  double get duration => this == skyCourier ? 75 : 60;
  String get shortTitle => this == skyCourier ? 'Courier' : title;

  String get title => switch (this) {
    classic => 'Classic',
    starTrail => 'Star Trail',
    skyCourier => 'Sky Courier',
    cloudCruise => 'Cloud Cruise',
  };
  String get subtitle => switch (this) {
    classic => 'Endless sky. One chance. Make it count.',
    starTrail => '60 seconds. Three hearts. A sky full of stars.',
    skyCourier => '75 seconds. Pick up letters. Deliver little joys.',
    cloudCruise => 'Cloud friends. Open sky. No crashes or clock.',
  };
  String get instructions => switch (this) {
    classic => 'Find the gaps. Follow the aiming marks for a perfect pass.',
    starTrail =>
      'Collect a full star trio for +5 points. Chain stars for up to 3×. Every 9 stars restores a shield; three perfect gates earn an 8-second magnet!',
    skyCourier =>
      'Clear a pickup gate to carry a letter. Clear a postbox gate to deliver it. A collision drops the letter, but you keep flying.',
    cloudCruise =>
      'Meet a whale, bunny and turtle in the clouds. Fly close to discover them! Collect star trios for +5 points, earn magnets and pause whenever you like.',
  };
  String get scoreLabel => switch (this) {
    classic => 'OBSTACLES',
    skyCourier => 'DELIVERIES',
    _ => 'STAR POINTS',
  };
  String get scoreUnit => switch (this) {
    classic => 'gates',
    skyCourier => 'deliveries',
    _ => 'star points',
  };
}
