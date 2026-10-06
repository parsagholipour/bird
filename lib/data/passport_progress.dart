import '../domain/flight_course.dart';
import '../domain/sky_passport.dart';
import '../domain/tracking.dart' show PlayMode;
import 'progress_repository.dart';

/// Campaign flights count toward the flight, perfect-pass, star, streak and
/// flock stamps; the endless-flight and mini game stamps stay endless-only
/// (docs/campaign.md).
extension PassportProgress on ProgressSnapshot {
  List<StampProgress> get passport => [
    for (final stamp in SkyStamp.values)
      switch (stamp) {
        SkyStamp.frequentFlyer => StampProgress(stamp, flightsFlown),
        SkyStamp.onTheDot => StampProgress(
          stamp,
          totalPerfects + campaignFlights.perfectPasses,
        ),
        SkyStamp.starChaser => StampProgress(stamp, starsEarned),
        SkyStamp.constellation => StampProgress(
          stamp,
          campaignFlights.bestCombo > longestCombo
              ? campaignFlights.bestCombo
              : longestCombo,
        ),
        SkyStamp.skyCaptain => StampProgress(
          stamp,
          [
            trailPushUp,
            trailJump,
            trailTouch,
            trailSquat,
          ].fold(0, (best, record) => record.best > best ? record.best : best),
        ),
        SkyStamp.trailblazer => StampProgress(stamp, trailCompletions),
        SkyStamp.flockTogether => StampProgress.medals(stamp, [
          birdsFlown.length,
          birdsFlown.length,
          _least([
            for (var bird = 0; bird < birdPrices.length; bird++)
              birdFlights[bird] ?? 0,
          ]),
        ]),
        SkyStamp.allRounder => () {
          final flights = [
            for (final mode in const [
              PlayMode.pushUp,
              PlayMode.squat,
              PlayMode.jump,
            ])
              record(mode).runs + record(mode, FlightCourse.starTrail).runs,
          ];
          final tried = flights.where((n) => n > 0).length;
          return StampProgress.medals(stamp, [tried, tried, _least(flights)]);
        }(),
      },
  ];

  /// Medals held across the passport, out of [passportMedals].
  int get earnedMedals => passport.fold(
    0,
    (n, p) => n + (p.medal == null ? 0 : p.medal!.index + 1),
  );

  /// The best medal of each stamp holding one, to tell after a flight which
  /// stamps it raised.
  Map<SkyStamp, StampMedal> get medals => {
    for (final p in passport)
      if (p.medal != null) p.stamp: p.medal!,
  };

  /// Stamps whose medal rose above [before] (a [medals] snapshot).
  List<StampProgress> medalsWonSince(Map<SkyStamp, StampMedal> before) => [
    for (final p in passport)
      if (p.medal != null &&
          (before[p.stamp] == null || p.medal!.index > before[p.stamp]!.index))
        p,
  ];

  /// The nearest medal still to earn. Ties keep the passport order, so a
  /// new passport suggests flying more and the suggestion doesn't jump
  /// around.
  StampProgress? get nextStamp {
    final pending = passport.where((p) => !p.complete).toList();
    if (pending.isEmpty) return null;
    return pending.reduce((a, b) => b.fraction > a.fraction ? b : a);
  }
}

/// Every medal of the passport.
final passportMedals = SkyStamp.values.length * StampMedal.values.length;

int _least(List<int> counts) =>
    counts.reduce((least, n) => n < least ? n : least);
