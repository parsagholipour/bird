import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/flight_school.dart';
import 'package:push_up_bird/domain/game_rules.dart';

void start(FlightSchool school) {
  school.start();
  for (var i = 0; i < 160; i++) {
    school.advance(.02, 2.2);
  }
}

void main() {
  test('lessons wait for start, use local inputs and are always practice', () {
    for (final course in FlightCourse.values) {
      for (final control in SchoolControl.values) {
        final school = FlightSchool(course: course, control: control);
        school.advance(.2, 2.2);
        expect(school.simulation.started, isFalse);
        start(school);
        expect(school.simulation.started, isTrue);
        expect(school.simulation.practice, isTrue);
        expect(school.simulation.obstacles, isNotEmpty);
        expect(school.simulation.phase, RunPhase.playing);
      }
    }
  });
  test(
    'drag reaches the full range, clamps boundaries and ignores nonfinite input',
    () {
      final school = FlightSchool(
        course: FlightCourse.starTrail,
        control: SchoolControl.drag,
      );
      start(school);
      school.dragTo(-3);
      school.advance(.02, 2.2);
      expect(school.simulation.birdY, closeTo(.15, 1e-10));
      school.dragTo(8);
      school.advance(.02, 2.2);
      expect(school.simulation.birdY, .85);
      school.dragTo(double.nan);
      school.flap();
      school.advance(.02, 2.2);
      expect(school.simulation.birdY, .85);
      expect(school.simulation.flaps, 0);
    },
  );
  test(
    'a tap creates one flap, while held frames and drag do not repeat it',
    () {
      final school = FlightSchool(
        course: FlightCourse.starTrail,
        control: SchoolControl.tap,
      );
      start(school);
      school.flap();
      school.advance(.02, 2.2);
      expect(school.simulation.flaps, 1);
      expect(school.simulation.velocity, lessThan(0));
      school.dragTo(.15);
      for (var i = 0; i < 10; i++) {
        school.advance(.02, 2.2);
      }
      expect(school.simulation.flaps, 1);
      school.flap();
      school.advance(.02, 2.2);
      expect(school.simulation.flaps, 2);
    },
  );
  test('pause clears queued taps and resume needs a fresh countdown', () {
    final school = FlightSchool(
      course: FlightCourse.starTrail,
      control: SchoolControl.tap,
    );
    start(school);
    school.flap();
    school.pause();
    final time = school.simulation.elapsed;
    school.advance(.3, 2.2);
    expect(school.simulation.elapsed, time);
    school.resume();
    school.advance(.1, 2.2);
    expect(school.simulation.phase, RunPhase.countdown);
    expect(school.simulation.elapsed, time);
    for (var i = 0; i < 160; i++) {
      school.advance(.02, 2.2);
    }
    expect(school.simulation.flaps, 0);
    school.advance(2, 2.2);
    expect(school.simulation.phase, RunPhase.paused);
  });
  test('every lesson uses the actual course rewards and ending rules', () {
    for (final course in FlightCourse.values) {
      final school = FlightSchool(course: course, control: SchoolControl.drag);
      start(school);
      for (
        var i = 0;
        i < 4000 && school.simulation.phase != RunPhase.ended;
        i++
      ) {
        final ahead = school.simulation.obstacles.where((o) => !o.scored);
        school.dragTo(ahead.isEmpty ? .5 : ahead.first.target);
        school.advance(.02, 2.2);
      }
      expect(school.simulation.gates, greaterThan(5));
      expect(school.simulation.phase, RunPhase.playing);
      expect(school.simulation.elapsed, greaterThan(75));
      if (course.collectsStars) {
        expect(school.simulation.completedTrios, greaterThan(0));
      }
    }
  });
}
