import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  Future<void> equip(int bird) async {
    await _repo.equipBird(bird);
    await refresh();
  }

  Future<void> reset() async {
    await ref.read(sessionRepositoryProvider).reset();
    ref.invalidate(sessionsProvider);
    await _repo.reset();
    ref.invalidate(flightVoiceMemoryProvider);
    ref.read(selectedCourseProvider.notifier).select(FlightCourse.starTrail);
    await refresh();
  }
}
