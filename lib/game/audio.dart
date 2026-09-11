import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import '../data/progress_repository.dart';

class SkyAudio {
  final _music = AudioPlayer();
  final _effects = [AudioPlayer(), AudioPlayer(), AudioPlayer()];
  GameSettings _settings = const GameSettings();
  int _next = 0;
  bool _playing = false, _disposed = false;
  Future<void> configure(GameSettings settings, {bool active = true}) async {
    _settings = settings;
    if (_disposed) return;
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
      /* Audio availability never blocks camera or game controls. */
    }
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

  Future<void> stop() async {
    if (!_disposed) {
      await _music.pause();
      _playing = false;
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    await _music.dispose();
    for (final p in _effects) {
      await p.dispose();
    }
  }
}
