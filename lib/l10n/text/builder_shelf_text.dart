import '../../domain/built_plan.dart' show BuiltPlan;
import '../generated/app_localizations.dart';

/// The Level Builder shelf's data words (owner: slice S5): the starter
/// levels' names. Their [BuiltPlan.name] in lib/domain/built_templates.dart
/// stays the English twin (tests, logs, the share code's text); a player's
/// own level keeps the name they typed, in whatever language they typed it.
/// test/l10n_s5_test.dart keeps the English ARB equal to the twins.
extension BuilderShelfText on AppLocalizations {
  /// The name to show for [plan]: a starter level's in the current
  /// language, anyone else's as it was saved.
  String builtLevelName(BuiltPlan plan) =>
      starterLevelName(plan.id) ?? plan.name;

  /// The starter level [id]'s name (lib/domain/built_templates.dart), or
  /// null when [id] is not a starter's.
  String? starterLevelName(String id) => switch (id) {
    't-tap-1' => starter_t_tap_1_name,
    't-push-1' => starter_t_push_1_name,
    't-squat-1' => starter_t_squat_1_name,
    't-jump-1' => starter_t_jump_1_name,
    't-tap-boss' => starter_t_tap_boss_name,
    _ => null,
  };
}
