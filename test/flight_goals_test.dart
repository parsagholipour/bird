import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/flight_goals.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/tracking.dart';

RunResult flight({
  FlightCourse course = FlightCourse.classic,
  int score = 0,
  int? gates,
  int stars = 0,
  int combo = 0,
  double seconds = 0,
  bool practice = false,
  EndReason reason = EndReason.quit,
}) => RunResult(
  id: 'flight',
  mode: PlayMode.pushUp,
  course: course,
  practice: practice,
  score: score,
  gates: gates,
  stars: stars,
  bestCombo: combo,
  repetitions: 0,
  flaps: 0,
  durationSeconds: seconds,
  reason: reason,
  finishedAt: DateTime(2026, 9, 16),
);

void main() {
  test('Classic wings follow exact cleared-gate thresholds', () {
    for (final (gates, count) in [
      (0, 0),
      (4, 0),
      (5, 1),
      (9, 1),
      (10, 2),
      (24, 2),
      (25, 3),
      (100, 3),
    ]) {
      final goals = FlightGoals.forRun(flight(score: gates));
      expect(FlightGoals.earned(goals), count);
      for (final goal in goals) {
        expect(goal.fraction, inInclusiveRange(0, 1));
        expect(goal.displayed, lessThanOrEqualTo(goal.goal.target));
        expect(goal.remaining, greaterThanOrEqualTo(0));
      }
    }
    expect(
      FlightGoals.earned(FlightGoals.forRun(flight(score: 100, gates: 4))),
      0,
    );
  });

  test('Star Trail uses stars and best streak, never multiplied points', () {
    final empty = FlightGoals.forRun(
      flight(course: FlightCourse.starTrail, score: 200),
    );
    expect(FlightGoals.earned(empty), 0);
    final streak = FlightGoals.forRun(
      flight(course: FlightCourse.starTrail, stars: 6, combo: 6),
    );
    expect(streak.map((g) => g.earned), [false, true, false]);
    final stars = FlightGoals.forRun(
      flight(course: FlightCourse.starTrail, stars: 12, combo: 5),
    );
    expect(stars.map((g) => g.earned), [true, false, false]);
    final all = FlightGoals.forRun(
      flight(
        course: FlightCourse.starTrail,
        stars: 12,
        combo: 6,
        seconds: 60,
        reason: EndReason.completed,
      ),
    );
    expect(FlightGoals.earned(all), 3);
  });

  test('endurance wings count time regardless of how the flight ends', () {
    for (final course in [FlightCourse.starTrail]) {
      for (final reason in EndReason.values.where(
        (r) => r != EndReason.completed,
      )) {
        final goal = FlightGoals.forRun(
          flight(course: course, seconds: course.duration, reason: reason),
        ).last;
        expect(goal.earned, isTrue);
        expect(goal.fraction, 1);
      }
      expect(
        FlightGoals.forRun(
          flight(
            course: course,
            seconds: course.duration - .001,
            reason: EndReason.completed,
          ),
        ).last.earned,
        isFalse,
      );
      expect(
        FlightGoals.forRun(
          flight(
            course: course,
            seconds: course.duration,
            reason: EndReason.completed,
          ),
        ).last.earned,
        isTrue,
      );
    }
  });

  test('practice flights never earn or display flight wings', () {
    for (final course in FlightCourse.values) {
      expect(
        FlightGoals.forRun(
          flight(
            course: course,
            practice: true,
            score: 999,
            stars: 999,
            combo: 999,
            seconds: 999,
            reason: EndReason.completed,
          ),
        ),
        isEmpty,
      );
    }
  });

  test('live, saved and replay-derived progress agree for either control', () {
    for (final mode in PlayMode.values) {
      for (final course in FlightCourse.values) {
        final sim =
            FlightSimulation(
                rules: mode == PlayMode.pushUp
                    ? PushUpFlightMode(cycleSeconds: 3)
                    : JumpFlyMode(),
                practice: false,
                course: course,
              )
              ..score = 3
              ..gates = 6
              ..collectedStars = 12
              ..bestCombo = 6
              ..combo = 0
              ..elapsed = course.duration;
        sim.end(EndReason.completed);
        final saved = flight(
          course: course,
          score: 3,
          gates: 6,
          stars: 12,
          combo: 6,
          seconds: course.duration,
          reason: EndReason.completed,
        );
        expect(
          FlightGoals.forSimulation(sim).map((g) => g.current),
          FlightGoals.forRun(saved).map((g) => g.current),
        );
      }
    }
  });
}
