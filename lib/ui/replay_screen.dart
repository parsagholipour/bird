import 'dart:async';
import 'dart:math' as math;
import 'jump_glide_hud.dart';
import 'dart:io';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show compute;
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import '../data/providers.dart';
import '../data/progress_repository.dart';
import '../data/session_repository.dart';
import '../domain/campaign.dart';
import '../domain/game_rules.dart';
import '../domain/session_replay.dart';
import '../domain/replay_highlights.dart';
import '../game/audio.dart';
import '../game/bird_game.dart';
import '../game/finish_celebration_art.dart';
import 'theme.dart';
import 'campaign_chrome.dart' show MapGlyph, MapKey;
import 'campaign_map_art.dart' show MapStarsPainter;
import 'components.dart';
import 'keyboard.dart' show BackKeyTarget;
import 'replay_highlights.dart';
import '../l10n/l10n.dart';
import '../l10n/text/date_text.dart';
import '../l10n/text/replay_text.dart';

enum ReplayView { corner, background, gameplay }

/// What the camera window says instead of video, if anything.
enum _VideoNote { none, paused, unavailable }

class SessionLibraryScreen extends ConsumerWidget {
  const SessionLibraryScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(
        leading: BackKeyTarget(
          onBack: () => context.go('/records'),
          child: IconButton(
            tooltip: l.replayBackToRecordsSemantics,
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/records'),
          ),
        ),
        title: Text(l.replaySavedSessions),
      ),
      body: ref
          .watch(sessionsProvider)
          .when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => Center(
              child: TextButton(
                onPressed: () => ref.invalidate(sessionsProvider),
                child: Text(l.replaySessionsLoadFailed),
              ),
            ),
            data: (sessions) => sessions.isEmpty
                ? SafeArea(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: Panel(
                            color: SkyColors.cream,
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const BirdArt(size: 48, bob: false),
                                const SizedBox(height: 8),
                                Text(
                                  l.replayEmptyTitle,
                                  style: heading(24),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  l.replayEmptyBody,
                                  style: bodyText(15),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                SkyButton(
                                  label: l.replayEmptyButton,
                                  onPressed: () => context.go('/'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: sessions.length,
                    itemBuilder: (context, i) {
                      final run = sessions[i];
                      return ListTile(
                        leading: const Icon(Icons.play_circle_outline),
                        title: Text(sessionTitle(run, l)),
                        subtitle: Text(sessionDetail(run, l)),
                        onTap: () => context.go('/replay/${run.id}'),
                        trailing: IconButton(
                          tooltip: l.replayDeleteSemantics,
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            final delete = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text(l.replayDeleteTitle),
                                content: Text(l.replayDeleteBody),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: Text(l.commonCancel),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: Text(l.commonDelete),
                                  ),
                                ],
                              ),
                            );
                            if (delete == true) {
                              try {
                                await ref
                                    .read(sessionRepositoryProvider)
                                    .delete(run.id);
                                ref.invalidate(sessionsProvider);
                              } catch (_) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(l.replayDeleteFailed),
                                    ),
                                  );
                                }
                              }
                            }
                          },
                        ),
                      );
                    },
                  ),
          ),
    );
  }
}

/// A saved session's name in the library: the level for a campaign flight
/// ("1-3 · Bat Patrol"), otherwise the mode and course; in [l]'s language
/// (the current one by default).
String sessionTitle(RunResult run, [AppLocalizations? l]) {
  l ??= L10n.strings;
  final mode = l.playModeName(run.mode);
  // A built level keeps the name its maker typed.
  if (run.levelName case final name?) return l.replaySessionBuilt(name, mode);
  final level = run.levelId == null ? null : Campaign.level(run.levelId!);
  if (level != null) return l.homeLevelLabel(level.id, l.levelName(level));
  if (run.levelId != null) return l.replaySessionUnknownLevel(run.levelId!);
  // A co-op flight's id ends with its mode, such as "-coop-free".
  if (run.id.contains('-coop')) {
    final mode = CoopMode.values.firstWhere(
      (mode) => run.id.endsWith('-coop-${mode.name}'),
      orElse: () => CoopMode.roped,
    );
    return l.flyTogetherName(mode);
  }
  final endless = run.course != FlightCourse.classic;
  return switch ((endless, run.practice)) {
    (true, true) => l.replaySessionEndlessPractice(mode),
    (true, false) => l.replaySessionEndless(mode),
    (false, true) => l.replaySessionPractice(mode),
    (false, false) => mode,
  };
}

/// A saved session's line under its name: when, how long, its score.
String sessionDetail(RunResult run, AppLocalizations l) {
  final date = l.dateTimeDigits(run.finishedAt.toLocal());
  final seconds = run.durationSeconds.round();
  return switch (run.course) {
    FlightCourse.classic => l.replaySessionGates(run.score, date, seconds),
    FlightCourse.starTrail => l.replaySessionStars(run.score, date, seconds),
  };
}

/// The replay's hearts and clock under the score: "3 hearts · 1:05", or
/// both duel birds' hearts.
String _heartsLine(AppLocalizations l, FlightSimulation sim) {
  final clock = sim.timed
      ? l.replayClockSeconds(sim.remainingSeconds.ceil())
      : sim.clockLabel;
  return sim.duel
      ? l.replayDuelHearts(sim.lead.hearts, sim.partner!.hearts, clock)
      : l.replayHearts(sim.hearts, clock);
}

/// The hearts and shields a replay sounds out: both of a duel's birds.
int _hearts(FlightSimulation sim) =>
    sim.duel ? sim.flock.fold(0, (n, bird) => n + bird.hearts) : sim.hearts;
int _shields(FlightSimulation sim) => sim.duel
    ? sim.flock.where((bird) => bird.shield).length
    : (sim.shield ? 1 : 0);

/// A level's collection marks reached so far, for the wing chime, as in live
/// play, read from the plan the replay flies. Endless flights have none.
int _marks(FlightSimulation sim) => switch (sim.plan) {
  LevelPlan(:final marks) => marks.reached(sim.collectedStars),
  _ => 0,
};

class ReplayScreen extends ConsumerStatefulWidget {
  const ReplayScreen({super.key, required this.id});
  final String id;
  @override
  ConsumerState<ReplayScreen> createState() => _ReplayScreenState();
}

class _ReplayScreenState extends ConsumerState<ReplayScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final Ticker _ticker;
  late final SkyAudio _audio;
  SavedSession? _session;
  ReplayPlayer? _player;
  BirdGame? _game;
  VideoPlayerController? _video;
  SessionClip? _clip;
  final Set<String> _failedClips = {};
  ReplayView _view = ReplayView.corner;
  bool _playing = false, _sound = true, _mediaBusy = false, _scrubbing = false;
  bool _controlsVisible = true, _cameraSound = true;
  bool get _hasCameraAudio => _session?.clips.any((c) => c.hasAudio) ?? false;
  bool _resumeAfterScrub = false,
      _syncPending = false,
      _forcePending = false,
      _loadingMedia = false,
      _closed = false;
  double _speed = 1, _position = 0, _lastFrame = 0, _lastSync = -1000;

  /// Seconds since the replay reached a level's finish line, while its
  /// celebration plays on past the end of the tape; null otherwise. A seek
  /// to the end shows its settled frame.
  double? _celebration;
  int _corner = 0;
  bool _error = false;
  _VideoNote _videoNote = _VideoNote.none;
  List<ReplayHighlight>? _highlights;
  bool get _scoreHudOnRight => _player!.simulation.boss != null;

  @override
  void initState() {
    super.initState();
    _audio = ref.read(audioFactoryProvider)();
    WidgetsBinding.instance.addObserver(this);
    _ticker = createTicker(_frame)..start();
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final session = await ref.read(sessionRepositoryProvider).load(widget.id);
      if (!mounted) return;
      final player = ReplayPlayer(session.tape)..seek(0);
      setState(() {
        _session = session;
        _player = player;
        if (session.clips.isEmpty) _view = ReplayView.gameplay;
        _game = BirdGame(
          simulation: player.simulation,
          nowMs: () => 0,
          bird: session.tape.bird,
          partnerBird: session.tape.partner,
          reducedMotion: session.tape.reducedMotion,
          playback: true,
          onChanged: () {},
          // With no result to hand over to, the bird ends hovering.
          finish: () => _celebration,
        );
      });
      unawaited(_indexHighlights(session.tape));
      await _syncVideo(force: true);
    } catch (_) {
      if (mounted) setState(() => _error = true);
    }
  }

  Future<void> _indexHighlights(ReplayTape tape) async {
    try {
      final moments = await compute(buildReplayHighlights, tape);
      if (mounted && !_closed) setState(() => _highlights = moments);
    } catch (_) {
      // Indexing is optional; the original replay stays fully playable.
      if (mounted && !_closed) setState(() => _highlights = const []);
    }
  }

  Future<void> _showHighlights() async {
    final moments = _highlights;
    if (moments == null || moments.isEmpty) return;
    _setPlaying(false);
    final selected = await showReplayHighlights(context, moments);
    if (!mounted || _closed || selected == null) return;
    _seek(selected.playFromMs);
    _setPlaying(true);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _setPlaying(false);
  }

  /// Whether [sim] has crossed a level's finish line, to celebrate.
  static bool _celebrates(FlightSimulation sim) =>
      sim.phase == RunPhase.ended &&
      sim.endReason == EndReason.completed &&
      sim.finishLine?.crossed == true;

  double get _celebrationStill => FinishCelebrationArt.stillAt(
    reducedMotion: _session?.tape.reducedMotion ?? false,
  );

  void _frame(Duration elapsed) {
    final now = elapsed.inMicroseconds / 1000;
    final dt = now - _lastFrame;
    _lastFrame = now;
    final party = _celebration;
    if (party != null && party < _celebrationStill && !_scrubbing) {
      setState(() {
        _celebration = math.min(
          _celebrationStill,
          party + dt.clamp(0, 100) / 1000 * _speed,
        );
      });
    }
    if (_player == null || !_playing || _scrubbing || _loadingMedia) return;
    if (_video?.value.isBuffering == true &&
        _video?.value.hasError == false &&
        (_view != ReplayView.gameplay ||
            (_cameraSound && _clip?.hasAudio == true)) &&
        _activeClip() != null &&
        _activeClip() == _clip) {
      return;
    }
    final oldScore = _player!.simulation.score,
        oldFlaps = _player!.simulation.flaps;
    final oldPerfects = _player!.simulation.perfectPasses;
    final oldStars = _player!.simulation.collectedStars;
    final oldMultiplier = _player!.simulation.multiplier;
    final oldMagnets = _player!.simulation.magnetActivations;
    final oldMarks = _marks(_player!.simulation);
    final oldFlightTime = _player!.simulation.elapsed;
    final oldHearts = _hearts(_player!.simulation);
    final oldShields = _shields(_player!.simulation);
    final oldPhase = _player!.simulation.phase;
    final oldCount = _player!.simulation.countdown.ceil();
    _position = (_position + dt.clamp(0, 100) * _speed).clamp(
      0,
      _session!.tape.durationMs,
    );
    _player!.seek(_position);
    _game!.simulation = _player!.simulation;
    if (oldPhase != RunPhase.ended && _celebrates(_player!.simulation)) {
      _celebration = 0;
    }
    _audio.syncCombat(_player!.simulation, silent: !_sound);
    if (_sound) {
      final sim = _player!.simulation;
      if (sim.phase == RunPhase.playing && oldPhase == RunPhase.countdown) {
        _audio.effect('go');
      } else if (sim.phase == RunPhase.countdown &&
          sim.countdown.ceil() != oldCount) {
        _audio.effect('ready');
      }
      if (sim.phase == RunPhase.playing && _marks(sim) > oldMarks) {
        _audio.effect('wing');
      } else if (sim.magnetActivations > oldMagnets) {
        _audio.effect('magnet');
      } else if (sim.collectsStars && sim.collectedStars > oldStars) {
        _audio.effect('star');
      } else if (sim.multiplier > oldMultiplier) {
        _audio.effect('streak');
      } else if (sim.perfectPasses > oldPerfects) {
        _audio.effect('perfect');
      } else if (!sim.collectsStars && sim.score > oldScore) {
        _audio.effect('point');
      }
      if (sim.isTrail && _hearts(sim) < oldHearts) _audio.effect('bump');
      if (sim.isTrail && _hearts(sim) > oldHearts) _audio.effect('heart');
      if (sim.isTrail && _shields(sim) < oldShields) {
        _audio.effect('shield_pop');
      }
      if (sim.isTrail && _shields(sim) > oldShields) _audio.effect('shield');
      if (sim.timed &&
          oldFlightTime < sim.course.duration - 10 &&
          sim.elapsed >= sim.course.duration - 10) {
        _audio.effect('final_stretch');
      }
      if (_player!.simulation.flaps > oldFlaps) _audio.effect('flap');
      if (oldPhase != RunPhase.ended &&
          _player!.simulation.phase == RunPhase.ended) {
        _audio.effect(
          _player!.simulation.endReason == EndReason.completed
              ? 'complete'
              : 'finish',
        );
      }
    }
    if (_position >= _session!.tape.durationMs) _setPlaying(false);
    if (now - _lastSync >= 100) {
      _lastSync = now;
      unawaited(_syncVideo());
    }
    setState(() {});
  }

  SessionClip? _activeClip() {
    for (final clip in _session?.clips ?? <SessionClip>[]) {
      if (_position >= clip.startMs &&
          _position < clip.startMs + clip.durationMs) {
        return clip;
      }
    }
    return null;
  }

  Future<void> _syncVideo({bool force = false}) async {
    if (_closed || _session == null) return;
    if (_mediaBusy) {
      _syncPending = true;
      _forcePending |= force;
      return;
    }
    _mediaBusy = true;
    try {
      final clip = _activeClip();
      if (clip == null ||
          (_view == ReplayView.gameplay && !(_cameraSound && clip.hasAudio))) {
        await _video?.setVolume(0);
        await _video?.pause();
        _videoNote = clip == null ? _VideoNote.paused : _VideoNote.none;
        return;
      }
      if (_failedClips.contains(clip.path)) {
        _videoNote = _VideoNote.unavailable;
        return;
      }
      if (_clip != clip) {
        _loadingMedia = true;
        final old = _video;
        _video = null;
        _clip = clip;
        await old?.dispose();
        if (!mounted) return;
        final video = VideoPlayerController.file(
          File(clip.path),
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
        );
        _video = video;
        await video.initialize().timeout(const Duration(seconds: 10));
        if (!mounted) return;
        force = true;
      }
      final video = _video!;
      if (video.value.hasError) throw StateError('Video playback failed');
      final volume = _cameraSound && clip.hasAudio && !_scrubbing ? 1.0 : 0.0;
      if (video.value.volume != volume) await video.setVolume(volume);
      final desired = (_position - clip.startMs).clamp(
        0.0,
        video.value.duration.inMilliseconds.toDouble(),
      );
      final actual = await video.position;
      if (force) _loadingMedia = true;
      if (force ||
          actual == null ||
          (actual.inMilliseconds - desired).abs() > 120) {
        await video.seekTo(Duration(milliseconds: desired.round()));
      }
      if (video.value.playbackSpeed != _speed) {
        await video.setPlaybackSpeed(_speed);
      }
      if (_playing && !_scrubbing) {
        if (!video.value.isPlaying) await video.play();
      } else {
        await video.pause();
      }
      _videoNote = _VideoNote.none;
    } catch (_) {
      if (_clip != null) _failedClips.add(_clip!.path);
      _videoNote = _VideoNote.unavailable;
      try {
        if (!_closed) await _video?.pause();
      } catch (_) {}
    } finally {
      _mediaBusy = false;
      _loadingMedia = false;
      if (_syncPending && !_closed) {
        final pendingForce = _forcePending;
        _syncPending = false;
        _forcePending = false;
        unawaited(_syncVideo(force: pendingForce));
      }
      if (mounted && !_closed) setState(() {});
    }
  }

  void _configureAudio() {
    unawaited(
      _audio.configure(
        GameSettings(music: _sound, effects: _sound),
        active: _playing && !_scrubbing,
        // A campaign flight replays to its region's song.
        track: SkyMusic.flightOver(
          Campaign.level(_session?.result.levelId ?? '')?.region ??
              _session?.tape.built?.region,
        ),
      ),
    );
    unawaited(_audio.setRate(_speed));
    if (!_playing || !_sound || _scrubbing) unawaited(_audio.stopEffects());
  }

  void _setPlaying(bool playing) {
    if (!mounted) return;
    if (playing && _position >= (_session?.tape.durationMs ?? 0)) _seek(0);
    setState(() {
      _playing = playing;
      if (!playing) _controlsVisible = true;
    });
    _configureAudio();
    unawaited(_syncVideo(force: true));
  }

  void _seek(double position) {
    if (_player == null) return;
    setState(() {
      _position = position.clamp(0.0, _session!.tape.durationMs);
      _player!.seek(_position);
      _audio.syncCombat(_player!.simulation, silent: true);
      _game!.simulation = _player!.simulation;
      _celebration =
          _position >= _session!.tape.durationMs &&
              _celebrates(_player!.simulation)
          ? _celebrationStill
          : null;
    });
    unawaited(_audio.stopEffects());
    unawaited(_syncVideo(force: true));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _closed = true;
    _ticker.dispose();
    unawaited(_video?.dispose());
    unawaited(_audio.dispose());
    super.dispose();
  }

  String _time(double ms) {
    final s = (ms / 1000).floor();
    return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
  }

  Widget _camera({required bool background}) {
    final video = _video;
    if (video == null ||
        !video.value.isInitialized ||
        _videoNote != _VideoNote.none ||
        _activeClip() != _clip) {
      return ColoredBox(
        color: SkyColors.night,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Text(
              switch (_videoNote) {
                _VideoNote.none => context.l10n.replayCameraLoading,
                _VideoNote.paused => context.l10n.replayCameraPaused,
                _VideoNote.unavailable => context.l10n.replayCameraUnavailable,
              },
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ),
      );
    }
    return ClipRect(
      child: SizedBox.expand(
        child: FittedBox(
          fit: background ? BoxFit.cover : BoxFit.contain,
          child: SizedBox(
            width: video.value.size.width,
            height: video.value.size.height,
            child: VideoPlayer(video),
          ),
        ),
      ),
    );
  }

  void _toggleControls() =>
      setState(() => _controlsVisible = !_controlsVisible);

  Widget _playback() {
    final theme = Theme.of(context);
    final l = context.l10n;
    return Theme(
      data: theme.copyWith(
        colorScheme: const ColorScheme.dark(
          primary: SkyColors.coral,
          surface: SkyColors.night,
        ),
        textTheme: theme.textTheme.apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: _player!.aspectRatio,
              child: ClipRect(
                child: LayoutBuilder(
                  builder: (context, constraints) => Stack(
                    fit: StackFit.expand,
                    children: [
                      if (_view == ReplayView.background)
                        _camera(background: true),
                      // Flame's game widget would take the focus and keep
                      // every key from the replay's controls.
                      ExcludeFocus(
                        child: FlightDirection(
                          child: GameWidget(game: _game!, autofocus: false),
                        ),
                      ),
                      if (_view == ReplayView.corner)
                        Align(
                          alignment: [
                            Alignment.topRight,
                            Alignment.topLeft,
                            Alignment.bottomRight,
                            Alignment.bottomLeft,
                          ][_corner],
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Container(
                              key: const ValueKey('replay-camera-inset'),
                              width: constraints.maxWidth * .25,
                              height: constraints.maxHeight * .34,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: _camera(background: false),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_player!.simulation.phase == RunPhase.paused)
            IgnorePointer(
              child: Center(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(l.replayPaused),
                  ),
                ),
              ),
            ),
          // This surface stays behind the controls, so their gestures never
          // toggle visibility or change the replay's viewport dimensions.
          Semantics(
            button: true,
            label: _controlsVisible
                ? l.replayHideControlsSemantics
                : l.replayShowControlsSemantics,
            onTap: _toggleControls,
            child: GestureDetector(
              key: const ValueKey('replay-tap-surface'),
              behavior: HitTestBehavior.opaque,
              excludeFromSemantics: true,
              onTap: _toggleControls,
            ),
          ),
          if (_controlsVisible) ...[
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black54, Colors.transparent],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 16, 12),
                  child: Row(
                    children: [
                      MapKey(
                        glyph: MapGlyph.back,
                        label: l.replayBackToSavedSemantics,
                        onPressed: () => context.go('/sessions'),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _session!.result.levelId == null
                              ? l.replayTitle
                              : l.replayTitleSession(
                                  sessionTitle(_session!.result, l),
                                ),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              // A media timeline runs left to right in every language,
              // like the flight it plays.
              child: FlightDirection(child: _playbackControls(l)),
            ),
          ],
          if (!_player!.simulation.bossCutscene)
            Positioned(
              top: 12,
              left: _scoreHudOnRight ? null : 0,
              right: _scoreHudOnRight ? 12 : 0,
              child: IgnorePointer(
                child: Center(
                  widthFactor: 1,
                  child: Semantics(
                    label: l.replayScoreSemantics(_player!.simulation.score),
                    excludeSemantics: true,
                    child: Container(
                      key: const ValueKey('replay-score'),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xcc18313b),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white38),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            l.replayScoreLabel(_player!.simulation.course),
                            style: bodyText(11, color: Colors.white),
                          ),
                          Text(
                            '${_player!.simulation.score}',
                            style: heading(32, color: Colors.white),
                          ),
                          // A level earns its stars at the finish.
                          if (_player!.simulation.levelId != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: SizedBox(
                                width: 54,
                                height: 16,
                                child: CustomPaint(
                                  painter: MapStarsPainter(
                                    _player!.simulation.levelStars,
                                  ),
                                ),
                              ),
                            ),
                          if (_player!.simulation.isTrail)
                            Text(
                              _heartsLine(l, _player!.simulation),
                              style: bodyText(11, color: Colors.white),
                            ),
                          if (_player!.simulation.magnetActive)
                            Text(
                              l.replayMagnet(
                                _player!.simulation.magnetRemaining.ceil(),
                              ),
                              style: bodyText(11, color: SkyColors.lavender),
                            ),
                          if (_player!.simulation.supportsJumpGlide)
                            JumpGlideHud(
                              simulation: _player!.simulation,
                              compact: true,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _playbackControls(AppLocalizations l) => Material(
    key: const ValueKey('replay-controls'),
    color: Colors.transparent,
    child: DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Color(0xb3000000), Color(0xe6000000)],
          stops: [0, .25, 1],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(_time(_position)),
                Expanded(
                  child: Slider(
                    value: _position,
                    max: _session!.tape.durationMs.clamp(1, double.infinity),
                    semanticFormatterCallback: _time,
                    onChangeStart: (_) {
                      _resumeAfterScrub = _playing;
                      _scrubbing = true;
                      _configureAudio();
                      unawaited(_syncVideo(force: true));
                    },
                    onChanged: _seek,
                    onChangeEnd: (v) {
                      _scrubbing = false;
                      _seek(v);
                      _setPlaying(_resumeAfterScrub);
                    },
                  ),
                ),
                Text(_time(_session!.tape.durationMs)),
              ],
            ),
            // Keep related controls together while allowing compact screens
            // to wrap without shrinking the gameplay underneath.
            SizedBox(
              width: double.infinity,
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: _playing
                            ? l.replayPauseSemantics
                            : l.replayPlaySemantics,
                        onPressed: () => _setPlaying(!_playing),
                        icon: Icon(_playing ? Icons.pause : Icons.play_arrow),
                      ),
                      IconButton(
                        tooltip: l.replayRestartSemantics,
                        onPressed: () => _seek(0),
                        icon: const Icon(Icons.replay),
                      ),
                      IconButton(
                        tooltip: l.replayBack5Semantics,
                        onPressed: () => _seek(_position - 5000),
                        icon: const Icon(Icons.replay_5),
                      ),
                      IconButton(
                        tooltip: l.replayForward5Semantics,
                        onPressed: () => _seek(_position + 5000),
                        icon: const Icon(Icons.forward_5),
                      ),
                      DropdownButton<double>(
                        value: _speed,
                        underline: const SizedBox(),
                        items: [0.5, 1.0, 1.5, 2.0]
                            .map(
                              (s) => DropdownMenuItem(
                                value: s,
                                // A playback speed: digits and an x.
                                child: Text('${s}x'), // l10n-ignore
                              ),
                            )
                            .toList(),
                        onChanged: (s) {
                          if (s != null) {
                            setState(() => _speed = s);
                            _configureAudio();
                            unawaited(_syncVideo(force: true));
                          }
                        },
                      ),
                      IconButton(
                        tooltip: _highlights == null
                            ? l.replayHighlightsFinding
                            : _highlights!.isEmpty
                            ? l.replayHighlightsNone
                            : l.replayHighlights,
                        onPressed: _highlights?.isNotEmpty == true
                            ? _showHighlights
                            : null,
                        icon: const Icon(Icons.movie_filter_rounded),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButton<ReplayView>(
                        value: _view,
                        underline: const SizedBox(),
                        items: [
                          if (_session!.clips.isNotEmpty)
                            DropdownMenuItem(
                              value: ReplayView.corner,
                              child: Text(l.replayViewCorner),
                            ),
                          if (_session!.clips.isNotEmpty)
                            DropdownMenuItem(
                              value: ReplayView.background,
                              child: Text(l.replayViewBackground),
                            ),
                          DropdownMenuItem(
                            value: ReplayView.gameplay,
                            child: Text(l.replayViewGameplay),
                          ),
                        ],
                        onChanged: (view) {
                          if (view == null) return;
                          setState(() {
                            _view = view;
                            _game!.transparent = view == ReplayView.background;
                          });
                          unawaited(_syncVideo(force: true));
                        },
                      ),
                      if (_view == ReplayView.corner)
                        IconButton(
                          tooltip: l.replayMoveCornerSemantics,
                          onPressed: () =>
                              setState(() => _corner = (_corner + 1) % 4),
                          icon: const Icon(Icons.picture_in_picture_alt),
                        ),
                      if (_hasCameraAudio)
                        IconButton(
                          tooltip: _cameraSound
                              ? l.replayMuteRecordedSemantics
                              : l.replayUnmuteRecordedSemantics,
                          onPressed: () {
                            setState(() => _cameraSound = !_cameraSound);
                            unawaited(_syncVideo());
                          },
                          icon: Icon(_cameraSound ? Icons.mic : Icons.mic_off),
                        ),
                      IconButton(
                        tooltip: _sound
                            ? l.replayMuteGameSemantics
                            : l.replayUnmuteGameSemantics,
                        onPressed: () {
                          setState(() => _sound = !_sound);
                          _configureAudio();
                        },
                        icon: Icon(_sound ? Icons.volume_up : Icons.volume_off),
                      ),
                      IconButton(
                        tooltip: l.replayFullScreenSemantics,
                        onPressed: _toggleControls,
                        icon: const Icon(Icons.fullscreen),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    body: SafeArea(
      child: _error
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    context.l10n.replayOpenFailed,
                    style: const TextStyle(color: Colors.white),
                  ),
                  TextButton(
                    onPressed: () => context.go('/sessions'),
                    child: Text(context.l10n.replayBackToSessions),
                  ),
                ],
              ),
            )
          : _player == null
          ? const Center(child: CircularProgressIndicator())
          : _playback(),
    ),
  );
}
