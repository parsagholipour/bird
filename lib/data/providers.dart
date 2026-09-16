import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'progress_repository.dart';
import 'session_repository.dart';
import '../game/audio.dart';
import '../tracking/native_tracking_source.dart';
import '../domain/game_rules.dart';

final audioFactoryProvider = Provider<SkyAudio Function()>(
  (ref) => SkyAudio.new,
);
final trackingSourceFactoryProvider = Provider<NativeTrackingSource Function()>(
  (ref) => NativeTrackingSource.new,
);

final progressRepositoryProvider = Provider<ProgressRepository>((ref) {
  final repository = SqliteProgressRepository(ProgressDatabase.onDevice());
  ref.onDispose(repository.close);
  return repository;
});
final sessionRepositoryProvider = Provider<SessionRepository>(
  (ref) => SessionRepository(),
);
final sessionsProvider = FutureProvider<List<RunResult>>(
  (ref) => ref.watch(sessionRepositoryProvider).list(),
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
    state = AsyncData(await _repo.load());
  }

  Future<void> save(RunResult run) async {
    await _repo.saveRun(run);
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
    await refresh();
  }
}
