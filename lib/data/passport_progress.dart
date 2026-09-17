import '../domain/sky_passport.dart';
import 'progress_repository.dart';

extension PassportProgress on ProgressSnapshot {
  List<StampProgress> get passport => [
    for (final stamp in SkyStamp.values)
      StampProgress(stamp, switch (stamp) {
        SkyStamp.firstWings => totalRuns,
        SkyStamp.onTheDot => totalPerfects,
        SkyStamp.starChaser => totalStars,
        SkyStamp.constellation => longestCombo,
        SkyStamp.skyCaptain => [
          pushUp,
          smile,
          touch,
        ].fold(0, (best, record) => record.best > best ? record.best : best),
        SkyStamp.trailblazer => trailCompletions,
        SkyStamp.flockTogether => unlocked.length,
        SkyStamp.bothWings =>
          (pushUp.runs + trailPushUp.runs + courierPushUp.runs > 0 ? 1 : 0) +
              (smile.runs + trailSmile.runs + courierSmile.runs > 0 ? 1 : 0),
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
