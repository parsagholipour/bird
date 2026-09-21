import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/session_replay.dart';
import 'package:push_up_bird/domain/tracking.dart';
import 'package:push_up_bird/data/progress_repository.dart';
import 'package:push_up_bird/data/passport_progress.dart';
import 'package:push_up_bird/domain/sky_passport.dart';
import 'star_magnet_test.dart' show FlightHarness;

void pass(FlightHarness h, CourierStop stop, {bool hit = false}) {
  h.sim.obstacles.clear();
  h.sim.obstacles.add(
    Obstacle(
      x: FlightSimulation.birdX - FlightSimulation.birdRadius - .141,
      center: .5,
      gap: .45,
      courierStop: stop,
    )..hit = hit,
  );
  h.step();
}

void bump(FlightHarness h) {
  h.sim.obstacles.clear();
  h.sim.obstacles.add(
    Obstacle(x: FlightSimulation.birdX, center: .15, gap: .3),
  );
  h.step();
}

void main() {
  test(
    'version 3 star flights keep their score and physics under the new reader',
    () {
      double now = 0;
      final current = ReplayTape(
        recordedVersion: 11,
        mode: PlayMode.pushUp,
        practice: false,
        seed: 5,
        cycleSeconds: 3,
        bird: 0,
        reducedMotion: true,
        originMs: 0,
        course: FlightCourse.starTrail,
      );
      final old = ReplayTape.fromJson(current.toJson()..['version'] = 3);
      expect(old.toJson()['version'], 3);
      final recorders = [
        FlightRecorder(current, () => now),
        FlightRecorder(old, () => now),
      ];
      for (var i = 0; i < 3300; i++) {
        now += 20;
        final sim = recorders.first.simulation;
        final ahead = sim.obstacles.where((o) => !o.scored);
        final target = ahead.isEmpty ? .5 : ahead.first.target;
        for (final recorder in recorders) {
          recorder.apply(
            MovementInput(valid: true, height: (.85 - target) / .7),
            TrackingSample(
              mode: PlayMode.pushUp,
              timestampMs: now,
              receivedMs: now,
              joints: const [],
            ),
            now,
          );
          recorder.tick(.02, now, 2.2);
        }
      }
      final a = recorders.first.simulation, b = recorders.last.simulation;
      expect(b.score, a.score - a.completedTrios * StarTrio.bonus);
      expect(b.score, 131);
      expect(b.completedTrios, 0);
      expect(b.gates, a.gates);
      expect(b.magnetUntil, a.magnetUntil);
      expect(b.collectedStars, a.collectedStars);
      expect(b.hearts, a.hearts);
      expect(b.endReason, a.endReason);
    },
  );
  test('courier needs a letter and a clean postbox; cargo never stacks', () {
    final h = FlightHarness(course: FlightCourse.skyCourier);
    pass(h, CourierStop.postbox);
    expect(h.sim.score, 0);
    expect(h.sim.obstacles.first.courierActionAt, isNull);
    pass(h, CourierStop.pickup);
    expect(h.sim.carryingLetter, isTrue);
    expect(h.sim.lettersCollected, 1);
    expect(h.sim.obstacles.first.courierActionAt, isNotNull);
    final pickup = h.sim.events.lastWhere(
      (e) => e.kind == FlightEventKind.letter,
    );
    expect(
      pickup.gateWorldX! - h.sim.distance,
      closeTo(h.sim.obstacles.first.x + h.sim.obstacles.first.width / 2, 1e-10),
    );
    expect(pickup.gateY, h.sim.obstacles.first.target);
    expect(h.sim.score, 0);
    pass(h, CourierStop.pickup);
    expect(h.sim.lettersCollected, 1);
    expect(h.sim.obstacles.first.courierActionAt, isNull);
    pass(h, CourierStop.postbox);
    expect(h.sim.score, 1);
    expect(h.sim.obstacles.first.courierActionAt, isNotNull);
    expect(h.sim.carryingLetter, isFalse);
    pass(h, CourierStop.postbox);
    expect(h.sim.score, 1);
    pass(h, CourierStop.pickup, hit: true);
    expect(h.sim.carryingLetter, isFalse);
    expect(h.sim.supportsMagnet, isFalse);
    expect(h.sim.stars, isEmpty);
    expect(h.sim.collectedStars, 0);
  });

  test('bumps drop cargo once and leave a route playable', () {
    final h = FlightHarness(course: FlightCourse.skyCourier);
    pass(h, CourierStop.pickup);
    bump(h);
    expect(h.sim.carryingLetter, isFalse);
    expect(h.sim.lettersDropped, 1);
    expect(h.sim.courierBumps, 1);
    expect(h.sim.phase, RunPhase.playing);
    expect(h.sim.hearts, 3);
    expect(h.sim.recoveryRemaining, greaterThan(1.4));
    bump(h);
    expect(h.sim.courierBumps, 1);
    expect(h.sim.lettersDropped, 1);
    pass(h, CourierStop.postbox);
    expect(h.sim.score, 0);
    h.sim.elapsed += 2;
    pass(h, CourierStop.pickup);
    pass(h, CourierStop.postbox);
    expect(h.sim.score, 1);
    expect(h.sim.gates, 4);
  });

  test('courier continues beyond 75 seconds without a final countdown', () {
    final h = FlightHarness(course: FlightCourse.skyCourier);
    h.sim.elapsed = 49.99;
    h.step();
    expect(
      h.sim.events.where((e) => e.kind == FlightEventKind.finalStretch),
      isEmpty,
    );
    h.sim.elapsed = 59.99;
    h.step();
    expect(h.sim.phase, RunPhase.playing);
    h.sim.elapsed = 64.99;
    h.step();
    expect(
      h.sim.events.where((e) => e.kind == FlightEventKind.finalStretch),
      isEmpty,
    );
    h.step();
    expect(
      h.sim.events.where((e) => e.kind == FlightEventKind.finalStretch),
      isEmpty,
    );
    h.sim.elapsed = 74.99;
    h.step();
    expect(h.sim.endReason, isNull);
    expect(h.sim.elapsed, greaterThan(75));
  });

  test('courier practice freezes cargo and clock while paused', () {
    final h = FlightHarness(course: FlightCourse.skyCourier, practice: true);
    pass(h, CourierStop.pickup);
    h.sim.takeBreak();
    final elapsed = h.sim.elapsed;
    h.step(.4);
    expect(h.sim.elapsed, elapsed);
    expect(h.sim.carryingLetter, isTrue);
    h.sim.resume();
    h.step(.2);
    expect(h.sim.elapsed, elapsed);
    expect(h.sim.carryingLetter, isTrue);
  });

  for (final cycle in [1.0, 4.0, 9.0]) {
    test('courier fits a calibrated $cycle-second push-up cycle', () {
      final sim = FlightSimulation(
        rules: PushUpFlightMode(cycleSeconds: cycle),
        practice: false,
        course: FlightCourse.skyCourier,
        random: Random(7),
      );
      double now = 0, height = 1;
      for (var i = 0; i < 4100 && sim.phase != RunPhase.ended; i++) {
        now += 20;
        final ahead = sim.obstacles.where(
          (o) =>
              o.x + o.width >=
              FlightSimulation.birdX - FlightSimulation.birdRadius,
        );
        final target = ahead.isEmpty ? 1.0 : (.85 - ahead.first.target) / .7;
        height += (target - height).clamp(-.02 * 2 / cycle, .02 * 2 / cycle);
        sim.apply(
          MovementInput(valid: true, height: height),
          TrackingSample(
            mode: PlayMode.pushUp,
            timestampMs: now,
            receivedMs: now,
            joints: const [],
          ),
          now,
        );
        sim.tick(.02, now);
      }
      expect(sim.phase, RunPhase.playing);
      expect(sim.courierBumps, 0);
      expect(sim.lettersDropped, 0);
      expect(sim.score, greaterThan(2));
      expect(sim.score, sim.gates ~/ 2);
      expect(sim.perfectPasses, sim.gates);
    });
  }

  for (final mode in PlayMode.values) {
    test(
      '$mode courier cargo and deliveries replay after backward seeking',
      () {
        double now = 0;
        final tape = ReplayTape(
          mode: mode,
          practice: false,
          seed: 18,
          cycleSeconds: 3,
          bird: 0,
          reducedMotion: false,
          originMs: 0,
          course: FlightCourse.skyCourier,
        );
        final recorder = FlightRecorder(tape, () => now);
        final checkpoints = <double, List<Object?>>{};
        List<Object?> state(FlightSimulation s) => [
          s.score,
          s.gates,
          s.elapsed,
          s.carryingLetter,
          s.lettersCollected,
          s.lettersDropped,
          s.courierBumps,
          s.birdY,
          s.phase,
          s.endReason,
          for (final o in s.obstacles)
            [o.x, o.target, o.courierStop, o.hit, o.scored, o.courierActionAt],
          for (final e in s.events.where((e) => e.gateWorldX != null))
            [e.kind, e.at, e.y, e.gateWorldX, e.gateY],
        ];
        for (var i = 0; i < 4100; i++) {
          now += 20;
          final sim = recorder.simulation;
          final ahead = sim.obstacles.where(
            (o) =>
                o.x + o.width >=
                FlightSimulation.birdX - FlightSimulation.birdRadius,
          );
          final target = ahead.isEmpty ? .5 : ahead.first.target;
          // A jump's higher arc must start below the passage center.
          final flapAt = (target + (mode == PlayMode.jump ? .13 : 0)).clamp(
            .15,
            .88,
          );
          recorder.apply(
            MovementInput(
              valid: true,
              height: (.85 - target) / .7,
              flap:
                  !mode.controlsHeight &&
                  sim.birdY > flapAt &&
                  sim.velocity >= 0,
            ),
            TrackingSample(
              mode: mode,
              timestampMs: now,
              receivedMs: now,
              joints: const [],
            ),
            now,
          );
          recorder.tick(.02, now, 2.2);
          if (i % 137 == 0) checkpoints[now] = state(sim);
          if (sim.phase == RunPhase.ended) break;
        }
        final sim = recorder.simulation;
        expect(sim.phase, RunPhase.playing);
        expect(sim.score, greaterThan(1));
        final player = ReplayPlayer(ReplayTape.fromJson(tape.toJson()));
        player.seek(tape.durationMs);
        expect(state(player.simulation), state(sim));
        for (final time in checkpoints.keys.toList().reversed) {
          player.seek(time);
          expect(state(player.simulation), checkpoints[time]);
        }
      },
    );
  }

  test(
    'courier records remain separate and clean gates count toward the flock',
    () async {
      final repo = SqliteProgressRepository(
        ProgressDatabase(NativeDatabase.memory()),
      );
      addTearDown(repo.close);
      for (final mode in PlayMode.values) {
        final run = RunResult(
          id: mode.name,
          mode: mode,
          practice: false,
          course: FlightCourse.skyCourier,
          score: 5,
          gates: 14,
          repetitions: 12,
          flaps: 30,
          durationSeconds: 75,
          reason: EndReason.completed,
          finishedAt: DateTime.now(),
        );
        await repo.saveRun(run);
        await repo.saveRun(run);
        await repo.saveRun(
          RunResult(
            id: 'practice-${mode.name}',
            mode: mode,
            practice: true,
            course: FlightCourse.skyCourier,
            score: 100,
            gates: 200,
            repetitions: 100,
            flaps: 100,
            durationSeconds: 75,
            reason: EndReason.completed,
            finishedAt: DateTime.now(),
          ),
        );
      }
      final p = await repo.load();
      expect(p.courierPushUp.best, 5);
      expect(p.courierJump.best, 5);
      expect(p.courierTouch.best, 5);
      expect(p.pushUp.best, 0);
      expect(p.trailPushUp.best, 0);
      expect(p.totalObstacles, 14 * PlayMode.values.length);
      expect(p.totalRuns, PlayMode.values.length);
      expect(p.totalRepetitions, 12);
      expect(p.trailCompletions, 0);
      expect(p.totalStars, 0);
      expect(p.recent, hasLength(PlayMode.values.length));
      expect(p.unlocked, contains(1));
      expect(
        p.passport.firstWhere((s) => s.stamp == SkyStamp.bothWings).earned,
        isTrue,
      );
    },
  );
}
