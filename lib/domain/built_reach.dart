import 'dart:math' as math;

import 'game_rules.dart';
import 'tracking.dart';

/// Something the editor tells a level's creator, at [x] on the route when
/// it is about one place. A [blocking] issue stops the level from flying
/// and sharing ([BuiltPlan.problem]); the rest is advice.
class BuiltIssue {
  const BuiltIssue(this.message, {this.x, this.blocking = false});
  final String message;
  final int? x;
  final bool blocking;
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
    void block(String message, [int? x]) =>
        issues.add(BuiltIssue(message, x: x, blocking: true));
    void advise(String message, [int? x]) =>
        issues.add(BuiltIssue(message, x: x));
    final mode = plan.mode;
    final movement = switch (mode) {
      PlayMode.pushUp => 'push-up',
      PlayMode.squat => 'squat',
      PlayMode.jump => 'jump',
      PlayMode.touch => 'tap',
    };

    if (!BuiltPlan.validName(plan.name)) {
      block('Give the level a name of up to ${BuiltPlan.maxName} letters.');
    }
    if (plan.finish < BuiltPlan.minFinish) {
      block('Move the finish line further on: the level is too short.');
    } else if (plan.finish > BuiltPlan.maxFinish) {
      block('Bring the finish line closer: the level is too long.');
    }
    if (plan.items.length > BuiltPlan.maxItems) {
      block('Too many things: a level holds up to ${BuiltPlan.maxItems}.');
    }
    if (plan.boss != null && (!plan.touch || plan.boss!.campaignOnly)) {
      block('Only Tap & Fly levels end with a boss.');
    }
    if (plan.gates.isEmpty) advise('Add gates for the bird to fly through.');

    BuiltGate? previous;
    final cruising = cruise(plan);
    for (final item in plan.items) {
      final x = item.x, y = item.y;
      if (item.left < BuiltPlan.firstX) {
        block('Too close to the start: move it past the start zone.', x);
      }
      switch (item) {
        case BuiltGate gate:
          if (gate.right + BuiltPlan.finishClearance > plan.finish) {
            block('Leave room before the finish line after this gate.', x);
          }
          if (previous != null && previous.right > gate.x) {
            block('Two gates overlap: move them apart.', x);
          }
          if (mode.controlsHeight
              ? y != BuiltPlan.highLane && y != BuiltPlan.lowLane
              : y < BuiltPlan.minGateY || y > BuiltPlan.maxGateY) {
            block('This gate is too high or too low.', x);
          }
          if (gate.amp < 0 ||
              gate.amp > BuiltPlan.maxAmp(mode) ||
              (gate.kind == ObstacleKind.garden && gate.amp != 0) ||
              gate.cycle < BuiltGate.minCycle ||
              gate.cycle > BuiltGate.maxCycle ||
              gate.phase < 0 ||
              gate.phase >= 360) {
            block('This gate cannot move that way.', x);
          }
          if (gate.look < 0 || gate.look >= BuiltGate.looks) {
            block('This gate has an unknown look.', x);
          }
          if (gate.gap < BuiltPlan.safeGap(mode, y, gate.amp)) {
            block('Open this gate wider: the bird cannot fit.', x);
          } else if (gate.gap > BuiltPlan.maxGap(mode)) {
            block('This gate is open too wide.', x);
          }
          if (gate.door && (!plan.touch || !plan.shoot)) {
            block('A stone door needs Tap & Fly with Shoot on.', x);
          } else if (gate.door && gate.kind != ObstacleKind.garden) {
            block('Only a garden gate can hold a stone door.', x);
          }
          if (previous != null &&
              mode.controlsHeight &&
              previous.y != gate.y &&
              gate.x - previous.right < laneSwitchRoom(plan)) {
            advise(
              'Tight switch: a steady $movement may not make it in time.',
              x,
            );
          }
          if (previous != null &&
              mode == PlayMode.jump &&
              previous.y - gate.y > 200 &&
              (gate.x - previous.right) / BuiltPlan.unit / cruising < 2.5) {
            advise('Steep climb: leave more room to jump up to this gate.', x);
          }
          previous = gate;
        case BuiltEnemy enemy:
          if (!plan.touch || enemy.kind.campaignOnly) {
            block('Enemies only fly in Tap & Fly levels.', x);
          }
          if (y < BuiltPlan.minItemY || y > BuiltPlan.maxItemY) {
            block('Keep it inside the sky.', x);
          }
          if (x >= plan.finish) block('Place it before the finish line.', x);
        case BuiltStar() || BuiltTrio() || BuiltHeart():
          if (y < BuiltPlan.minItemY || y > BuiltPlan.maxItemY) {
            block('Keep it inside the sky.', x);
          }
          if (item.right >= plan.finish) {
            block('Place it before the finish line.', x);
          }
          if (mode.controlsHeight && (y < 90 || y > 910)) {
            advise('Out of a $movement\'s reach: move it nearer the lanes.', x);
          }
          for (final gate in plan.gates) {
            if (item.right < gate.x || item.left > gate.right) continue;
            if ((y - gate.y).abs() > gate.gap ~/ 2) {
              advise('Inside a wall: move it into the opening.', x);
              break;
            }
          }
      }
    }

    final stars = plan.totalStars;
    if (stars == 0) {
      block('Place at least one star.');
    } else if (plan.marks.two < 1 ||
        plan.marks.three < plan.marks.two ||
        plan.marks.three > stars) {
      block('The star marks ask for more stars than the level has.');
    }
    // Whatever else the plan's own check finds.
    final problem = plan.problem;
    if (problem != null && !issues.any((i) => i.blocking)) {
      block('This level cannot fly yet ($problem).');
    }
    issues.sort((a, b) {
      if (a.blocking != b.blocking) return a.blocking ? -1 : 1;
      return (a.x ?? -1).compareTo(b.x ?? -1);
    });
    return issues;
  }
}
