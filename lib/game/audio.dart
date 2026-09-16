import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import '../data/progress_repository.dart';

class SkyAudio {
  final _music = AudioPlayer();
  final _effects = [AudioPlayer(), AudioPlayer(), AudioPlayer()];
  GameSettings _settings = const GameSettings();
  int _next = 0;
  bool _playing = false, _disposed = false;
  Future<void> _configuration = Future.value();
  int _revision = 0;
  Future<void> configure(GameSettings settings, {bool active = true}) {
    _settings = settings;
    final revision = ++_revision;
    // Rapid mute/play/pause changes must finish in their requested order.
    return _configuration = _configuration.then((_) async {
      if (_disposed || revision != _revision) return;
      try {
        if (settings.music && active) {
          if (!_playing) {
            await _music.setReleaseMode(ReleaseMode.loop);
            await _music.setVolume(.20);
            await _music.play(AssetSource('audio/sky_club.wav'));
            _playing = true;
          }
        } else {
          await _music.pause();
          _playing = false;
        }
      } catch (_) {
        // Audio availability never blocks camera or game controls.
      }
    });
  }

  void effect(String name) {
    if (_disposed || !_settings.effects) return;
    final player = _effects[_next++ % _effects.length];
    unawaited(
      player
          .play(AssetSource('audio/$name.wav'), volume: .45)
          .catchError((Object _) {}),
    );
  }

  Future<void> setRate(double rate) async {
    if (_disposed) return;
    try {
      await _music.setPlaybackRate(rate);
      for (final player in _effects) {
        await player.setPlaybackRate(rate);
      }
    } catch (_) {}
  }

  Future<void> stopEffects() async {
    if (_disposed) return;
    for (final player in _effects) {
      try {
        await player.stop();
      } catch (_) {}
    }
  }

  Future<void> stop() => configure(_settings, active: false);

  Future<void> dispose() async {
    _disposed = true;
    ++_revision;
    await _configuration;
    await _music.dispose();
    for (final p in _effects) {
      await p.dispose();
    }
  }
}
