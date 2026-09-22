import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/bird_motion.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/session_replay.dart';
import 'package:push_up_bird/domain/tracking.dart';
import 'package:push_up_bird/game/bird_puppet.dart';
import 'touch_mode_test.dart' show touchController, advance;

FlightSimulation playing({FlightCourse course = FlightCourse.starTrail}) {
  final sim = FlightSimulation(
    rules: TapFlyMode(),
    practice: false,
    course: course,
    random: Random(4),
  );
  sim.apply(
    const MovementInput(valid: true),
    TrackingSample(
      mode: PlayMode.touch,
      timestampMs: 0,
      receivedMs: 0,
      joints: const [],
    ),
    0,
  );
  sim.tick(3, 0);
  // Isolate the collision under test after normal countdown/spawn setup.
  sim.obstacles.clear();
  sim.stars.clear();
  sim.starTrios.clear();
  sim.enemies.clear();
  return sim;
}

void tick(FlightSimulation sim, double dt) {
  final now = (sim.elapsed + dt) * 1000;
  sim.apply(
    const MovementInput(valid: true),
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
  TestWidgetsFlutterBinding.ensureInitialized();

  test('touch jumps higher with tighter openings and closer buildings', () {
    final touch = TapFlyMode(), smile = LegacyFlapMode();
    double jump(GameMode mode) =>
        mode.flapImpulse * mode.flapImpulse / (2 * mode.gravity);
    expect(jump(touch), greaterThan(jump(smile) * 1.35));
    for (final gates in [0, 10, 40, 100]) {
      final current = playing()..gates = gates;
      final old = FlightSimulation(
        rules: TapFlyMode(rulesVersion: 6),
        practice: false,
        course: FlightCourse.starTrail,
        rulesVersion: 6,
      )..gates = gates;
      expect(current.gap, lessThan(old.gap));
      expect(
        current.spawnInterval * current.speed,
        lessThan(old.spawnInterval * old.speed * .8),
      );
      expect(current.gap, greaterThan(.27));
    }
  });

  test(
    'rock starts at the rendered mouth and flies straight while bird falls',
    () {
      for (final reducedMotion in [false, true]) {
        final sim = playing()
          ..velocity = -.3
          ..lastFlapAt = -.04;
        final pose = BirdPose.forFlight(sim, reducedMotion: reducedMotion);
        final localX =
            BirdFlightMotion.size * (223 / 256 - .48) * (1 + pose.spring);
        final localY =
            BirdFlightMotion.size * (120 / 256 - .43) * (1 - pose.spring);
        expect(sim.shoot(reducedMotion: reducedMotion), isTrue);
        final rock = sim.rocks.single;
        expect(
          rock.x,
          closeTo(
            FlightSimulation.birdX +
                localX * cos(pose.tilt) -
                localY * sin(pose.tilt),
            1e-10,
          ),
        );
        expect(
          rock.y,
          closeTo(
            sim.birdY + localX * sin(pose.tilt) + localY * cos(pose.tilt),
            1e-10,
          ),
        );
        final x = rock.x, y = rock.y;
        tick(sim, .3);
        expect(rock.x, closeTo(x + BirdRock.speed * .3, 1e-10));
        expect(rock.y, y);
        expect(sim.birdY, isNot(.5));
        expect(sim.flaps, 0);
      }
    },
  );

  test(
    'shots respect cooldown and cannot queue during countdown or pause',
    () async {
      final controller = touchController(practice: true);
      addTearDown(controller.dispose);
      // A tap is a press and a release. Holding is covered in power_shot_test.
      void tap() {
        controller.startCharge();
        controller.shoot();
      }

      tap();
      await controller.fly();
      tap();
      advance(controller, 150);
      final sim = controller.simulation!;
      expect(sim.shots, 0);
      tap();
      tap();
      expect(sim.shots, 1);
      advance(controller, 10);
      tap();
      expect(sim.shots, 1);
      advance(controller, 5);
      tap();
      expect(sim.shots, 2);
      controller.pause();
      final rockX = sim.rocks.first.x;
      tap();
      advance(controller, 20);
      expect(sim.rocks.first.x, rockX);
      await controller.resume();
      tap();
      advance(controller, 150);
      expect(sim.shots, 2);
      controller.endFlight();
      tap();
      expect(sim.shots, 2);
      await controller.finish();
      await controller.retry();
      expect(controller.simulation!.shots, 0);
      expect(controller.simulation!.rocks, isEmpty);
    },
  );

  test(
    'one straight rock defeats only its first target, including slow frames',
    () {
      final sim = playing();
      sim.enemies.addAll([SkyEnemy(x: .82, y: .5), SkyEnemy(x: 1.03, y: .5)]);
      sim.shoot(reducedMotion: true);
      tick(sim, .4);
      expect(sim.enemiesDefeated, 1);
      expect(sim.enemies, hasLength(1));
      expect(sim.score, 3);
      expect(sim.rocks, isEmpty);
      expect(
        sim.events.where((e) => e.kind == FlightEventKind.enemyHit),
        hasLength(1),
      );
    },
  );

  test(
    'rocks miss targets at a different height and are removed offscreen',
    () {
      final sim = playing();
      sim.enemies.add(SkyEnemy(x: .85, y: .25));
      sim.shoot();
      for (var i = 0; i < 5; i++) {
        tick(sim, .3);
      }
      expect(sim.enemiesDefeated, 0);
      expect(sim.rocks, isEmpty);
    },
  );

  test('buildings block rocks before they can hit enemies behind them', () {
    final sim = playing();
    sim.obstacles.add(Obstacle(x: .7, center: .2, gap: .2));
    sim.enemies.add(SkyEnemy(x: 1.1, y: .5));
    sim.shoot();
    tick(sim, .3);
    expect(sim.rocks, isEmpty);
    expect(sim.enemiesDefeated, 0);
    expect(sim.enemies, hasLength(1));
  });

  test('enemies use shield, recovery and hearts; classic ends on contact', () {
    final sim = playing();
    void hit() {
      sim.birdY = .5;
      sim.velocity = 0;
      sim.enemies.add(SkyEnemy(x: FlightSimulation.birdX, y: .5));
      tick(sim, .02);
    }

    hit();
    expect(sim.shield, isFalse);
    expect(sim.hearts, 3);
    hit();
    expect(sim.hearts, 3);
    sim.invulnerableUntil = 0;
    hit();
    expect(sim.hearts, 2);
    expect(sim.enemies, isEmpty);
    final classic = playing(course: FlightCourse.classic);
    classic.enemies.add(SkyEnemy(x: FlightSimulation.birdX, y: .5));
    tick(classic, .02);
    expect(classic.endReason, EndReason.collision);
    expect(classic.shoot(), isFalse);
    final courier = playing(course: FlightCourse.skyCourier)
      ..carryingLetter = true;
    courier.enemies.add(SkyEnemy(x: FlightSimulation.birdX, y: .5));
    tick(courier, .02);
    expect(courier.lettersDropped, 1);
    expect(courier.carryingLetter, isFalse);
    expect(courier.phase, RunPhase.playing);
  });

  test('combat is limited to new touch flights outside Cloud Cruise', () {
    for (final mode in [
      JumpFlyMode(),
      PushUpFlightMode(cycleSeconds: 3),
      TapFlyMode(),
    ]) {
      for (final course in FlightCourse.values) {
        for (final version in [6, 7]) {
          final sim = FlightSimulation(
            rules: mode,
            course: course,
            practice: false,
            rulesVersion: version,
          )..phase = RunPhase.playing;
          final enabled =
              mode.mode == PlayMode.touch && !course.relaxed && version >= 7;
          expect(sim.shoot(), enabled);
        }
      }
    }
  });

  for (final reducedMotion in [false, true]) {
    test(
      'enemy generation, hits and rocks survive replay seeks (reduced: $reducedMotion)',
      () {
        var now = 0.0;
        final recorder = FlightRecorder(
          ReplayTape(
            mode: PlayMode.touch,
            course: FlightCourse.starTrail,
            practice: false,
            seed: 4,
            cycleSeconds: 3,
            bird: 0,
            reducedMotion: reducedMotion,
            originMs: 0,
          ),
          () => now,
        );
        final sim = recorder.simulation;
        for (var i = 0; i < 950 && sim.phase != RunPhase.ended; i++) {
          now += 20;
          final upcoming = sim.obstacles.where(
            (o) => o.x + o.width > FlightSimulation.birdX,
          );
          final target = upcoming.isEmpty ? .5 : upcoming.first.target;
          recorder.apply(
            MovementInput(
              valid: true,
              flap: sim.birdY > target + .06 && sim.velocity > 0,
            ),
            TrackingSample(
              mode: PlayMode.touch,
              timestampMs: now,
              receivedMs: now,
              joints: const [],
            ),
            now,
          );
          if (sim.canShoot) recorder.command('shoot');
          recorder.tick(.02, now, 2.2);
        }
        expect(sim.enemiesDefeated, greaterThan(0));
        expect(sim.gates, greaterThan(3));
        final tape = ReplayTape.fromJson(recorder.tape.toJson());
        final replay = ReplayPlayer(tape);
        for (final seek in [
          tape.durationMs,
          6000.0,
          tape.durationMs,
          0.0,
          tape.durationMs,
        ]) {
          replay.seek(seek);
          if (seek != tape.durationMs) continue;
          final actual = replay.simulation;
          expect(actual.birdY, sim.birdY);
          expect(actual.shots, sim.shots);
          expect(actual.enemiesDefeated, sim.enemiesDefeated);
          expect(actual.score, sim.score);
          expect(actual.hearts, sim.hearts);
          expect(
            actual.enemies.map((e) => (e.x, e.y, e.appearance)),
            sim.enemies.map((e) => (e.x, e.y, e.appearance)),
          );
          expect(
            actual.rocks.map((r) => (r.x, r.y)),
            sim.rocks.map((r) => (r.x, r.y)),
          );
        }
      },
    );
  }

  test(
    'version 6 touch journals retain their exact physics and reject shoot events',
    () {
      final tape = ReplayTape(
        mode: PlayMode.touch,
        practice: false,
        seed: 2,
        cycleSeconds: 3,
        bird: 0,
        reducedMotion: false,
        originMs: 0,
        recordedVersion: 6,
      );
      final sim = ReplayTape.fromJson(tape.toJson()).createSimulation();
      final smile = LegacyFlapMode();
      expect(sim.rules.gravity, smile.gravity);
      expect(sim.rules.flapImpulse, smile.flapImpulse);
      expect(sim.rules.intervalFor(5), smile.intervalFor(5));
      expect(sim.rules.gapFor(5), smile.gapFor(5));
      expect(sim.rules.speedFor(5), smile.speedFor(5));
      tape.events.add([0.0, 'shoot']);
      expect(() => ReplayTape.fromJson(tape.toJson()), throwsFormatException);
    },
  );
}
