import 'dart:convert';
import 'dart:math' as math;

import 'game_rules.dart';
import 'tracking.dart';

/// How fast a built level's course scrolls, as a factor on its mode's
/// cruising speed. The pace never ramps within a level, so a position on
/// the route is a fixed time from the start.
enum BuiltPace {
  relaxed(1.0),
  steady(1.15),
  brisk(1.3);

  const BuiltPace(this.factor);
  final double factor;
}

/// One hand-placed thing on a built level's route. Positions are integer
/// thousandths of the viewport height (the sky is 1000 tall): [x] is the
/// world position where the bird meets it, as for [LevelRoute.passages],
/// the leading edge of a gate and the centre of anything else.
sealed class BuiltItem {
  const BuiltItem({required this.x});
  final int x;

  /// Sort rank within one [x]: gates, stars, trios, hearts, enemies.
  int get rank;

  /// The JSON type tag.
  String get tag;
  int get y;
  double get worldX => x / BuiltPlan.unit;

  /// Where the item begins and ends along the route.
  int get left => x;
  int get right => x;

  BuiltItem movedTo({int? x, int? y});
  Map<String, Object?> toJson();

  static int compare(BuiltItem a, BuiltItem b) {
    if (a.x != b.x) return a.x.compareTo(b.x);
    if (a.rank != b.rank) return a.rank.compareTo(b.rank);
    return a.y.compareTo(b.y);
  }
}

/// A gate: an obstacle of [kind] whose opening of [gap] is centred on [y].
/// A moving family swings by [amp] over a [cycle] of route distance, and
/// is at [phase] degrees of its swing when the bird reaches its middle. A
/// garden gate on a Tap & Fly level may carry a stone [door].
class BuiltGate extends BuiltItem {
  const BuiltGate({
    required super.x,
    required this.y,
    required this.gap,
    this.kind = ObstacleKind.garden,
    this.amp = 0,
    this.cycle = defaultCycle,
    this.phase = 0,
    this.look = 0,
    this.door = false,
  });
  final ObstacleKind kind;
  @override
  final int y;
  final int gap, amp, cycle, phase, look;
  final bool door;

  static const defaultCycle = 2500, minCycle = 1000, maxCycle = 6000;
  static const looks = 3;

  @override
  int get rank => 0;
  @override
  String get tag => 'g';
  @override
  int get right => x + (kind.width * BuiltPlan.unit).round();
  bool get moving => amp > 0;

  BuiltGate copyWith({
    int? x,
    int? y,
    int? gap,
    ObstacleKind? kind,
    int? amp,
    int? cycle,
    int? phase,
    int? look,
    bool? door,
  }) => BuiltGate(
    x: x ?? this.x,
    y: y ?? this.y,
    gap: gap ?? this.gap,
    kind: kind ?? this.kind,
    amp: amp ?? this.amp,
    cycle: cycle ?? this.cycle,
    phase: phase ?? this.phase,
    look: look ?? this.look,
    door: door ?? this.door,
  );

  @override
  BuiltGate movedTo({int? x, int? y}) => copyWith(x: x, y: y);

  @override
  Map<String, Object?> toJson() => {
    't': tag,
    'x': x,
    'y': y,
    'gap': gap,
    'k': kind.name,
    if (amp != 0) 'amp': amp,
    if (cycle != defaultCycle) 'cyc': cycle,
    if (phase != 0) 'ph': phase,
    if (look != 0) 'look': look,
    if (door) 'door': true,
  };
}

/// A single star at ([x], [y]).
class BuiltStar extends BuiltItem {
  const BuiltStar({required super.x, required this.y});
  @override
  final int y;
  @override
  int get rank => 1;
  @override
  String get tag => 's';
  @override
  BuiltStar movedTo({int? x, int? y}) =>
      BuiltStar(x: x ?? this.x, y: y ?? this.y);
  @override
  Map<String, Object?> toJson() => {'t': tag, 'x': x, 'y': y};
}

/// Three stars in a row centred on ([x], [y]), [spacing] apart: collecting
/// all three pays the trio bonus ([StarTrio.bonus]).
class BuiltTrio extends BuiltItem {
  const BuiltTrio({required super.x, required this.y});
  @override
  final int y;
  static const spacing = 170;
  @override
  int get rank => 2;
  @override
  String get tag => '3';
  @override
  int get left => x - spacing;
  @override
  int get right => x + spacing;
  @override
  BuiltTrio movedTo({int? x, int? y}) =>
      BuiltTrio(x: x ?? this.x, y: y ?? this.y);
  @override
  Map<String, Object?> toJson() => {'t': tag, 'x': x, 'y': y};
}

/// A heart pickup at ([x], [y]): one heart back, up to the flight's
/// maximum.
class BuiltHeart extends BuiltItem {
  const BuiltHeart({required super.x, required this.y});
  @override
  final int y;
  @override
  int get rank => 3;
  @override
  String get tag => 'h';
  @override
  BuiltHeart movedTo({int? x, int? y}) =>
      BuiltHeart(x: x ?? this.x, y: y ?? this.y);
  @override
  Map<String, Object?> toJson() => {'t': tag, 'x': x, 'y': y};
}

/// A small enemy of [kind] hovering at ([x], [y]). Tap & Fly only.
class BuiltEnemy extends BuiltItem {
  const BuiltEnemy({required super.x, required this.y, required this.kind});
  @override
  final int y;
  final EnemyKind kind;
  @override
  int get rank => 4;
  @override
  String get tag => 'e';
  @override
  BuiltEnemy movedTo({int? x, int? y}) =>
      BuiltEnemy(x: x ?? this.x, y: y ?? this.y, kind: kind);
  @override
  Map<String, Object?> toJson() => {'t': tag, 'x': x, 'y': y, 'k': kind.name};
}

/// A level a player built by hand (rules version 64): every gate, star,
/// heart and enemy at its own place on one region's route, and the
/// [finish] line. Unlike a campaign [LevelPlan] nothing is drawn from a
/// random: the simulation lays exactly the [items], in order, as they come
/// within reach (`built_rules.dart`). Replays and share codes carry the
/// whole plan as [toJson].
///
/// The course scrolls at the [mode]'s cruising speed times the [pace],
/// without the endless ramp. On a push-up or squat level it slows for a
/// player whose calibrated movement is slower than [referenceCycle]
/// ([speedScale]), so every player meets the same gates in the same order
/// and does the same workout. With a [boss] (Tap & Fly only) the line is
/// the boss's mark instead: the boss arrives when the bird reaches it, and
/// the finish line is laid after its defeat, as on a campaign boss level.
class BuiltPlan extends FlightPlan {
  BuiltPlan({
    required this.id,
    required this.name,
    required this.mode,
    required this.region,
    required this.finish,
    required this.marks,
    required List<BuiltItem> items,
    this.pace = BuiltPace.relaxed,
    this.boss,
    this._shoot = true,
    this._sprint = true,
  }) : items = List.unmodifiable(
         List<BuiltItem>.of(items)..sort(BuiltItem.compare),
       );

  /// The JSON format; a share code or tape of a newer one is refused.
  static const formatVersion = 1;

  /// Positions are thousandths of the viewport height.
  static const unit = 1000;

  /// Nothing may sit nearer the start than this: past the widest landscape
  /// viewport (2.4), so nothing is on screen when the flight begins.
  static const firstX = 2400;
  static const minFinish = 6000, maxFinish = 300000, maxItems = 400;
  static const maxName = 24;

  /// The calibrated cycle a push-up or squat level is designed for, and
  /// the slowest course it slows to for a slower player.
  static const referenceCycle = 3.0, slowestTempo = .35;

  /// Nearest a gate's trailing edge may come to the finish line: the
  /// campaign's [FinishLine.clearance].
  static final finishClearance = (FinishLine.clearance * unit).round();

  /// A height-controlled bird (push-ups, squats) flies one of two lanes:
  /// gates are centred on [lowLane] or [highLane] as in endless, and aim it
  /// at the calibrated endpoint beyond ([laneTarget]).
  static const highLane = 250, lowLane = 750;

  final String id, name;
  final PlayMode mode;
  @override
  final WorldRegion region;
  final BuiltPace pace;

  /// The finish line's world x or, with a [boss], the boss's mark.
  final int finish;
  final StarMarks marks;
  final BossKind? boss;

  /// In canonical order ([BuiltItem.compare]).
  final List<BuiltItem> items;
  final bool _shoot, _sprint;

  double get finishX => finish / unit;
  bool get touch => mode == PlayMode.touch;

  /// Whether the Shoot and Sprint controls exist. Only Tap & Fly has them.
  @override
  bool get shoot => touch && _shoot;
  @override
  bool get sprint => touch && _sprint;

  Iterable<BuiltGate> get gates => items.whereType<BuiltGate>();

  /// Every star the route lays: singles and three per trio.
  int get totalStars => items.fold(
    0,
    (sum, item) =>
        sum +
        switch (item) {
          BuiltStar() => 1,
          BuiltTrio() => 3,
          _ => 0,
        },
  );

  /// The ★★ and ★★★ marks a new level starts with: about 55 % and 80 % of
  /// its stars, as the campaign's marks.
  static StarMarks suggestMarks(int stars) {
    if (stars < 1) return const StarMarks(1, 1);
    final two = math.max(1, (stars * .55).round());
    return StarMarks(two, math.max(two, (stars * .8).round()));
  }

  /// The aiming mark of a gate centred on [y] for a bird of [mode]: the
  /// calibrated endpoint beyond a height lane, else the opening's centre.
  static double laneTarget(PlayMode mode, double y) =>
      mode.controlsHeight ? (y < .5 ? .15 : .85) : y;

  /// The smallest opening (thousandths) a gate of [amp] centred on [y]
  /// may have: the simulation's own safe lane, which leaves the bird room
  /// at the tightest point of the swing.
  static int safeGap(PlayMode mode, int y, int amp) {
    final centre = y / unit;
    final aim = laneTarget(mode, centre);
    return (2 *
            ((centre - aim).abs() +
                amp / unit +
                FlightSimulation.birdRadius +
                .025) *
            unit)
        .ceil();
  }

  static int maxGap(PlayMode mode) => 600;

  /// How far a moving gate of this [mode] may swing.
  static int maxAmp(PlayMode mode) => switch (mode) {
    PlayMode.touch => 100,
    PlayMode.jump => 80,
    PlayMode.pushUp || PlayMode.squat => 35,
  };

  /// The heights a free-flying (Tap & Fly, Jump) gate may be centred on.
  static const minGateY = 200, maxGateY = 800;

  /// Anything else stays inside the sky.
  static const minItemY = 50, maxItemY = 950;

  // -------------------------------------------------------------------
  // FlightPlan: everything the route does not hand-place is switched off.

  @override
  String get levelId => id;
  @override
  int get minRulesVersion => FlightSimulation.builtLevelsRulesVersion;

  /// Only the level's own mode flies it.
  @override
  bool flies(PlayMode mode) => mode == this.mode;

  /// The [pace], and on a push-up or squat level the player's tempo: a
  /// player slower than [referenceCycle] meets the same route at a slower
  /// course, by the ratio of the passage spacing endless would give them
  /// ([PushUpFlightMode.intervalFor]), never faster than designed.
  @override
  double speedScale(GameMode rules) => pace.factor * tempo(rules);

  static double tempo(GameMode rules) => rules is PushUpFlightMode
      ? ((referenceCycle / 2 + .65) / (rules.cycleSeconds / 2 + .65)).clamp(
          slowestTempo,
          1.0,
        )
      : 1.0;

  /// The pace never ramps.
  @override
  double paceClock({required double elapsed, required double route}) => 0;
  @override
  double scheduleClock({required double elapsed, required double route}) =>
      route;
  @override
  FamilyBag? familyBag({
    required int passage,
    required double elapsed,
    required int rulesVersion,
  }) => null;
  @override
  double panelChance(int bossesDefeated) => 0;
  @override
  int? enemyIndex(int passage) => null;

  /// A boss's helpers come from the endless lineup.
  @override
  int enemyAppearance(int index, {required bool bossHelper}) =>
      const EndlessPlan().enemyAppearance(index, bossHelper: bossHelper);
  @override
  int enemyToughness(int bossesDefeated) => 0;

  /// The boss is called by the route when the bird reaches its mark.
  @override
  double get firstBossAt => double.infinity;
  @override
  double get bossInterval => double.infinity;
  @override
  BossEncounter bossEncounter(int bossesDefeated, int rulesVersion) =>
      (kind: boss!, number: boss!.index + 1, debut: true);

  /// Hearts are placed, never earned.
  @override
  bool get heartPickups => false;
  @override
  double get firstRushAt => double.infinity;
  @override
  double get rushAfterBoss => double.infinity;
  @override
  double get rushAfterGale => double.infinity;
  @override
  double? galeAfter(BossKind kind) => null;
  @override
  double resumeCenter(double birdY) => .5;

  /// Nothing on the route draws from a random; a boss's attacks do, from
  /// one seeded by the level, so every attempt meets the same boss.
  @override
  math.Random courseRandom(math.Random? given) => math.Random(_seed);
  @override
  math.Random setPieceRandom(int piece, math.Random flight) =>
      math.Random((_seed * 7919 + (piece + 1) * 104729) & 0x3fffffff);
  int get _seed => int.parse(fingerprint, radix: 16) & 0x3fffffff;

  @override
  LevelRoute route({required double baseSpeed, required double interval}) =>
      LevelRoute.built(goal: finishX, boss: boss != null);

  @override
  int rate({required bool finished, required int stars}) =>
      marks.rate(finished: finished, stars: stars);

  // -------------------------------------------------------------------

  BuiltPlan copyWith({
    String? id,
    String? name,
    PlayMode? mode,
    WorldRegion? region,
    BuiltPace? pace,
    int? finish,
    StarMarks? marks,
    List<BuiltItem>? items,
    BossKind? Function()? boss,
    bool? shoot,
    bool? sprint,
  }) => BuiltPlan(
    id: id ?? this.id,
    name: name ?? this.name,
    mode: mode ?? this.mode,
    region: region ?? this.region,
    pace: pace ?? this.pace,
    finish: finish ?? this.finish,
    marks: marks ?? this.marks,
    items: items ?? this.items,
    boss: boss == null ? this.boss : boss(),
    shoot: shoot ?? _shoot,
    sprint: sprint ?? _sprint,
  );

  /// The level from route position [from] on, for a creator's test flight
  /// "from here": what lies before it is dropped and the rest moves up to
  /// [firstX]. A moving gate is defined by its phase on arrival, so it
  /// meets the bird the same way. The marks shrink to the stars left.
  BuiltPlan startingAt(int from) {
    final shift = firstX - from;
    final kept = [
      for (final item in items)
        if (item.left >= from) item.movedTo(x: item.x + shift),
    ];
    final left = kept.fold(
      0,
      (sum, item) =>
          sum +
          switch (item) {
            BuiltStar() => 1,
            BuiltTrio() => 3,
            _ => 0,
          },
    );
    final two = math.min(marks.two, math.max(1, left));
    return copyWith(
      items: kept,
      finish: math.max(finish + shift, firstX + unit),
      marks: StarMarks(two, math.max(two, math.min(marks.three, left))),
    );
  }

  /// The route's content without its [id] and [name], as written by
  /// [toJson]: what makes two levels the same level.
  Map<String, Object?> contentJson() => {
    'v': formatVersion,
    'mode': mode.name,
    'region': region.name,
    'pace': pace.name,
    'finish': finish,
    'marks': [marks.two, marks.three],
    if (boss != null) 'boss': boss!.name,
    if (!_shoot) 'shoot': false,
    if (!_sprint) 'sprint': false,
    'items': [for (final item in items) item.toJson()],
  };

  Map<String, Object?> toJson() => {'id': id, 'name': name, ...contentJson()};

  /// FNV-1a (32 bits) of [contentJson], as 8 hex digits.
  late final String fingerprint = () {
    var hash = 0x811c9dc5;
    for (final byte in utf8.encode(jsonEncode(contentJson()))) {
      hash = ((hash ^ byte) * 0x01000193) & 0xffffffff;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }();

  /// Reads a plan saved by [toJson]. Anything malformed, or (when
  /// [checked]) a plan that cannot be flown ([problem]), throws a
  /// [FormatException]. A creator's draft is read unchecked: it may be
  /// half built.
  factory BuiltPlan.fromJson(Map<String, dynamic> json, {bool checked = true}) {
    Never invalid() => throw const FormatException('Invalid built level');
    T named<T extends Enum>(List<T> values, Object? name) {
      for (final value in values) {
        if (value.name == name) return value;
      }
      invalid();
    }

    int whole(Object? value) => value is int ? value : invalid();
    String text(Object? value) => value is String ? value : invalid();
    List<Object?> list(Object? value) => value is List ? value : invalid();
    bool flag(String key) => switch (json[key]) {
      null => true,
      false => false,
      _ => invalid(),
    };

    if (json['v'] != formatVersion) invalid();
    final marks = list(json['marks']);
    if (marks.length != 2) invalid();
    final items = <BuiltItem>[];
    for (final raw in list(json['items'])) {
      if (raw is! Map) invalid();
      final x = whole(raw['x']), y = whole(raw['y']);
      items.add(switch (raw['t']) {
        'g' => BuiltGate(
          x: x,
          y: y,
          gap: whole(raw['gap']),
          kind: named(ObstacleKind.values, raw['k']),
          amp: raw.containsKey('amp') ? whole(raw['amp']) : 0,
          cycle: raw.containsKey('cyc')
              ? whole(raw['cyc'])
              : BuiltGate.defaultCycle,
          phase: raw.containsKey('ph') ? whole(raw['ph']) : 0,
          look: raw.containsKey('look') ? whole(raw['look']) : 0,
          door: switch (raw['door']) {
            null => false,
            true => true,
            _ => invalid(),
          },
        ),
        's' => BuiltStar(x: x, y: y),
        '3' => BuiltTrio(x: x, y: y),
        'h' => BuiltHeart(x: x, y: y),
        'e' => BuiltEnemy(x: x, y: y, kind: named(EnemyKind.values, raw['k'])),
        _ => invalid(),
      });
    }
    final boss = json['boss'];
    final plan = BuiltPlan(
      id: text(json['id']),
      name: text(json['name']),
      mode: named(PlayMode.values, json['mode']),
      region: named(WorldRegion.values, json['region']),
      pace: named(BuiltPace.values, json['pace']),
      finish: whole(json['finish']),
      marks: StarMarks(whole(marks[0]), whole(marks[1])),
      items: items,
      boss: boss == null ? null : named(BossKind.values, boss),
      shoot: flag('shoot'),
      sprint: flag('sprint'),
    );
    if (checked && plan.problem != null) invalid();
    return plan;
  }

  static final _userId = RegExp(r'^u-[a-z0-9]{10}$');
  static final _templateId = RegExp(r'^t-[a-z0-9-]{1,14}$');

  /// Whether [id] names a built level: a player's (`u-…`) or a starter
  /// template (`t-…`). Never a campaign level's.
  static bool isBuiltId(String id) =>
      _userId.hasMatch(id) || _templateId.hasMatch(id);

  /// A fresh id for a player's level.
  static String newId(math.Random random) {
    const letters = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return 'u-${String.fromCharCodes([for (var i = 0; i < 10; i++) letters.codeUnitAt(random.nextInt(letters.length))])}';
  }

  /// A name a level may carry: 1–[maxName] characters, no control
  /// characters, no leading or trailing space.
  static bool validName(String name) =>
      name.isNotEmpty &&
      name.length <= maxName &&
      name.trim() == name &&
      !name.runes.any((r) => r < 0x20 || r == 0x7f);

  /// Why this plan cannot be flown, or null when it can. The editor shows
  /// softer advice ([BuiltReach]) on top.
  String? get problem {
    if (!isBuiltId(id)) return 'id';
    if (!validName(name)) return 'name';
    if (finish < minFinish || finish > maxFinish) return 'finish';
    if (items.length > maxItems) return 'items';
    if (boss != null && (!touch || boss!.campaignOnly)) return 'boss';
    BuiltGate? previous;
    for (final item in items) {
      if (item.left < firstX) return 'start';
      final y = item.y;
      switch (item) {
        case BuiltGate gate:
          if (gate.right + finishClearance > finish) return 'finish';
          if (previous != null && previous.right > gate.x) return 'overlap';
          previous = gate;
          if (mode.controlsHeight
              ? y != highLane && y != lowLane
              : y < minGateY || y > maxGateY) {
            return 'height';
          }
          if (gate.amp < 0 ||
              gate.amp > maxAmp(mode) ||
              (gate.kind == ObstacleKind.garden && gate.amp != 0)) {
            return 'motion';
          }
          if (gate.cycle < BuiltGate.minCycle ||
              gate.cycle > BuiltGate.maxCycle ||
              gate.phase < 0 ||
              gate.phase >= 360) {
            return 'motion';
          }
          if (gate.look < 0 || gate.look >= BuiltGate.looks) return 'look';
          if (gate.gap < safeGap(mode, y, gate.amp) ||
              gate.gap > maxGap(mode)) {
            return 'gap';
          }
          if (gate.door &&
              (!touch || !shoot || gate.kind != ObstacleKind.garden)) {
            return 'door';
          }
        case BuiltEnemy enemy:
          if (!touch || enemy.kind.campaignOnly) return 'enemy';
          if (y < minItemY || y > maxItemY || item.x >= finish) return 'place';
        case BuiltStar() || BuiltTrio() || BuiltHeart():
          if (y < minItemY || y > maxItemY || item.right >= finish) {
            return 'place';
          }
      }
    }
    final stars = totalStars;
    if (marks.two < 1 || marks.three < marks.two || marks.three > stars) {
      return 'marks';
    }
    return null;
  }
}
