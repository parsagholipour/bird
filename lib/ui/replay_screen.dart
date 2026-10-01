import 'dart:async';
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
import '../domain/flight_goals.dart';
import '../domain/session_replay.dart';
import '../domain/replay_highlights.dart';
import '../game/audio.dart';
import '../game/bird_game.dart';
import 'theme.dart';
import 'campaign_map_art.dart' show MapStarsPainter;
import 'components.dart';
import 'flight_goals.dart';
import 'replay_highlights.dart';

enum ReplayView { corner, background, gameplay }

class SessionLibraryScreen extends ConsumerWidget {
  const SessionLibraryScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(
      leading: IconButton(
        tooltip: 'Back to Records',
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.go('/records'),
      ),
      title: const Text('Saved sessions'),
    ),
    body: ref
        .watch(sessionsProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(
            child: TextButton(
              onPressed: () => ref.invalidate(sessionsProvider),
              child: const Text('Could not load sessions. Retry'),
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
                                'Your flights belong here',
                                style: heading(24),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Save a session after a flight to watch it here.',
                                style: bodyText(15),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              SkyButton(
                                label: 'Choose a flight',
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
                      title: Text(sessionTitle(run)),
                      subtitle: Text(
                        '${run.finishedAt.toLocal().toString().substring(0, 16)} · ${run.durationSeconds.round()} sec · ${run.score} ${run.course.scoreUnit}',
                      ),
                      onTap: () => context.go('/replay/${run.id}'),
                      trailing: IconButton(
                        tooltip: 'Delete session',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          final delete = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete this session?'),
                              content: const Text(
                                'The camera video and replay will be removed. Your scores stay in Records.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Delete'),
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
                                  const SnackBar(
                                    content: Text(
                                      'Could not delete session. Try again.',
                                    ),
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

/// A saved session's name in the library: the level for a campaign flight
/// ("1-3 · Bat Patrol"), otherwise the mode and course.
String sessionTitle(RunResult run) {
  final level = run.levelId == null ? null : Campaign.level(run.levelId!);
  if (level != null) return '${level.id} · ${level.name}';
  if (run.levelId != null) return 'Level ${run.levelId}';
  // A co-op flight's id ends with its mode, such as "-coop-free".
  if (run.id.contains('-coop')) {
    final mode = CoopMode.values.firstWhere(
      (mode) => run.id.endsWith('-coop-${mode.name}'),
      orElse: () => CoopMode.roped,
    );
    return 'Fly Together · ${mode.title}';
  }
  return '${run.mode.title}'
      '${run.course != FlightCourse.classic ? ' · ${run.course.title}' : ''}'
      '${run.practice ? ' · Practice' : ''}';
}

/// The hearts and shields a replay sounds out: both of a duel's birds.
int _hearts(FlightSimulation sim) =>
    sim.duel ? sim.flock.fold(0, (n, bird) => n + bird.hearts) : sim.hearts;
int _shields(FlightSimulation sim) => sim.duel
    ? sim.flock.where((bird) => bird.shield).length
    : (sim.shield ? 1 : 0);

/// Wings earned so far, for the wing chime. A level's collection marks take
/// their place, as in live play, read from the plan the replay flies.
int _wings(FlightSimulation sim) => switch (sim.plan) {
  LevelPlan(:final marks) => marks.reached(sim.collectedStars),
  _ => FlightGoals.earned(FlightGoals.forSimulation(sim)),
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
  int _corner = 0;
  String? _error;
  String _videoMessage = '';
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
        );
      });
      unawaited(_indexHighlights(session.tape));
      await _syncVideo(force: true);
    } catch (_) {
      if (mounted) setState(() => _error = 'This session could not be opened.');
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

  void _frame(Duration elapsed) {
    final now = elapsed.inMicroseconds / 1000;
    final dt = now - _lastFrame;
    _lastFrame = now;
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
    final oldWings = _wings(_player!.simulation);
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
    _audio.syncCombat(_player!.simulation, silent: !_sound);
    if (_sound) {
      final sim = _player!.simulation;
      if (sim.phase == RunPhase.playing && oldPhase == RunPhase.countdown) {
        _audio.effect('go');
      } else if (sim.phase == RunPhase.countdown &&
          sim.countdown.ceil() != oldCount) {
        _audio.effect('ready');
      }
      if (sim.phase == RunPhase.playing && _wings(sim) > oldWings) {
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
        _videoMessage = clip == null
            ? 'Camera was paused during this part of the session'
            : '';
        return;
      }
      if (_failedClips.contains(clip.path)) {
        _videoMessage = 'Camera clip unavailable · Gameplay still plays';
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
      _videoMessage = '';
    } catch (_) {
      if (_clip != null) _failedClips.add(_clip!.path);
      _videoMessage = 'Camera clip unavailable · Gameplay still plays';
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
        _videoMessage.isNotEmpty ||
        _activeClip() != _clip) {
      return ColoredBox(
        color: const Color(0xff18313b),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Text(
              _videoMessage.isEmpty ? 'Loading camera…' : _videoMessage,
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
    return Theme(
      data: theme.copyWith(
        colorScheme: const ColorScheme.dark(
          primary: SkyColors.coral,
          surface: Color(0xff18313b),
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
                      GameWidget(game: _game!),
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
            const IgnorePointer(
              child: Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('Taking a breather'),
                  ),
                ),
              ),
            ),
          // This surface stays behind the controls, so their gestures never
          // toggle visibility or change the replay's viewport dimensions.
          Semantics(
            button: true,
            label: _controlsVisible
                ? 'Hide replay controls'
                : 'Show replay controls',
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
                      IconButton(
                        tooltip: 'Back to saved sessions',
                        onPressed: () => context.go('/sessions'),
                        icon: const Icon(Icons.arrow_back),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _session!.result.levelId == null
                              ? 'REPLAY'
                              : 'REPLAY · ${sessionTitle(_session!.result)}',
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
              child: _playbackControls(),
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
                    label: 'Score: ${_player!.simulation.score}',
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
                            _player!.simulation.course.scoreLabel,
                            style: bodyText(11, color: Colors.white),
                          ),
                          Text(
                            '${_player!.simulation.score}',
                            style: heading(32, color: Colors.white),
                          ),
                          // A level earns its stars at the finish, in place of
                          // flight wings.
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
                            )
                          else if (!_player!.simulation.practice)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 3),
                              child: FlightWings(
                                goals: FlightGoals.forSimulation(
                                  _player!.simulation,
                                ),
                                size: 18,
                              ),
                            ),
                          if (_player!.simulation.isTrail)
                            Text(
                              '${_player!.simulation.duel ? 'P1 ${_player!.simulation.lead.hearts} · P2 ${_player!.simulation.partner!.hearts}' : _player!.simulation.hearts} hearts · ${_player!.simulation.clockLabel}',
                              style: bodyText(11, color: Colors.white),
                            ),
                          if (_player!.simulation.magnetActive)
                            Text(
                              'Magnet · ${_player!.simulation.magnetRemaining.ceil()}s',
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

  Widget _playbackControls() => Material(
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
                        tooltip: _playing ? 'Pause replay' : 'Play replay',
                        onPressed: () => _setPlaying(!_playing),
                        icon: Icon(_playing ? Icons.pause : Icons.play_arrow),
                      ),
                      IconButton(
                        tooltip: 'Restart replay',
                        onPressed: () => _seek(0),
                        icon: const Icon(Icons.replay),
                      ),
                      IconButton(
                        tooltip: 'Back 5 seconds',
                        onPressed: () => _seek(_position - 5000),
                        icon: const Icon(Icons.replay_5),
                      ),
                      IconButton(
                        tooltip: 'Forward 5 seconds',
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
                                child: Text('${s}x'),
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
                            ? 'Finding flight highlights'
                            : _highlights!.isEmpty
                            ? 'No flight highlights available'
                            : 'Flight highlights',
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
                            const DropdownMenuItem(
                              value: ReplayView.corner,
                              child: Text('Corner camera'),
                            ),
                          if (_session!.clips.isNotEmpty)
                            const DropdownMenuItem(
                              value: ReplayView.background,
                              child: Text('Camera background'),
                            ),
                          const DropdownMenuItem(
                            value: ReplayView.gameplay,
                            child: Text('Gameplay only'),
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
                          tooltip: 'Move camera corner',
                          onPressed: () =>
                              setState(() => _corner = (_corner + 1) % 4),
                          icon: const Icon(Icons.picture_in_picture_alt),
                        ),
                      if (_hasCameraAudio)
                        IconButton(
                          tooltip: _cameraSound
                              ? 'Mute recorded audio'
                              : 'Enable recorded audio',
                          onPressed: () {
                            setState(() => _cameraSound = !_cameraSound);
                            unawaited(_syncVideo());
                          },
                          icon: Icon(_cameraSound ? Icons.mic : Icons.mic_off),
                        ),
                      IconButton(
                        tooltip: _sound
                            ? 'Mute game sound'
                            : 'Enable game sound',
                        onPressed: () {
                          setState(() => _sound = !_sound);
                          _configureAudio();
                        },
                        icon: Icon(_sound ? Icons.volume_up : Icons.volume_off),
                      ),
                      IconButton(
                        tooltip: 'Hide controls / full screen',
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
      child: _error != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_error!, style: const TextStyle(color: Colors.white)),
                  TextButton(
                    onPressed: () => context.go('/sessions'),
                    child: const Text('Back to sessions'),
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
