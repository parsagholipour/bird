import 'package:drift/drift.dart' show InsertMode;
import 'package:push_up_bird/data/progress_repository.dart';

/// Unlocks [birds] in [repo]'s save without spending stars, for tests that
/// dress a scene with Pip or Orbit. Players buy them on the crew screen.
Future<void> unlockBirds(
  SqliteProgressRepository repo, [
  Iterable<int> birds = const [0, 1, 2, 3],
]) => repo.db
    .into(repo.db.preferences)
    .insert(
      PreferencesCompanion.insert(key: 'birdUnlocks', value: birds.join(',')),
      mode: InsertMode.insertOrReplace,
    );
