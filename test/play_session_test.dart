import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/data/progress_repository.dart';
import 'package:push_up_bird/domain/tracking.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/game/audio.dart';
import 'package:push_up_bird/game/play_controller.dart';
import 'package:push_up_bird/tracking/native_tracking_source.dart';
import 'package:push_up_bird/tracking/tracking_api.g.dart';

class SilentAudio implements SkyAudio {
  @override
  void syncCombat(FlightSimulation simulation, {bool silent = false}) {}
  @override
  void syncBoss(SkyBoss? boss, {bool silent = false}) {}
  @override
  Future<void> configure(
    GameSettings settings, {
    bool active = true,
    SkyMusic track = SkyMusic.flight,
  }) async {}
  @override
  void effect(String name, {int? variant}) {}
  @override
  Future<void> stop() async {}
  @override
  Future<void> resumeMusic() async {}
  @override
  Future<void> dispose() async {}
  @override
  Future<void> setRate(double rate) async {}
  @override
  Future<void> stopEffects() async {}
}

class TestInterpreter implements MovementInterpreter {
  @override
  MovementInput add(TrackingSample sample, double now) =>
      const MovementInput(valid: true, height: 1);
  @override
  void reset() {}
}

class CountingAudio extends SilentAudio {
  int resumes = 0;
  @override
  Future<void> resumeMusic() async {
    resumes++;
  }
}

class RecordingAudio extends SilentAudio {
  final effects = <String>[];

  @override
  void effect(String name, {int? variant}) => effects.add(name);
}

class SessionSource extends NativeTrackingSource {
  double time = 1000;
  MicrophoneAccess micAccess = MicrophoneAccess.denied;
  int microphoneRequests = 0;
  bool microphoneThrows = false;
  final List<bool> recordingAudio = [];
  Completer<MicrophoneAccess>? permission;
  @override
  Future<MicrophoneAccess> microphoneAccess() async => micAccess;
  @override
  Future<MicrophoneAccess> requestMicrophone() async {
    microphoneRequests++;
    if (microphoneThrows) throw StateError('unavailable');
    return permission == null ? micAccess : await permission!.future;
  }

  final sampleStream = StreamController<TrackingSample>.broadcast(sync: true);
  final issueStream = StreamController<TrackingIssue>.broadcast(sync: true);
  Completer<CameraClip?>? finalize;
  @override
  Stream<TrackingSample> get samples => sampleStream.stream;
  @override
  Stream<TrackingIssue> get issues => issueStream.stream;
  @override
  double get nowMs => time;
  @override
  Future<bool> requestPermission() async => true;
  @override
  Future<void> start(PlayMode mode, {bool frontCamera = true}) async {}
  @override
  Future<void> stop() async {}
  @override
  Future<double> startRecording({bool withAudio = false}) async {
    recordingAudio.add(withAudio);
    return time;
  }

  @override
  Future<CameraClip?> stopRecording() async {
    final pending = finalize;
    finalize = null;
    return pending == null ? null : await pending.future;
  }

  @override
  double recordingTime(int nativeMs) => nativeMs.toDouble();
  @override
  Future<void> dispose() async {
    await sampleStream.close();
    await issueStream.close();
  }
}

Future<void> startFlight(
  PlayController controller,
  SessionSource source,
) async {
  controller.stage = PlayStage.ready;
  controller.interpreter = TestInterpreter();
  await controller.fly();
  for (var i = 0; i < 170; i++) {
    source.time += 20;
    source.sampleStream.add(
      TrackingSample(
        mode: controller.mode,
        timestampMs: source.time,
        receivedMs: source.time,
        joints: const [],
      ),
    );
    controller.advance(.02, source.time, 2.2);
  }
  expect(controller.simulation!.started, isTrue);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'failed run plays game over while a completed run plays victory',
    () async {
      for (final (reason, expectedCue) in [
        (EndReason.collision, 'game_over'),
        (EndReason.completed, 'complete'),
      ]) {
        final audio = RecordingAudio();
        final controller = PlayController(
          mode: PlayMode.touch,
          practice: false,
          source: null,
          audio: audio,
          saveRun: (_) async {},
          saveSession: (_) async {},
        );
        await controller.fly();
        controller.simulation!.end(reason);
        await controller.finish();
        expect(audio.effects, contains(expectedCue));
        controller.dispose();
      }
    },
  );
  test(
    'practice flights pause, restore music, and finish with saveable results',
    () async {
      final source = SessionSource();
      final audio = CountingAudio();
      RunResult? result;
      final controller = PlayController(
        mode: PlayMode.pushUp,
        practice: true,
        course: FlightCourse.starTrail,
        source: source,
        audio: audio,
        saveRun: (run) async => result = run,
        saveSession: (_) async {},
      );
      await startFlight(controller, source);
      controller.pause();
      expect(controller.simulation!.phase, RunPhase.paused);
      await controller.resume();
      expect(controller.simulation!.phase, RunPhase.countdown);
      expect(audio.resumes, 1);
      controller.endFlight();
      await controller.finish();
      expect(controller.stage, PlayStage.results);
      expect(controller.canSaveSession, isTrue);
      expect(result!.practice, isTrue);
      expect(result!.course, FlightCourse.starTrail);
      expect(result!.reason, EndReason.breakTaken);
      controller.dispose();
      await Future<void>.delayed(Duration.zero);
    },
  );
  test(
    'finish awaits camera finalization; Save session is explicit and deduplicated',
    () async {
      final temp = await Directory.systemTemp.createTemp('session-controller');
      final clip = await File('${temp.path}/camera.mp4').writeAsBytes([1, 2]);
      final source = SessionSource();
      var scores = 0, saves = 0;
      final saving = Completer<void>();
      final controller = PlayController(
        mode: PlayMode.pushUp,
        practice: false,
        source: source,
        audio: SilentAudio(),
        saveRun: (_) async {
          scores++;
        },
        saveSession: (session) async {
          saves++;
          expect(session.clips.single.path, clip.path);
          await saving.future;
        },
      );
      await startFlight(controller, source);
      final finalize = source.finalize = Completer<CameraClip?>();
      final finish = controller.finish();
      expect(controller.canSaveSession, isFalse);
      expect(saves, 0);
      finalize.complete(
        CameraClip(path: clip.path, startedAtMs: 1000, durationMs: 3400),
      );
      await finish;
      expect(scores, 1);
      expect(saves, 0);
      expect(controller.canSaveSession, isTrue);
      final first = controller.persistSession();
      final second = controller.persistSession();
      expect(saves, 1);
      saving.complete();
      await Future.wait([first, second]);
      expect(controller.sessionSaved, isTrue);
      expect(await clip.exists(), isFalse);
      controller.dispose();
      await Future<void>.delayed(Duration.zero);
      await temp.delete(recursive: true);
    },
  );
  test(
    'failed save retains camera for retry; leaving discards unsaved footage',
    () async {
      final temp = await Directory.systemTemp.createTemp(
        'session-controller-retry',
      );
      final clip = await File('${temp.path}/camera.mp4').writeAsBytes([1]);
      final source = SessionSource();
      var shouldFail = true;
      final controller = PlayController(
        mode: PlayMode.pushUp,
        practice: true,
        source: source,
        audio: SilentAudio(),
        saveRun: (_) async {
          if (shouldFail) throw const FileSystemException('full');
        },
        saveSession: (_) async {
          if (shouldFail) throw const FileSystemException('full');
        },
      );
      await startFlight(controller, source);
      source.finalize = Completer<CameraClip?>()
        ..complete(
          CameraClip(path: clip.path, startedAtMs: 1000, durationMs: 3400),
        );
      await controller.finish();
      await controller.persistSession();
      expect(controller.sessionSaved, isFalse);
      expect(controller.sessionError, isNotEmpty);
      expect(await clip.exists(), isTrue);
      await controller.retry();
      expect(await clip.exists(), isTrue);
      expect(controller.stage, PlayStage.results);
      shouldFail = false;
      await controller.persistSession();
      expect(controller.sessionSaved, isTrue);
      expect(await clip.exists(), isFalse);
      controller.dispose();
      await Future<void>.delayed(Duration.zero);
      final abandoned = await File(
        '${temp.path}/abandoned.mp4',
      ).writeAsBytes([2]);
      final source2 = SessionSource();
      final controller2 = PlayController(
        mode: PlayMode.pushUp,
        practice: false,
        source: source2,
        audio: SilentAudio(),
        saveRun: (_) async {},
        saveSession: (_) async => fail('Must not save on exit'),
      );
      await startFlight(controller2, source2);
      source2.finalize = Completer<CameraClip?>()
        ..complete(
          CameraClip(path: abandoned.path, startedAtMs: 1000, durationMs: 3400),
        );
      await controller2.exit();
      expect(await abandoned.exists(), isFalse);
      controller2.dispose();
      await Future<void>.delayed(Duration.zero);
      await temp.delete(recursive: true);
    },
  );
}
