// New York's four levels (the catalog's 3-1 to 3-4) flown end to end by the
// whole-level pilots of `ny_pilots.dart`: every level is completed, both
// guardians are beaten, and what the fights cost is written to the test log
// as a table (fight lengths in combat seconds; add the 4.6 s arrival and the
// 3.8 s defeat for the whole encounter).
//
// The pilots are mortal and fire the base weapon the campaign really gives
// (10 damage; nothing in the game upgrades it today). A sharp pilot reacts
// after .4 s and taps up to five times a second, an average one after .6 s
// and 3.5 times, a casual one after .9 s and 2.5 times with one shot in
// 0.75 s and no charged shots; in a guardian's fight they are R2's CooBot
// and R3's Pilot at three tempos.
@Timeout(Duration(minutes: 12))
library;

import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/campaign.dart';
import 'package:push_up_bird/domain/game_rules.dart';

import 'ny_pilots.dart';

const _ids = ['3-1', '3-2', '3-3', '3-4'];
const _screens = {'640': 640 / 360, '800': 800 / 360};

/// Flights are deterministic, so every test shares one run of a flight.
final _runs = <String, NyRun>{};
NyRun _fly(
  String id,
  Skill skill,
  double width, {
  bool keepAlive = false,
  int damage = BirdRock.baseDamage,
  bool sprints = true,
}) => _runs.putIfAbsent(
  '$id ${skill.name} $width $keepAlive $damage $sprints',
  () => flyNewYork(
    id,
    skill: skill,
    width: width,
    keepAlive: keepAlive,
    weaponDamage: damage,
    sprints: sprints,
  ),
);

String _row(String id, String screen, Skill skill, NyRun run) {
  final sim = run.sim;
  return '${id.padRight(3)} ${screen.padLeft(3)} ${skill.name.padRight(7)} '
      '${(sim.endReason?.name ?? '-').padRight(9)} '
      'stars ${sim.collectedStars}/${sim.starsLaid} (${sim.levelStars}*) '
      'hearts ${sim.hearts} (low ${run.minHearts}) '
      'thefts ${sim.starsSnatched} lost ${sim.starsLost} '
      'steam ${sim.steamBursts} scalds ${sim.steamScalds} '
      '${run.fight == null ? '' : 'fight ${run.fight!.toStringAsFixed(1)} s '}'
      't ${run.seconds.toStringAsFixed(1)} s';
}

void main() {
  group('every New York level is completed by a mortal pilot', () {
    for (final id in _ids) {
      for (final MapEntry(key: screen, value: width) in _screens.entries) {
        for (final skill in Skill.values) {
          test('$id at $screen, ${skill.name}', () {
            final run = _fly(id, skill, width);
            final sim = run.sim;
            final level = Campaign.level(id)!;
            // ignore: avoid_print
            print(_row(id, screen, skill, run));
            // From rules 45 King Coo (his vanguard throwing, his health
            // doubled, his stragglers back, as the owner chose) fells most
            // mortal pilots; `ny_levels_spread_test` holds the rates.
            if (id == '3-2' && !run.finished) {
              expect(sim.endReason, EndReason.collision);
              // Paired stragglers can fell a pilot that reached the boss
              // with all three hearts, too.
              expect(run.minHearts, 0);
              return;
            }
            expect(sim.endReason, EndReason.completed);
            expect(sim.finishLine!.crossed, isTrue);
            expect(sim.starsLaid, sim.route!.stars);
            expect(sim.levelStars, inInclusiveRange(1, 3));
            expect(sim.bossesDefeated, level.isBoss ? 1 : 0);
            expect(sim.boss?.kind ?? level.boss, level.boss);
            expect(run.minHearts, greaterThanOrEqualTo(1));
            // Pigeons come from 3-2 on, steam from 3-3; nothing before.
            expect(sim.pigeonWarnings > 0, id != '3-1', reason: 'pigeons');
            // One burst per vent passed: seven in Steam Alley, three in the
            // Gargoyle's run-up.
            expect(sim.steamBursts, {'3-3': 7, '3-4': 3}[id] ?? 0);
            // The flight ends where the level says: a boss's run-up is 30 s,
            // a finish line the level's length.
            if (!level.isBoss) {
              expect(sim.routeSeconds, greaterThanOrEqualTo(level.length - 1));
            }
          });
        }
      }
    }
  });

  group('the guardians fall', () {
    for (final kind in [BossKind.kingCoo, BossKind.searchlightGargoyle]) {
      final id = kind == BossKind.kingCoo ? '3-2' : '3-4';
      final hp = SkyBoss.campaignHealthFor(kind);
      // What each skill's fight takes, in combat seconds. Rules 44 made the
      // guardians' fights long and staged (200 health for the Gargoyle) and
      // 45 doubled King Coo's (840) and sends his stragglers back: the bots
      // measured King Coo at about 100 / 155 / 210 s. Rules 46 made the
      // Gargoyle as long (640 health, feathers over his open lamp): about
      // 107 / 134 to 144 / 323 to 350 s (27 / 68 / 130 s at 44 and 45; his
      // lamp is open 29% of the time, so the slowest shot takes longest).
      // (At 43, with 140 and 160, the report's model was Coo 18 / 31 / 59 s
      // and Gargoyle 35 / 62 / 133 s.) King Coo's pilots fly with their
      // hearts topped up: from 45 he fells some of them, and this is his
      // fight's length, not their survival (`ny_levels_spread_test`).
      final keepAlive = kind == BossKind.kingCoo;
      final bands = switch (kind) {
        BossKind.kingCoo => {
          Skill.sharp: (75.0, 135.0),
          Skill.average: (115.0, 200.0),
          Skill.casual: (160.0, 270.0),
        },
        _ => {
          Skill.sharp: (85.0, 135.0),
          Skill.average: (110.0, 185.0),
          Skill.casual: (270.0, 420.0),
        },
      };
      for (final MapEntry(key: screen, value: width) in _screens.entries) {
        for (final skill in Skill.values) {
          final (least, most) = bands[skill]!;
          test('${kind.name} at $screen, ${skill.name}: $least to $most s', () {
            final run = _fly(id, skill, width, keepAlive: keepAlive);
            final sim = run.sim;
            final boss = run.boss!;
            expect(boss.kind, kind);
            expect(boss.maxHp, hp);
            expect(boss.phase, BossPhase.defeated);
            expect(run.fight, isNotNull);
            expect(run.fight, inInclusiveRange(least, most));
            // A pilot that reads the telegraphs is hit by nothing either
            // guardian throws, and the cause of EVERY hit is checked, not only
            // the counters (the shield would hide a hit from them). The
            // casual King Coo bot was hit by his squadron in 31 of 32 fights
            // until R2's fix round showed that was its policy, not the rules;
            // the rates over shoot phases are in `ny_levels_spread_test`.
            // From rules 45 King Coo's fight is long and his stragglers come
            // back throwing: his crumb rings, his squadron and the
            // stragglers catch a pilot a few times a fight; never anything
            // else.
            if (boss.isKingCoo) {
              expect(
                run.fightHits.map((hit) => hit.cause),
                everyElement(
                  anyOf(
                    'crumb-cloud',
                    'squad-pigeon',
                    'pigeon-crumb',
                    'enemy-vanguard',
                  ),
                ),
              );
              expect(run.fightHits.length, lessThanOrEqualTo(12));
            } else {
              expect(run.fightHits, isEmpty, reason: '${run.fightHits}');
            }
            if (boss.isGargoyle) {
              expect(boss.spots, 0);
            } else if (!keepAlive) {
              expect(sim.hearts, greaterThanOrEqualTo(run.heartsAtBoss!));
            }
            // The fight used his whole repertoire.
            if (boss.isKingCoo) {
              expect(boss.lobsLaunched, greaterThanOrEqualTo(2));
            } else {
              expect(boss.sweepsAimed, greaterThanOrEqualTo(2));
            }
          });
        }
      }

      test('${kind.name}: slower players take longer', () {
        for (final MapEntry(value: width) in _screens.entries) {
          final times = [
            for (final skill in Skill.values)
              _fly(id, skill, width, keepAlive: keepAlive).fight!,
          ];
          expect(times[1], greaterThan(times[0]), reason: '$times');
          expect(times[2], greaterThan(times[1]), reason: '$times');
        }
      });
    }
  });

  group('sprint in the guardians\' levels', () {
    test('King Coo\'s level offers it and his fight is proof against it', () {
      // A pilot that hammers sprint through the run-up and his whole fight,
      // against one that never presses it: both win with at most three
      // crumb hits, and the boss's hazards keep their timing. From rules 56
      // paired stragglers make their routes (and hit counts) diverge.
      final width = _screens['800']!;
      // Hearts topped up: from rules 45 his fight fells some average pilots,
      // and this is about what a sprint changes, not survival.
      final calm = flyNewYork(
        '3-2',
        skill: Skill.average,
        width: width,
        sprints: false,
        keepAlive: true,
      );
      var inFight = 0;
      final hasty = flyNewYork(
        '3-2',
        skill: Skill.average,
        width: width,
        keepAlive: true,
        sprintsInFights: true,
        watch: (sim) {
          if (sim.boss?.phase == BossPhase.attacking && sim.sprinting) {
            inFight++;
          }
        },
      );
      expect(hasty.sim.offersSprint, isTrue);
      expect(calm.sim.sprints, 0);
      expect(hasty.sim.sprints, greaterThan(2));
      expect(inFight, greaterThan(60), reason: 'he fought a sprinting bird');
      for (final run in [calm, hasty]) {
        expect(run.sim.endReason, EndReason.completed);
        // From rules 45 his long fury catches a pilot now and then, sprinting
        // or not.
        expect(run.boss!.crumbHits, lessThanOrEqualTo(3));
      }
      // His clock is his own: the rings lock at the same cycle times.
      // Up to his fury: a long fight (rules 45) reaches it at different
      // times for different pilots, and fury locks its rings on its own beat.
      List<String> locks(NyRun run) => [
        for (final lob in run.boss!.lobs.takeWhile((lob) => !lob.fury))
          lob.lockedAt.toStringAsFixed(6),
      ];
      final shared = math.min(locks(calm).length, locks(hasty).length);
      expect(shared, greaterThan(4));
      expect(locks(hasty).take(shared), locks(calm).take(shared));
    });

    test(
      'the Gargoyle\'s level refuses it: no sprint, whatever is pressed',
      () {
        final level = Campaign.level('3-4')!;
        expect(level.plan.sprint, isFalse);
        final run = flyNewYork(
          '3-4',
          skill: Skill.sharp,
          width: _screens['800']!,
          watch: (sim) {
            // Every frame the player hammers the key.
            expect(sim.canSprint, isFalse);
            expect(sim.sprint(), isFalse);
          },
        );
        expect(run.sim.offersSprint, isFalse);
        expect(run.sim.sprints, 0);
        expect(run.sim.ringSprints, 0);
        expect(run.sim.endReason, EndReason.completed);
        // The same flight that never pressed it: nothing differs.
        final plain = _fly('3-4', Skill.sharp, _screens['800']!);
        expect(run.sim.elapsed, plain.sim.elapsed);
        expect(run.sim.score, plain.sim.score);
        expect(run.sim.collectedStars, plain.sim.collectedStars);
      },
    );

    test('Steam Alley and Moth Light offer sprint like any level', () {
      for (final id in ['3-1', '3-3']) {
        final run = _fly(id, Skill.sharp, _screens['800']!);
        expect(run.sim.offersSprint, isTrue, reason: id);
        expect(run.sim.sprints, greaterThan(0), reason: id);
      }
    });
  });
}
