import '../../domain/daily_adventure.dart';
import '../generated/app_localizations.dart';

/// The daily Adventure's words (slice S6). The domain keeps its English
/// twins ([DailyGoal.title], [DailyGoal.description], [DailyAdventure.title]);
/// the screens show these. test/l10n_menus_test.dart keeps them equal.
extension DailyText on AppLocalizations {
  /// "Spread your wings".
  String dailyTaskTitle(DailyTask task) => switch (task) {
    DailyTask.flights => task_flights_title,
    DailyTask.gates => task_gates_title,
    DailyTask.stars => task_stars_title,
    DailyTask.streak => task_streak_title,
    DailyTask.perfects => task_perfects_title,
    DailyTask.finishTrail => task_finishTrail_title,
  };

  /// "Finish 2 scored flights today."
  String dailyGoalText(DailyGoal goal) => switch (goal.task) {
    DailyTask.flights => task_flights_goal(goal.target),
    DailyTask.gates => task_gates_goal(goal.target),
    DailyTask.stars => task_stars_goal(goal.target),
    DailyTask.streak => task_streak_goal(goal.target),
    DailyTask.perfects => task_perfects_goal(goal.target),
    DailyTask.finishTrail => task_finishTrail_goal,
  };

  /// The day's postcard title: "Sunrise delivery".
  String dailyThemeTitle(int theme) => switch (theme % 6) {
    0 => dailyTheme_0,
    1 => dailyTheme_1,
    2 => dailyTheme_2,
    3 => dailyTheme_3,
    4 => dailyTheme_4,
    _ => dailyTheme_5,
  };
}
