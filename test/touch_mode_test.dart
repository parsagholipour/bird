import 'dart:io';
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
import 'play_session_test.dart' show SilentAudio;

void advance(PlayController controller, int frames) {
  for (var i = 0; i < frames; i++) {
    controller.advance(.02, controller.nowMs, 2.2);
  }
}

PlayController touchController({
  FlightCourse course = FlightCourse.classic,
  bool practice = false,
}) => PlayController(
  mode: PlayMode.touch,
  practice: practice,
  course: course,
  source: null,
  audio: SilentAudio(),
  recordAudio: true,
  saveRun: (_) async {},
  saveSession: (_) async {},
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final course in FlightCourse.values) {
    test(
      'touch starts $course without camera, calibration or microphone',
      () async {
        final controller = touchController(course: course);
        addTearDown(controller.dispose);
        await controller.verifyMicrophoneAccess();
        await controller.setRecordAudio(true);
        await controller.fly();
        expect(controller.stage, PlayStage.flying);
        expect(controller.cameraActive, isFalse);
        expect(controller.simulation!.rules.mode, PlayMode.touch);
        expect(controller.simulation!.course, course);
        expect(controller.simulation!.practice, isFalse);
        controller.flap(); // Countdown taps must not queue a flap at launch.
        advance(controller, 150);
        final sim = controller.simulation!;
        expect(sim.phase, RunPhase.playing);
        expect(sim.flaps, 0);
        final height = sim.birdY;
        controller.flap();
        advance(controller, 1);
        expect(sim.flaps, 1);
        expect(sim.birdY, lessThan(height));
        advance(controller, 30);
        expect(sim.flaps, 1); // Holding still never repeats a flap.
        expect(sim.velocity, greaterThan(0));
        expect(sim.phase, RunPhase.playing); // No missing tracking timeout.
        controller.flap();
        advance(controller, 1);
        expect(sim.flaps, 2);
        await controller.finish();
        expect(controller.canSaveSession, isTrue);
        expect(controller.cameraRecordingError, isEmpty);
        expect(controller.result!.mode, PlayMode.touch);
        expect(controller.result!.flaps, 2);

        final tape = ReplayTape.fromJson(controller.recorder!.tape.toJson());
        final replay = ReplayPlayer(tape)..seek(tape.durationMs);
        expect(replay.simulation.rules.mode, PlayMode.touch);
        expect(replay.simulation.flaps, sim.flaps);
        expect(replay.simulation.birdY, closeTo(sim.birdY, 1e-9));
        expect(replay.simulation.elapsed, sim.elapsed);
        expect(replay.simulation.endReason, sim.endReason);
        replay.seek(0);
        replay.seek(tape.durationMs);
        expect(replay.simulation.birdY, closeTo(sim.birdY, 1e-9));
      },
    );
  }

  test(
    'touch practice clears pending taps across pause, background and retry',
    () async {
      final controller = touchController(practice: true);
      addTearDown(controller.dispose);
      await controller.fly();
      advance(controller, 150);
      controller.flap();
      controller.pause();
      final pausedTime = controller.nowMs;
      advance(controller, 20);
      controller.flap();
      expect(controller.nowMs, pausedTime);
      expect(controller.simulation!.flaps, 0);
      await controller.resume();
      advance(controller, 150);
      expect(controller.simulation!.phase, RunPhase.playing);
      expect(controller.simulation!.flaps, 0);
      controller.flap();
      controller.background();
      expect(controller.simulation!.phase, RunPhase.paused);
      await controller.resume();
      advance(controller, 150);
      expect(controller.simulation!.flaps, 0);
      controller.endFlight();
      await controller.finish();
      await controller.retry();
      expect(controller.stage, PlayStage.flying);
      expect(controller.simulation!.phase, RunPhase.countdown);
      advance(controller, 150);
      expect(controller.simulation!.started, isTrue);
      expect(controller.simulation!.flaps, 0);
      expect(controller.cameraRecordingError, isEmpty);
    },
  );

  test(
    'scored touch flight ends on background and interrupted frame',
    () async {
      final controller = touchController();
      addTearDown(controller.dispose);
      await controller.fly();
      advance(controller, 150);
      controller.background();
      await controller.finish();
      expect(controller.result!.reason, EndReason.backgrounded);
      await controller.retry();
      advance(controller, 150);
      controller.advance(1, controller.nowMs, 2.2);
      controller.tick();
      await controller.finish();
      expect(controller.result!.reason, EndReason.stalled);
    },
  );

  test(
    'touch records stay separate and saved sessions replay without video',
    () async {
      final repo = SqliteProgressRepository(
        ProgressDatabase(NativeDatabase.memory()),
      );
      final folder = await Directory.systemTemp.createTemp('touch-session');
      final sessions = SessionRepository(folder);
      addTearDown(() async {
        await repo.close();
        await folder.delete(recursive: true);
      });
      for (final course in FlightCourse.values) {
        await repo.saveRun(
          RunResult(
            id: course.name,
            mode: PlayMode.touch,
            course: course,
            practice: false,
            score: course == FlightCourse.starTrail ? 50 : 25,
            gates: 25,
            repetitions: 0,
            flaps: 42,
            durationSeconds: 60,
            reason: EndReason.completed,
            finishedAt: DateTime.now(),
          ),
        );
      }
      final progress = await repo.load();
      for (final course in FlightCourse.values) {
        expect(
          progress.record(PlayMode.touch, course).best,
          course == FlightCourse.starTrail ? 50 : 25,
        );
        expect(progress.record(PlayMode.jump, course).runs, 0);
        expect(progress.record(PlayMode.pushUp, course).runs, 0);
      }
      expect(progress.totalRuns, 2);
      expect(progress.trailCompletions, 1);
      expect(progress.recent.every((run) => run.flaps == 42), isTrue);
      expect(
        progress.passport
            .firstWhere((s) => s.stamp == SkyStamp.skyCaptain)
            .earned,
        isTrue,
      );
      expect(
        progress.passport
            .firstWhere((s) => s.stamp == SkyStamp.bothWings)
            .earned,
        isFalse,
      );

      final controller = PlayController(
        mode: PlayMode.touch,
        practice: false,
        source: null,
        audio: SilentAudio(),
        saveRun: repo.saveRun,
        saveSession: sessions.save,
      );
      await controller.fly();
      advance(controller, 150);
      controller.flap();
      advance(controller, 1);
      await controller.finish();
      await controller.persistSession();
      final saved = await sessions.load(controller.result!.id);
      expect(saved.clips, isEmpty);
      expect(saved.result.mode, PlayMode.touch);
      final replay = ReplayPlayer(saved.tape)..seek(saved.tape.durationMs);
      expect(replay.simulation.flaps, 1);
      expect(replay.simulation.phase, RunPhase.ended);
      await controller.exit();
      controller.dispose();
    },
  );
}
