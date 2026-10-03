/// Level ids that moved, and everything named after them.
///
/// Rules version 50 gave Egypt its guardian: Neferhoo's level became 2-6
/// "Return to Sender", and Ancient Arabia's three levels moved up by one
/// (Lantern Bazaar 2-6 → 2-7, The Long Caravan 2-7 → 2-8, Spitter King 2-8 →
/// 2-9). Their plans kept their seeds, so their routes did not change; only
/// the id string did. A save made before the move is renamed once, when the
/// database is first opened by a build that knows the new ids
/// (`ProgressDatabase.renumberLevels`): level records and flights,
/// highest id first, and the watched story scenes named by level, in one
/// transaction. A saved replay keeps its whole plan and replays as it was
/// flown; its library title is looked up through [level].
abstract final class CampaignIds {
  /// The id scheme a save is in: 1 before Egypt's guardian, 2 after.
  static const scheme = 2;

  /// The ids that moved, old to new, in the order a rename must apply them
  /// (highest first, so no new id exists before its old owner has left it).
  static const renumbered = <String, String>{
    '2-8': '2-9',
    '2-7': '2-8',
    '2-6': '2-7',
  };

  /// The id a level saved under the old scheme has now.
  static String level(String saved) => renumbered[saved] ?? saved;

  /// The story scenes named by a moved level (`before-2-6` was Arabia's
  /// arrival, `before-2-8` the Spitter King's lair), old to new, highest
  /// first. The new `before-2-6` and `last-2-6` are Neferhoo's.
  static const scenes = <String, String>{
    'before-2-8': 'before-2-9',
    'before-2-6': 'before-2-7',
  };

  /// The id a scene watched under the old scheme has now.
  static String scene(String saved) => scenes[saved] ?? saved;

  /// A voice clip named by a moved level, as the old scheme named it: a
  /// bird's cargo line (`pip-cargo-2-6-01`), a lair scene's line
  /// (`before-2-8-3-pip`) or a thank-you (`thanks-2-7`). Every other name
  /// is its own. The clip files were renamed with their levels (no take was
  /// recorded again); this is what the flight voices' memory of what was
  /// said is renamed with.
  static String clip(String name) {
    for (final MapEntry(key: from, value: to) in renumbered.entries) {
      for (final (before, after) in [
        ('-cargo-$from-', '-cargo-$to-'),
        ('before-$from-', 'before-$to-'),
      ]) {
        final at = name.indexOf(before);
        if (at >= 0 && (before.startsWith('before') ? at == 0 : at > 0)) {
          return name.replaceFirst(before, after);
        }
      }
      if (name == 'thanks-$from') return 'thanks-$to';
    }
    return name;
  }
}
