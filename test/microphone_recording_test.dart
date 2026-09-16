import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/data/session_repository.dart';
import 'package:push_up_bird/domain/tracking.dart';
import 'package:push_up_bird/game/play_controller.dart';
import 'package:push_up_bird/tracking/tracking_api.g.dart';
import 'play_session_test.dart' show SessionSource, SilentAudio, startFlight;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  PlayController controller(
    SessionSource source, {
    bool recordAudio = false,
    Future<void> Function(bool)? remember,
    Future<void> Function(SavedSession)? save,
  }) {
    final c = PlayController(
      mode: PlayMode.pushUp,
      practice: false,
      source: source,
      audio: SilentAudio(),
      saveRun: (_) async {},
      saveSession: save ?? (_) async {},
      recordAudio: recordAudio,
      rememberRecordAudio: remember,
    );
    addTearDown(() async {
      c.dispose();
      await Future<void>.delayed(Duration.zero);
    });
    return c;
  }

  test(
    'microphone defaults off even when Android permission is already granted',
    () async {
      final source = SessionSource()..micAccess = MicrophoneAccess.granted;
      final c = controller(source);
      await startFlight(c, source);
      expect(source.microphoneRequests, 0);
      expect(source.recordingAudio, [false]);
    },
  );
  test(
    'explicit opt-in is remembered and enables capture without another prompt',
    () async {
      final source = SessionSource()..micAccess = MicrophoneAccess.granted;
      final choices = <bool>[];
      final c = controller(
        source,
        remember: (value) async => choices.add(value),
      );
      await c.setRecordAudio(true);
      expect(c.recordAudio, isTrue);
      expect(choices, [true]);
      await startFlight(c, source);
      expect(source.microphoneRequests, 1);
      expect(source.recordingAudio, [true]);
      await c.finish();
      await c.retry();
      expect(source.microphoneRequests, 1);
    },
  );
  for (final access in [
    MicrophoneAccess.denied,
    MicrophoneAccess.permanentlyDenied,
    MicrophoneAccess.unavailable,
  ]) {
    test(
      '$access leaves video playable and never prompts on start or retry',
      () async {
        final source = SessionSource()..micAccess = access;
        final c = controller(source);
        await c.setRecordAudio(true);
        expect(c.recordAudio, isFalse);
        expect(c.microphoneMessage, isNotEmpty);
        expect(
          c.microphoneSettingsAvailable,
          access == MicrophoneAccess.permanentlyDenied,
        );
        await startFlight(c, source);
        expect(source.recordingAudio, [false]);
        await c.finish();
        await c.retry();
        expect(source.microphoneRequests, 1);
      },
    );
  }
  test(
    'permission bridge failure does not stop silent camera recording',
    () async {
      final source = SessionSource()..microphoneThrows = true;
      final c = controller(source);
      await c.setRecordAudio(true);
      await startFlight(c, source);
      expect(source.recordingAudio, [false]);
      expect(c.microphoneRequestPending, isFalse);
    },
  );
  test(
    'revoked remembered permission quietly switches off and persists the change',
    () async {
      final source = SessionSource()..micAccess = MicrophoneAccess.denied;
      final choices = <bool>[];
      final c = controller(
        source,
        recordAudio: true,
        remember: (value) async => choices.add(value),
      );
      await startFlight(c, source);
      expect(source.microphoneRequests, 0);
      expect(source.recordingAudio, [false]);
      expect(c.recordAudio, isFalse);
      expect(choices, [false]);
    },
  );
  test('turning off a granted microphone needs no prompt', () async {
    final source = SessionSource()..micAccess = MicrophoneAccess.granted;
    final c = controller(source, recordAudio: true);
    await c.setRecordAudio(false);
    await startFlight(c, source);
    expect(source.recordingAudio, [false]);
    expect(source.microphoneRequests, 0);
  });
  test(
    'permission request is deduplicated and camera waits for its response',
    () async {
      final source = SessionSource()
        ..permission = Completer<MicrophoneAccess>();
      final c = controller(source);
      final requesting = c.setRecordAudio(true);
      await c.setRecordAudio(true);
      await c.startCamera();
      expect(c.stage, PlayStage.setup);
      expect(c.microphoneRequestPending, isTrue);
      expect(source.microphoneRequests, 1);
      source.permission!.complete(MicrophoneAccess.denied);
      await requesting;
      expect(c.microphoneRequestPending, isFalse);
      expect(c.recordAudio, isFalse);
    },
  );
  test('saved session retains the native audio-track metadata', () async {
    final source = SessionSource()..micAccess = MicrophoneAccess.granted;
    SavedSession? saved;
    final c = controller(
      source,
      recordAudio: true,
      save: (session) async {
        saved = session;
      },
    );
    await startFlight(c, source);
    source.finalize = Completer<CameraClip?>()
      ..complete(
        CameraClip(
          path: '/missing/test-clip.mp4',
          startedAtMs: 1000,
          durationMs: 3400,
          hasAudio: true,
        ),
      );
    await c.finish();
    await c.persistSession();
    expect(saved!.clips.single.hasAudio, isTrue);
  });
}
