import '../domain/sky_passport.dart';
import 'progress_repository.dart';

/// Campaign flights count toward the flight, star and streak stamps; the
/// Star Trail and camera stamps stay endless-only (docs/campaign.md).
extension PassportProgress on ProgressSnapshot {
  List<StampProgress> get passport => [
    for (final stamp in SkyStamp.values)
      StampProgress(stamp, switch (stamp) {
        SkyStamp.firstWings => flightsFlown,
        SkyStamp.onTheDot => totalPerfects + campaignFlights.perfectPasses,
        SkyStamp.starChaser => totalStars + campaignFlights.stars,
        SkyStamp.constellation =>
          campaignFlights.bestCombo > longestCombo
              ? campaignFlights.bestCombo
              : longestCombo,
        SkyStamp.skyCaptain => [
          trailPushUp,
          trailJump,
          trailTouch,
          trailSquat,
        ].fold(0, (best, record) => record.best > best ? record.best : best),
        SkyStamp.trailblazer => trailCompletions,
        SkyStamp.flockTogether => birdsFlown.length,
        SkyStamp.bothWings =>
          (pushUp.runs + trailPushUp.runs > 0 ? 1 : 0) +
              (jump.runs + trailJump.runs > 0 ? 1 : 0) +
              (squat.runs + trailSquat.runs > 0 ? 1 : 0),
      }),
  ];
  int get earnedStamps => passport.where((s) => s.earned).length;

  /// First flight comes first; afterwards suggest the nearest unfinished goal.
  /// Keep the passport order for ties, so the suggestion doesn't jump around.
  StampProgress? get nextStamp {
    final pending = passport.where((p) => !p.earned).toList();
    if (pending.isEmpty) return null;
    if (pending.first.stamp == SkyStamp.firstWings) return pending.first;
    return pending.reduce((a, b) => b.fraction > a.fraction ? b : a);
  }
}
