// New York's star marks, re-derived from the real route code and proven
// reachable by flights: the Alley Pigeon's thefts (capped per level) and the
// steam vents (a vent keeps its passage's three stars) must leave the marks
// where the rules put them: a guardian's run-up has 36 route stars (20 and 30
// for King Coo, 20 and 27 for the Gargoyle), Steam Alley 45 and 70 of 90, Moth
// Light 40 and 65 of 81 (the fix round shortened the last two and moved the
// Gargoyle's third mark: see docs/validation.md).
//
// A star mark is earned by a FINISHED flight: one star for finishing (for a
// guardian's level that means beating him), two or three for collecting the
// marks' number of stars. On a guardian's level the stars are the run-up's
// (nothing is laid after he arrives), so "never shoots" there is about the
// run-up's harvest; a player must shoot to win the fight.
//
// Every proof here is a rate over shoot phases, widths and layouts (the
// review's lesson: a deterministic pilot's single flight proves little).
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/campaign.dart';
import 'package:push_up_bird/domain/game_rules.dart';

import 'campaign_flight.dart' show levelFlight;
import 'ny_arena.dart' show arenaOf, runUntil, vacuumY;
import 'ny_pilots.dart';

const _ids = ['3-1', '3-2', '3-3', '3-4'];
const _screens = {'640': 640 / 360, '800': 800 / 360};

/// The shipped layout and five re-seeded ones (k = 0 is the catalog's).
LevelPlan _layout(String id, int k) {
  final plan = Campaign.level(id)!.plan;
  return k == 0 ? plan : reseeded(plan, k);
}

/// Marks at [low] and [high] of the stars laid, rounded to fives (the
/// campaign's rule from chapter 2 on).
(int, int) _marksFor(int stars) {
  int five(double value) => (value / 5).round() * 5;
  return (five(stars * .5), five(stars * .8));
}

void main() {
  group('the marks come from the real route', () {
    const expected = {
      '3-1': (81, 40, 65),
      '3-2': (36, 20, 30),
      '3-3': (90, 45, 70),
      '3-4': (36, 20, 27),
    };
    for (final id in _ids) {
      test('$id: ${expected[id]}', () {
        final (stars, two, three) = expected[id]!;
        final level = Campaign.level(id)!;
        final sim = levelFlight(level);
        expect(sim.route!.stars, stars);
        expect((level.marks.two, level.marks.three), (two, three));
        // 50% and 80% of the stars laid, rounded to fives, on every level but
        // 3-4, whose third mark is 75% (27 of 36): its steam run-up costs a
        // casual pilot two stars more than 3-2's, and 30 was reached by 38 to
        // 65% of the casual pilots of the review's ladder against 95 to 100%
        // on 3-2 (27: 85 to 100%, as 3-2 at 30). Its thief cap, (36 - 27) / 2
        // = 4, still covers the three pigeons it lays.
        if (id == '3-4') {
          expect(_marksFor(stars).$1, two);
          expect(three, (stars * .75).round());
        } else {
          expect(_marksFor(stars), (two, three));
        }
        // The run-up of a guardian is 12 passages of three stars; a vent
        // keeps its passage's three stars, so steam changes no total.
        expect(sim.route!.stars, 3 * sim.route!.passages.length);
        expect(level.marks.three, lessThan(stars));
        expect(level.plan.problem, isNull);
        final steam = level.plan.steam;
        if (!steam.isEmpty) {
          expect(steam.routeProblem(sim.route!, level.plan.length), isNull);
        }
      });
    }

    test('steam and pigeons take no star off the route', () {
      // The same level without its vents and flocks lays the same route
      // stars, so its marks are the same.
      for (final id in ['3-3', '3-4']) {
        final plan = Campaign.level(id)!.plan;
        final bare = LevelPlan(
          id: plan.id,
          region: plan.region,
          length: plan.length,
          start: plan.start,
          seed: plan.seed,
          families: plan.families,
          lineup: plan.lineup,
          toughness: plan.toughness,
          panels: plan.panels,
          boss: plan.boss,
          marks: plan.marks,
        );
        final a = arenaOf(plan), b = arenaOf(bare);
        expect(a.route!.stars, b.route!.stars, reason: id);
        expect(a.route!.passages, b.route!.passages, reason: id);
      }
    });
  });

  group('thieves leave the third star in reach', () {
    // Worst case, per level: every pigeon that can takes one star because
    // nothing is ever shot (the cap is half the slack between the route's
    // stars and the third mark). A perfect collector that never fires still
    // earns the third star, steam included.
    for (final id in _ids) {
      test('$id: a perfect collector that never shoots, on six layouts', () {
        final level = Campaign.level(id)!;
        for (var k = 0; k < 6; k++) {
          final sim = arenaOf(_layout(id, k));
          runUntil(
            sim,
            (s) => s.boss != null || s.phase == RunPhase.ended,
            steer: vacuumY,
            immortal: true,
            seconds: 200,
            allowEnd: true,
          );
          final reason = '$id layout $k';
          final cap = sim.thiefBudget;
          expect(cap, (sim.route!.stars - level.marks.three) ~/ 2);
          expect(sim.shots, 0, reason: reason);
          expect(sim.starsLost, lessThanOrEqualTo(cap), reason: reason);
          expect(
            sim.collectedStars,
            sim.starsLaid - sim.starsLost,
            reason: reason,
          );
          expect(
            sim.collectedStars,
            greaterThanOrEqualTo(level.marks.three),
            reason: '$reason: ${sim.collectedStars} of ${sim.starsLaid}',
          );
          if (!level.isBoss) {
            expect(sim.endReason, EndReason.completed, reason: reason);
            expect(sim.levelStars, 3, reason: reason);
          }
        }
      });
    }

    test('the caps of the real levels: 8, 3, 10 and 4', () {
      expect(
        [for (final id in _ids) arenaOf(Campaign.level(id)!.plan).thiefBudget],
        [8, 3, 10, 4],
      );
    });
  });

  group('three stars are reachable by mortal pilots, at every phase', () {
    // Six shoot phases at both phones: the rate of three stars, not one
    // flight. 3-3's third mark (70 of 90 stars) is what the pilots that never
    // aim at a ride vent's stars (they collect about 70) only reach in 40 to
    // 80% of the phases at the two phones (at 640 px and 800 px they lose five
    // of the nine stars the pigeons take); the review's planners, who do aim
    // at them, reach it in 96 to 100% (see docs/validation.md).
    for (final id in _ids) {
      test('$id: sharp and average pilots earn three at least '
          '${id == '3-3' ? '30' : '90'}% of the time, casual ones two', () {
        final level = Campaign.level(id)!;
        for (final skill in Skill.values) {
          var n = 0, three = 0, two = 0;
          for (final width in _screens.values) {
            for (final phase in spreadPhases(6)) {
              final run = flyNewYork(
                id,
                skill: skill,
                width: width,
                phase: phase,
              );
              n++;
              expect(run.finished, isTrue, reason: '$id ${skill.name}');
              if (run.sim.levelStars == 3) three++;
              if (run.sim.levelStars >= 2) two++;
              // A guardian's stars are the run-up's.
              final harvest = level.isBoss
                  ? run.starsAtBoss!
                  : run.sim.collectedStars;
              expect(run.sim.collectedStars, harvest);
            }
          }
          expect(two / n, greaterThanOrEqualTo(.95), reason: skill.name);
          if (skill != Skill.casual) {
            final floor = id == '3-3' ? .3 : .9;
            expect(
              three / n,
              greaterThanOrEqualTo(floor),
              reason: '$id ${skill.name}: $three of $n',
            );
          }
        }
      });
    }
  });

  group('one star is for finishing, none for falling', () {
    test('a finished flight earns one star whatever it collected', () {
      for (final id in _ids) {
        final marks = Campaign.level(id)!.marks;
        expect(marks.rate(finished: true, stars: 0), 1, reason: id);
        expect(marks.rate(finished: true, stars: marks.two - 1), 1);
        expect(marks.rate(finished: true, stars: marks.two), 2);
        expect(marks.rate(finished: true, stars: marks.three - 1), 2);
        expect(marks.rate(finished: true, stars: marks.three), 3);
        expect(marks.rate(finished: false, stars: marks.three), 0);
      }
    });

    test('a guardian\'s level without the guardian beaten earns nothing', () {
      for (final id in ['3-2', '3-4']) {
        // A bird that reaches him with every star and then falls: no mark.
        final run = flyNewYork(
          id,
          width: _screens['800']!,
          keepAlive: true,
          stopAtBoss: true,
        );
        final sim = run.sim;
        expect(
          run.starsAtBoss,
          greaterThanOrEqualTo(Campaign.level(id)!.marks.three),
          reason: id,
        );
        expect(sim.boss, isNotNull, reason: id);
        expect(sim.levelStars, 0, reason: '$id: not finished yet');
        sim.end(EndReason.collision);
        expect(sim.levelStars, 0, reason: '$id: knocked out');
      }
    });
  });

  group('a player who never shoots still reaches two stars', () {
    // The pilots cannot survive a level without shooting (the shared bot
    // dodges by shooting, in every chapter), so these keep their hearts: the
    // question is the economy, not the dodging. On a guardian's level the
    // run-up's stars are the harvest (and the fight must be shot to be won).
    // Six layouts at both phones: the thieves, doors and vents differ.
    for (final id in _ids) {
      test('$id, on six layouts at both phones', () {
        final level = Campaign.level(id)!;
        for (final width in _screens.values) {
          for (var k = 0; k < 6; k++) {
            final run = flyNewYork(
              id,
              width: width,
              shoots: false,
              keepAlive: true,
              stopAtBoss: level.isBoss,
              plan: _layout(id, k),
            );
            final sim = run.sim;
            final harvest = level.isBoss
                ? run.starsAtBoss!
                : sim.collectedStars;
            final reason = '$id layout $k at $width: $harvest';
            expect(sim.shots, 0, reason: 'never fires');
            expect(
              harvest,
              greaterThanOrEqualTo(level.marks.two),
              reason: reason,
            );
            // The worst case of the thieves stays within their cap.
            expect(sim.starsLost, lessThanOrEqualTo(sim.thiefBudget));
            if (!level.isBoss) {
              expect(sim.endReason, EndReason.completed, reason: reason);
              expect(sim.levelStars, greaterThanOrEqualTo(2), reason: reason);
            }
          }
        }
      });
    }
  });
}
