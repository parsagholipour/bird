import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../domain/tracking.dart';
import '../domain/game_rules.dart';
import '../tracking/native_tracking_source.dart';
import 'audio.dart';

enum PlayStage { setup, starting, calibration, ready, flying, results, error }

class PlayController extends ChangeNotifier {
  PlayController({
    required this.mode,
    required this.practice,
    required this.source,
    required this.saveRun,
    required this.audio,
  }) {
    _samples = source.samples.listen(_onSample);
    _issues = source.issues.listen((issue) {
      if (issue.code == 'background') {
        background();
        return;
      }
      message = issue.message;
      if (simulation?.phase == RunPhase.playing) {
        simulation?.end(EndReason.trackingLost);
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
  final NativeTrackingSource source;
  final Future<void> Function(RunResult) saveRun;
  final SkyAudio audio;
  late final StreamSubscription<TrackingSample> _samples;
  late final StreamSubscription<TrackingIssue> _issues;
  Timer? _refresh;
  bool _disposed = false, _saving = false, front = true, cameraActive = false;
  int _operation = 0;
  PlayStage stage = PlayStage.setup;
  BodyCalibrator body = BodyCalibrator();
  SmileCalibrator face = SmileCalibrator();
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
  bool get readyNow => source.nowMs - _lastGood < 250;
  void notify() {
    if (!_disposed) notifyListeners();
  }

  void _onSample(TrackingSample sample) {
    latest = sample;
    final now = sample.receivedMs;
    if (stage == PlayStage.calibration) {
      if (mode == PlayMode.pushUp) {
        body.add(sample, now);
        message = body.feedback;
        if (body.result != null) {
          final c = body.result!;
          source.recordDiagnostic(
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
      } else {
        face.add(sample, now);
        message = face.feedback;
        if (face.result != null) {
          interpreter = SmileInterpreter(face.result!);
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
      simulation?.apply(movement, sample, now);
      if (movement.flap && simulation?.phase == RunPhase.playing) {
        audio.effect('flap');
      }
    }
    metrics.add(sample, source.nowMs);
    if (trackingDiagnosticsEnabled && now - _lastDiagnostic >= 250) {
      _lastDiagnostic = now;
      source.recordDiagnostic(
        'PushUpBird control: t=${now.round()} stage=${stage.name} '
        'step=${body.step.name} cycles=${body.cycles} '
        'view=${body.perspective?.name} valid=${movement.valid} '
        'cues=${body.result?.cues.map((m) => '${m.cue.name}:${m.bottom.toStringAsFixed(2)}-${m.top.toStringAsFixed(2)}@${m.weight.toStringAsFixed(0)}').join(',')} '
        'topElbow=${body.result?.topElbow?.toStringAsFixed(1)} bottomElbow=${body.result?.bottomElbow?.toStringAsFixed(1)} '
        'height=${movement.height.toStringAsFixed(2)} reps=${movement.repetitions} '
        'preview=${body.previewHeight.toStringAsFixed(2)} '
        'pose=${mode == PlayMode.pushUp ? bodyDiagnostics(sample, now, preferredSide: body.side, preferredPerspective: body.perspective) : 'face'} '
        'phase=${simulation?.phase.name} count=${simulation?.countdown.toStringAsFixed(2)} '
        'feedback=${simulation?.trackingFeedback ?? message}',
      );
    }
  }

  Future<void> startCamera({bool recalibrate = true}) async {
    if (_disposed || stage == PlayStage.starting) return;
    final op = ++_operation;
    stage = PlayStage.starting;
    message = 'Waking up your camera…';
    notify();
    try {
      if (!await source.requestPermission()) {
        if (_disposed || op != _operation) return;
        stage = PlayStage.error;
        message =
            'Camera access is off. Allow it in Android settings, then come back and try again.';
        notify();
        return;
      }
      await source.stop();
      if (_disposed || op != _operation) return;
      if (recalibrate) {
        body = BodyCalibrator();
        face = SmileCalibrator();
        interpreter = null;
        latest = null;
        metrics = TrackingMetrics();
        movement = const MovementInput(valid: false);
        _lastGood = -10000;
      }
      await source.start(mode, frontCamera: front);
      if (_disposed || op != _operation) {
        await source.stop();
        return;
      }
      cameraActive = true;
      stage = recalibrate ? PlayStage.calibration : PlayStage.flying;
      if (!recalibrate) simulation?.resume();
      message = mode == PlayMode.pushUp
          ? 'Find a comfortable top position'
          : 'Relax your face and look at the phone';
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
    if (stage == PlayStage.starting) return;
    front = !front;
    await startCamera();
  }

  void fly() {
    if (stage != PlayStage.calibration && stage != PlayStage.ready) return;
    if (interpreter == null) return;
    interpreter!.reset();
    source.recordDiagnostic('PushUpBird reset: t=${source.nowMs} reason=fly');
    simulation = FlightSimulation(
      rules: mode == PlayMode.pushUp
          ? PushUpFlightMode(cycleSeconds: body.result!.cycleSeconds)
          : GrinGlideMode(),
      practice: practice,
    );
    stage = PlayStage.flying;
    result = null;
    saved = false;
    saveError = '';
    notify();
  }

  void tick() {
    if (simulation?.phase == RunPhase.ended) {
      unawaited(finish());
    }
    notify();
  }

  Future<void> finish() async {
    final game = simulation;
    if (_disposed || game == null || _saving || stage == PlayStage.results) {
      return;
    }
    _saving = true;
    game.end(game.endReason ?? EndReason.quit);
    if (trackingDiagnosticsEnabled) {
      source.recordDiagnostic(
        'PushUpBird end: ${game.endReason?.name}; '
        'elapsed=${game.elapsed.toStringAsFixed(2)}; '
        'feedback=${game.trackingFeedback}',
      );
    }
    final date = DateTime.now();
    result = RunResult(
      id: '${date.microsecondsSinceEpoch}-${mode.name}',
      mode: mode,
      practice: practice,
      score: game.score,
      repetitions: game.repetitions,
      flaps: game.flaps,
      durationSeconds: game.elapsed,
      reason: game.endReason!,
      finishedAt: date,
    );
    stage = PlayStage.results;
    audio.effect('finish');
    notify();
    await source.stop();
    cameraActive = false;
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
    simulation?.takeBreak();
    if (simulation?.phase == RunPhase.ended) {
      unawaited(finish());
    } else {
      audio.stop();
      notify();
    }
  }

  Future<void> resume() async {
    if (simulation?.phase != RunPhase.paused) return;
    if (!cameraActive) {
      await startCamera(recalibrate: false);
    } else {
      simulation?.resume();
      notify();
    }
  }

  void background() {
    if (_disposed || stage == PlayStage.starting) return;
    ++_operation;
    cameraActive = false;
    unawaited(source.stop());
    unawaited(audio.stop());
    if (stage == PlayStage.flying) {
      simulation?.background();
      if (simulation?.phase == RunPhase.ended) unawaited(finish());
    } else if (stage == PlayStage.calibration || stage == PlayStage.ready) {
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
      simulation!.end(EndReason.quit);
      await finish();
    }
    await source.stop();
    cameraActive = false;
  }

  Future<void> retry() async {
    if (saveError.isNotEmpty) {
      await persist();
      if (!saved) return;
    }
    simulation = null;
    result = null;
    stage = PlayStage.setup;
    await startCamera();
  }

  @override
  void dispose() {
    _disposed = true;
    ++_operation;
    _refresh?.cancel();
    _samples.cancel();
    _issues.cancel();
    source.dispose();
    super.dispose();
  }
}
