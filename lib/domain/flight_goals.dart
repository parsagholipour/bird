import 'game_rules.dart';

enum FlightGoalMetric { gates, stars, streak, flightSeconds }

class FlightGoal {
  const FlightGoal(this.title, this.description, this.metric, this.target);
  final String title, description;
  final FlightGoalMetric metric;
  final int target;
}

class FlightGoalProgress {
  const FlightGoalProgress(this.goal, this.current);
  final FlightGoal goal;
  final int current;
  bool get earned => current >= goal.target;
  int get displayed => current.clamp(0, goal.target);
  int get remaining => (goal.target - current).clamp(0, goal.target);
  double get fraction => (current / goal.target).clamp(0.0, 1.0);
}

/// Three goals belong to one scored flight. Saved statistics are the source of
/// truth, so old results, local replays and duplicate saves need no new state.
abstract final class FlightGoals {
  static List<FlightGoal> forCourse(FlightCourse course) => switch (course) {
    FlightCourse.classic => const [
      FlightGoal(
        'Find your wings',
        'Clear 5 gates.',
        FlightGoalMetric.gates,
        5,
      ),
      FlightGoal(
        'Keep it going',
        'Clear 10 gates.',
        FlightGoalMetric.gates,
        10,
      ),
      FlightGoal('Own the sky', 'Clear 25 gates.', FlightGoalMetric.gates, 25),
    ],
    FlightCourse.starTrail => const [
      FlightGoal(
        'Star pocket',
        'Collect 12 stars.',
        FlightGoalMetric.stars,
        12,
      ),
      FlightGoal(
        'Stay sparkling',
        'Reach a 6-star streak.',
        FlightGoalMetric.streak,
        6,
      ),
      FlightGoal(
        'Whole horizon',
        'Fly for 60 seconds in one trail.',
        FlightGoalMetric.flightSeconds,
        60,
      ),
    ],
  };

  static List<FlightGoalProgress> forRun(RunResult run) => _progress(
    run.course,
    practice: run.practice,
    gates: run.gates,
    stars: run.stars,
    streak: run.bestCombo,
    score: run.score,
    duration: run.durationSeconds,
  );

  static List<FlightGoalProgress> forSimulation(FlightSimulation sim) =>
      _progress(
        sim.course,
        practice: sim.practice,
        gates: sim.gates,
        stars: sim.collectedStars,
        streak: sim.bestCombo,
        score: sim.score,
        duration: sim.elapsed,
      );

  static List<FlightGoalProgress> _progress(
    FlightCourse course, {
    required bool practice,
    required int gates,
    required int stars,
    required int streak,
    required int score,
    required double duration,
  }) {
    if (practice) return const [];
    return [
      for (final goal in forCourse(course))
        FlightGoalProgress(goal, switch (goal.metric) {
          FlightGoalMetric.gates => gates,
          FlightGoalMetric.stars => stars,
          FlightGoalMetric.streak => streak,
          FlightGoalMetric.flightSeconds => duration.floor(),
        }),
    ];
  }

  static int earned(Iterable<FlightGoalProgress> goals) =>
      goals.where((g) => g.earned).length;
}
