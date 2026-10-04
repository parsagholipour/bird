/// The activity controls the bird; the course defines the arcade objective.
/// Star Trail is the course new flights start. Classic remains so older
/// sessions still load. Sky Courier and Cloud Cruise names map here so saved
/// journals from those retired modes still open.
enum FlightCourse {
  classic,
  starTrail;

  static const retiredNames = {'skyCourier', 'cloudCruise'};

  static FlightCourse named(String? name, {FlightCourse orElse = starTrail}) {
    if (retiredNames.contains(name)) return orElse;
    for (final course in values) {
      if (course.name == name) return course;
    }
    return orElse;
  }

  bool get collectsStars => this == starTrail;

  /// The duration belongs only to saved, pre-endless replay rules.
  bool get legacyTimed => this == starTrail;
  double get duration => 60;
  String get shortTitle => title;

  String get title => switch (this) {
    classic => 'Classic',
    starTrail => 'Star Trail',
  };
  String get subtitle => switch (this) {
    classic => 'Endless sky. One chance. Make it count.',
    starTrail => 'Endless stars. Three hearts. A sky that keeps changing.',
  };
  String get instructions => switch (this) {
    classic => 'Find the gaps. Follow the aiming marks for a perfect pass.',
    starTrail =>
      'Collect all 3 stars in a group for +5. Chain stars for up to 3×. Stars restore your shield; perfect gates earn a star magnet. Upgrade both with stars!',
  };
  String get scoreLabel => switch (this) {
    classic => 'OBSTACLES',
    starTrail => 'STAR POINTS',
  };
  String get scoreUnit => switch (this) {
    classic => 'gates',
    starTrail => 'star points',
  };
}
