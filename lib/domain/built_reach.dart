import 'dart:math' as math;

import 'game_rules.dart';
import 'tracking.dart';

// l10n-english-twin: [BuiltIssue.message] is the English twin of the
// `reach_*` keys; the editor words an issue by its [BuiltIssueKind]
// (lib/l10n/text/builder_text.dart, test/l10n_builder_test.dart).

/// What an issue says, for the editor to word in the player's language.
enum BuiltIssueKind {
  name,
  tooShort,
  tooLong,
  tooMany,
  bossNeedsTap,
  noGates,
  startZone,
  finishRoom,
  overlap,
  gateHeight,
  gateMotion,
  gateLook,
  gateNarrow,
  gateWide,
  doorNeedsShoot,
  doorNeedsGarden,
  tightSwitch,
  steepClimb,
  enemyNeedsTap,
  outsideSky,
  pastFinish,
  outOfReach,
  inWall,
  noStars,
  marks,
  cannotFly,
}

/// Something the editor tells a level's creator, at [x] on the route when
/// it is about one place. A [blocking] issue stops the level from flying
/// and sharing ([BuiltPlan.problem]); the rest is advice.
class BuiltIssue {
  const BuiltIssue(
    this.kind, {
    this.x,
    this.blocking = false,
    this.limit,
    this.movement,
    this.problem,
  });
  final BuiltIssueKind kind;
  final int? x;
  final bool blocking;

  /// The number a [BuiltIssueKind.name] or [BuiltIssueKind.tooMany] issue
  /// names: the longest name, the most things.
  final int? limit;

  /// The mode whose movement a [BuiltIssueKind.tightSwitch] or
  /// [BuiltIssueKind.outOfReach] issue names (push-ups or squats).
  final PlayMode? movement;

  /// The plan's own [BuiltPlan.problem] code, for
  /// [BuiltIssueKind.cannotFly].
  final String? problem;

  /// The words of a push-up or squat: "push-up", "squat".
  static String movementWord(PlayMode? mode) => switch (mode) {
    PlayMode.squat => 'squat',
    PlayMode.jump => 'jump',
    PlayMode.touch => 'tap',
    _ => 'push-up',
  };

  /// What the issue says, in English (logs, tests, tools).
  String get message => switch (kind) {
    BuiltIssueKind.name => 'Give the level a name of up to $limit letters.',
    BuiltIssueKind.tooShort =>
      'Move the finish line further on: the level is too short.',
    BuiltIssueKind.tooLong =>
      'Bring the finish line closer: the level is too long.',
    BuiltIssueKind.tooMany => 'Too many things: a level holds up to $limit.',
    BuiltIssueKind.bossNeedsTap => 'Only Tap & Fly levels end with a boss.',
    BuiltIssueKind.noGates => 'Add gates for the bird to fly through.',
    BuiltIssueKind.startZone =>
      'Too close to the start: move it past the start zone.',
    BuiltIssueKind.finishRoom =>
      'Leave room before the finish line after this gate.',
    BuiltIssueKind.overlap => 'Two gates overlap: move them apart.',
    BuiltIssueKind.gateHeight => 'This gate is too high or too low.',
    BuiltIssueKind.gateMotion => 'This gate cannot move that way.',
    BuiltIssueKind.gateLook => 'This gate has an unknown look.',
    BuiltIssueKind.gateNarrow => 'Open this gate wider: the bird cannot fit.',
    BuiltIssueKind.gateWide => 'This gate is open too wide.',
    BuiltIssueKind.doorNeedsShoot =>
      'A stone door needs Tap & Fly with Shoot on.',
    BuiltIssueKind.doorNeedsGarden =>
      'Only a garden gate can hold a stone door.',
    BuiltIssueKind.tightSwitch =>
      'Tight switch: a steady ${movementWord(movement)} may not make it in '
          'time.',
    BuiltIssueKind.steepClimb =>
      'Steep climb: leave more room to jump up to this gate.',
    BuiltIssueKind.enemyNeedsTap => 'Enemies only fly in Tap & Fly levels.',
    BuiltIssueKind.outsideSky => 'Keep it inside the sky.',
    BuiltIssueKind.pastFinish => 'Place it before the finish line.',
    BuiltIssueKind.outOfReach =>
      'Out of a ${movementWord(movement)}\'s reach: move it nearer the '
          'lanes.',
    BuiltIssueKind.inWall => 'Inside a wall: move it into the opening.',
    BuiltIssueKind.noStars => 'Place at least one star.',
    BuiltIssueKind.marks =>
      'The star marks ask for more stars than the level has.',
    BuiltIssueKind.cannotFly => 'This level cannot fly yet ($problem).',
  };

  @override
  String toString() =>
      '${blocking ? '!' : '?'} $message${x == null ? '' : ' @$x'}';
}

/// What a built level asks of a player, measured on the route as the
/// level is designed: at its pace, and for push-ups and squats at
/// [BuiltPlan.referenceCycle] (a slower player meets the same route more
/// slowly, [BuiltPlan.speedScale]).
abstract final class BuiltReach {
  /// The course's cruising speed, viewport heights a second.
  static double cruise(BuiltPlan plan) {
    final rules = switch (plan.mode) {
      PlayMode.pushUp || PlayMode.squat => PushUpFlightMode(
        cycleSeconds: BuiltPlan.referenceCycle,
      ),
      PlayMode.jump => JumpFlyMode(),
      PlayMode.touch => TapFlyMode(),
    };
    return rules.speedFor(0) * .9 * plan.pace.factor;
  }

  /// Seconds from the start to [x] (thousandths) on the route.
  static double secondsTo(BuiltPlan plan, int x) => math.max(
    0.0,
    (x / BuiltPlan.unit - FlightSimulation.birdX) / cruise(plan),
  );

  /// Seconds to the finish line (to the boss's mark, with a boss).
  static double seconds(BuiltPlan plan) => secondsTo(plan, plan.finish);

  /// Push-ups or squats the route asks for: every dip to the low lane and
  /// back up is one. Null for Tap & Fly and jumps.
  static int? reps(BuiltPlan plan) {
    if (!plan.mode.controlsHeight) return null;
    var reps = 0;
    var low = false;
    for (final gate in plan.gates) {
      final dip = gate.y == BuiltPlan.lowLane;
      if (dip && !low) reps++;
      low = dip;
    }
    return reps;
  }

  /// Room (thousandths) a push-up or squat needs between one gate and the
  /// next on the other lane: half a movement at the designed tempo, and
  /// the bird's width.
  static int laneSwitchRoom(BuiltPlan plan) =>
      ((cruise(plan) * (BuiltPlan.referenceCycle / 2) + .1) * BuiltPlan.unit)
          .round();

  static List<BuiltIssue> check(BuiltPlan plan) {
    final issues = <BuiltIssue>[];
    final mode = plan.mode;
    void block(BuiltIssueKind kind, [int? x, int? limit, String? problem]) =>
        issues.add(
          BuiltIssue(
            kind,
            x: x,
            blocking: true,
            limit: limit,
            movement: mode,
            problem: problem,
          ),
        );
    void advise(BuiltIssueKind kind, [int? x]) =>
        issues.add(BuiltIssue(kind, x: x, movement: mode));

    if (!BuiltPlan.validName(plan.name)) {
      block(BuiltIssueKind.name, null, BuiltPlan.maxName);
    }
    if (plan.finish < BuiltPlan.minFinish) {
      block(BuiltIssueKind.tooShort);
    } else if (plan.finish > BuiltPlan.maxFinish) {
      block(BuiltIssueKind.tooLong);
    }
    if (plan.items.length > BuiltPlan.maxItems) {
      block(BuiltIssueKind.tooMany, null, BuiltPlan.maxItems);
    }
    if (plan.boss != null && (!plan.touch || plan.boss!.campaignOnly)) {
      block(BuiltIssueKind.bossNeedsTap);
    }
    if (plan.gates.isEmpty) advise(BuiltIssueKind.noGates);

    BuiltGate? previous;
    final cruising = cruise(plan);
    for (final item in plan.items) {
      final x = item.x, y = item.y;
      if (item.left < BuiltPlan.firstX) {
        block(BuiltIssueKind.startZone, x);
      }
      switch (item) {
        case BuiltGate gate:
          if (gate.right + BuiltPlan.finishClearance > plan.finish) {
            block(BuiltIssueKind.finishRoom, x);
          }
          if (previous != null && previous.right > gate.x) {
            block(BuiltIssueKind.overlap, x);
          }
          if (mode.controlsHeight
              ? y != BuiltPlan.highLane && y != BuiltPlan.lowLane
              : y < BuiltPlan.minGateY || y > BuiltPlan.maxGateY) {
            block(BuiltIssueKind.gateHeight, x);
          }
          if (gate.amp < 0 ||
              gate.amp > BuiltPlan.maxAmp(mode) ||
              (gate.kind == ObstacleKind.garden && gate.amp != 0) ||
              gate.cycle < BuiltGate.minCycle ||
              gate.cycle > BuiltGate.maxCycle ||
              gate.phase < 0 ||
              gate.phase >= 360) {
            block(BuiltIssueKind.gateMotion, x);
          }
          if (gate.look < 0 || gate.look >= BuiltGate.looks) {
            block(BuiltIssueKind.gateLook, x);
          }
          if (gate.gap < BuiltPlan.safeGap(mode, y, gate.amp)) {
            block(BuiltIssueKind.gateNarrow, x);
          } else if (gate.gap > BuiltPlan.maxGap(mode)) {
            block(BuiltIssueKind.gateWide, x);
          }
          if (gate.door && (!plan.touch || !plan.shoot)) {
            block(BuiltIssueKind.doorNeedsShoot, x);
          } else if (gate.door && gate.kind != ObstacleKind.garden) {
            block(BuiltIssueKind.doorNeedsGarden, x);
          }
          if (previous != null &&
              mode.controlsHeight &&
              previous.y != gate.y &&
              gate.x - previous.right < laneSwitchRoom(plan)) {
            advise(BuiltIssueKind.tightSwitch, x);
          }
          if (previous != null &&
              mode == PlayMode.jump &&
              previous.y - gate.y > 200 &&
              (gate.x - previous.right) / BuiltPlan.unit / cruising < 2.5) {
            advise(BuiltIssueKind.steepClimb, x);
          }
          previous = gate;
        case BuiltEnemy enemy:
          if (!plan.touch || enemy.kind.campaignOnly) {
            block(BuiltIssueKind.enemyNeedsTap, x);
          }
          if (y < BuiltPlan.minItemY || y > BuiltPlan.maxItemY) {
            block(BuiltIssueKind.outsideSky, x);
          }
          if (x >= plan.finish) block(BuiltIssueKind.pastFinish, x);
        case BuiltStar() || BuiltTrio() || BuiltHeart():
          if (y < BuiltPlan.minItemY || y > BuiltPlan.maxItemY) {
            block(BuiltIssueKind.outsideSky, x);
          }
          if (item.right >= plan.finish) {
            block(BuiltIssueKind.pastFinish, x);
          }
          if (mode.controlsHeight && (y < 90 || y > 910)) {
            advise(BuiltIssueKind.outOfReach, x);
          }
          for (final gate in plan.gates) {
            if (item.right < gate.x || item.left > gate.right) continue;
            if ((y - gate.y).abs() > gate.gap ~/ 2) {
              advise(BuiltIssueKind.inWall, x);
              break;
            }
          }
      }
    }

    final stars = plan.totalStars;
    if (stars == 0) {
      block(BuiltIssueKind.noStars);
    } else if (plan.marks.two < 1 ||
        plan.marks.three < plan.marks.two ||
        plan.marks.three > stars) {
      block(BuiltIssueKind.marks);
    }
    // Whatever else the plan's own check finds.
    final problem = plan.problem;
    if (problem != null && !issues.any((i) => i.blocking)) {
      block(BuiltIssueKind.cannotFly, null, null, problem);
    }
    issues.sort((a, b) {
      if (a.blocking != b.blocking) return a.blocking ? -1 : 1;
      return (a.x ?? -1).compareTo(b.x ?? -1);
    });
    return issues;
  }
}
