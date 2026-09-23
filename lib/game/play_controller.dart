import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import '../domain/session_replay.dart';
import '../data/session_repository.dart';
import 'package:flutter/foundation.dart';
import '../domain/tracking.dart';
import '../domain/jump_tracking.dart';
import '../domain/squat_tracking.dart';
import '../domain/game_rules.dart';
import '../tracking/native_tracking_source.dart';
import '../tracking/tracking_api.g.dart' show MicrophoneAccess;
import 'audio.dart';

enum PlayStage { setup, starting, calibration, ready, flying, results, error }

class PlayController extends ChangeNotifier {
  PlayController({
    required this.mode,
    required this.practice,
    this.course = FlightCourse.starTrail,
    required this.source,
    required this.saveRun,
    required this.audio,
    required this.saveSession,
    this.bird = 0,
    this.weaponDamage = BirdRock.baseDamage,
    this.reducedMotion = false,
    this.recordAudio = false,
    this.rememberRecordAudio,
    DateTime Function()? clock,
  }) : assert(mode == PlayMode.touch || source != null),
       clock = clock ?? DateTime.now {
    if (isTouch) return;
    _samples = source!.samples.listen(_onSample);
    _issues = source!.issues.listen((issue) {
      if (stage == PlayStage.results || _disposed) return;
      if (issue.code == 'background') {
        background();
        return;
      }
      message = issue.message;
      if (simulation?.phase == RunPhase.playing) {
        recorder?.command('end', EndReason.trackingLost);
        finish();
      } else {
        stage = PlayStage.error;
        notify();
      }
    });
    _refresh = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (stage == PlayStage.calibration || stage == PlayStage.ready) notify();
    });
  }
  final PlayMode mode;
  final bool practice;
  final FlightCourse course;
  final DateTime Function() clock;
  final NativeTrackingSource? source;
  bool get isTouch => mode == PlayMode.touch;
  // Touch time advances with gameplay so pauses produce no gaps in the replay.
  double _touchTime = 0;
  bool _touchFlap = false;
  double get nowMs => isTouch ? _touchTime : source!.nowMs;
  final Future<void> Function(RunResult) saveRun;
  final SkyAudio audio;
  final Future<void> Function(SavedSession) saveSession;
  final int bird;
  final int weaponDamage;
  final bool reducedMotion;
  final Future<void> Function(bool)? rememberRecordAudio;
  bool recordAudio, microphoneRequestPending = false;
  bool microphoneSettingsAvailable = false;
  String microphoneMessage = '';
  int _audioChoiceRevision = 0;

  Future<void> _rememberAudio() async {
    try {
      await rememberRecordAudio?.call(recordAudio);
    } catch (_) {
      microphoneMessage =
          'Changed for this flight. Could not remember your preference.';
    }
  }

  /// Only this user-invoked action may request the microphone. Camera startup,
  /// replay, practice resume and retry only check existing access.
  Future<void> setRecordAudio(bool enabled) async {
    if (isTouch ||
        _disposed ||
        microphoneRequestPending ||
        stage != PlayStage.setup) {
      return;
    }
    ++_audioChoiceRevision;
    microphoneMessage = '';
    microphoneSettingsAvailable = false;
    if (!enabled) {
      recordAudio = false;
      notify();
      await _rememberAudio();
      notify();
      return;
    }
    microphoneRequestPending = true;
    notify();
    try {
      final access = await source!.requestMicrophone();
      if (_disposed) return;
      recordAudio = access == MicrophoneAccess.granted;
      if (!recordAudio) _microphoneUnavailable(access);
      await _rememberAudio();
    } catch (_) {
      recordAudio = false;
      microphoneMessage =
          'Microphone unavailable. Video and gameplay still work.';
    } finally {
      microphoneRequestPending = false;
      notify();
    }
  }

  void _microphoneUnavailable(MicrophoneAccess access) {
    microphoneSettingsAvailable = access == MicrophoneAccess.permanentlyDenied;
    microphoneMessage = microphoneSettingsAvailable
        ? 'Microphone blocked. You can allow it in Settings; video still works.'
        : 'Microphone off. You can still play and save video.';
  }

  Future<void> verifyMicrophoneAccess() async {
    if (isTouch || !recordAudio || _disposed) return;
    final revision = _audioChoiceRevision;
    MicrophoneAccess access;
    try {
      access = await source!.microphoneAccess();
    } catch (_) {
      access = MicrophoneAccess.unavailable;
    }
    if (_disposed ||
        revision != _audioChoiceRevision ||
        access == MicrophoneAccess.granted) {
      return;
    }
    recordAudio = false;
    _microphoneUnavailable(access);
    await _rememberAudio();
    notify();
  }

  FlightRecorder? recorder;
  final List<SessionClip> _clips = [];
  bool sessionSaved = false, sessionSaving = false, preparingReplay = false;
  String sessionError = '', cameraRecordingError = '';
  Future<void>? _finishing, _stoppingCamera, _sessionSave;
  Future<void>? _preparingCapture;
  bool get canSaveSession =>
      result != null && simulation?.started == true && !preparingReplay;

  Future<void> _startCapture() async {
    if (isTouch) return;
    try {
      await verifyMicrophoneAccess();
      await source!.startRecording(withAudio: recordAudio);
    } catch (_) {
      cameraRecordingError =
          'Camera video unavailable. Gameplay can still be saved.';
    }
  }

  Future<void> _collectClip() async {
    try {
      final clip = await source!.stopRecording();
      if (clip != null && recorder != null) {
        if (recordAudio && !clip.hasAudio) {
          cameraRecordingError =
              'Microphone audio was unavailable. Your video and gameplay can still be saved.';
        }
        _clips.add(
          SessionClip(
            path: clip.path,
            startMs:
                source!.recordingTime(clip.startedAtMs) -
                recorder!.tape.originMs,
            durationMs: clip.durationMs.toDouble(),
            hasAudio: clip.hasAudio,
          ),
        );
      } else if (clip != null) {
        await File(clip.path).delete();
      }
    } catch (_) {
      cameraRecordingError =
          'Camera video interrupted. Available footage and gameplay can still be saved.';
    }
  }

  Future<void> _stopCamera() => _stoppingCamera ??= () async {
    if (isTouch) return;
    await _preparingCapture;
    await _collectClip();
    try {
      await source!.stop();
    } catch (error) {
      debugPrint('PushUpBird camera cleanup: $error');
    }
    cameraActive = false;
  }().whenComplete(() => _stoppingCamera = null);

  Future<void> persistSession() => _sessionSave ??= _persistSession()
      .whenComplete(() => _sessionSave = null);
  Future<void> _persistSession() async {
    if (!canSaveSession || sessionSaved) return;
    sessionSaving = true;
    sessionError = '';
    notify();
    try {
      await saveSession(
        SavedSession(
          result: result!,
          tape: recorder!.tape,
          clips: List.of(_clips),
        ),
      );
      sessionSaved = true;
      await _discardClips();
    } catch (_) {
      sessionError = 'Could not save the session. Tap Save session to retry.';
    }
    sessionSaving = false;
    notify();
  }

  Future<void> _discardClips() async {
    for (final clip in _clips) {
      try {
        final file = File(clip.path);
        if (await file.exists()) await file.delete();
      } catch (_) {}
    }
    _clips.clear();
  }

  void flap() {
    if (isTouch &&
        !_disposed &&
        stage == PlayStage.flying &&
        simulation?.phase == RunPhase.playing) {
      _touchFlap = true;
    }
  }

  /// Pressing Shoot starts a power shot; releasing it calls [shoot].
  void startCharge() {
    if (_disposed ||
        stage != PlayStage.flying ||
        simulation?.canCharge != true) {
      return;
    }
    recorder?.command('charge');
    notify();
  }

  void shoot() {
    final sim = simulation;
    // A rejected release is still journaled when it ends a held charge.
    // Once a full charge has fired itself, lifting the button must not
    // spend a second rock.
    if (_disposed ||
        stage != PlayStage.flying ||
        sim == null ||
        !(sim.supportsPowerShots ? sim.charging : sim.canShoot)) {
      return;
    }
    recorder?.command('shoot');
    audio.syncCombat(sim);
    notify();
  }

  void sprint() {
    if (_disposed ||
        stage != PlayStage.flying ||
        simulation?.canSprint != true) {
      return;
    }
    recorder?.command('sprint');
    audio.syncCombat(simulation!);
    notify();
  }

  void advance(double dt, double now, double width) {
    if (isTouch) {
      if (_disposed ||
          stage != PlayStage.flying ||
          simulation?.phase == RunPhase.paused ||
          simulation?.phase == RunPhase.ended ||
          !dt.isFinite ||
          dt <= 0) {
        return;
      }
      _touchTime += dt * 1000;
      now = _touchTime;
      final before = simulation!.flaps;
      recorder?.apply(
        MovementInput(valid: true, flap: _touchFlap),
        TrackingSample(
          mode: mode,
          timestampMs: now,
          receivedMs: now,
          joints: const [],
          sensorTimestamp: false,
        ),
        now,
      );
      _touchFlap = false;
      if (simulation!.flaps > before) audio.effect('flap');
    }
    recorder?.tick(dt, now, width);
    if (simulation != null) audio.syncCombat(simulation!);
  }

  StreamSubscription<TrackingSample>? _samples;
  StreamSubscription<TrackingIssue>? _issues;
  Timer? _refresh;
  bool _disposed = false, _saving = false, front = true, cameraActive = false;
  int _operation = 0;
  PlayStage stage = PlayStage.setup;
  BodyCalibrator body = BodyCalibrator();
  JumpCalibrator jump = JumpCalibrator();
  SquatCalibrator squat = SquatCalibrator();
  MovementInterpreter? interpreter;
  TrackingSample? latest;
  TrackingMetrics metrics = TrackingMetrics();
  MovementInput movement = const MovementInput(valid: false);
  FlightSimulation? simulation;
  RunResult? result;
  String message = '', saveError = '';
  bool saved = false;
  double _lastGood = -10000;
  double _lastDiagnostic = -10000;
  bool get readyNow => nowMs - _lastGood < 250;
  void notify() {
    if (!_disposed) notifyListeners();
  }

  void _onSample(TrackingSample sample) {
    if (isTouch || _disposed) return;
    latest = sample;
    final now = sample.receivedMs;
    if (stage == PlayStage.calibration) {
      if (mode == PlayMode.pushUp) {
        body.add(sample, now);
        message = body.feedback;
        if (body.result != null) {
          final c = body.result!;
          source!.recordDiagnostic(
            'PushUpBird calibration: ${jsonEncode({
              't': now,
              'cues': [
                for (final m in c.cues) {'cue': m.cue.name, 'top': m.top, 'bottom': m.bottom, 'weight': m.weight},
              ],
              'topElbow': c.topElbow,
              'bottomElbow': c.bottomElbow,
              'side': c.side,
              'perspective': c.perspective.name,
              'bodyLength': c.bodyLength,
              'armLength': c.armLength,
              'cycleSeconds': c.cycleSeconds,
            })}',
          );
          interpreter = PushUpInterpreter(body.result!);
          audio.effect('go');
          fly();
        }
      } else if (mode == PlayMode.squat) {
        squat.add(sample, now);
        message = squat.feedback;
        if (squat.result != null) {
          interpreter = SquatInterpreter(squat.result!);
          audio.effect('go');
          fly();
        }
      } else {
        jump.add(sample, now);
        message = jump.feedback;
        if (jump.result != null) {
          final standing = jump.result!.standing;
          source!.recordDiagnostic(
            'PushUpBird calibration: ${jsonEncode({'t': now, 'mode': mode.name, 'shoulderY': standing.shoulderY, 'hipY': standing.hipY, 'leftFootY': standing.leftFootY, 'rightFootY': standing.rightFootY, 'bodyHeight': standing.bodyHeight, 'riseThreshold': jump.result!.riseThreshold})}',
          );
          interpreter = JumpInterpreter(jump.result!);
          audio.effect('go');
          fly();
        }
      }
    }
    if (interpreter != null &&
        (stage == PlayStage.ready || stage == PlayStage.flying)) {
      movement = interpreter!.add(sample, now);
      if (movement.valid) _lastGood = now;
      if (stage == PlayStage.ready) message = movement.feedback;
      final flapsBefore = simulation?.flaps ?? 0;
      if (stage == PlayStage.flying && simulation?.phase != RunPhase.ended) {
        recorder?.apply(movement, sample, now);
      }
      if (trackingDiagnosticsEnabled &&
          mode == PlayMode.jump &&
          movement.flap) {
        source!.recordDiagnostic(
          'PushUpBird jump: ${jsonEncode({'t': now, 'capturedAt': sample.timestampMs, 'phase': simulation?.phase.name, 'accepted': (simulation?.flaps ?? 0) > flapsBefore, 'gameJumps': simulation?.flaps ?? 0})}',
        );
      }
      if (movement.flap && simulation?.phase == RunPhase.playing) {
        audio.effect('flap');
      }
    }
    metrics.add(sample, nowMs);
    if (trackingDiagnosticsEnabled && now - _lastDiagnostic >= 250) {
      _lastDiagnostic = now;
      source!.recordDiagnostic(
        'PushUpBird control: t=${now.round()} stage=${stage.name} '
        'step=${body.step.name} cycles=${body.cycles} '
        'view=${body.perspective?.name} valid=${movement.valid} '
        'cues=${body.result?.cues.map((m) => '${m.cue.name}:${m.bottom.toStringAsFixed(2)}-${m.top.toStringAsFixed(2)}@${m.weight.toStringAsFixed(0)}').join(',')} '
        'topElbow=${body.result?.topElbow?.toStringAsFixed(1)} bottomElbow=${body.result?.bottomElbow?.toStringAsFixed(1)} '
        'height=${movement.height.toStringAsFixed(2)} reps=${movement.repetitions} '
        'preview=${body.previewHeight.toStringAsFixed(2)} '
        'pose=${mode == PlayMode.pushUp ? bodyDiagnostics(sample, now, preferredSide: body.side, preferredPerspective: body.perspective) : mode.name} '
        'phase=${simulation?.phase.name} count=${simulation?.countdown.toStringAsFixed(2)} '
        'feedback=${simulation?.trackingFeedback ?? message}',
      );
    }
  }

  Future<void> startCamera({bool recalibrate = true}) async {
    if (isTouch) return;
    if (_disposed || microphoneRequestPending || stage == PlayStage.starting) {
      return;
    }
    final op = ++_operation;
    stage = PlayStage.starting;
    message = 'Waking up your camera…';
    notify();
    try {
      if (!await source!.requestPermission()) {
        if (_disposed || op != _operation) return;
        stage = PlayStage.error;
        message =
            'Camera access is off. Allow it in Android settings, then come back and try again.';
        notify();
        return;
      }
      await _stoppingCamera;
      await source!.stop();
      if (_disposed || op != _operation) return;
      if (recalibrate) {
        body = BodyCalibrator();
        jump = JumpCalibrator();
        squat = SquatCalibrator();
        interpreter = null;
        latest = null;
        metrics = TrackingMetrics();
        movement = const MovementInput(valid: false);
        _lastGood = -10000;
      }
      await source!.start(mode, frontCamera: front);
      if (_disposed || op != _operation) {
        await source!.stop();
        return;
      }
      cameraActive = true;
      stage = recalibrate ? PlayStage.calibration : PlayStage.flying;
      if (!recalibrate) {
        _preparingCapture = _startCapture();
        await _preparingCapture;
        if (_disposed || op != _operation) return;
        recorder?.command('resume');
      }
      message = mode == PlayMode.pushUp
          ? 'Find a comfortable top position'
          : 'Stand still with your whole body and both feet in view';
      notify();
    } catch (e) {
      if (_disposed || op != _operation) return;
      stage = PlayStage.error;
      message = 'The camera could not start. Try again or switch cameras.';
      debugPrint('PushUpBird camera: $e');
      notify();
    }
  }

  Future<void> switchCamera() async {
    if (isTouch || stage == PlayStage.starting || preparingReplay) return;
    front = !front;
    await startCamera();
  }

  Future<void> fly() async {
    if (_disposed || preparingReplay) return;
    if (isTouch) {
      if (stage != PlayStage.setup) return;
    } else if ((stage != PlayStage.calibration && stage != PlayStage.ready) ||
        interpreter == null) {
      return;
    }
    final op = _operation;
    preparingReplay = true;
    if (!isTouch) {
      stage = PlayStage.ready;
      message = 'Preparing your session…';
      notify();
      _preparingCapture = _startCapture();
      await _preparingCapture;
    }
    if (_disposed || op != _operation) {
      preparingReplay = false;
      return;
    }
    interpreter?.reset();
    _touchFlap = false;
    source?.recordDiagnostic('PushUpBird reset: t=$nowMs reason=fly');
    recorder = FlightRecorder(
      ReplayTape(
        mode: mode,
        course: course,
        practice: practice,
        seed: Random().nextInt(1 << 32),
        cycleSeconds:
            squat.result?.cycleSeconds ?? body.result?.cycleSeconds ?? 3,
        bird: bird,
        weaponDamage: weaponDamage,
        reducedMotion: reducedMotion,
        originMs: nowMs,
      ),
      () => nowMs,
    );
    simulation = recorder!.simulation;
    audio.syncCombat(simulation!, silent: true);
    stage = PlayStage.flying;
    result = null;
    saved = false;
    sessionSaved = false;
    sessionError = '';
    saveError = '';
    preparingReplay = false;
    notify();
  }

  void tick() {
    if (simulation?.phase == RunPhase.ended) {
      unawaited(finish());
    }
    notify();
  }

  Future<void> finish() => _finishing ??= _finish();

  Future<void> _finish() async {
    final game = simulation;
    if (_disposed || game == null || _saving || stage == PlayStage.results) {
      return;
    }
    _saving = true;
    recorder?.command('end', game.endReason ?? EndReason.quit);
    preparingReplay = true;
    if (!isTouch && trackingDiagnosticsEnabled) {
      source!.recordDiagnostic(
        'PushUpBird end: ${game.endReason?.name}; '
        'elapsed=${game.elapsed.toStringAsFixed(2)}; '
        'feedback=${game.trackingFeedback}',
      );
    }
    final date = clock();
    result = RunResult(
      id: '${date.microsecondsSinceEpoch}-${mode.name}',
      mode: mode,
      course: course,
      gates: game.gates,
      stars: game.collectedStars,
      bestCombo: game.bestCombo,
      perfectPasses: game.perfectPasses,
      practice: practice,
      score: game.score,
      repetitions: game.repetitions,
      flaps: game.flaps,
      durationSeconds: game.elapsed,
      reason: game.endReason!,
      finishedAt: date,
    );
    stage = PlayStage.results;
    audio.effect(game.endReason == EndReason.completed ? 'complete' : 'finish');
    notify();
    await _stopCamera();
    preparingReplay = false;
    // Countdown exits are not runs. Scored run writes are idempotent.
    if (game.started) {
      await persist();
    } else {
      saved = true;
    }
    _saving = false;
    notify();
  }

  Future<void> persist() async {
    if (result == null || saved) return;
    try {
      await saveRun(result!);
      saved = true;
      saveError = '';
    } catch (e) {
      saveError = 'Could not save your flight. Tap to retry.';
      debugPrint('PushUpBird save: $e');
    }
    notify();
  }

  void pause() {
    _touchFlap = false;
    recorder?.command('break');
    if (simulation?.phase == RunPhase.ended) {
      unawaited(finish());
    } else {
      audio.stop();
      notify();
    }
  }

  void endFlight() {
    if (simulation == null || stage != PlayStage.flying) return;
    recorder?.command('end', EndReason.breakTaken);
    unawaited(finish());
  }

  Future<void> resume() async {
    if (simulation?.phase != RunPhase.paused) return;
    if (isTouch) {
      _touchFlap = false;
      recorder?.command('resume');
      notify();
    } else if (!cameraActive) {
      await startCamera(recalibrate: false);
    } else {
      recorder?.command('resume');
      notify();
    }
    if (!_disposed && simulation?.phase == RunPhase.countdown) {
      unawaited(audio.resumeMusic());
    }
  }

  void background() {
    if (_disposed) return;
    _touchFlap = false;
    ++_operation;
    cameraActive = false;
    unawaited(_stopCamera());
    unawaited(audio.stop());
    if (stage == PlayStage.flying) {
      recorder?.command('background');
      if (simulation?.phase == RunPhase.ended) unawaited(finish());
    } else if (stage == PlayStage.calibration ||
        stage == PlayStage.ready ||
        stage == PlayStage.starting) {
      stage = PlayStage.setup;
      interpreter = null;
      message = 'Welcome back. Let’s check your position again.';
    }
    notify();
  }

  Future<void> exit() async {
    ++_operation;
    if (simulation != null &&
        simulation!.started &&
        stage == PlayStage.flying) {
      recorder?.command('end', EndReason.quit);
      await finish();
    }
    await _finishing;
    await _sessionSave;
    await _stopCamera();
    await _discardClips();
  }

  Future<void> retry() async {
    await _finishing;
    await _sessionSave;
    if (saveError.isNotEmpty) {
      await persist();
      if (!saved) return;
    }
    await _discardClips();
    _finishing = null;
    cameraRecordingError = '';
    simulation = null;
    result = null;
    stage = PlayStage.setup;
    if (isTouch) {
      await fly();
      await audio.resumeMusic();
    } else {
      await startCamera();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    ++_operation;
    _refresh?.cancel();
    _samples?.cancel();
    _issues?.cancel();
    unawaited(() async {
      await _finishing;
      await _sessionSave;
      await _stopCamera();
      await _discardClips();
      await source?.dispose();
    }());
    super.dispose();
  }
}
