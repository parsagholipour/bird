/// THE ONE SWITCH for the Searchlight Gargoyle's real-art contract tests.
///
/// `gargoyle_envelope_test.dart` (every pose stays inside
/// `GargoyleLayout.envelope`, at both phone sizes), `gargoyle_budget_test.dart`
/// (ops, shaders and clips per frame, whole rig and per part) and
/// `gargoyle_silhouette_test.dart` (the negative-space gates) run against the
/// real art in `GargoyleBossRig`. The first-cut painters that ship with the
/// contract already pass them. Every part has landed (G1 head, G2 body, G3
/// wings, G5 beams, G6 feathers, G7 plate and card, G8 staging), so the switch
/// below is `true` by default: the same checks fail, each failure naming the
/// part, the pose and the coordinate that broke the rule. (Before the parts
/// landed, the real art only REPORTED what was over.)
///
/// To see the report without the failures (a study of a new part):
///   flutter test --no-pub --dart-define=GARGOYLE_ENFORCE=false \
///       test/gargoyle_envelope_test.dart test/gargoyle_budget_test.dart \
///       test/gargoyle_silhouette_test.dart
const enforceRealArt = bool.fromEnvironment(
  'GARGOYLE_ENFORCE',
  defaultValue: true,
);

/// How many time offsets of the animation the envelope sweep samples per state
/// (each shifts the idle sway's phase). 12 is quick; the final check before a
/// merge runs 40:
///   flutter test --no-pub --dart-define=GARGOYLE_PHASES=40 test/gargoyle_envelope_test.dart
const envelopePhases = int.fromEnvironment('GARGOYLE_PHASES', defaultValue: 3);
