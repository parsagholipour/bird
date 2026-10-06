import 'built_level.dart';
import 'game_rules.dart';
import 'tracking.dart';

/// The starter levels the builder opens with: one or more per mode, to fly
/// as they are or to remix into a level of your own. They are read-only
/// and kept in code; their flights' bests are saved like any built level's.
/// Retuning one's route bumps its [revision], so old bests start afresh.
abstract final class BuiltTemplates {
  static final List<BuiltLevel> all = List.unmodifiable([
    _level(_gardenHop(), revision: 1),
    _level(_tenPushUps(), revision: 1),
    _level(_stairSquats(), revision: 1),
    _level(_bounceBay(), revision: 1),
    _level(_baronsBridge(), revision: 1),
  ]);

  static BuiltLevel? byId(String id) {
    for (final level in all) {
      if (level.id == id) return level;
    }
    return null;
  }

  static BuiltLevel _level(BuiltPlan plan, {required int revision}) {
    assert(plan.problem == null, '${plan.id}: ${plan.problem}');
    return BuiltLevel(plan: plan, revision: revision);
  }

  /// A trio of stars on [gate]'s aiming line, just before it.
  static BuiltTrio _trioFor(PlayMode mode, BuiltGate gate) => BuiltTrio(
    x: gate.x - 250,
    y: (BuiltPlan.laneTarget(mode, gate.y / BuiltPlan.unit) * BuiltPlan.unit)
        .round(),
  );

  static BuiltPlan _plan({
    required String id,
    required String name,
    required PlayMode mode,
    required WorldRegion region,
    required List<BuiltGate> gates,
    List<BuiltItem> extra = const [],
    BuiltPace pace = BuiltPace.relaxed,
    BossKind? boss,
    int tail = 900,
  }) {
    final items = <BuiltItem>[
      for (final gate in gates) ...[gate, _trioFor(mode, gate)],
      ...extra,
    ];
    final stars = items.fold(
      0,
      (sum, item) =>
          sum +
          switch (item) {
            BuiltStar() => 1,
            BuiltTrio() => 3,
            _ => 0,
          },
    );
    return BuiltPlan(
      id: id,
      name: name,
      mode: mode,
      region: region,
      pace: pace,
      finish: gates.last.right + tail,
      marks: BuiltPlan.suggestMarks(stars),
      items: items,
      boss: boss,
    );
  }

  /// Tap & Fly in the jungle: still gates first, then gentle movers, a
  /// stone door to shoot open and two bats.
  static BuiltPlan _gardenHop() {
    const heights = [
      500,
      420,
      580,
      460,
      380,
      560,
      640,
      500,
      420,
      600,
      480,
      540,
    ];
    const kinds = [
      ObstacleKind.garden,
      ObstacleKind.garden,
      ObstacleKind.garden,
      ObstacleKind.windLift,
      ObstacleKind.garden,
      ObstacleKind.petalGate,
      ObstacleKind.garden,
      ObstacleKind.lanternDrift,
      ObstacleKind.garden,
      ObstacleKind.switchback,
      ObstacleKind.sunWheels,
      ObstacleKind.crystalSteps,
    ];
    final gates = <BuiltGate>[];
    var x = 3000;
    for (var i = 0; i < heights.length; i++) {
      final kind = kinds[i];
      gates.add(
        BuiltGate(
          x: x,
          y: heights[i],
          gap: kind == ObstacleKind.garden ? 400 : 440,
          kind: kind,
          amp: kind == ObstacleKind.garden ? 0 : 60,
          phase: (i * 90) % 360,
          look: i % BuiltGate.looks,
          door: i == 6,
        ),
      );
      x += gates.last.right - gates.last.x + 900;
    }
    return _plan(
      id: 't-tap-1',
      name: 'Garden Hop',
      mode: PlayMode.touch,
      region: WorldRegion.jungle,
      gates: gates,
      extra: [
        const BuiltEnemy(x: 6400, y: 300, kind: EnemyKind.simpleBat),
        const BuiltEnemy(x: 11950, y: 700, kind: EnemyKind.caveBat),
        BuiltHeart(x: gates[7].right + 300, y: 500),
      ],
    );
  }

  /// Ten push-ups over the Great Wall: every low gate is the bottom of a
  /// push-up, every high one its top.
  static BuiltPlan _tenPushUps() {
    final gates = [
      for (var i = 0; i < 20; i++)
        BuiltGate(
          x: 3000 + i * 1250,
          y: i.isEven ? BuiltPlan.highLane : BuiltPlan.lowLane,
          gap: 440,
          kind: i < 4
              ? ObstacleKind.garden
              : const [
                  ObstacleKind.garden,
                  ObstacleKind.windLift,
                  ObstacleKind.petalGate,
                  ObstacleKind.crystalSteps,
                ][i % 4],
          amp: i < 4 || i % 4 == 0 ? 0 : 30,
          phase: (i * 45) % 360,
          look: i % BuiltGate.looks,
        ),
    ];
    return _plan(
      id: 't-push-1',
      name: 'Ten Push-Ups',
      mode: PlayMode.pushUp,
      region: WorldRegion.china,
      gates: gates,
      extra: [
        BuiltHeart(x: gates[11].right + 350, y: 850),
        // The tenth push-up ends back at the top.
        BuiltTrio(x: gates.last.right + 500, y: 150),
      ],
    );
  }

  /// Squats up the steps of Rome: pairs of gates on one lane, then a
  /// switch, with lanterns drifting in the second half.
  static BuiltPlan _stairSquats() {
    const lanes = [
      BuiltPlan.highLane,
      BuiltPlan.lowLane,
      BuiltPlan.lowLane,
      BuiltPlan.highLane,
      BuiltPlan.highLane,
      BuiltPlan.lowLane,
      BuiltPlan.highLane,
      BuiltPlan.lowLane,
      BuiltPlan.lowLane,
      BuiltPlan.highLane,
      BuiltPlan.lowLane,
      BuiltPlan.highLane,
      BuiltPlan.lowLane,
      BuiltPlan.highLane,
    ];
    final gates = <BuiltGate>[];
    var x = 3000;
    for (var i = 0; i < lanes.length; i++) {
      final kind = i < 7 ? ObstacleKind.garden : ObstacleKind.lanternDrift;
      gates.add(
        BuiltGate(
          x: x,
          y: lanes[i],
          gap: 440,
          kind: kind,
          amp: kind == ObstacleKind.garden ? 0 : 35,
          phase: (i * 135) % 360,
          look: i % BuiltGate.looks,
        ),
      );
      // A switch of lane needs room for the movement; a repeat does not.
      final same = i + 1 < lanes.length && lanes[i + 1] == lanes[i];
      x = gates.last.right + (same ? 700 : 1150);
    }
    return _plan(
      id: 't-squat-1',
      name: 'Stair Squats',
      mode: PlayMode.squat,
      region: WorldRegion.rome,
      gates: gates,
      extra: [
        BuiltHeart(x: gates[6].right + 350, y: 150),
        BuiltStar(x: gates[2].right + 350, y: 850),
        BuiltStar(x: gates[8].right + 350, y: 850),
      ],
    );
  }

  /// Jumps over the open sea: wide gates that drift up and down in long,
  /// easy swells, with room to land between them.
  static BuiltPlan _bounceBay() {
    const heights = [520, 460, 560, 480, 420, 520, 600, 500, 440, 540];
    final gates = [
      for (var i = 0; i < heights.length; i++)
        BuiltGate(
          x: 3000 + i * 1500,
          y: heights[i],
          gap: 500,
          kind: i < 3 ? ObstacleKind.garden : ObstacleKind.windLift,
          amp: i < 3 ? 0 : 40,
          cycle: 4000,
          phase: (i * 60) % 360,
          look: i % BuiltGate.looks,
        ),
    ];
    return _plan(
      id: 't-jump-1',
      name: 'Bounce Bay',
      mode: PlayMode.jump,
      region: WorldRegion.sea,
      gates: gates,
      extra: [BuiltHeart(x: gates[5].right + 500, y: 500)],
    );
  }

  /// A short run over the Aztec causeway, then Baron Bat.
  static BuiltPlan _baronsBridge() {
    const heights = [500, 440, 560, 480, 400, 520, 600, 480];
    final gates = [
      for (var i = 0; i < heights.length; i++)
        BuiltGate(
          x: 3000 + i * 1100,
          y: heights[i],
          gap: 400,
          kind: i.isEven ? ObstacleKind.garden : ObstacleKind.windLift,
          amp: i.isEven ? 0 : 65,
          phase: (i * 90) % 360,
          look: i % BuiltGate.looks,
        ),
    ];
    return _plan(
      id: 't-tap-boss',
      name: 'Baron’s Bridge',
      mode: PlayMode.touch,
      region: WorldRegion.aztec,
      gates: gates,
      boss: BossKind.baronBat,
      tail: 1200,
      extra: const [BuiltEnemy(x: 6600, y: 350, kind: EnemyKind.caveBat)],
    );
  }
}
