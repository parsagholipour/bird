import 'package:flutter/material.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

class FakeVideoPlatform extends VideoPlayerPlatform {
  Duration position = Duration.zero;
  bool playing = false;
  double speed = 1, volume = 0;
  bool mixedAudio = false;
  @override
  Future<void> setMixWithOthers(bool mixWithOthers) async {
    mixedAudio = mixWithOthers;
  }

  @override
  Future<void> init() async {}
  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async => 1;
  @override
  Stream<VideoEvent> videoEventsFor(int playerId) => Stream.value(
    VideoEvent(
      eventType: VideoEventType.initialized,
      duration: const Duration(seconds: 10),
      size: const Size(640, 480),
    ),
  );
  @override
  Future<void> dispose(int playerId) async {}
  @override
  Future<void> setLooping(int playerId, bool looping) async {}
  @override
  Future<void> play(int playerId) async {
    playing = true;
  }

  @override
  Future<void> pause(int playerId) async {
    playing = false;
  }

  @override
  Future<void> setVolume(int playerId, double volume) async {
    this.volume = volume;
  }

  @override
  Future<void> seekTo(int playerId, Duration position) async {
    this.position = position;
  }

  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {
    this.speed = speed;
  }

  @override
  Future<Duration> getPosition(int playerId) async => position;
  @override
  Widget buildViewWithOptions(VideoViewOptions options) => const ColoredBox(
    color: Colors.indigo,
    child: Center(child: Icon(Icons.person, color: Colors.white, size: 80)),
  );
}
