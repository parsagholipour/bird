import 'game_rules.dart';

/// A built level as it is kept: its [plan], which [revision] of it this
/// is, where it came from and whether its creator has cleared this
/// revision. Editing the route makes a new revision, whose bests start
/// afresh ([BuiltBest]).
class BuiltLevel {
  const BuiltLevel({
    required this.plan,
    this.revision = 1,
    this.origin = BuiltOrigin.created,
    this.from,
    this.clearedRevision,
    this.importedCleared = false,
    this.createdAt,
    this.updatedAt,
  });
  final BuiltPlan plan;
  final int revision;
  final BuiltOrigin origin;

  /// The template a remix was made from.
  final String? from;

  /// The revision the creator last flew to the finish line in a test flight
  /// (or for real), or null.
  final int? clearedRevision;

  /// Whether a share code said its creator had cleared the level.
  final bool importedCleared;
  final DateTime? createdAt, updatedAt;

  String get id => plan.id;
  bool get template => plan.id.startsWith('t-');

  /// Whether this revision has been flown to the finish line by whoever
  /// made it.
  bool get cleared => clearedRevision == revision || importedCleared;

  BuiltLevel copyWith({
    BuiltPlan? plan,
    int? revision,
    int? Function()? clearedRevision,
    DateTime? updatedAt,
  }) => BuiltLevel(
    plan: plan ?? this.plan,
    revision: revision ?? this.revision,
    origin: origin,
    from: from,
    clearedRevision: clearedRevision == null
        ? this.clearedRevision
        : clearedRevision(),
    importedCleared: importedCleared,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}

/// Where a built level came from.
enum BuiltOrigin { created, remixed, imported }

/// A built level's bests at one revision, folded from the flights saved
/// for it: each flight is rated against the marks as it is saved.
class BuiltBest {
  const BuiltBest({
    required this.level,
    required this.revision,
    this.stars = 0,
    this.collected = 0,
    this.score = 0,
    this.plays = 0,
    this.firstClearedAt,
    this.lastPlayedAt,
  });
  final String level;
  final int revision;

  /// Level stars (0–3), stars collected and score: the best of each.
  final int stars, collected, score;
  final int plays;
  final DateTime? firstClearedAt, lastPlayedAt;
  bool get cleared => stars > 0;
}

/// A built level's flight, as the play screen hands it to be saved: the
/// level's [plan] and [revision] as flown, and the flight itself.
typedef BuiltFlightRecord = ({BuiltPlan plan, int revision, RunResult run});

/// A built level flown: for real, or the creator's [test] flight, which
/// is practice and saved nowhere and may start [from] a place on the
/// route ([BuiltPlan.startingAt]).
class BuiltFlight {
  BuiltFlight(this.level, {this.test = false, this.from});
  final BuiltLevel level;
  final bool test;
  final int? from;
  late final BuiltPlan plan = from == null
      ? level.plan
      : level.plan.startingAt(from!);
  int get revision => level.revision;

  /// Whether a finished flight shows the whole level was flown: a test from
  /// the start (or a real flight).
  bool get whole => from == null;
}
