import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import '../domain/campaign.dart';
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
import 'flight_voices.dart';
import 'knockout_art.dart';

/// [fallen] plays the knockout after a fatal collision; the run is already
/// being saved while it does. [results] follows it (or any other ending).
enum PlayStage {
  setup,
  starting,
  calibration,
  ready,
  flying,
  fallen,
  results,
  error,
}

class PlayController extends ChangeNotifier {
  PlayController({
    required this.mode,
    this.course = FlightCourse.starTrail,
    required this.source,
    required this.saveRun,
    required this.audio,
    required this.saveSession,
    this.bird = 0,
    this.partner,
    this.coopMode = CoopMode.roped,
    this.weaponDamage = BirdRock.baseDamage,
    this.reducedMotion = false,
    this.recordAudio = false,
    this.rememberRecordAudio,
    this.level,
    this.best = 0,
    FlightVoiceMemory? voiceMemory,
    this.rememberVoices,
    DateTime Function()? clock,
  }) : voiceMemory = voiceMemory ?? FlightVoiceMemory(),
       assert(mode == PlayMode.touch || source != null),
       assert(
         level == null ||
             (mode == PlayMode.touch && course == FlightCourse.starTrail),
         'A campaign level is a Tap & Fly Star Trail',
       ),
       assert(
         partner == null || (mode == PlayMode.touch && level == null),
         'Co-op is an endless Tap & Fly flight',
       ),
       clock = clock ?? DateTime.now {
    if (isTouch) return;
    _samples = source!.samples.listen(_onSample);
    _issues = source!.issues.listen((issue) {
      if (stage == PlayStage.results || _disposed) return;
      if (issue.code == 'background') {
        background();
        return;
      }
      // The run has ended; the camera stopping must not interrupt the fall.
      if (stage == PlayStage.fallen) return;
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
  final FlightCourse course;
  final DateTime Function() clock;
  final NativeTrackingSource? source;
  bool get isTouch => mode == PlayMode.touch;
  // Touch time advances with gameplay so pauses produce no gaps in the replay.
  double _touchTime = 0;
  bool _touchFlap = false, _partnerFlap = false;
  double get nowMs => isTouch ? _touchTime : source!.nowMs;
  final Future<void> Function(RunResult) saveRun;
  final SkyAudio audio;
  final Future<void> Function(SavedSession) saveSession;
  final int bird;

  /// Player 2's bird on a co-op flight, flying with player 1's [bird]; null
  /// for a solo flight.
  final int? partner;
  bool get coop => partner != null;

  /// Whether a co-op flight's birds share the rope, or fight a duel.
  final CoopMode coopMode;

  /// Two players fighting each other rather than flying as a team.
  bool get duel => coop && coopMode == CoopMode.duel;
  final int weaponDamage;
  final bool reducedMotion;

  /// The campaign level flown, or null for endless. Every attempt, retries
  /// included, flies the level's plan and fixed seed; the tape keeps the
  /// plan and the result carries the level id.
  final CampaignLevel? level;
  bool get campaign => level != null;

  /// The endless record this flight chases, for the bird's "new record".
  final int best;

  /// What the characters have said, shared by every flight so none repeats
  /// the last ([FlightVoices]). It may be swapped for the saved memory once
  /// that has loaded.
  FlightVoiceMemory voiceMemory;

  /// The face of whoever is talking in flight this frame, if anyone.
  FlightSpeech? get speech => audio.voices?.speech;

  /// Switches to the saved memory once it has loaded.
  void useVoiceMemory(FlightVoiceMemory memory) {
    voiceMemory = memory;
    audio.voices?.memory = memory;
  }

  /// Saves [voiceMemory] when a flight ends.
  final Future<void> Function(FlightVoiceMemory)? rememberVoices;

  /// The next flight tries again after one that was lost.
  bool _retrying = false;

  void _rememberVoices() {
    final remember = rememberVoices;
    if (remember == null) return;
    unawaited(
      remember(voiceMemory).catchError((Object error) {
        debugPrint('PushUpBird voices: $error');
      }),
    );
  }

  /// Level stars (0–3) this flight earned: none until it crosses the
  /// finish line (or beats a boss level's boss), then one for finishing and
  /// one for each collection mark reached.
  int get levelStars => simulation?.levelStars ?? 0;

  /// Whether this flight finished its level. A level fails when the flight
  /// ends any other way, such as a knockout or Finish flight in the pause
  /// menu.
  bool get levelComplete => campaign && result?.reason == EndReason.completed;

  /// The level after this one, across chapters, or null after the last or
  /// in endless. Whether it is unlocked is up to the saved progress.
  CampaignLevel? get nextLevel => level == null ? null : Campaign.after(level!);
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
  /// replay, resume and retry only check existing access.
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

  /// [player] 1 is the partner on a co-op flight.
  void flap({int player = 0}) {
    if (isTouch &&
        !_disposed &&
        stage == PlayStage.flying &&
        simulation?.phase == RunPhase.playing) {
      if (player == 0) {
        _touchFlap = true;
      } else if (coop && player == 1) {
        _partnerFlap = true;
      }
    }
  }

  /// Reads [player]'s bird: its Shoot and Sprint state on a co-op flight.
  bool _ready(int player, bool Function(FlightSimulation sim) check) {
    final sim = simulation;
    if (_disposed ||
        stage != PlayStage.flying ||
        sim == null ||
        player < 0 ||
        player >= sim.flock.length) {
      return false;
    }
    return sim.viewing(sim.flock[player], () => check(sim));
  }

  /// A co-op journal names the player behind each action.
  int? _who(int player) => coop ? player : null;

  /// Pressing Shoot starts a power shot; releasing it calls [shoot].
  void startCharge({int player = 0}) {
    if (!_ready(player, (sim) => sim.canCharge)) return;
    recorder?.command('charge', null, _who(player));
    notify();
  }

  void shoot({int player = 0}) {
    // A rejected release is still journaled when it ends a held charge.
    // Once a full charge has fired itself, lifting the button must not
    // spend a second rock.
    if (!_ready(
      player,
      (sim) => sim.supportsPowerShots ? sim.charging : sim.canShoot,
    )) {
      return;
    }
    recorder?.command('shoot', null, _who(player));
    audio.syncCombat(simulation!);
    notify();
  }

  void sprint({int player = 0}) {
    if (!_ready(player, (sim) => sim.canSprint)) return;
    recorder?.command('sprint', null, _who(player));
    audio.syncCombat(simulation!);
    notify();
  }

  void advance(double dt, double now, double width) {
    if (stage == PlayStage.fallen) {
      _advanceKnockout(dt);
      return;
    }
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
      if (coop) {
        // Each player's flap is its own journal entry.
        if (_touchFlap) recorder?.command('flap', null, 0);
        if (_partnerFlap) recorder?.command('flap', null, 1);
        _touchFlap = _partnerFlap = false;
      }
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
      _touchFlap = _partnerFlap = false;
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
    _touchFlap = _partnerFlap = false;
    source?.recordDiagnostic('PushUpBird reset: t=$nowMs reason=fly');
    recorder = FlightRecorder(
      ReplayTape(
        mode: mode,
        course: course,
        practice: false,
        seed: Random().nextInt(1 << 32),
        cycleSeconds:
            squat.result?.cycleSeconds ?? body.result?.cycleSeconds ?? 3,
        bird: bird,
        weaponDamage: weaponDamage,
        reducedMotion: reducedMotion,
        originMs: nowMs,
        // A level ignores the seed and lays its own fixed route.
        plan: level?.plan,
        partner: partner,
        coop: coopMode,
      ),
      () => nowMs,
    );
    simulation = recorder!.simulation;
    // Player 1's bird would cheer or mourn a duel as its own flight.
    audio.voices = duel
        ? null
        : FlightVoices(
            bird: bird,
            mode: mode,
            level: level,
            best: best,
            retry: _retrying,
            memory: voiceMemory,
          );
    _retrying = false;
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
      // The knockout and its stage change only on their own transitions.
      if (stage == PlayStage.fallen || stage == PlayStage.results) return;
    }
    notify();
  }

  /// Seconds since a fatal bump while its knockout plays, then held at its
  /// end under the game-over stage. Null for every other ending.
  double? knockout;
  Timer? _knockoutTimer;
  double get knockoutSeconds =>
      KnockoutArt.duration(reducedMotion: reducedMotion);

  /// A tap may skip the rest of the knockout only after [KnockoutArt.skipAfter],
  /// so frantic flapping cannot dismiss it by accident.
  bool get canSkipKnockout =>
      stage == PlayStage.fallen && (knockout ?? 0) >= KnockoutArt.skipAfter;

  void skipKnockout() {
    if (canSkipKnockout) _showStage();
  }

  void _startKnockout() {
    knockout = 0;
    _knockoutTimer?.cancel();
    // The game loop drives the knockout; this only guards against frames
    // stopping, so the stage can never be stranded.
    _knockoutTimer = Timer(
      Duration(milliseconds: ((knockoutSeconds + 1) * 1000).round()),
      _showStage,
    );
  }

  void _advanceKnockout(double dt) {
    final before = knockout;
    if (_disposed || before == null || !dt.isFinite || dt <= 0) return;
    final now = before + dt;
    knockout = now;
    final splash = simulation == null
        ? null
        : KnockoutArt.splashAt(simulation!, reducedMotion: reducedMotion);
    if (splash != null && before < splash && now >= splash) {
      audio.effect('sea_splash');
    }
    if (now >= knockoutSeconds) _showStage();
  }

  void _showStage() {
    _knockoutTimer?.cancel();
    _knockoutTimer = null;
    if (_disposed || stage != PlayStage.fallen) return;
    knockout = knockoutSeconds;
    stage = PlayStage.results;
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
      // A co-op flight is named for it: the session library tells it apart.
      id:
          '${date.microsecondsSinceEpoch}-'
          '${coop ? 'coop-${coopMode.name}' : mode.name}',
      mode: mode,
      course: course,
      gates: game.gates,
      stars: game.collectedStars,
      bestCombo: game.bestCombo,
      perfectPasses: game.perfectPasses,
      practice: false,
      score: game.score,
      repetitions: game.repetitions,
      flaps: game.flaps,
      durationSeconds: game.elapsed,
      reason: game.endReason!,
      finishedAt: date,
      bird: bird,
      levelId: game.levelId,
    );
    _rememberVoices();
    // A fatal bump plays its knockout first; saving still starts right now.
    if (game.endReason == EndReason.collision) {
      stage = PlayStage.fallen;
      _startKnockout();
      // Star Trail's last lost heart already sounds its bump.
      if (!game.isTrail) audio.effect('bump');
    } else {
      stage = PlayStage.results;
    }
    final endCue = switch (game.endReason!) {
      // A knockout ends a duel with a winner.
      EndReason.collision when duel => 'complete',
      EndReason.completed => 'complete',
      EndReason.collision ||
      EndReason.trackingLost ||
      EndReason.postureLost ||
      EndReason.stalled => 'game_over',
      _ => 'finish',
    };
    audio.effect(endCue);
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
    _touchFlap = _partnerFlap = false;
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
      _touchFlap = _partnerFlap = false;
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
    _touchFlap = _partnerFlap = false;
    ++_operation;
    cameraActive = false;
    unawaited(_stopCamera());
    unawaited(audio.stop());
    if (stage == PlayStage.flying) {
      recorder?.command('background');
      if (simulation?.phase == RunPhase.ended) unawaited(finish());
    } else if (stage == PlayStage.fallen) {
      // Coming back lands on the game-over stage, not a stale fall.
      _showStage();
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
    _retrying = result?.reason != EndReason.completed;
    await audio.stopEffects();
    if (saveError.isNotEmpty) {
      await persist();
      if (!saved) return;
    }
    await _discardClips();
    _finishing = null;
    _knockoutTimer?.cancel();
    _knockoutTimer = null;
    knockout = null;
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
    _knockoutTimer?.cancel();
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
