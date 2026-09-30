import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/campaign.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/tracking.dart';

import 'campaign_flight.dart';
import 'endless_plan_baseline_test.dart' show stateOf;

final playable = [
  for (final chapter in Campaign.chapters)
    if (chapter.playable) ...chapter.levels,
];

CampaignLevel level(String id) => Campaign.level(id)!;

/// Everything a flight of a level showed, frame by frame.
class Sightings {
  final kinds = <ObstacleKind>{};
  final enemies = <EnemyKind>{};
  final bosses = <BossKind>{};
  final rushes = <RushPathKind>{};
  final regions = <WorldRegion?>{};
  var panels = false, gales = false, vents = false, swarm = false;
  var sea = false, meteors = false, hearts = false;

  void watch(FlightSimulation sim) {
    regions.add(sim.region);
    for (final o in sim.obstacles) {
      if (!o.rubble) kinds.add(o.kind);
      panels |= o.door != null;
    }
    enemies.addAll(sim.enemies.map((e) => e.kind));
    if (sim.boss case final boss?) {
      bosses.add(boss.kind);
      sea |= boss.waterLevel != null;
    }
    if (sim.rushPath case final path?) rushes.add(path.kind);
    gales |= sim.gale != null || sim.galeDebris.isNotEmpty;
    vents |= sim.lavaVents.isNotEmpty;
    swarm |= sim.swarm.isNotEmpty;
    meteors |= sim.meteors.isNotEmpty;
    hearts |= sim.heartPickups.isNotEmpty;
  }
}

void main() {
  test('every chapter 1 and 2 level flies to its finish, laying its route '
      'stars', () {
    for (final level in playable) {
      final sim = levelFlight(level, weaponDamage: 30);
      final seen = Sightings();
      flyLevel(sim, watch: seen.watch);
      expect(sim.endReason, EndReason.completed, reason: level.id);
      expect(sim.finishLine!.crossed, isTrue, reason: level.id);
      expect(sim.starsLaid, sim.route!.stars, reason: level.id);
      expect(sim.levelStars, inInclusiveRange(1, 3), reason: level.id);
      expect(seen.regions, {level.region}, reason: level.id);
      expect(
        level.plan.families.toSet().containsAll(seen.kinds),
        isTrue,
        reason: level.id,
      );
      expect(seen.hearts, isFalse, reason: '${level.id}: no heart pickups');
      if (!level.isBoss) {
        // The finish sits a fixed route distance away: a flight that never
        // sprints crosses it at the level's length.
        expect(sim.routeSeconds, closeTo(level.length, .05), reason: level.id);
      }
    }
  });

  test('each hazard is absent before its chapter', () {
    for (final level in playable) {
      final sim = levelFlight(level, weaponDamage: 30);
      final seen = Sightings();
      flyLevel(sim, watch: seen.watch);
      final id = level.id;
      if (level.chapter == 1) {
        expect(seen.enemies, isNot(contains(EnemyKind.spitterBeetle)));
        expect(seen.panels, isFalse, reason: id);
        expect(seen.rushes, isEmpty, reason: id);
        expect(seen.kinds, isNot(contains(ObstacleKind.switchback)));
        expect(seen.kinds, isNot(contains(ObstacleKind.lanternDrift)));
      }
      expect(seen.enemies, isNot(contains(EnemyKind.duskMoth)), reason: id);
      expect(seen.kinds, isNot(contains(ObstacleKind.sunWheels)));
      expect(seen.kinds, isNot(contains(ObstacleKind.crystalSteps)));
      expect(seen.gales, isFalse, reason: id);
      expect(seen.vents, isFalse, reason: id);
      expect(seen.swarm, isFalse, reason: id);
      expect(seen.sea, isFalse, reason: id);
      expect(seen.rushes, isNot(contains(RushPathKind.eruption)));
      expect(seen.rushes, isNot(contains(RushPathKind.swarm)));
      expect(seen.rushes, level.plan.pieces.map((p) => p.kind.rush).toSet());
      expect(seen.bosses, {?level.boss}, reason: id);
      if (level.id == '1-1' || level.id == '1-2') {
        expect(seen.enemies, isEmpty, reason: id);
      }
    }
    // Where a mechanic arrives, the flight shows it.
    Sightings flown(String id) {
      final seen = Sightings();
      flyLevel(levelFlight(level(id), weaponDamage: 30), watch: seen.watch);
      return seen;
    }

    expect(flown('1-3').enemies, isNotEmpty);
    expect(flown('2-1').enemies, contains(EnemyKind.spitterBeetle));
    expect(flown('2-2').panels, isTrue);
    expect(flown('2-3').rushes, {RushPathKind.wildfire});
    expect(flown('2-5').meteors, isTrue);
  });

  test('Shoot and Sprint are refused before 1-3 and 1-5', () {
    for (final level in playable) {
      final sim = levelFlight(level);
      var shots = 0, charges = 0, sprints = 0;
      flyLevel(
        sim,
        seconds: 20,
        watch: (sim) {
          if (sim.startCharge()) charges++;
          if (sim.shoot()) shots++;
          if (sim.sprint()) sprints++;
        },
      );
      final shoot = level.chapter > 1 || level.number >= 3;
      final sprint = level.chapter > 1 || level.number >= 5;
      expect(sim.offersShoot, shoot, reason: level.id);
      expect(sim.offersSprint, sprint, reason: level.id);
      expect(shots > 0 && charges > 0, shoot, reason: level.id);
      expect(sprints > 0, sprint, reason: level.id);
      if (!shoot) expect(sim.dryFires, 0, reason: level.id);
    }
  });

  test('the same seed and inputs fly the same level exactly', () {
    for (final id in ['1-5', '2-3', '2-8']) {
      final states = [
        for (var i = 0; i < 2; i++)
          () {
            final sim = levelFlight(level(id), weaponDamage: 30);
            final samples = <String>[];
            var frame = 0;
            flyLevel(
              sim,
              watch: (sim) {
                if (++frame % 25 == 0) samples.add(stateOf(sim));
              },
            );
            samples.add(stateOf(sim));
            return samples;
          }(),
      ];
      expect(states[0].length, greaterThan(50));
      expect(states[1], states[0], reason: id);
    }
  });

  test('every attempt lays the same route, however it is flown, on every '
      'phone', () {
    for (final level in playable) {
      final attempts = <List<String>>[];
      final laid = <int>[];
      for (final (width, sprintWhen) in [
        (1.6, (FlightSimulation sim, int frame) => false),
        (2.4, (FlightSimulation sim, int frame) => sim.canSprint),
        (2.0, (FlightSimulation sim, int frame) => frame > 900),
      ]) {
        final sim = levelFlight(level, weaponDamage: 30);
        final seen = <Object>{};
        final route = <String>[], enemies = <String>[];
        final walls = <double>[];
        // No shots on the way: one could meet an enemy as it is laid.
        flyLevel(
          sim,
          viewportWidth: width,
          shootWhen: (sim) => sim.boss != null,
          sprintWhen: sprintWhen,
          watch: (sim) {
            for (final o in sim.obstacles) {
              if (!seen.add(o)) continue;
              route.add(obstacleSignature(sim, o));
              walls.add(sim.distance + o.x);
            }
            // Boss helpers come with the fight, not the route.
            if (sim.boss != null || sim.bossesDefeated > 0) return;
            for (final e in sim.enemies) {
              if (!seen.add(e)) continue;
              // Each enemy leads a wall: name it by that wall.
              final lead = sim.distance + e.x + .55;
              var wall = 0;
              for (var i = 1; i < walls.length; i++) {
                if ((walls[i] - lead).abs() < (walls[wall] - lead).abs()) {
                  wall = i;
                }
              }
              enemies.add('enemy ${e.kind.name} ${e.maxHp} at wall $wall');
            }
          },
        );
        route.addAll(enemies..sort());
        expect(sim.endReason, EndReason.completed, reason: level.id);
        attempts.add(route);
        laid.add(sim.starsLaid);
      }
      expect(attempts[1], attempts[0], reason: level.id);
      expect(attempts[2], attempts[0], reason: level.id);
      expect(laid.toSet(), {
        level.plan
            .route(
              baseSpeed: TapFlyMode().speedFor(0) * .9,
              interval: levelFlight(level).spawnInterval,
            )
            .stars,
      }, reason: level.id);
    }
  });

  test('a cruising bird meets moving passages in the same phase on every '
      'phone', () {
    List<double> phases(double width) {
      final sim = levelFlight(level('1-4'));
      final met = <Obstacle, double>{};
      flyLevel(
        sim,
        viewportWidth: width,
        sprintWhen: (_, _) => false,
        watch: (sim) {
          for (final o in sim.obstacles) {
            if (o.x > FlightSimulation.birdX) continue;
            met.putIfAbsent(o, () => o.angle);
          }
        },
      );
      expect(sim.sprints + sim.ringSprints, 0);
      return met.values.toList();
    }

    final narrow = phases(1.6), wide = phases(2.4);
    expect(narrow.length, 32);
    for (var i = 0; i < narrow.length; i++) {
      expect(narrow[i], closeTo(wide[i], 1e-9));
    }
  });

  test('later chapters are data for now, but their set pieces already fly', () {
    // Chapters 3 to 5 stay locked in this build and the sea and tide are not
    // built, but their gales and shuffled rush paths lay on the route.
    for (final id in ['3-4', '3-6', '5-2', '5-3', '5-7']) {
      final gales = level(id).plan.pieces.where((p) => p.gale).length;
      for (final sprint in [false, true]) {
        final sim = levelFlight(level(id), weaponDamage: 30);
        flyLevel(sim, sprintWhen: (sim, _) => sprint && sim.canSprint);
        expect(sim.endReason, EndReason.completed, reason: id);
        expect(sim.galesBlown, gales, reason: id);
        expect(sim.galesWeathered, gales, reason: id);
        expect(sim.starsLaid, sim.route!.stars, reason: '$id sprint: $sprint');
      }
    }
  });

  test('crossing the finish line completes the level', () {
    final sim = levelFlight(level('1-1'));
    expect(sim.route!.boss, isFalse);
    expect(sim.finishLine, isNull);
    double? laidAt;
    flyLevel(
      sim,
      watch: (sim) {
        if (sim.finishLine != null) laidAt ??= sim.routeSeconds;
      },
    );
    expect(sim.endReason, EndReason.completed);
    final line = sim.finishLine!;
    expect(line.worldX, sim.route!.goal);
    expect(line.x, lessThanOrEqualTo(FlightSimulation.birdX));
    expect(line.crossedAt, sim.elapsed);
    // Laid before it comes into view, clear of the last passage.
    expect(laidAt, lessThan(level('1-1').length - 4));
    expect(sim.starsLaid, 81);
    expect(sim.obstacles.every((o) => o.scored), isTrue);
    expect(sim.routeProgress, 1);
    expect(sim.distanceToGo, 0);
  });

  test('a boss level ends with the boss, then a short glide to the line', () {
    for (final (id, kind, hp) in [
      ('1-8', BossKind.baronBat, 120),
      ('2-8', BossKind.spitterBeetle, 210),
    ]) {
      final sim = levelFlight(level(id), weaponDamage: 30);
      SkyBoss? met;
      double? arrivedAt, lineAt;
      final helpers = <EnemyKind>{};
      var passed = true;
      flyLevel(
        sim,
        watch: (sim) {
          if (sim.boss case final boss? when met == null) {
            met = boss;
            arrivedAt = sim.routeSeconds;
            // No passage was left half-flown.
            expect(passed, isTrue, reason: id);
            expect(sim.starsLaid, sim.route!.stars, reason: id);
          }
          if (met == null) passed = sim.obstacles.every((o) => o.scored);
          if (sim.boss != null) helpers.addAll(sim.enemies.map((e) => e.kind));
          if (sim.finishLine != null) lineAt ??= sim.elapsed;
          if (sim.boss != null) expect(sim.finishLine, isNull, reason: id);
        },
      );
      final boss = met!;
      expect(boss.kind, kind, reason: id);
      expect(boss.maxHp, hp, reason: id);
      expect(boss.debut, isTrue, reason: id);
      expect(boss.upgraded, isFalse, reason: id);
      expect(arrivedAt, closeTo(level(id).length, .05), reason: id);
      expect(sim.bossesDefeated, 1, reason: id);
      expect(sim.endReason, EndReason.completed, reason: id);
      expect(sim.heartPickups, isEmpty, reason: id);
      expect(sim.galesBlown + sim.rushPathsRun, 0, reason: id);
      expect(sim.elapsed - lineAt!, lessThan(7), reason: id);
      if (kind == BossKind.baronBat) {
        // His helpers come from the chapter's bats, never a beetle or moth.
        expect(
          {EnemyKind.simpleBat, EnemyKind.caveBat}.containsAll(helpers),
          isTrue,
        );
      }
    }
  });

  test('a beaten boss cannot fail the level: the bird coasts to the line', () {
    for (final id in ['1-8', '2-8']) {
      // The player either lets go, or taps, shoots and sprints on every
      // frame; neither changes the glide.
      final glides = <String>[];
      for (final tapping in [false, true]) {
        final sim = levelFlight(level(id), weaponDamage: 30);
        flyLevel(sim, until: (sim) => sim.bossesDefeated > 0);
        expect(sim.boss?.defeatedAt, isNotNull, reason: id);
        expect(sim.victoryGlide, isTrue, reason: id);
        sim
          ..hearts = 1
          ..shield = false
          ..invulnerableUntil = 0;
        final flaps = sim.flaps, shots = sim.shots, sprints = sim.sprints;
        final from = sim.birdY;
        var now = sim.lastValidMs;
        var low = from, high = from;
        var bossLeft = false;
        while (sim.phase != RunPhase.ended && sim.elapsed < 400) {
          now += 20;
          sim.apply(
            MovementInput(valid: true, height: .5, flap: tapping),
            touchAt(now),
            now,
          );
          if (tapping) {
            sim.startCharge();
            sim.shoot();
            sim.sprint();
          }
          sim.tick(.02, now);
          bossLeft |= sim.boss == null;
          low = math.min(low, sim.birdY);
          high = math.max(high, sim.birdY);
        }
        expect(bossLeft, isTrue, reason: id);
        expect(sim.endReason, EndReason.completed, reason: '$id $tapping');
        expect(sim.finishLine!.crossed, isTrue, reason: id);
        expect(sim.hearts, 1, reason: id);
        expect(sim.levelStars, greaterThanOrEqualTo(1), reason: id);
        expect((sim.flaps, sim.shots, sim.sprints), (flaps, shots, sprints));
        // It only eases toward the middle, far from either edge.
        expect(low, greaterThanOrEqualTo(math.min(from, .52) - 1e-9));
        expect(high, lessThanOrEqualTo(math.max(from, .52) + 1e-9));
        glides.add(stateOf(sim));
      }
      expect(glides[1], glides[0], reason: id);
    }
  });

  test("a boss level's route marks the boss; the victory glide fills the "
      'rest', () {
    for (final id in ['1-8', '2-8']) {
      final sim = levelFlight(level(id), weaponDamage: 30);
      double? atBoss, laid;
      var last = 0.0, rising = true;
      flyLevel(
        sim,
        watch: (sim) {
          final progress = sim.routeProgress;
          rising &= progress >= last - 1e-9;
          last = progress;
          if (sim.boss != null) atBoss ??= progress;
          if (sim.finishLine != null) laid ??= progress;
        },
      );
      expect(rising, isTrue, reason: id);
      expect(atBoss, closeTo(FinishLine.bossMark, .01), reason: id);
      expect(laid, closeTo(FinishLine.bossMark, .005), reason: id);
      expect(sim.routeProgress, 1, reason: id);
    }
  });

  test('a gale before a boss never holds the boss back', () {
    // The catalog never gives a boss level a set piece (LevelPlan.problem),
    // but the rules stay safe if a plan did: the gale's endless rush
    // schedule must not push the boss away for good.
    final base = level('1-8').plan;
    final plan = LevelPlan(
      id: base.id,
      region: base.region,
      length: 60,
      start: base.start,
      seed: base.seed,
      families: base.families,
      marks: base.marks,
      lineup: base.lineup,
      cadence: base.cadence,
      pieces: const [SetPiece(SetPieceKind.gale, at: 10)],
      boss: base.boss,
    );
    expect(plan.problem, 'boss');
    final sim = FlightSimulation(
      rules: TapFlyMode(),
      practice: false,
      course: FlightCourse.starTrail,
      weaponDamage: 30,
      plan: plan,
    );
    double? arrivedAt;
    flyLevel(
      sim,
      watch: (sim) {
        if (sim.boss != null) arrivedAt ??= sim.routeSeconds;
      },
    );
    expect(sim.galesWeathered, 1);
    expect(arrivedAt, closeTo(60, .05));
    expect(sim.endReason, EndReason.completed);
  });

  test('losing the last heart fails the level with no stars', () {
    final sim = levelFlight(level('1-1'));
    flyLevel(sim, keepAlive: false, flap: false);
    expect(sim.endReason, EndReason.collision);
    expect(sim.hearts, 0);
    expect(sim.levelStars, 0);
    expect(sim.finishLine, isNull);
  });

  test('level stars follow the collected-star marks', () {
    const marks = StarMarks(35, 60);
    expect(marks.rate(finished: false, stars: 81), 0);
    expect(marks.rate(finished: true, stars: 0), 1);
    expect(marks.rate(finished: true, stars: 34), 1);
    expect(marks.rate(finished: true, stars: 35), 2);
    expect(marks.rate(finished: true, stars: 59), 2);
    expect(marks.rate(finished: true, stars: 60), 3);
    expect(marks.rate(finished: true, stars: 81), 3);

    final sim = levelFlight(level('1-1'))..collectedStars = 60;
    expect(sim.levelStars, 0, reason: 'not finished yet');
    sim.end(EndReason.completed);
    expect(sim.levelStars, 3);
    sim.collectedStars = 59;
    expect(sim.levelStars, 2);
    final endless = FlightSimulation(
      rules: TapFlyMode(),
      practice: false,
      course: FlightCourse.starTrail,
    )..collectedStars = 100;
    endless.end(EndReason.completed);
    expect(endless.levelStars, 0);
  });

  test('campaign rules need a touch Star Trail on rules version 41', () {
    final plan = level('1-1').plan;
    for (final make in [
      () => FlightSimulation(
        rules: TapFlyMode(),
        practice: false,
        course: FlightCourse.classic,
        plan: plan,
      ),
      () => FlightSimulation(
        rules: JumpFlyMode(),
        practice: false,
        course: FlightCourse.starTrail,
        plan: plan,
      ),
      () => FlightSimulation(
        rules: TapFlyMode(rulesVersion: 40),
        practice: false,
        course: FlightCourse.starTrail,
        rulesVersion: 40,
        plan: plan,
      ),
    ]) {
      expect(make, throwsArgumentError);
    }
    final endless = FlightSimulation(
      rules: PushUpFlightMode(cycleSeconds: 3),
      practice: true,
    );
    expect(endless.levelId, isNull);
    expect(endless.region, isNull);
    expect(endless.route, isNull);
    expect(endless.routeProgress, 0);
  });

  test('a level holds its region and ramps from its starting clock', () {
    for (final id in ['1-1', '1-5', '2-7']) {
      final sim = levelFlight(level(id));
      expect(sim.region, level(id).region);
      expect(sim.levelId, id);
      final start = level(id).start;
      expect(sim.paceMultiplier, FlightPlan.pace(start));
      expect(sim.gap, TapFlyMode().gapFor((start / 20).floor()));
      flyLevel(sim, seconds: 30);
      expect(sim.paceMultiplier, FlightPlan.pace(start + sim.routeSeconds));
    }
  });

  test('enemies grow tougher with the chapter, not the flight', () {
    final bat = levelFlight(level('1-4'));
    final beetle = levelFlight(level('2-1'));
    final health = <String, Set<int>>{};
    for (final (name, sim) in [('1-4', bat), ('2-1', beetle)]) {
      flyLevel(
        sim,
        seconds: 40,
        watch: (sim) {
          for (final enemy in sim.enemies) {
            health
                .putIfAbsent('$name ${enemy.kind.name}', () => {})
                .add(enemy.maxHp);
          }
        },
      );
    }
    expect(health['1-4 simpleBat'], {10});
    expect(health['2-1 simpleBat'], {15});
    expect(health['2-1 spitterBeetle'], {25});
  });

  test('a paused campaign flight holds its route clock', () {
    final sim = levelFlight(level('1-3'));
    flyLevel(sim, seconds: 10);
    sim.takeBreak();
    expect(sim.phase, RunPhase.paused);
    final at = sim.routeSeconds;
    sim.tick(.02, 1e6);
    expect(sim.routeSeconds, at);
    sim.resume();
    expect(sim.phase, RunPhase.countdown);
  });
}
