import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/data/play_achievements.dart';

typedef A = PlayAchievement;

void main() {
  test('every goal and type matches what Play Console published', () {
    for (final a in A.values) {
      final published = publishedPlaySteps[a];
      final source = a.stamp == null
          ? 'its goal in play_achievements.dart'
          : 'the ${a.stamp!.title} ${a.medal!.label.toLowerCase()} target '
                'in sky_passport.dart';
      final reason =
          '${a.name} is published on Play as '
          '${published == null ? 'standard' : 'incremental, $published steps'}'
          ' and Play cannot change that: changing this needs a new Play '
          'achievement (or revert $source)';
      expect(a.steps, published, reason: reason);
      expect(a.goal, published ?? 1, reason: reason);
    }
  });

  test('19 incremental achievements, each within Play\'s 2 to 10,000', () {
    expect(publishedPlaySteps, hasLength(19));
    for (final MapEntry(key: a, value: steps) in publishedPlaySteps.entries) {
      expect(steps, inInclusiveRange(2, 10000), reason: a.name);
    }
  });
}
