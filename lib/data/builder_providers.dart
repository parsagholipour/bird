import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/built_level.dart';
import '../domain/built_templates.dart';
import '../domain/game_rules.dart';
import 'built_level_repository.dart';
import 'providers.dart';

/// The levels players build, kept in the progress save.
final builtStoreProvider = Provider<BuiltLevelStore>(
  (ref) => ref.watch(progressRepositoryProvider).builtLevels,
);

/// What the builder's shelf shows: the starter templates, the player's own
/// levels and every level's bests at the revision it is at now.
class BuiltShelf {
  const BuiltShelf({
    this.templates = const [],
    this.mine = const [],
    this.bests = const [],
  });
  final List<BuiltLevel> templates, mine;
  final List<BuiltBest> bests;

  /// [level]'s bests at its current revision, or null before its first
  /// scored flight.
  BuiltBest? best(BuiltLevel level) {
    for (final best in bests) {
      if (best.level == level.id && best.revision == level.revision) {
        return best;
      }
    }
    return null;
  }
}

final builtShelfProvider = FutureProvider<BuiltShelf>((ref) async {
  final store = ref.watch(builtStoreProvider);
  return BuiltShelf(
    templates: BuiltTemplates.all,
    mine: await store.levels(),
    bests: await store.bests(),
  );
});

/// One built level by id: a starter template or one of the player's.
final builtLevelProvider = FutureProvider.family<BuiltLevel?, String>((
  ref,
  id,
) async {
  final template = BuiltTemplates.byId(id);
  if (template != null) return template;
  if (!BuiltPlan.isBuiltId(id)) return null;
  return ref.watch(builtStoreProvider).level(id);
});

/// Saves what a built level's flight earned. A creator's test flight is
/// saved nowhere: a whole one that reaches the finish only marks the level
/// cleared. A real flight keeps its level's bests and its workout, which
/// the lifetime totals count.
Future<void> saveBuiltFlight(
  WidgetRef ref,
  BuiltFlight flight,
  RunResult run,
) async {
  final store = ref.read(builtStoreProvider);
  final level = flight.level;
  if (flight.test) {
    if (run.reason == EndReason.completed && flight.whole && !level.template) {
      await store.markCleared(level.id, level.revision);
    }
  } else {
    await store.saveFlight((
      plan: flight.plan,
      revision: flight.revision,
      run: run,
    ));
    await ref.read(progressProvider.notifier).refresh();
  }
  ref.invalidate(builtShelfProvider);
  ref.invalidate(builtLevelProvider(level.id));
}
