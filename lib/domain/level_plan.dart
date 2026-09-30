import 'dart:math' as math;

import 'game_rules.dart';

/// What a campaign set piece brings: a rush path of a fixed kind, one drawn
/// from the endless shuffled bag (only the banner says which), or a gale.
enum SetPieceKind {
  wildfire,
  skyfall,
  eruption,
  swarm,
  shuffled,
  gale;

  /// The rush path this piece runs, or null for a shuffled rush or a gale.
  RushPathKind? get rush => switch (this) {
    wildfire => RushPathKind.wildfire,
    skyfall => RushPathKind.skyfall,
    eruption => RushPathKind.eruption,
    swarm => RushPathKind.swarm,
    shuffled || gale => null,
  };
}

/// A rush path or gale at a route mark: [at] cruising seconds from the start
/// of the level or, [after] the previous set piece, from where it ends.
class SetPiece {
  const SetPiece(this.kind, {required this.at, this.after = false});
  final SetPieceKind kind;
  final double at;
  final bool after;
  bool get gale => kind == SetPieceKind.gale;
}

/// A level's star marks: a finished flight earns ★, ★★ for collecting at
/// least [two] stars and ★★★ for at least [three].
class StarMarks {
  const StarMarks(this.two, this.three);
  final int two, three;

  /// Level stars (0–3). A flight that did not finish earns none.
  int rate({required bool finished, required int stars}) => !finished
      ? 0
      : stars >= three
      ? 3
      : stars >= two
      ? 2
      : 1;

  /// How many of the two marks [stars] collected stars reach (0–2). A level
  /// chimes for these where an endless flight chimes for its wings.
  int reached(int stars) => (stars >= two ? 1 : 0) + (stars >= three ? 1 : 0);
}

/// A campaign level's rules (rules version 41): one region, a fixed route of
/// generated passages to a finish line or a boss, and the hazards the level
/// allows. Replays save the whole plan, so a level retuned later still
/// replays the way it was flown.
///
/// Its schedules follow the route clock rather than elapsed time, and every
/// passage and set piece sits at a fixed point on the route (see
/// [LevelRoute]), so every attempt lays the same route whether or not the
/// player sprints, on every phone.
class LevelPlan extends FlightPlan {
  const LevelPlan({
    required this.id,
    required this.region,
    required this.length,
    required this.start,
    required this.seed,
    required this.families,
    required this.marks,
    this.lineup = const [],
    this.cadence = 2,
    this.toughness = 0,
    this.shoot = true,
    this.sprint = true,
    this.panels = 0,
    this.pieces = const [],
    this.boss,
  });

  final String id;
  @override
  final WorldRegion region;

  /// Cruising seconds to the finish line, or the run-up before the boss.
  final double length;

  /// The endless-clock second the pace and openings start from.
  final double start;

  /// Seeds the passages. The boss and each set piece draw from their own
  /// randoms seeded from it, so how the player flew one cannot change the
  /// passages after it.
  final int seed;

  /// Obstacle families after the opening three garden gates.
  final List<ObstacleKind> families;

  /// The enemies in turn, one on every [cadence]th passage. Boss helpers
  /// come from the same lineup. Empty for a level without enemies.
  final List<EnemyKind> lineup;
  final int cadence;

  /// Small enemies gain health as if this many bosses had fallen.
  final int toughness;
  @override
  final bool shoot, sprint;

  /// Chance that an eligible wall carries a stone panel.
  final double panels;
  final List<SetPiece> pieces;

  /// The boss that ends the level, or null for a finish line.
  final BossKind? boss;
  final StarMarks marks;

  @override
  String get levelId => id;

  @override
  double paceClock({required double elapsed, required double route}) =>
      start + route;
  @override
  double scheduleClock({required double elapsed, required double route}) =>
      route;

  @override
  FamilyBag? familyBag({
    required int passage,
    required double elapsed,
    required int rulesVersion,
  }) => passage <= 3 ? null : (tier: 0, kinds: families);

  @override
  double panelChance(int bossesDefeated) => panels;

  /// A [cadence] of 4 shows the enemies on every fourth passage, from the
  /// third; 2 matches endless, from the first.
  @override
  int? enemyIndex(int passage) =>
      lineup.isEmpty || passage % cadence != cadence - 1
      ? null
      : passage ~/ cadence;

  @override
  int enemyAppearance(int index, {required bool bossHelper}) =>
      lineup[index % lineup.length].index;

  @override
  int enemyToughness(int bossesDefeated) => toughness;

  @override
  double get firstBossAt => boss == null ? double.infinity : length;
  @override
  double get bossInterval => double.infinity;

  /// The chapter's boss, with the health of its first endless encounter
  /// and its debut fight.
  @override
  BossEncounter bossEncounter(int bossesDefeated, int rulesVersion) =>
      (kind: boss!, number: boss!.index + 1, debut: true);

  @override
  bool get heartPickups => false;

  /// Rush paths and gales are set pieces on the route instead.
  @override
  double get firstRushAt => double.infinity;
  @override
  double get rushAfterBoss => double.infinity;
  @override
  double get rushAfterGale => double.infinity;
  @override
  double? galeAfter(BossKind kind) => null;

  /// Not where the bird happens to be, so the route stays the same.
  @override
  double resumeCenter(double birdY) => .5;

  /// Every attempt draws the same passages, whatever random it is given.
  @override
  math.Random courseRandom(math.Random? given) => math.Random(seed);

  @override
  math.Random setPieceRandom(int piece, math.Random flight) =>
      math.Random((seed * 7919 + (piece + 1) * 104729) & 0x3fffffff);

  @override
  LevelRoute route({required double baseSpeed, required double interval}) =>
      LevelRoute.lay(this, baseSpeed: baseSpeed, interval: interval);

  @override
  int rate({required bool finished, required int stars}) =>
      marks.rate(finished: finished, stars: stars);

  Map<String, Object?> toJson() => {
    'id': id,
    'region': region.name,
    'length': length,
    'start': start,
    'seed': seed,
    'families': [for (final kind in families) kind.name],
    'lineup': [for (final kind in lineup) kind.name],
    'cadence': cadence,
    'toughness': toughness,
    'shoot': shoot,
    'sprint': sprint,
    'panels': panels,
    'pieces': [
      for (final piece in pieces)
        {'kind': piece.kind.name, 'at': piece.at, 'after': piece.after},
    ],
    'boss': boss?.name,
    'marks': [marks.two, marks.three],
  };

  /// Reads a plan saved by [toJson]. Anything malformed throws a
  /// [FormatException], like the rest of a replay tape.
  factory LevelPlan.fromJson(Map<String, dynamic> json) {
    Never invalid() => throw const FormatException('Invalid level plan');
    T named<T extends Enum>(List<T> values, Object? name) {
      for (final value in values) {
        if (value.name == name) return value;
      }
      invalid();
    }

    double number(Object? value) =>
        value is num && value.isFinite ? value.toDouble() : invalid();
    int whole(Object? value) => value is int ? value : invalid();
    bool flag(Object? value) => value is bool ? value : invalid();
    List<Object?> list(Object? value) => value is List ? value : invalid();

    final id = json['id'];
    final boss = json['boss'];
    final marks = list(json['marks']);
    if (id is! String || marks.length != 2) invalid();
    final plan = LevelPlan(
      id: id,
      region: named(WorldRegion.values, json['region']),
      length: number(json['length']),
      start: number(json['start']),
      seed: whole(json['seed']),
      families: [
        for (final name in list(json['families']))
          named(ObstacleKind.values, name),
      ],
      lineup: [
        for (final name in list(json['lineup'])) named(EnemyKind.values, name),
      ],
      cadence: whole(json['cadence']),
      toughness: whole(json['toughness']),
      shoot: flag(json['shoot']),
      sprint: flag(json['sprint']),
      panels: number(json['panels']),
      pieces: [
        for (final piece in list(json['pieces']))
          if (piece is Map)
            SetPiece(
              named(SetPieceKind.values, piece['kind']),
              at: number(piece['at']),
              after: flag(piece['after']),
            )
          else
            invalid(),
      ],
      boss: boss == null ? null : named(BossKind.values, boss),
      marks: StarMarks(whole(marks[0]), whole(marks[1])),
    );
    if (plan.problem case final _?) invalid();
    return plan;
  }

  /// Why this plan cannot be flown, or null when it can.
  String? get problem {
    if (id.isEmpty || id.length > 16) return 'id';
    if (!(length >= 10 && length <= 600)) return 'length';
    if (!(start >= 0 && start <= 3600)) return 'start';
    if (families.isEmpty || families.toSet().length != families.length) {
      return 'families';
    }
    if (cadence < 1 || cadence > 8) return 'cadence';
    if (toughness < 0 || toughness > 4) return 'toughness';
    if (!(panels >= 0 && panels <= 1)) return 'panels';
    for (final piece in pieces) {
      if (!(piece.at >= 0 && piece.at <= length)) return 'pieces';
    }
    if (boss != null && (pieces.isNotEmpty || lineup.isEmpty)) return 'boss';
    if (marks.two < 1 || marks.three < marks.two) return 'marks';
    return null;
  }
}

/// A level's route, fixed before the flight begins: where every ordinary
/// passage and set piece sits and where the goal is, as world positions
/// (course distance flown plus a screen x, so the bird meets a point once
/// `distance + FlightSimulation.birdX` reaches it).
///
/// Passages arrive every `interval` cruising seconds. The route clock and
/// the course both speed up together in a sprint, so a sprinting bird meets
/// the same passages sooner; it never skips or adds one. The pace follows
/// the endless formula from the level's start, so the distance a cruising
/// bird covers is its closed-form integral.
class LevelRoute {
  LevelRoute._({
    required this.passages,
    required this.due,
    required this.pieces,
    required this.goal,
    required this.boss,
  });

  factory LevelRoute.lay(
    LevelPlan plan, {
    required double baseSpeed,
    required double interval,
  }) {
    const birdX = FlightSimulation.birdX;
    final a = plan.start;
    // Course distance a cruising bird covers in r route seconds.
    double covered(double r) =>
        baseSpeed *
        (1.65 * r -
            .65 * 240 * (math.exp(-a / 240) - math.exp(-(a + r) / 240)));
    // Newton's method from above: the pace only rises, so it converges.
    double routeAt(double distance) {
      var r = distance / (baseSpeed * FlightPlan.pace(a));
      for (var i = 0; i < 60; i++) {
        final step =
            (covered(r) - distance) / (baseSpeed * FlightPlan.pace(a + r));
        r -= step;
        if (step.abs() < 1e-12) break;
      }
      return r;
    }

    double world(double r) => birdX + covered(r);
    final width = plan.families.fold(ObstacleKind.garden.width, (w, kind) {
      return math.max(w, kind.width);
    });
    final passages = <double>[];
    var next = routeAt(firstPassage - birdX);
    void layUntil(double limit, double clearance) {
      for (var x = world(next); x + width + clearance <= limit;) {
        passages.add(x);
        next += interval;
        x = world(next);
      }
    }

    final pieces = <RoutePiece>[];
    var ended = 0.0;
    for (final (i, piece) in plan.pieces.indexed) {
      final at = piece.after ? ended + piece.at : piece.at;
      final start = world(at);
      layUntil(start, piece.gale ? Gale.clearance : Rush.clearance);
      final double end;
      if (piece.gale) {
        ended = at + galeRoute;
        end = world(ended);
        // Passages resume beyond the entry edge at the moment a cruising
        // bird weathers the gale, with room for sprints during it.
        next = routeAt(end - 2 * birdX + firstPassage + galeMargin);
      } else {
        end = start + rushLength;
        ended = routeAt(end - birdX);
        next = routeAt(end + Rush.exitClearance - birdX);
      }
      pieces.add(RoutePiece(piece, number: i + 1, start: start, end: end));
    }
    final goal = world(plan.length);
    layUntil(goal, FinishLine.clearance);
    return LevelRoute._(
      passages: List.unmodifiable(passages),
      due: List.unmodifiable([
        for (final x in passages) math.max(0.0, routeAt(x - firstPassage)),
      ]),
      pieces: List.unmodifiable(pieces),
      goal: goal,
      boss: plan.boss != null,
    );
  }

  /// World x of each ordinary passage's leading edge, in the order laid.
  final List<double> passages;

  /// The route second each passage comes within reach of the widest screen
  /// ([firstPassage] away), which sets its opening and the phase of its
  /// motion.
  final List<double> due;
  final List<RoutePiece> pieces;

  /// Where the finish line sits or, when [boss], where the boss arrives.
  final double goal;
  final bool boss;

  /// Stars laid along the route: three before every passage and every beat
  /// of a rush path. A gale lays none.
  int get stars =>
      3 * passages.length +
      3 * Rush.beats * pieces.where((p) => !p.piece.gale).length;

  /// The first passage is laid past the widest landscape viewport (2.4),
  /// with room for the enemy that leads it, so it is off screen on every
  /// phone when the flight starts.
  static const firstPassage = 2.4 + .7;

  /// A rush path's length, from its start to the bird's escape past the
  /// final barrier.
  static const rushLength =
      (Rush.beats - 1) * Rush.beatLength +
      Rush.barrierAt +
      Rush.barrierWidth +
      FlightSimulation.birdRadius;

  /// Route seconds a cruising bird flies while a gale blows: its tailwind
  /// rises over [Gale.riseSeconds] and then holds.
  static const galeRoute =
      Gale.seconds +
      (Gale.peakBoost - 1) * (Gale.seconds - Gale.riseSeconds / 2);

  /// Extra room after a gale. A sprint in the tailwind carries the bird at
  /// most this much further than cruising before the wind drops.
  static const galeMargin = .8;
}

/// A set piece placed on the route. [start] is where the bird meets it and
/// [end] where a cruising bird leaves it (escapes a rush path or weathers a
/// gale). [number] counts the level's pieces from 1 and seeds its random.
class RoutePiece {
  const RoutePiece(
    this.piece, {
    required this.number,
    required this.start,
    required this.end,
  });
  final SetPiece piece;
  final int number;
  final double start, end;
}
