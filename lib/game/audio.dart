import 'dart:async';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import '../data/progress_repository.dart';
import '../domain/game_rules.dart';
import 'boss_audio_cues.dart';
import 'combat_audio_cues.dart';
import 'sound_bank.dart';
import 'campaign_voices.dart';
import 'flight_voices.dart';

enum SkyMusic {
  menu('audio/sky_menu.ogg'),
  flight('audio/sky_flight.ogg'),
  boss('audio/sky_boss.ogg');

  const SkyMusic(this.asset);
  final String asset;
}

class SkyAudio {
  SkyAudio({this._effectClock, Random? random}) : _random = random ?? Random();
  final int Function()? _effectClock;
  final Random _random;
  /// The sprint calls of a bird with none of its own recorded.
  static const _sharedSprintVoices = [
    'audio/sprint_voice_examples/sprint_03.mp3',
    'audio/sprint_voice_examples/sprint_01.mp3',
    'audio/sprint_voice_examples/sprint_08.mp3',
    'audio/sprint_voice_examples/whee_no_laugh/whee_04.mp3',
  ];

  /// The equipped bird calls out in its own voice as it sprints.
  List<String> get _sprintVoiceAssets {
    final own = CampaignVoices.sprints(_settings.bird);
    return own.length >= 2 ? own : _sharedSprintVoices;
  }

  int? _lastSprintVoice;
  int get _now => _effectClock?.call() ?? _clock.elapsedMilliseconds;
  // Only the music player owns focus. Effects must mix without pausing it.
  static final _effectContext = AudioContext(
    android: const AudioContextAndroid(
      usageType: AndroidUsageType.game,
      contentType: AndroidContentType.sonification,
      audioFocus: AndroidAudioFocus.none,
    ),
  );
  final _bossCues = BossAudioCues();
  final _combatCues = CombatAudioCues();
  void syncCombat(FlightSimulation simulation, {bool silent = false}) {
    if (_disposed) return;
    for (final cue in _combatCues.advance(simulation, silent: silent)) {
      effect(
        cue,
        variant: cue == 'sprint_ring'
            ? (simulation.ringChain - 1).clamp(0, 2)
            : null,
      );
    }
    syncBoss(simulation.boss, silent: silent);
    final line = voices?.update(
      simulation,
      mute: silent || _disposed || !_settings.voices,
    );
    if (line == null) return;
    final revision = ++_flightLine;
    if (line.delay <= 0) {
      speak(line.asset, duck: flightDuck);
    } else {
      Timer(Duration(milliseconds: (line.delay * 1000).round()), () {
        if (revision == _flightLine) speak(line.asset, duck: flightDuck);
      });
    }
  }

  /// Counts in-flight lines, so a delayed one is dropped when another line
  /// or a stop comes first.
  int _flightLine = 0;

  /// The live flight's voice-over, set by the flight's controller. Replays
  /// and Flight School leave it null and stay quiet; the sprint calls then
  /// come from [_playSprintVoice] as before.
  FlightVoices? voices;

  /// How far the music ducks under an in-flight line: less than under a
  /// story line, so short calls never pump the flight's music.
  static const flightDuck = .6;

  bool _bossPresent = false, _bossQuiet = false;
  void syncBoss(SkyBoss? boss, {bool silent = false}) {
    if (_disposed) return;
    final present = boss != null;
    final quiet = boss?.inCutscene == true;
    if (_bossPresent != present || _bossQuiet != quiet) {
      _bossPresent = present;
      _bossQuiet = quiet;
      // Silent replay seeks still select the next track, but cannot unpause it.
      unawaited(_syncMusic());
    }
    for (final cue in _bossCues.advance(boss, silent: silent)) {
      effect(cue);
    }
  }

  final _music = AudioPlayer();
  final _effects = List.generate(8, (_) => _EffectVoice());
  final _sprintVoice = _EffectVoice();
  Iterable<_EffectVoice> get _allEffects => [..._effects, _sprintVoice];

  /// Says the story's recorded lines. It plays at normal speed whatever the
  /// flight's rate, and the music ducks under it.
  final _speech = _EffectVoice();
  StreamSubscription<void>? _speechEnds;

  /// The line being said, by its [_speech] revision, or null in silence.
  int? _speaking;

  /// The music's level under the line being said.
  double _duckTo = .35;
  final _clock = Stopwatch()..start();
  final _lastEffect = <String, int>{};
  final _variations = <String, int>{};
  double _rate = 1;
  bool _effectsSuspended = false;
  bool _preloaded = false;
  GameSettings _settings = const GameSettings();
  SkyMusic _scene = SkyMusic.flight;
  SkyMusic? _loadedTrack;
  bool _active = false;
  double? _volume;
  bool _playing = false, _disposed = false;
  Future<void> _configuration = Future.value();
  int _revision = 0;
  Future<void> configure(
    GameSettings settings, {
    bool active = true,
    SkyMusic track = SkyMusic.flight,
  }) {
    _settings = settings;
    _active = active;
    _scene = track;
    if (active) _effectsSuspended = false;
    if (!_preloaded && settings.effects) {
      _preloaded = true;
      unawaited(
        AudioCache.instance
            .loadAll([
              for (final entry in soundBank.entries)
                for (var variant = 0; variant < entry.value.variants; variant++)
                  soundAsset(entry.key, variant),
              ..._sprintVoiceAssets,
            ])
            .catchError((Object error) {
              debugPrint('SkyAudio preload: $error');
              return <Uri>[];
            }),
      );
    }
    if (!settings.effects) unawaited(stopEffects());
    return _syncMusic();
  }

  Future<void> _syncMusic() {
    final revision = ++_revision;
    // Boss state, settings and pause changes share one queue. Per-frame boss
    // updates only enter it when the encounter or cinematic state changes.
    return _configuration = _configuration.then((_) async {
      if (_disposed || revision != _revision) return;
      try {
        if (_settings.music && _active) {
          final track = _scene == SkyMusic.flight && _bossPresent
              ? SkyMusic.boss
              : _scene;
          // Dominant bed; cinematic duck leaves roar and reveal cues in front.
          // A character speaking ducks it further.
          final volume =
              (_scene != SkyMusic.menu && _bossQuiet ? .14 : .70) *
              (_speaking == null ? 1 : _duckTo);
          if (!_playing || _loadedTrack != track) {
            if (_loadedTrack != null && _loadedTrack != track) {
              await _music.stop();
            }
            await _music.setReleaseMode(ReleaseMode.loop);
            await _music.setVolume(volume);
            _volume = volume;
            if (_loadedTrack == track) {
              await _music.resume();
            } else {
              await _music.play(AssetSource(track.asset));
              _loadedTrack = track;
            }
            _playing = true;
          } else if (_volume != volume) {
            await _music.setVolume(volume);
            _volume = volume;
          }
        } else {
          await _music.pause();
          _playing = false;
        }
      } catch (error) {
        _playing = false;
        _loadedTrack = null;
        debugPrint('SkyAudio music: $error');
        // Audio availability never blocks camera or game controls.
      }
    });
  }

  /// [variant] picks a specific take; otherwise takes rotate.
  void effect(String name, {int? variant}) {
    final spec = soundBank[name];
    if (_disposed || _effectsSuspended || !_settings.effects || spec == null) {
      return;
    }
    final now = _now;
    final last = _lastEffect[name];
    if (last != null && now - last < spec.cooldownMs / _rate) return;
    if (name == 'sprint' && _settings.voices && voices == null) {
      _playSprintVoice();
    }
    // Free voices first. If full, steal only a less important sound. A shot
    // can never truncate a roar, damage cue, death or victory celebration.
    _EffectVoice? voice;
    for (final candidate in _effects) {
      if (candidate.until <= now) {
        voice = candidate;
        break;
      }
      if (candidate.priority < spec.priority &&
          (voice == null ||
              candidate.priority < voice.priority ||
              (candidate.priority == voice.priority &&
                  candidate.until < voice.until))) {
        voice = candidate;
      }
    }
    if (voice == null) return;
    if (name == 'game_over') {
      _active = false;
      unawaited(_syncMusic());
    }
    _lastEffect[name] = now;
    final take = (variant ?? _variations[name] ?? 0) % spec.variants;
    _variations[name] = take + 1;
    final selected = voice;
    final revision = ++selected.revision;
    selected.priority = spec.priority;
    selected.until = now + (spec.seconds * 1000 / _rate).ceil() + 80;
    selected.pending = selected.pending.then((_) async {
      bool cancelled() =>
          _disposed || revision != selected.revision || !_settings.effects;
      if (cancelled()) return;
      try {
        await selected.player.stop();
        if (!selected.initialized) {
          await selected.player.setAudioContext(_effectContext);
          await selected.player.setPlayerMode(PlayerMode.lowLatency);
          await selected.player.setReleaseMode(ReleaseMode.stop);
          selected.initialized = true;
        }
        await selected.player.setSource(AssetSource(soundAsset(name, take)));
        await selected.player.setVolume(spec.volume);
        await selected.player.setPlaybackRate(_rate);
        if (cancelled()) return;
        // Reservation starts at playback, including slow first asset loads.
        selected.until = _now + (spec.seconds * 1000 / _rate).ceil() + 30;
        await selected.player.resume();
        if (cancelled()) await selected.player.stop();
      } catch (error) {
        if (revision == selected.revision) selected.until = 0;
        debugPrint('SkyAudio effect $name: $error');
      }
    });
  }

  void _playSprintVoice() {
    // Draw uniformly from the other three clips, so consecutive sprints never
    // use the same line. A dedicated player keeps voices from overlapping.
    final clips = _sprintVoiceAssets;
    final draw = _random.nextInt(clips.length - 1);
    final previous = _lastSprintVoice;
    final index = previous != null && draw >= previous ? draw + 1 : draw;
    _lastSprintVoice = index;
    final voice = _sprintVoice;
    final revision = ++voice.revision;
    voice.pending = voice.pending.then((_) async {
      bool cancelled() =>
          _disposed || revision != voice.revision || !_settings.effects;
      if (cancelled()) return;
      try {
        await voice.player.stop();
        if (!voice.initialized) {
          await voice.player.setAudioContext(_effectContext);
          await voice.player.setPlayerMode(PlayerMode.lowLatency);
          await voice.player.setReleaseMode(ReleaseMode.stop);
          voice.initialized = true;
        }
        await voice.player.setSource(AssetSource(clips[index]));
        await voice.player.setVolume(.60);
        await voice.player.setPlaybackRate(_rate);
        if (cancelled()) return;
        await voice.player.resume();
        if (cancelled()) await voice.player.stop();
      } catch (error) {
        debugPrint('SkyAudio sprint voice: $error');
      }
    });
  }

  /// Says one recorded line ([CampaignVoices], [FlightVoices]) over the
  /// music, which ducks to [duck] under it until the line ends. A new line
  /// cuts off the one before, and [hush] stops it. Nothing plays while
  /// voices are turned off.
  void speak(String asset, {double duck = .35}) {
    if (_disposed || !_settings.voices) return;
    final voice = _speech;
    final revision = ++voice.revision;
    if (_speaking != null && _duckTo != duck) {
      _duckTo = duck;
      unawaited(_syncMusic());
    }
    _duckTo = duck;
    _duck(revision);
    voice.pending = voice.pending.then((_) async {
      bool cancelled() =>
          _disposed || revision != voice.revision || !_settings.voices;
      if (cancelled()) return;
      try {
        await voice.player.stop();
        if (!voice.initialized) {
          await voice.player.setAudioContext(_effectContext);
          await voice.player.setReleaseMode(ReleaseMode.stop);
          _speechEnds = voice.player.onPlayerComplete.listen((_) {
            if (_speaking == voice.revision) _duck(null);
          });
          voice.initialized = true;
        }
        await voice.player.setSource(AssetSource(asset));
        await voice.player.setVolume(1);
        if (cancelled()) return;
        await voice.player.resume();
        if (cancelled()) await voice.player.stop();
      } catch (error) {
        if (_speaking == revision) _duck(null);
        debugPrint('SkyAudio speech: $error');
      }
    });
  }

  /// Stops the line being said, and brings the music back up.
  Future<void> hush() {
    ++_flightLine;
    voices?.hush();
    if (_disposed) return Future.value();
    final voice = _speech;
    ++voice.revision;
    _duck(null);
    return voice.pending = voice.pending.then((_) async {
      try {
        await voice.player.stop();
      } catch (_) {}
    });
  }

  void _duck(int? speaking) {
    if (_speaking == speaking) return;
    final was = _speaking;
    _speaking = speaking;
    if ((was == null) != (speaking == null)) unawaited(_syncMusic());
  }

  Future<void> setRate(double rate) async {
    if (_disposed) return;
    _rate = rate.clamp(.5, 2);
    try {
      await _music.setPlaybackRate(_rate);
      for (final voice in _allEffects) {
        await voice.player.setPlaybackRate(_rate);
      }
    } catch (_) {}
  }

  Future<void> stopEffects() async {
    if (_disposed) return;
    _lastEffect.clear();
    final stops = <Future<void>>[hush()];
    for (final voice in _allEffects) {
      ++voice.revision;
      voice.until = 0;
      voice.pending = voice.pending.then((_) async {
        try {
          await voice.player.stop();
        } catch (_) {}
      });
      stops.add(voice.pending);
    }
    await Future.wait(stops);
  }

  Future<void> stop() async {
    _effectsSuspended = true;
    await Future.wait([
      configure(_settings, active: false, track: _scene),
      stopEffects(),
    ]);
  }

  Future<void> resumeMusic() => configure(_settings, track: _scene);

  Future<void> dispose() async {
    _disposed = true;
    ++_revision;
    await _configuration;
    await _music.dispose();
    await _speechEnds?.cancel();
    for (final p in [..._allEffects, _speech]) {
      ++p.revision;
      await p.pending;
      await p.player.dispose();
    }
    _clock.stop();
  }
}

class _EffectVoice {
  final player = AudioPlayer();
  Future<void> pending = Future.value();
  int revision = 0, until = 0, priority = 0;
  bool initialized = false;
}
