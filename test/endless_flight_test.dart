import 'dart:math';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/data/passport_progress.dart';
import 'package:push_up_bird/data/progress_repository.dart';
import 'package:push_up_bird/domain/daily_adventure.dart';
import 'package:push_up_bird/domain/flight_goals.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/session_replay.dart';
import 'package:push_up_bird/domain/sky_passport.dart';
import 'package:push_up_bird/domain/tracking.dart';
import 'package:push_up_bird/game/arrival_art.dart';
import 'replay_highlights_test.dart' show recordRoute;

void step(FlightSimulation sim, double now, {double dt = .02, double? y}) {
  sim.apply(
    MovementInput(valid: true, height: (.85 - (y ?? sim.birdY)) / .7),
    TrackingSample(
      mode: sim.rules.mode,
      timestampMs: now,
      receivedMs: now,
      joints: const [],
    ),
    now,
  );
  sim.tick(dt, now);
}

void main() {
  test(
    'endless survival earns saved stamps and daily goals only once per scored flight',
    () async {
      final date = DateTime(2026, 1, 1, 12);
      final repo = SqliteProgressRepository(
        ProgressDatabase(NativeDatabase.memory()),
        clock: () => date,
      );
      addTearDown(repo.close);
      for (final (id, seconds, reason, practice, course) in [
        ('short', 59.99, EndReason.collision, false, FlightCourse.starTrail),
        ('minute', 60.0, EndReason.collision, false, FlightCourse.starTrail),
        ('break', 120.0, EndReason.breakTaken, false, FlightCourse.starTrail),
        ('quit', 180.0, EndReason.quit, false, FlightCourse.starTrail),
        ('quit', 180.0, EndReason.quit, false, FlightCourse.starTrail),
        ('practice', 180.0, EndReason.quit, true, FlightCourse.starTrail),
        ('courier', 180.0, EndReason.quit, false, FlightCourse.skyCourier),
      ]) {
        await repo.saveRun(
          RunResult(
            id: id,
            mode: PlayMode.pushUp,
            practice: practice,
            course: course,
            score: 0,
            repetitions: 0,
            flaps: 0,
            durationSeconds: seconds,
            reason: reason,
            finishedAt: date,
          ),
        );
      }
      final saved = await repo.load();
      expect(saved.trailCompletions, 3);
      expect(
        saved.passport
            .singleWhere((p) => p.stamp == SkyStamp.trailblazer)
            .earned,
        isTrue,
      );
      expect(
        saved.today!.goals
            .singleWhere((g) => g.task == DailyTask.finishTrail)
            .current,
        3,
      );
    },
  );

  for (final course in FlightCourse.values) {
    for (final squat in [false, true]) {
      for (final cycle in [1.0, 4.0, 9.0]) {
        test(
          '$course ${squat ? 'squat' : 'push-up'} $cycle cadence lasts five minutes',
          () {
            final sim = FlightSimulation(
              rules: squat
                  ? SquatFlyMode(cycleSeconds: cycle)
                  : PushUpFlightMode(cycleSeconds: cycle),
              practice: false,
              course: course,
              random: Random(42),
            );
            final seen = <ObstacleKind>{};
            final initialSpeed = sim.speed;
            var largestWorld = 0;
            for (
              var frame = 0;
              frame < 15300 && sim.phase != RunPhase.ended;
              frame++
            ) {
              final ahead = sim.obstacles.where((o) => !o.scored);
              final target = ahead.isEmpty ? .15 : ahead.first.target;
              final maxStep = .7 / (cycle / 2) * .02;
              final y =
                  sim.birdY + (target - sim.birdY).clamp(-maxStep, maxStep);
              step(sim, (frame + 1) * 20.0, y: y);
              seen.addAll(sim.obstacles.map((o) => o.kind));
              largestWorld = max(
                largestWorld,
                sim.obstacles.length +
                    sim.stars.length +
                    sim.starTrios.length +
                    sim.clouds.length +
                    sim.events.length,
              );
            }
            expect(sim.phase, RunPhase.playing);
            expect(sim.elapsed, greaterThan(300));
            expect(sim.endReason, isNull);
            expect(sim.hearts, 3);
            expect(sim.shield, isTrue);
            expect(sim.courierBumps, 0);
            expect(sim.speed, greaterThan(initialSpeed));
            expect(seen, ObstacleKind.values.toSet());
            expect(
              largestWorld,
              lessThan(100),
              reason: 'Passed objects are retired during endless flights',
            );
            expect(ArrivalPose.forFlight(sim), isNull);
            if (course.collectsStars) {
              expect(sim.collectedStars, greaterThan(30));
              expect(sim.bestCombo, sim.collectedStars);
            }
            if (!course.relaxed) {
              expect(FlightGoals.forSimulation(sim).last.earned, isTrue);
            }
          },
        );
      }
    }
  }

  test(
    'all controls accelerate gradually with time, independently of rewards',
    () {
      for (final rules in <GameMode>[
        PushUpFlightMode(cycleSeconds: 3),
        SquatFlyMode(cycleSeconds: 3),
        JumpFlyMode(),
        TapFlyMode(),
      ]) {
        final sim = FlightSimulation(
          rules: rules,
          practice: false,
          course: FlightCourse.starTrail,
        );
        final initial = sim.speed;
        var previous = initial;
        for (var second = 1; second <= 3600; second++) {
          sim.elapsed = second.toDouble();
          expect(sim.speed, greaterThanOrEqualTo(previous));
          expect(sim.speed - previous, lessThan(initial * .003));
          expect(sim.speed, lessThanOrEqualTo(initial * 1.65));
          previous = sim.speed;
        }
        sim.score = 100000;
        sim.gates = 100000;
        expect(sim.speed, previous);
        expect(sim.clockLabel, '60:00');
      }
    },
  );

  test(
    'old trails and couriers retain their timer, finish cue and static gates',
    () {
      for (final course in [FlightCourse.starTrail, FlightCourse.skyCourier]) {
        final sim =
            FlightSimulation(
                rules: PushUpFlightMode(cycleSeconds: 3),
                practice: false,
                course: course,
                rulesVersion: 11,
                random: Random(3),
              )
              ..phase = RunPhase.playing
              ..started = true
              ..elapsed = course.duration - 10.01;
        step(sim, 20, y: .5);
        expect(
          sim.events.where((e) => e.kind == FlightEventKind.finalStretch),
          hasLength(1),
        );
        expect(
          sim.obstacles.every((o) => o.kind == ObstacleKind.garden),
          isTrue,
        );
        sim.elapsed = course.duration - .01;
        step(sim, 40, y: .5);
        expect(sim.elapsed, course.duration);
        expect(sim.endReason, EndReason.completed);
      }
    },
  );

  test('the moving opening determines collisions, even on a slow frame', () {
    for (final phase in [-pi / 2, pi / 2]) {
      final sim =
          FlightSimulation(
              rules: PushUpFlightMode(cycleSeconds: 3),
              practice: false,
            )
            ..phase = RunPhase.playing
            ..started = true;
      sim.obstacles.add(
        Obstacle(
          x: FlightSimulation.birdX,
          center: .5,
          gap: .3,
          kind: ObstacleKind.windLift,
          amplitude: .12,
          phaseOffset: phase,
          period: 1000,
        ),
      );
      step(sim, 200, dt: .2, y: .62);
      expect(sim.endReason, phase < 0 ? EndReason.collision : isNull);
    }
  });

  test(
    'switchback collision uses both offset columns and the gap between them',
    () {
      for (final (offset, y, hit) in [
        (0.0, .39, false),
        (.14, .39, true),
        (.115, .5, false),
      ]) {
        final sim =
            FlightSimulation(
                rules: PushUpFlightMode(cycleSeconds: 3),
                practice: false,
              )
              ..phase = RunPhase.playing
              ..started = true;
        sim.obstacles.add(
          Obstacle(
            x: FlightSimulation.birdX - offset,
            center: .5,
            gap: .3,
            width: .24,
            kind: ObstacleKind.switchback,
            amplitude: .08,
            phaseOffset: pi / 2,
            period: 1000,
          ),
        );
        step(sim, 20, y: y);
        expect(sim.endReason, hit ? EndReason.collision : isNull);
      }
    },
  );

  test('motion freezes with practice and pickups follow the opening', () {
    final sim =
        FlightSimulation(
            rules: PushUpFlightMode(cycleSeconds: 3),
            practice: true,
          )
          ..phase = RunPhase.playing
          ..started = true;
    final obstacle = Obstacle(
      x: 1.5,
      center: .5,
      gap: .4,
      kind: ObstacleKind.windLift,
      amplitude: .06,
    );
    sim.obstacles.add(obstacle);
    final star = SkyStar(x: 1.2, y: .5, passage: obstacle);
    step(sim, 100, dt: .1, y: .5);
    expect(star.y, obstacle.target);
    expect(star.y, isNot(.5));
    final before = obstacle.center;
    sim.takeBreak();
    sim.tick(.4, 500);
    expect(obstacle.center, before);
    sim.resume();
    step(sim, 600, y: .5);
    expect(obstacle.center, before);
  });

  test(
    'new replay journals reproduce shuffled motion through backwards seeks',
    () {
      final tape = recordRoute(FlightCourse.starTrail, seconds: 180);
      expect(tape.recordedVersion, FlightSimulation.currentRulesVersion);
      final replay = ReplayPlayer(ReplayTape.fromJson(tape.toJson()));
      for (final time in [
        90000.0,
        130000.0,
        30000.0,
        90000.0,
        tape.durationMs,
      ]) {
        replay.seek(time);
        final reference = ReplayPlayer(tape)..seek(time);
        final a = replay.simulation, b = reference.simulation;
        expect(a.score, b.score);
        expect(a.speed, b.speed);
        expect(
          a.obstacles.map(
            (o) => [
              o.kind,
              o.appearance,
              o.x,
              o.center,
              o.gap,
              o.target,
              o.orbs.map((b) => [b.x, b.y]).toList(),
            ],
          ),
          b.obstacles.map(
            (o) => [
              o.kind,
              o.appearance,
              o.x,
              o.center,
              o.gap,
              o.target,
              o.orbs.map((b) => [b.x, b.y]).toList(),
            ],
          ),
        );
      }
      expect(replay.simulation.elapsed, greaterThan(179));
      expect(replay.simulation.endReason, EndReason.quit);
    },
  );
}
