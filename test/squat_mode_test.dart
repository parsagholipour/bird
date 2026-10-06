import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/data/passport_progress.dart';
import 'package:push_up_bird/data/progress_repository.dart';
import 'package:push_up_bird/data/session_repository.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/session_replay.dart';
import 'package:push_up_bird/domain/sky_passport.dart';
import 'package:push_up_bird/domain/tracking.dart';
import 'package:push_up_bird/game/play_controller.dart';
import 'play_session_test.dart' show SessionSource, SilentAudio;
import 'squat_tracking_test.dart' show squatSample;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'camera calibration starts a squat flight and saves its height inputs',
    () async {
      final source = SessionSource();
      SavedSession? saved;
      final controller = PlayController(
        mode: PlayMode.squat,
        source: source,
        audio: SilentAudio(),
        saveRun: (_) async {},
        saveSession: (s) async => saved = s,
      );
      addTearDown(controller.dispose);
      await controller.startCamera();
      for (var t = 1000.0; t <= 3200; t += 40) {
        source.time = t;
        source.sampleStream.add(
          squatSample(t, depth: t >= 2000 && t < 2640 ? .14 : 0),
        );
        await Future<void>.delayed(Duration.zero);
      }
      expect(controller.stage, PlayStage.flying);
      expect(controller.simulation!.rules, isA<SquatFlyMode>());
      for (var t = 3240.0; t <= 8000; t += 40) {
        source.time = t;
        source.sampleStream.add(
          squatSample(t, depth: t >= 6600 && t < 7400 ? .14 : 0),
        );
        controller.advance(.04, t, 2.2);
        if (t == 7000) expect(controller.simulation!.birdY, closeTo(.85, .03));
      }
      expect(controller.simulation!.birdY, closeTo(.15, .01));
      expect(controller.simulation!.repetitions, 1);
      expect(controller.simulation!.flaps, 0);
      controller.pause();
      expect(controller.simulation!.phase, RunPhase.paused);
      await controller.resume();
      expect(controller.simulation!.phase, RunPhase.countdown);
      controller.endFlight();
      await controller.finish();
      await controller.persistSession();
      expect(saved!.result.mode, PlayMode.squat);
      expect(saved!.result.repetitions, 1);
      final player = ReplayPlayer(ReplayTape.fromJson(saved!.tape.toJson()));
      player.seek(player.tape.durationMs);
      expect(
        player.simulation.birdY,
        closeTo(controller.simulation!.birdY, .001),
      );
      expect(player.simulation.repetitions, 1);
      player.seek(100);
      player.seek(player.tape.durationMs);
      expect(player.simulation.repetitions, 1);
    },
  );

  test(
    'every course follows squat height without falling or enabling glide/combat',
    () {
      for (final course in FlightCourse.values) {
        final sim = FlightSimulation(
          rules: SquatFlyMode(cycleSeconds: 4),
          practice: true,
          course: course,
        )..phase = RunPhase.playing;
        for (var frame = 0; frame < 50; frame++) {
          final time = frame * 20.0;
          sim.apply(
            const MovementInput(valid: true, height: .5, flap: true),
            squatSample(time),
            time,
          );
          sim.tick(.02, time);
        }
        expect(sim.birdY, closeTo(.5, .001));
        expect(sim.flaps, 0);
        expect(sim.supportsJumpGlide, isFalse);
        expect(sim.supportsCombat, isFalse);
      }
      expect(PlayMode.pushUp.index, 0);
      expect(PlayMode.jump.index, 1);
      expect(PlayMode.touch.index, 2);
      expect(PlayMode.squat.index, 3);
    },
  );

  test(
    'squat records stay separate, count toward progress and exclude practice',
    () async {
      final repo = SqliteProgressRepository(
        ProgressDatabase(NativeDatabase.memory()),
      );
      addTearDown(repo.close);
      for (final course in FlightCourse.values) {
        for (final practice in [false, true]) {
          await repo.saveRun(
            RunResult(
              id: '${course.name}-$practice',
              mode: PlayMode.squat,
              practice: practice,
              course: course,
              score: practice ? 100 : 15,
              gates: practice ? 10 : 13,
              stars: 12,
              repetitions: 4,
              flaps: 99,
              durationSeconds: 60,
              reason: EndReason.completed,
              finishedAt: DateTime.now(),
            ),
          );
        }
      }
      final p = await repo.load();
      expect(p.totalRuns, 2);
      expect(p.totalObstacles, 26);
      expect(p.totalSquats, 8);
      expect(p.totalRepetitions, 0);
      expect(p.trailCompletions, 1);
      expect(p.birdsFlown, {0});
      for (final course in FlightCourse.values) {
        expect(p.record(PlayMode.squat, course).best, 15);
        expect(p.record(PlayMode.jump, course).best, 0);
        expect(p.record(PlayMode.pushUp, course).best, 0);
      }
      expect(p.recent.every((r) => r.flaps == 0 && r.repetitions == 4), isTrue);
      expect(
        p.passport.firstWhere((s) => s.stamp == SkyStamp.allRounder).current,
        1,
      );
      expect(p.today!.goals.any((g) => g.current > 0), isTrue);
    },
  );
}
