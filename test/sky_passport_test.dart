import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/data/passport_progress.dart';
import 'package:push_up_bird/data/progress_repository.dart';
import 'package:push_up_bird/domain/sky_passport.dart';

void main() {
  test('a new passport gives eight reachable goals without earned stamps', () {
    const progress = ProgressSnapshot();
    expect(progress.passport, hasLength(8));
    expect(progress.earnedStamps, 0);
    expect(progress.nextStamp?.stamp, SkyStamp.firstWings);
    expect(
      progress.passport
          .singleWhere((p) => p.stamp == SkyStamp.flockTogether)
          .current,
      0,
    );
  });
  test(
    'stamps combine both controls and captain requires a 50-point Star Trail',
    () {
      const progress = ProgressSnapshot(
        pushUp: ModeRecord(runs: 2, best: 12, perfectPasses: 4),
        trailJump: ModeRecord(
          runs: 3,
          best: 20,
          stars: 60,
          bestCombo: 14,
          perfectPasses: 6,
          completions: 3,
        ),
        birdsFlown: {0, 1, 2, 3},
      );
      expect(progress.earnedStamps, 7);
      expect(
        progress.passport
            .singleWhere((p) => p.stamp == SkyStamp.skyCaptain)
            .earned,
        isFalse,
      );
      expect(
        progress.passport
            .singleWhere((p) => p.stamp == SkyStamp.bothWings)
            .earned,
        isTrue,
      );
    },
  );
  test('displayed progress clamps at completion', () {
    const earned = StampProgress(SkyStamp.firstWings, 100);
    expect(earned.fraction, 1);
    expect(earned.remaining, 0);
    const pending = StampProgress(SkyStamp.starChaser, 17);
    expect(pending.remaining, 33);
    expect(pending.fraction, .34);
  });

  test(
    'the next stamp is the closest unfinished goal, never one already earned',
    () {
      const progress = ProgressSnapshot(
        pushUp: ModeRecord(runs: 3, best: 11, perfectPasses: 8),
        trailJump: ModeRecord(runs: 2, stars: 50, bestCombo: 7),
      );
      expect(progress.nextStamp?.stamp, SkyStamp.onTheDot);
      expect(progress.nextStamp?.remaining, 2);
      const complete = ProgressSnapshot(
        pushUp: ModeRecord(runs: 3, best: 25, perfectPasses: 10),
        trailJump: ModeRecord(
          runs: 3,
          best: 50,
          stars: 50,
          bestCombo: 12,
          completions: 3,
        ),
        birdsFlown: {0, 1, 2, 3},
      );
      expect(complete.nextStamp, isNull);
    },
  );
}
