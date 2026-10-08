import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/campaign.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/tracking.dart';
import 'package:push_up_bird/domain/tutorial.dart';

import 'built_pilot.dart';
import 'recorded_flight.dart';

/// Flies flight school as a new player would: the [TutorialCoach] holds the
/// moment at each new lesson, and the pilot does what it asks (a tap,
/// Shoot or Sprint) a beat later. Between lessons it flies the campaign
/// bot's lane and shoots now and then. [lazy] never flaps at all.
({FlightSimulation sim, TutorialCoach coach, List<TutorialLesson> lessons})
_flySchool({bool lazy = false, double seconds = 400}) {
  final sim = builtFlight(TutorialPlan.course);
  final coach = TutorialCoach();
  final lessons = <TutorialLesson>[];
  var now = 0.0;
  var held = 0;
  var charging = 0;
  for (var frame = 1; frame <= seconds * 50; frame++) {
    coach.update(.02, sim);
    if (lessons.isEmpty || lessons.last != coach.lesson) {
      lessons.add(coach.lesson);
    }
    if (coach.holding) {
      // Time stands still until the player acts, half a second later.
      if (++held < 25) continue;
      held = 0;
      final gesture = coach.waitingFor;
      expect(coach.act(CoachGesture.tap), gesture == CoachGesture.tap);
      switch (gesture) {
        case CoachGesture.tap:
          break;
        case CoachGesture.shoot:
          expect(coach.act(CoachGesture.shoot), isTrue);
          sim.shoot();
        case CoachGesture.holdShoot:
          expect(coach.act(CoachGesture.shoot), isTrue);
          sim.startCharge();
          charging = 1;
        case CoachGesture.sprint:
          expect(coach.act(CoachGesture.sprint), isTrue);
          sim.sprint();
        case CoachGesture.none:
          fail('held for nothing');
      }
      expect(coach.holding, isFalse);
    }
    now += 20;
    sim.apply(
      MovementInput(valid: true, height: .5, flap: !lazy && _pilot(sim)),
      builtSample(PlayMode.touch, now),
      now,
    );
    if (charging > 0 && ++charging > 60) {
      sim.shoot();
      charging = 0;
    } else if (!lazy && charging == 0 && frame % 9 == 0 && sim.canShoot) {
      sim.shoot();
    }
    sim.tick(.02, now, viewportWidth: 2.2);
    if (sim.phase == RunPhase.ended) break;
  }
  return (sim: sim, coach: coach, lessons: lessons);
}

/// The campaign bot's lane, but at a bat's height while one is ahead: a
/// player lines up with what they mean to shoot.
bool _pilot(FlightSimulation sim) {
  final bat = sim.enemies
      .where((e) => e.x > FlightSimulation.birdX + .1 && e.x < 1.8)
      .firstOrNull;
  if (bat == null || sim.boss != null) return rideTheSky(sim);
  return sim.birdY > bat.y + .03 && sim.velocity > 0;
}

void main() {
  test('flight school is a valid built level that ends with the captain', () {
    final plan = TutorialPlan.course;
    expect(plan.problem, isNull);
    expect(plan.boss, BossKind.pirate);
    expect(plan.forgiving, isTrue);
    expect(plan.rookieBoss, isTrue);
    expect(plan.touch && plan.shoot && plan.sprint, isTrue);
    expect(
      plan.items.whereType<BuiltGate>().where((g) => g.door),
      hasLength(1),
    );
  });

  test('a new player flies every lesson in order and beats the rookie '
      'captain', () {
    final (:sim, :coach, :lessons) = _flySchool();
    expect(lessons, TutorialLesson.values);
    expect(sim.endReason, EndReason.completed);
    expect(sim.bossesDefeated, 1);
    expect(coach.lesson, TutorialLesson.victory);
    expect(
      coach.passed,
      containsAll([
        TutorialLesson.flap,
        TutorialLesson.gates,
        TutorialLesson.shoot,
        TutorialLesson.power,
        TutorialLesson.sprint,
        TutorialLesson.boss,
      ]),
    );
    expect(sim.doorsDestroyed, 1);
    expect(sim.sprints, greaterThanOrEqualTo(1));
    // The whole lesson, holds aside, is short.
    expect(sim.elapsed, lessThan(150));
  });

  test('the rookie captain is a gentle fight', () {
    late SkyBoss captain;
    flyBuilt(
      builtFlight(TutorialPlan.course),
      keepAlive: true,
      watch: (sim) {
        if (sim.boss case final boss?) captain = boss;
      },
    );
    expect(captain.rookie, isTrue);
    expect(captain.staged, isTrue);
    expect(captain.maxHp, SkyBoss.rookieHp);
    expect(captain.maxHp, lessThan(SkyBoss.campaignHealthFor(BossKind.pirate)));
  });

  test('flight school never knocks the bird out', () {
    final (:sim, :coach, lessons: _) = _flySchool(lazy: true, seconds: 120);
    expect(sim.phase, isNot(RunPhase.ended));
    expect(sim.hearts, greaterThanOrEqualTo(1));
    expect(sim.fallsCaught, greaterThan(0));
    expect(coach.line, isNotNull);
  });

  test('a Sprint still recharging never strands a held lesson', () {
    final sim = builtFlight(TutorialPlan.course);
    final coach = TutorialCoach()..waitingFor = CoachGesture.sprint;
    // Sprint cannot answer (here: the flight has not begun).
    expect(sim.canSprint, isFalse);
    coach.update(.02, sim);
    expect(coach.holding, isFalse);
    expect(coach.timeScale, 1);
  });

  test('the campaign captain is no rookie', () {
    final level = Campaign.level('4-8')!;
    expect(level.plan.forgiving, isFalse);
    expect(level.plan.rookieBoss, isFalse);
    expect(FlightPlan.endless.forgiving, isFalse);
    expect(FlightPlan.endless.rookieBoss, isFalse);
  });
}
