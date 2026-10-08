import 'dart:math' as math;

import 'built_level.dart';
import 'game_rules.dart';
import 'tracking.dart';

/// Flight school: the first-time lesson every new courier flies before the
/// campaign (docs/tutorial.md). It is a hand-placed Tap & Fly route
/// ([BuiltPlan], rules version 64) over the Sky Club's bay, laid out as a
/// string of small lessons, and ends with a rookie fight against the Pirate
/// Captain ([FlightPlan.rookieBoss]). Nothing in it can knock the bird out
/// ([FlightPlan.forgiving]), and it is never saved: no run, no record, no
/// star, no session.
///
/// Every place on the route is in thousandths of the sky's height, as in a
/// built level. The bird meets a thing once `distance + birdX` reaches its
/// x; at the relaxed Tap & Fly pace a thousand is about 2.8 seconds.
class TutorialPlan extends BuiltPlan {
  TutorialPlan._({
    required super.items,
    required super.finish,
    required super.marks,
  }) : super(
         id: planId,
         name: 'Flight School', // l10n-ignore: never shown, l.tutorialTitle is
         mode: PlayMode.touch,
         region: WorldRegion.sea,
         boss: BossKind.pirate,
       );

  /// The plan's id: a starter-style id, so it reads as a built level.
  static const planId = 't-flight-school';

  /// The one flight school route.
  static final TutorialPlan course = _lay();

  /// The level the play screen flies: [course], kept like a starter.
  static final BuiltLevel level = BuiltLevel(plan: course);

  @override
  bool get forgiving => true;
  @override
  bool get rookieBoss => true;

  // ---------------------------------------------------------------------
  // The route, lesson by lesson. The coach ([TutorialCoach]) reads these
  // marks to know where each lesson begins.

  /// Open sky first: tap to flap and stay up.
  static const starsFrom = 2700, starsTo = 5900;

  /// Three wide, still garden gates, each with a trio before it.
  static const gateXs = [7100, 8400, 9700];
  static const gateYs = [500, 420, 580];

  /// Three purple bats, one at a time, near the bird's height.
  static const batXs = [12000, 13300, 14600];
  static const batYs = [480, 400, 580];

  /// A garden gate with a stone door: a charged shot breaks it.
  static const doorX = 17200;

  /// A line of bats to sprint through, with stars along it.
  static const sprintXs = [20300, 20550, 20800, 21050];

  /// Everything together: gates, bats and a heart to catch.
  static const togetherFrom = 23600;
  static const finalGateXs = [24200, 25700, 27200];
  static const finalGateYs = [440, 580, 460];
  static const heartX = 26450;

  /// The Pirate Captain's mark: he sails in when the bird reaches it.
  static const bossMark = 29400;

  static TutorialPlan _lay() {
    final items = <BuiltItem>[
      // Stars: a gentle wave of trios and a few singles between them.
      const BuiltTrio(x: 2900, y: 500),
      const BuiltStar(x: 3350, y: 460),
      const BuiltTrio(x: 3800, y: 420),
      const BuiltStar(x: 4250, y: 470),
      const BuiltTrio(x: 4700, y: 540),
      const BuiltStar(x: 5150, y: 520),
      const BuiltTrio(x: 5600, y: 480),
      // Gates, each with a trio on its line just before it.
      for (var i = 0; i < gateXs.length; i++) ...[
        BuiltGate(x: gateXs[i], y: gateYs[i], gap: 520),
        BuiltTrio(x: gateXs[i] - 300, y: gateYs[i]),
      ],
      // Bats, each with a trio on its line before it, so the bird is
      // already at its height when Shoot is pressed.
      for (var i = 0; i < batXs.length; i++) ...[
        BuiltTrio(x: batXs[i] - 900, y: batYs[i]),
        BuiltEnemy(x: batXs[i], y: batYs[i], kind: EnemyKind.simpleBat),
      ],
      // The stone door, centred where a level flight sits.
      const BuiltTrio(x: doorX - 900, y: 500),
      const BuiltGate(x: doorX, y: 500, gap: 460, door: true),
      const BuiltTrio(x: doorX + 1000, y: 500),
      // Sprint: bats in a row on the line a trio leads the bird onto.
      const BuiltTrio(x: 19400, y: 500),
      for (final x in sprintXs)
        BuiltEnemy(x: x, y: 500, kind: EnemyKind.simpleBat),
      const BuiltTrio(x: 22300, y: 500),
      // Together.
      for (var i = 0; i < finalGateXs.length; i++) ...[
        BuiltGate(x: finalGateXs[i], y: finalGateYs[i], gap: 480),
        BuiltTrio(x: finalGateXs[i] - 300, y: finalGateYs[i]),
      ],
      const BuiltEnemy(x: 25000, y: 360, kind: EnemyKind.simpleBat),
      const BuiltHeart(x: heartX, y: 500),
      const BuiltEnemy(x: 28000, y: 560, kind: EnemyKind.caveBat),
      const BuiltTrio(x: 28400, y: 480),
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
    final plan = TutorialPlan._(
      items: items,
      finish: bossMark,
      marks: BuiltPlan.suggestMarks(stars),
    );
    assert(plan.problem == null, 'flight school: ${plan.problem}');
    return plan;
  }
}

/// The lessons of flight school, in order.
enum TutorialLesson {
  flap,
  stars,
  gates,
  shoot,
  power,
  sprint,
  together,
  boss,
  victory,
}

/// What Postmaster Bill says in flight. Each is one recorded line
/// (`TutorialStory.coach`), shown in his speech bubble.
enum CoachLine {
  flap,
  air,
  stars,
  streak,
  gates,
  hit,
  safe,
  shoot,
  shootMore,
  power,
  powerDone,
  sprint,
  together,
  heart,
  pirate,
  stronger,
  tide,
  victory,
}

/// What the player must do to let a held moment go on.
enum CoachGesture { none, tap, shoot, holdShoot, sprint }

/// What a lesson's goal chip counts.
enum CoachGoalKind { flaps, stars, gates, bats, door, sprint, boss }

/// A lesson's goal: [done] of [total]. A boss goal has no count.
typedef CoachGoal = ({CoachGoalKind kind, int done, int total});

/// Runs flight school's lessons over a [FlightSimulation]: which lesson the
/// bird is in, what Bill says, the goal on screen and whether the moment is
/// held still until the player does what a new lesson asks.
///
/// It only reads the simulation: holding stops time from reaching the
/// simulation at all (`PlayController.advance`), so the route, the boss and
/// every rule run exactly as on any built level.
class TutorialCoach {
  TutorialCoach();

  /// How long a line stays in Bill's bubble when nothing holds it.
  static const lineSeconds = 4.5;

  /// How long the world takes to slow to a stop when a lesson holds it.
  static const easeSeconds = .35;

  /// How long the praise pop shows after a goal is met.
  static const praiseSeconds = 1.4;

  TutorialLesson lesson = TutorialLesson.flap;

  /// Bill's line now, and how long (real seconds) it has been showing.
  CoachLine? line;
  double lineAge = 0;

  /// Bumped each time Bill starts a line, so the screen can speak it once.
  int lineCount = 0;

  /// The held moment's gesture, or [CoachGesture.none] while flying.
  CoachGesture waitingFor = CoachGesture.none;
  bool get holding => waitingFor != CoachGesture.none;

  /// How fast time runs, 0 to 1: it eases to a stop as a hold begins and
  /// snaps back when the player acts.
  double timeScale = 1;

  /// The goal on screen, or null.
  CoachGoal? goal;

  /// Bumped each time a goal is met, with how long ago (real seconds).
  int praises = 0;
  double praiseAge = double.infinity;

  /// Lessons whose goal has been met, for the licence.
  final Set<TutorialLesson> passed = {};

  /// Tips said once each.
  final Set<CoachLine> _said = {};

  /// The simulation's counters as each lesson began.
  int _flaps = 0, _stars = 0, _gates = 0, _bats = 0, _doors = 0, _sprints = 0;
  bool _goalMet = false;

  /// Hearts and shield last frame, for the first bump's tip.
  int? _hearts;
  bool? _shield;
  int _caught = 0;

  /// The line now as long as it should still show.
  bool get speaking =>
      line != null && (holding || lineAge < lineSeconds || _sticky);
  bool get _sticky => lesson == TutorialLesson.victory;

  void _say(CoachLine next) {
    line = next;
    lineAge = 0;
    lineCount++;
  }

  void _hold(CoachGesture gesture) => waitingFor = gesture;

  /// The player acted: a tap, Shoot pressed or Sprint pressed. Lets the held
  /// moment go if it was waiting for that, and returns whether it was.
  bool act(CoachGesture gesture) {
    if (!holding) return false;
    final lets = switch (waitingFor) {
      CoachGesture.tap => gesture == CoachGesture.tap,
      CoachGesture.shoot ||
      CoachGesture.holdShoot => gesture == CoachGesture.shoot,
      CoachGesture.sprint => gesture == CoachGesture.sprint,
      CoachGesture.none => false,
    };
    if (!lets) return false;
    waitingFor = CoachGesture.none;
    timeScale = 1;
    // The line stays a moment after the hold lets go.
    lineAge = math.min(lineAge, lineSeconds - 2.2);
    return true;
  }

  /// Whether a gesture the player makes now reaches the flight. While a
  /// lesson holds, only the gesture it waits for does.
  bool lets(CoachGesture gesture) =>
      !holding ||
      switch (waitingFor) {
        CoachGesture.tap => gesture == CoachGesture.tap,
        CoachGesture.shoot ||
        CoachGesture.holdShoot => gesture == CoachGesture.shoot,
        CoachGesture.sprint => gesture == CoachGesture.sprint,
        CoachGesture.none => true,
      };

  void _begin(TutorialLesson next, FlightSimulation sim) {
    lesson = next;
    _flaps = sim.flaps;
    _stars = sim.collectedStars;
    _gates = sim.gates;
    _bats = sim.enemiesDefeated;
    _doors = sim.doorsDestroyed;
    _sprints = sim.sprints;
    _goalMet = false;
  }

  /// The bird's place on the route, in plan units.
  static double reach(FlightSimulation sim) =>
      (sim.distance + FlightSimulation.birdX) * BuiltPlan.unit;

  /// One frame of [dt] real seconds over [sim], before the simulation moves.
  void update(double dt, FlightSimulation sim) {
    if (!dt.isFinite || dt < 0) dt = 0;
    lineAge += dt;
    praiseAge += dt;
    if (holding) {
      timeScale = math.max(0, timeScale - dt / easeSeconds);
      // A key that cannot answer now (Sprint still recharging after a
      // press before its lesson) never strands the player: the moment
      // goes on and the line stays.
      if (waitingFor == CoachGesture.sprint && !sim.canSprint) {
        waitingFor = CoachGesture.none;
        timeScale = 1;
      }
      return;
    }
    if (sim.phase != RunPhase.playing || !sim.started) return;
    final at = reach(sim);
    switch (lesson) {
      case TutorialLesson.flap:
        if (line == null) {
          _begin(TutorialLesson.flap, sim);
          _say(CoachLine.flap);
          _hold(CoachGesture.tap);
          return;
        }
        if (line == CoachLine.flap) _say(CoachLine.air);
        _count(CoachGoalKind.flaps, sim.flaps - _flaps, 3);
        if (at >= TutorialPlan.starsFrom - 900) {
          _begin(TutorialLesson.stars, sim);
          _say(CoachLine.stars);
        }
      case TutorialLesson.stars:
        _count(CoachGoalKind.stars, sim.collectedStars - _stars, 6);
        if (at >= TutorialPlan.gateXs.first - 1100) {
          _begin(TutorialLesson.gates, sim);
          _say(CoachLine.gates);
          _hold(CoachGesture.tap);
        }
      case TutorialLesson.gates:
        _count(CoachGoalKind.gates, sim.gates - _gates, 3);
        if (at >= TutorialPlan.batXs.first - 2600 && _batAhead(sim, 1.7)) {
          // A bat shot down early still counts.
          final bats = _bats;
          _begin(TutorialLesson.shoot, sim);
          _bats = bats;
          _say(CoachLine.shoot);
          _hold(CoachGesture.shoot);
        }
      case TutorialLesson.shoot:
        final bats = sim.enemiesDefeated - _bats;
        if (bats == 1 && line == CoachLine.shoot) _say(CoachLine.shootMore);
        _count(CoachGoalKind.bats, bats, 3);
        if (at >= TutorialPlan.doorX - 1500) {
          _begin(TutorialLesson.power, sim);
          _say(CoachLine.power);
          _hold(CoachGesture.holdShoot);
        }
      case TutorialLesson.power:
        final doors = sim.doorsDestroyed - _doors;
        if (doors > 0 && line == CoachLine.power) _say(CoachLine.powerDone);
        _count(CoachGoalKind.door, doors, 1);
        if (at >= TutorialPlan.sprintXs.first - 2600 && _batAhead(sim, .9)) {
          _begin(TutorialLesson.sprint, sim);
          _say(CoachLine.sprint);
          _hold(CoachGesture.sprint);
        }
      case TutorialLesson.sprint:
        _count(CoachGoalKind.sprint, sim.sprints - _sprints, 1);
        if (at >= TutorialPlan.togetherFrom - 600) {
          _begin(TutorialLesson.together, sim);
          _say(CoachLine.together);
        }
      case TutorialLesson.together:
        _count(CoachGoalKind.gates, sim.gates - _gates, 3);
        if (at >= TutorialPlan.heartX - 1300 && _once(CoachLine.heart)) {
          _say(CoachLine.heart);
        }
        if (sim.boss != null || sim.bossFight) {
          _begin(TutorialLesson.boss, sim);
          goal = null;
        }
      case TutorialLesson.boss:
        final boss = sim.boss;
        if (boss == null) break;
        if (boss.phase == BossPhase.defeated || sim.bossesDefeated > 0) {
          passed.add(TutorialLesson.boss);
          _begin(TutorialLesson.victory, sim);
          goal = null;
          _praise();
          _say(CoachLine.victory);
          return;
        }
        if (sim.bossCutscene) return;
        goal = (
          kind: CoachGoalKind.boss,
          done: boss.maxHp - boss.hp,
          total: boss.maxHp,
        );
        if (_once(CoachLine.pirate)) {
          _say(CoachLine.pirate);
        } else if (boss.stageReached >= 1 && _once(CoachLine.stronger)) {
          _say(CoachLine.stronger);
        } else if (boss.tideWarning > 0 && _once(CoachLine.tide)) {
          _say(CoachLine.tide);
        }
      case TutorialLesson.victory:
        break;
    }
    _tips(sim);
  }

  /// Tips that come when they happen, once each: the first bump, the first
  /// fall caught and the first star streak.
  void _tips(FlightSimulation sim) {
    final hurt =
        (_shield == true && !sim.shield) ||
        (_hearts != null && sim.hearts < _hearts!);
    _hearts = sim.hearts;
    _shield = sim.shield;
    final busy = speaking && lineAge < 2.5;
    if (sim.fallsCaught > _caught) {
      _caught = sim.fallsCaught;
      if (_once(CoachLine.safe)) _say(CoachLine.safe);
    } else if (hurt && !busy && _once(CoachLine.hit)) {
      _say(CoachLine.hit);
    } else if (sim.multiplier > 1 && !busy && _once(CoachLine.streak)) {
      _say(CoachLine.streak);
    }
  }

  bool _once(CoachLine tip) => _said.add(tip);

  /// Whether a bat is within [ahead] of the bird (screen heights): the
  /// bats fly to meet the bird, so their lessons start by sight.
  static bool _batAhead(FlightSimulation sim, double ahead) => sim.enemies.any(
    (enemy) =>
        enemy.x > FlightSimulation.birdX &&
        enemy.x - FlightSimulation.birdX < ahead,
  );

  void _count(CoachGoalKind kind, int done, int total) {
    goal = (kind: kind, done: math.min(done, total), total: total);
    if (!_goalMet && done >= total) {
      _goalMet = true;
      passed.add(lesson);
      _praise();
    }
  }

  void _praise() {
    praises++;
    praiseAge = 0;
  }

  /// Whether the praise pop is showing.
  bool get praising => praiseAge < praiseSeconds;
}
