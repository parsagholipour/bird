import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'builder_providers.dart';
import 'play_games.dart';
import 'progress_repository.dart';
import 'session_repository.dart';
import '../game/audio.dart';
import '../game/flight_voices.dart';
import '../tracking/native_tracking_source.dart';
import '../domain/campaign.dart';
import '../domain/campaign_story.dart';
import '../domain/game_rules.dart';

final appClockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

final audioFactoryProvider = Provider<SkyAudio Function()>(
  (ref) => SkyAudio.new,
);
final trackingSourceFactoryProvider = Provider<NativeTrackingSource Function()>(
  (ref) => NativeTrackingSource.new,
);

final progressRepositoryProvider = Provider<ProgressRepository>((ref) {
  final repository = SqliteProgressRepository(
    ProgressDatabase.onDevice(),
    clock: ref.watch(appClockProvider),
  );
  ref.onDispose(repository.close);
  return repository;
});
final sessionRepositoryProvider = Provider<SessionRepository>(
  (ref) => SessionRepository(),
);
final sessionsProvider = FutureProvider<List<RunResult>>(
  (ref) => ref.watch(sessionRepositoryProvider).list(),
);
// Keep the current course when visiting the flock, passport or results.
final selectedCourseProvider = NotifierProvider<CourseSelection, FlightCourse>(
  CourseSelection.new,
);

class CourseSelection extends Notifier<FlightCourse> {
  @override
  FlightCourse build() => FlightCourse.starTrail;
  void select(FlightCourse course) => state = course;
}

/// What the characters have said in flight, loaded once and shared by every
/// flight so a new one never repeats the lines the last one used.
final flightVoiceMemoryProvider = FutureProvider<FlightVoiceMemory>(
  (ref) async => FlightVoiceMemory.decode(
    await ref.watch(progressRepositoryProvider).loadFlightVoices(),
  ),
);

final progressProvider =
    AsyncNotifierProvider<ProgressController, ProgressSnapshot>(
      ProgressController.new,
    );

class ProgressController extends AsyncNotifier<ProgressSnapshot> {
  ProgressRepository get _repo => ref.read(progressRepositoryProvider);
  @override
  Future<ProgressSnapshot> build() => _repo.load();
  Future<void> refresh() async {
    final progress = await _repo.load();
    if (ref.mounted) state = AsyncData(progress);
  }

  /// Saves a scored flight. A campaign flight also updates its level on
  /// the map ([ProgressSnapshot.campaign]).
  Future<void> save(RunResult run) async {
    await _repo.saveRun(run);
    await refresh();
  }

  Future<void> postcardSeen(CampaignChapter chapter) async {
    await _repo.markPostcardSeen(chapter);
    await refresh();
  }

  Future<void> storyWatched(StoryScene scene) async {
    await _repo.markStoryWatched(scene);
    await refresh();
  }

  Future<void> setting(SettingKey key, bool value) async {
    await _repo.setSetting(key, value);
    await refresh();
  }

  /// Equips an unlocked bird. A locked one has to be bought first
  /// ([unlockBird]).
  Future<void> equip(int bird) async {
    final unlocked = (await future).birdUnlocked(bird);
    if (!unlocked) throw StateError('${birdNames[bird]} is locked');
    await _repo.equipBird(bird);
    await refresh();
  }

  /// Saves a co-op flight's best, apart from the solo records.
  Future<void> saveCoop(CoopMode mode, RunResult run) async {
    await _repo.saveCoop(mode, run);
    await refresh();
  }

  Future<void> chooseCoop(int first, int second, CoopMode mode) async {
    await _repo.chooseCoop(first, second, mode);
    await refresh();
  }

  /// Unlocks [bird] with collected stars.
  Future<void> unlockBird(int bird) async {
    await _repo.unlockBird(bird);
    await refresh();
  }

  /// Buys [p]'s next level with collected stars.
  Future<void> buyUpgrade(PowerUp p) async {
    await _repo.buyUpgrade(p);
    await refresh();
  }

  /// Clears this phone's progress and, once this phone has synced with Play
  /// Games, the cloud logbook too (see [ProgressRepository.reset]).
  Future<void> reset() async {
    final cloud = await _repo.cloudSynced();
    await ref.read(sessionRepositoryProvider).reset();
    ref.invalidate(sessionsProvider);
    await _repo.reset(cloud: cloud);
    ref.invalidate(builtShelfProvider);
    ref.invalidate(builtLevelProvider);
    ref.invalidate(flightVoiceMemoryProvider);
    ref.read(selectedCourseProvider.notifier).select(FlightCourse.starTrail);
    await refresh();
    if (cloud) unawaited(ref.read(playGamesProvider.notifier).afterReset());
  }
}
