import 'game_rules.dart';

/// Calendar goals are reproducible offline and independent of movement controls.
enum DailyTask { flights, gates, stars, streak, perfects, finishTrail }

String localDayKey(DateTime date) {
  final local = date.toLocal();
  return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
}

class DailyGoal {
  const DailyGoal(this.task, this.target, this.current);
  final DailyTask task;
  final int target, current;
  bool get complete => current >= target;
  double get fraction => (current / target).clamp(0.0, 1.0);
  int get displayed => current.clamp(0, target);
  String get title => switch (task) {
    DailyTask.flights => 'Spread your wings',
    DailyTask.gates => 'Open horizons',
    DailyTask.stars => 'Pocketful of stars',
    DailyTask.streak => 'Keep the sparkle',
    DailyTask.perfects => 'Right on the mark',
    DailyTask.finishTrail => 'The whole journey',
  };
  String get description => switch (task) {
    DailyTask.flights => 'Finish $target scored flights today.',
    DailyTask.gates => 'Clear $target gates across today’s scored flights.',
    DailyTask.stars => 'Collect $target stars across today’s flights.',
    DailyTask.streak => 'Collect $target stars in one unbroken streak.',
    DailyTask.perfects => 'Fly $target perfect passes today.',
    DailyTask.finishTrail => 'Fly for at least 60 seconds in one Star Trail.',
  };
}

class DailyAdventure {
  DailyAdventure._(this.date, this.goals, this.theme);
  final DateTime date;
  final List<DailyGoal> goals;
  final int theme;
  String get dayKey => localDayKey(date);
  int get completedGoals => goals.where((g) => g.complete).length;
  bool get complete => completedGoals == goals.length;
  String get title => const [
    'Sunrise delivery',
    'Peach picnic',
    'Moonlit mail',
    'Cloud parade',
    'Twilight treasure',
    'Garden party',
  ][theme];

  factory DailyAdventure.forDate(DateTime date, Iterable<RunResult> runs) {
    final local = date.toLocal();
    final day = DateTime(local.year, local.month, local.day);
    // UTC calendar arithmetic keeps the rotation stable across DST changes.
    final ordinal = DateTime.utc(
      local.year,
      local.month,
      local.day,
    ).difference(DateTime.utc(2026)).inDays;
    final key = localDayKey(day);
    final eligible = <String, RunResult>{
      for (final run in runs)
        if (!run.practice && localDayKey(run.finishedAt) == key) run.id: run,
    }.values;
    var flights = 0,
        gates = 0,
        stars = 0,
        streak = 0,
        perfects = 0,
        finishes = 0;
    for (final run in eligible) {
      flights++;
      gates += run.gates;
      perfects += run.perfectPasses;
      if (run.course == FlightCourse.starTrail) {
        stars += run.stars;
        if (run.bestCombo > streak) streak = run.bestCombo;
        // "The whole journey" is an endless Star Trail; a campaign level
        // has its own finish line.
        if (run.levelId == null &&
            run.durationSeconds >= FlightSimulation.trailDuration) {
          finishes++;
        }
      }
    }
    return DailyAdventure._(
      day,
      List.unmodifiable([
        ordinal % 2 == 0
            ? DailyGoal(DailyTask.flights, 2, flights)
            : DailyGoal(DailyTask.gates, 8, gates),
        (ordinal ~/ 2) % 2 == 0
            ? DailyGoal(DailyTask.stars, 18, stars)
            : DailyGoal(DailyTask.streak, 9, streak),
        ordinal % 3 == 0
            ? DailyGoal(DailyTask.finishTrail, 1, finishes)
            : DailyGoal(DailyTask.perfects, 3, perfects),
      ]),
      ordinal % 6,
    );
  }
}
