/// THE ONE SWITCH for the Ember Dragon's real-art contract tests.
///
/// `dragon_envelope_test.dart` (every pose stays inside `DragonLayout.envelope`)
/// and `dragon_budget_test.dart` (ops, shaders, clips, layers per frame, whole
/// rig and per part) run against the real art in `DragonBossRig`. Until every
/// part has landed (head, body, wings) they only REPORT what is over; once
/// they have, flip the default below to `true` and the same checks fail, each
/// failure naming the part, the pose and the coordinate that broke the rule.
///
/// Without editing anything:
///   flutter test --no-pub --dart-define=DRAGON_ENFORCE=true \
///       test/dragon_envelope_test.dart test/dragon_budget_test.dart
const enforceRealArt = bool.fromEnvironment(
  'DRAGON_ENFORCE',
  defaultValue: true,
);

/// How many whole breath cycles the envelope sweep samples per state (each
/// shifts the wingbeat phase by 2.85 rad, so the beat is covered all round).
/// 24 is quick; the final check before a merge runs 70:
///   flutter test --no-pub --dart-define=DRAGON_CYCLES=70 test/dragon_envelope_test.dart
const envelopeCycles = int.fromEnvironment('DRAGON_CYCLES', defaultValue: 24);
