import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';

import 'ny_arena.dart';

/// The star economy of the Alley Pigeon (spec section 2, "Numbers for New
/// York"): a level's worst case, which is every pigeon it lays stealing one
/// star because nothing is ever shot, is capped at half the slack between its
/// route stars and its three-star mark, so a player who never shoots can
/// always still earn the third star.

const _bat = EnemyKind.simpleBat, _pigeon = EnemyKind.alleyPigeon;
const _moth = EnemyKind.duskMoth, _beetle = EnemyKind.spitterBeetle;

/// The three levels of the stop that hold pigeons, with the lineups, flocks
/// and run-ups of report 02 (marks from the structure report).
final levels = <String, LevelPlan Function(int seed)>{
  '3-2 run-up': (seed) => rulesPlan(
    id: '3-2',
    length: 30,
    start: 85,
    seed: seed,
    lineup: const [_pigeon, _bat, _pigeon, _moth],
    flocks: const [1, 1, 1],
    marks: const StarMarks(20, 30),
  ),
  '3-3 Steam Alley': (seed) => rulesPlan(
    id: '3-3',
    length: 80,
    start: 100,
    seed: seed,
    lineup: const [_bat, _pigeon, _moth, _beetle, _pigeon, EnemyKind.caveBat],
    flocks: const [1, 2, 2, 2, 2, 2],
    marks: const StarMarks(55, 90),
  ),
  '3-4 run-up': (seed) => rulesPlan(
    id: '3-4',
    length: 30,
    start: 120,
    seed: seed,
    lineup: const [_bat, _pigeon, _moth, _beetle, _pigeon, EnemyKind.caveBat],
    flocks: const [1, 2],
    marks: const StarMarks(20, 30),
  ),
};

/// Route stars, cap and worst case the report gives: (36, 3, 3), (114, 12,
/// 11) and (36, 3, 3).
const expected = <String, (int, int, int)>{
  '3-2 run-up': (36, 3, 3),
  '3-3 Steam Alley': (114, 12, 11),
  '3-4 run-up': (36, 3, 3),
};

void main() {
  test('the cap is half the slack between route stars and the third mark', () {
    expect(AlleyPigeon.thiefCap(routeStars: 36, threeStarMark: 30), 3);
    expect(AlleyPigeon.thiefCap(routeStars: 114, threeStarMark: 90), 12);
    expect(AlleyPigeon.thiefCap(routeStars: 37, threeStarMark: 30), 3);
    expect(AlleyPigeon.thiefCap(routeStars: 36, threeStarMark: 36), 0);
    expect(AlleyPigeon.thiefCap(routeStars: 36, threeStarMark: 40), 0);
    // A worst case at the cap still leaves the mark, with as much again.
    for (var route = 20; route < 140; route += 7) {
      for (var mark = 10; mark < route; mark += 5) {
        final cap = AlleyPigeon.thiefCap(
          routeStars: route,
          threeStarMark: mark,
        );
        expect(route - cap, greaterThanOrEqualTo(mark), reason: '$route/$mark');
      }
    }
  });

  for (final MapEntry(key: name, value: make) in levels.entries) {
    group(name, () {
      test('lays the report\'s pigeons: worst case within the cap', () {
        final (routeStars, cap, worst) = expected[name]!;
        final sim = arenaOf(make(3100));
        expect(sim.route!.stars, routeStars);
        expect(sim.thiefBudget, cap);
        final seen = <SkyEnemy>{};
        runUntil(
          sim,
          (s) => s.phase == RunPhase.ended,
          steer: vacuumY,
          immortal: true,
          seconds: 200,
          watch: (s) => seen.addAll(raiders(s)),
        );
        // Every pigeon of a formation, with no panel to hold one back.
        expect(seen.length, worst);
        expect(seen.length, lessThanOrEqualTo(cap));
      });

      test('a player who never shoots still reaches the third star', () {
        for (var seed = 3100; seed < 3112; seed++) {
          final plan = make(seed);
          final sim = arenaOf(plan);
          runUntil(
            sim,
            (s) => s.phase == RunPhase.ended,
            steer: vacuumY,
            immortal: true,
            seconds: 200,
          );
          final reason = 'seed $seed';
          expect(sim.endReason, EndReason.completed, reason: reason);
          // A perfect collector loses exactly what the thieves got away with.
          expect(
            sim.starsLost,
            lessThanOrEqualTo(sim.thiefBudget),
            reason: reason,
          );
          expect(
            sim.collectedStars,
            sim.starsLaid - sim.starsLost,
            reason: reason,
          );
          expect(sim.starsLaid, sim.route!.stars, reason: reason);
          expect(sim.levelStars, 3, reason: reason);
          expect(sim.collectedStars, greaterThanOrEqualTo(plan.marks.three));
        }
      });

      test('pigeons sit at least four passages apart', () {
        final plan = make(3100);
        final passages = arenaOf(plan).route!.passages.length;
        final at = [
          for (var n = 1; n <= passages; n++)
            if (plan.enemyIndex(n) case final index?
                when plan.lineup[index % plan.lineup.length] == _pigeon)
              n,
        ];
        expect(at, isNotEmpty);
        for (var i = 1; i < at.length; i++) {
          expect(
            at[i] - at[i - 1],
            greaterThanOrEqualTo(4),
            reason: '$name $at',
          );
        }
      });
    });
  }

  test('a plan whose pigeons exceed the cap is held to it', () {
    // Flocks of three on every pigeon entry against a mark two stars short
    // of the route: the cap is 1, whatever the lineup asks.
    final sim = arenaOf(
      rulesPlan(
        flocks: const [3],
        length: 40,
        marks: const StarMarks(10, 49),
        lineup: const [_pigeon],
      ),
    );
    final cap = sim.thiefBudget;
    expect(sim.route!.stars, 51);
    expect(cap, 1);
    var peak = 0;
    runUntil(
      sim,
      (s) => s.phase == RunPhase.ended,
      steer: vacuumY,
      immortal: true,
      seconds: 200,
      watch: (s) {
        expect(s.thievesCommitted + s.starsLost, lessThanOrEqualTo(cap));
        if (s.thievesCommitted > peak) peak = s.thievesCommitted;
      },
    );
    expect(sim.starsLost, lessThanOrEqualTo(cap));
    expect(sim.levelStars, 3);
    expect(sim.starsSnatched, cap);
    expect(peak, 1);
  });

  test('a level with no room above its third mark has harmless pigeons', () {
    // Route stars == the mark: nothing may be taken. The pigeons still fly.
    final probe = arenaOf(rulesPlan(flocks: const [2]));
    final marks = StarMarks(10, probe.route!.stars);
    final sim = arenaOf(rulesPlan(flocks: const [2], marks: marks));
    expect(sim.thiefBudget, 0);
    var sawPigeon = false;
    runUntil(
      sim,
      (s) => s.phase == RunPhase.ended,
      steer: vacuumY,
      immortal: true,
      seconds: 200,
      watch: (s) => sawPigeon |= raiders(s).isNotEmpty,
    );
    expect(sawPigeon, isTrue);
    expect(sim.pigeonWarnings, 0);
    expect(sim.starsSnatched, 0);
    expect(sim.collectedStars, sim.route!.stars);
    expect(sim.levelStars, 3);
  });

  test(
    'shooting wins stars back: a shooter loses fewer than the worst case',
    () {
      final plan = levels['3-3 Steam Alley']!(3100);
      final never = arenaOf(plan, weaponDamage: 30);
      runUntil(
        never,
        (s) => s.phase == RunPhase.ended,
        steer: vacuumY,
        immortal: true,
        seconds: 200,
      );
      // The same level with a gunner who shoots every pigeon that comes.
      final gunner = arenaOf(plan, weaponDamage: 30);
      runUntil(
        gunner,
        (s) => s.phase == RunPhase.ended,
        steer: vacuumY,
        immortal: true,
        seconds: 200,
        watch: (s) {
          for (final e in raiders(s)) {
            if (e.x < 1.9 && e.x > .8 && s.canShoot) {
              s.rocks.add(BirdRock(x: e.x - .04, y: e.y, damage: 30));
            }
          }
        },
      );
      expect(never.starsLost, 11);
      expect(gunner.starsLost, lessThan(never.starsLost));
      expect(gunner.pigeonsDefeated, greaterThan(0));
    },
  );
}
