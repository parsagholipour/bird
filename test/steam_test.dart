import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';

import 'campaign_flight.dart' show obstacleSignature;
import 'ny_arena.dart';

/// The steam geysers' rules (spec `reports/03-steam-geysers.md` section 2):
/// where a vent is laid and how tall its plume stands, the hit box and the
/// scald, the lift and the ride, the score, what Sprint does not do, the
/// boss clearing, and that the route of a level is the same with and without
/// its steam. The fairness proof is in `steam_reach_test`, replay and seek in
/// `steam_replay_test`, the pure cycle in `steam_geyser_scaffold_test`.

const hit = SteamCycle.hitHalfWidth;

/// Steam Alley's shape (80 s, eight slots, hop and ride alternating) with
/// no enemies, so a vent is all the level has to say.
LevelPlan alley({
  SteamPlan steam = SteamPlan.steady,
  double length = 80,
  List<EnemyKind> lineup = const [],
  BossKind? boss,
  int seed = 3103,
}) => rulesPlan(
  id: '3-3',
  length: length,
  start: 100,
  seed: seed,
  lineup: lineup,
  steam: steam,
  boss: boss,
  marks: const StarMarks(55, 90),
);

/// Takes the walls, stars and pickups out of the way, so a scene holds only
/// the steam.
void clearAway(FlightSimulation sim) {
  sim.obstacles.clear();
  sim.stars.clear();
  sim.starTrios.clear();
}

/// Holds a bird at [y] while it passes the [index]th vent of [plan] (from 0),
/// with the route clock moved on by [shift] seconds so the vent meets it in
/// another state, and returns the flight once the vent is behind it.
FlightSimulation passVent(
  LevelPlan plan,
  int index, {
  required double Function(SteamVent vent) y,
  double shift = 0,
  bool shield = true,
  int hearts = 3,
  void Function(FlightSimulation sim, SteamVent vent)? watch,
  bool clear = true,
}) {
  final sim = arenaOf(plan);
  final geyser = sim.route!.geysers[index];
  runUntil(
    sim,
    (s) => s.steamVents.any((v) => v.geyser == geyser),
    holdY: .3,
    immortal: true,
    watch: clear ? clearAway : null,
  );
  // The books start at this vent: whatever earlier vents did is forgotten.
  sim
    ..shield = shield
    ..hearts = hearts
    ..score = 0
    ..steamHisses = 0
    ..steamBursts = 0
    ..steamRides = 0
    ..steamScalds = 0
    ..steamClears = 0
    ..routeSeconds += shift
    ..invulnerableUntil = 0;
  final vent = sim.steamVents.firstWhere((v) => v.geyser == geyser);
  runUntil(
    sim,
    (s) => vent.x < birdX - hit - FlightSimulation.birdRadius - .05,
    steer: (s) => y(vent),
    allowEnd: hearts <= 1,
    watch: (s) {
      if (clear) clearAway(s);
      watch?.call(s, vent);
    },
  );
  return sim;
}

void main() {
  group('laying', () {
    test('a vent takes the wall, stars and place of its slot passage', () {
      final plan = alley();
      final sim = arenaOf(plan);
      final route = sim.route!;
      expect(route.geysers, hasLength(8));
      final laid = <int>{};
      final top = <int, double>{};
      runUntil(
        sim,
        (s) => s.phase == RunPhase.ended,
        steer: vacuumY,
        immortal: true,
        seconds: 200,
        watch: (s) {
          for (final v in s.steamVents) {
            if (laid.add(v.geyser.slot)) top[v.geyser.slot] = v.top;
            // Exactly where its place on the route puts it.
            expect(v.x, closeTo(v.geyser.x - s.distance, 1e-9));
          }
        },
      );
      expect(laid, {4, 8, 12, 16, 20, 24, 28, 32});
      // The slot keeps its three stars and its count: route stars and marks
      // do not change.
      expect(sim.starsLaid, route.stars);
      expect(sim.starsLaid, 114);
      expect(sim.endReason, EndReason.completed);
    });

    test(
      'a slot passage has no wall: one wall fewer per vent, the rest alike',
      () {
        Set<String> walls(LevelPlan plan) {
          final seen = <String>{};
          final sim = arenaOf(plan);
          runUntil(
            sim,
            (s) => s.phase == RunPhase.ended,
            holdY: .5,
            immortal: true,
            seconds: 200,
            watch: (s) {
              for (final o in s.obstacles) {
                seen.add(obstacleSignature(s, o));
              }
            },
          );
          seen.add('next draw ${sim.random.nextInt(1 << 30)}');
          seen.add('passages ${sim.route!.passages.length}');
          return seen;
        }

        // Bats on the other passages so enemies are in the comparison too.
        final lineup = const [EnemyKind.simpleBat, EnemyKind.caveBat];
        final withSteam = walls(alley(lineup: lineup));
        final without = walls(alley(steam: SteamPlan.none, lineup: lineup));
        expect(
          without.difference(withSteam),
          hasLength(8),
          reason: 'the eight slots',
        );
        expect(withSteam.difference(without), isEmpty);
      },
    );

    test(
      'the route is the same with and without steam, and so are the enemies',
      () {
        const lineup = [
          EnemyKind.simpleBat,
          EnemyKind.caveBat,
          EnemyKind.duskMoth,
        ];
        Set<String> enemies(LevelPlan plan) {
          final seen = <String>{};
          final sim = arenaOf(plan);
          runUntil(
            sim,
            (s) => s.phase == RunPhase.ended,
            holdY: .5,
            immortal: true,
            seconds: 200,
            watch: (s) {
              for (final e in s.enemies) {
                seen.add(
                  '${e.kind.name} ${e.maxHp} ${(s.distance + e.x).toStringAsFixed(1)}',
                );
              }
            },
          );
          return seen;
        }

        final withSteam = enemies(alley(lineup: lineup));
        final without = enemies(alley(steam: SteamPlan.none, lineup: lineup));
        expect(withSteam, without);
        expect(withSteam, isNotEmpty);
        final a = arenaOf(alley(lineup: lineup)).route!;
        final b = arenaOf(alley(steam: SteamPlan.none, lineup: lineup)).route!;
        expect(a.passages, b.passages);
        expect(a.due, b.due);
        expect(a.stars, b.stars);
        expect(a.goal, b.goal);
      },
    );

    test('a hop vent\'s plume top follows the spec, a ride vent\'s too', () {
      // First hops are stubs, later ones taller; the ride lands on the aim.
      double hop(double c, double prev, int k) => SteamCycle.hopTop(c, prev, k);
      expect(
        hop(.50, .50, 0),
        closeTo(.58, 1e-12),
        reason: 'c - .06 = .44 -> T_min .58',
      );
      expect(hop(.72, .72, 0), closeTo(.64, 1e-12), reason: 'capped at .64');
      expect(hop(.70, .50, 0), closeTo(.64, 1e-12));
      expect(
        hop(.60, .50, 3),
        closeTo(.54, 1e-12),
        reason: 'c - .06 above T_min .46',
      );
      expect(
        hop(.50, .50, 3),
        closeTo(.46, 1e-12),
        reason: 'T_min .58 - .04 x 3',
      );
      expect(hop(.30, .30, 9), closeTo(.42, 1e-12), reason: 'never above .42');
      // After a low gate the top may not stay far above it.
      expect(hop(.30, .72, 3), closeTo(.50, 1e-12), reason: 'prev - .22');
      expect(hop(.30, .72, 0), closeTo(.58, 1e-12));
      expect(SteamCycle.rideTop(.30), .50);
      expect(SteamCycle.rideTop(.50), closeTo(.54, 1e-12));
      expect(SteamCycle.rideTop(.72), .62);
      expect(
        SteamCycle.top(SteamKind.hop, centre: .4, previous: .4, ordinal: 1),
        SteamCycle.hopTop(.4, .4, 1),
      );
      expect(
        SteamCycle.top(SteamKind.ride, centre: .4, previous: .9, ordinal: 1),
        SteamCycle.rideTop(.4),
      );
      // Over any centres, the top never stands above .42 or below .64.
      for (var c = .28; c <= .72; c += .02) {
        for (var prev = .28; prev <= .72; prev += .02) {
          for (var k = 0; k < 12; k++) {
            final t = hop(c, prev, k);
            expect(t, inInclusiveRange(.42, .64));
            expect(t, greaterThanOrEqualTo(prev - .22 - 1e-12));
          }
        }
      }
    });

    test(
      'the vents of a flight stand where the rule puts them, stars above',
      () {
        for (final seed in [3103, 3104, 3105]) {
          final plan = alley(seed: seed);
          final sim = arenaOf(plan);
          final checked = <int>{};
          var hops = 0;
          runUntil(
            sim,
            (s) => s.phase == RunPhase.ended,
            steer: vacuumY,
            immortal: true,
            seconds: 200,
            watch: (s) {
              for (final v in s.steamVents) {
                if (!checked.add(v.geyser.slot)) continue;
                final g = v.geyser;
                if (g.kind == SteamKind.hop) {
                  final least = math.max(.42, .58 - .04 * hops);
                  expect(
                    v.top,
                    inInclusiveRange(least - 1e-9, .64),
                    reason: 'seed $seed slot ${g.slot}',
                  );
                  hops++;
                } else {
                  expect(
                    v.top,
                    inInclusiveRange(.50, .62),
                    reason: 'seed $seed slot ${g.slot}',
                  );
                }
                // Three stars on an arc above the plume, never inside it.
                final arc = s.stars.where((star) {
                  return (star.x - v.x - SteamCycle.starsX[0]).abs() < .02 ||
                      (star.x - v.x - SteamCycle.starsX[1]).abs() < .02 ||
                      (star.x - v.x - SteamCycle.starsX[2]).abs() < .02;
                }).toList();
                expect(arc, hasLength(3), reason: 'seed $seed slot ${g.slot}');
                for (final star in arc) {
                  expect(
                    star.y + SkyStar.radius,
                    lessThan(v.top),
                    reason: 'above the plume',
                  );
                  expect(star.y, closeTo(v.top - .14, .06));
                  expect(star.trio, isNotNull);
                }
              }
            },
          );
          expect(checked, hasLength(8), reason: 'seed $seed');
          expect(hops, 4);
        }
      },
    );

    test(
      'a hop vent lands after the previous gate: the climb out is bounded',
      () {
        // Over many levels: a hop's plume top is never higher than the climb
        // from the previous gate's exit allows (prev - .22, floor .42).
        for (var seed = 3100; seed < 3140; seed++) {
          final sim = arenaOf(alley(seed: seed, length: 40));
          final before = <int, double>{};
          runUntil(
            sim,
            (s) => s.phase == RunPhase.ended,
            holdY: .5,
            immortal: true,
            seconds: 200,
            watch: (s) {
              for (final v in s.steamVents) {
                if (before.containsKey(v.geyser.slot)) continue;
                final prev = s.obstacles
                    .where((o) => o.x + s.distance < v.geyser.x - .1)
                    .fold<Obstacle?>(
                      null,
                      (a, o) => a == null || o.x > a.x ? o : a,
                    );
                before[v.geyser.slot] = prev?.baseCenter ?? .5;
                if (v.kind == SteamKind.hop && prev != null) {
                  expect(
                    v.top,
                    greaterThanOrEqualTo(prev.baseCenter - .22 - 1e-9),
                    reason: 'seed $seed',
                  );
                }
              }
            },
          );
        }
      },
    );
  });

  group('the hot burst', () {
    test('scalds a bird in the column: the shield first, once per burst', () {
      final sim = passVent(alley(), 0, y: (v) => v.top + .15);
      expect(sim.steamScalds, 1);
      expect(sim.shield, isFalse);
      expect(sim.hearts, 3);
      expect(sim.steamClears, 0, reason: 'scalded: no hop point');
      expect(sim.recoveryRemaining, greaterThanOrEqualTo(0));
    });

    test('then a heart, with the usual 1.5 s recovery', () {
      final sim = passVent(alley(), 0, y: (v) => v.top + .15, shield: false);
      expect(sim.steamScalds, 1);
      expect(sim.hearts, 2);
      // The next hop vent (slot 12) costs a heart again.
      final next = passVent(alley(), 2, y: (v) => v.top + .15, shield: false);
      expect(next.hearts, 2);
      expect(next.steamScalds, 1);
      // A bird down to its last heart that is scalded ends the flight.
      final last = passVent(
        alley(),
        0,
        y: (v) => v.top + .15,
        shield: false,
        hearts: 1,
      );
      expect(last.hearts, 0);
      expect(last.phase, RunPhase.ended);
      expect(last.endReason, EndReason.collision);
    });

    test('a bird in recovery is not scalded again and earns no hop point', () {
      late FlightSimulation sim;
      sim = passVent(
        alley(),
        0,
        y: (v) => v.top + .15,
        shield: false,
        watch: (s, v) {
          if (s.steamScalds == 1) s.invulnerableUntil = s.elapsed + 10;
        },
      );
      expect(sim.steamScalds, 1);
      expect(sim.hearts, 2);
      expect(sim.steamClears, 0);
    });

    test('a bird above the plume passes unscathed and earns a point', () {
      late int score;
      final sim = passVent(
        alley(),
        0,
        y: (v) => v.top - .10,
        watch: (s, v) => score = s.score,
      );
      expect(sim.steamScalds, 0);
      expect(sim.shield, isTrue);
      expect(sim.hearts, 3);
      expect(sim.steamClears, 1);
      // Only the hop point: nothing else moved the score in this scene.
      expect(score, SteamCycle.hopPoints);
    });

    test('the column ends at the vent\'s mouth: a bird below it is clear', () {
      // A cover vent (plume top from .47): its mouth is at .915.
      final sim = passVent(
        alley(),
        0,
        y: (v) => v.top >= SteamCycle.stackBelow ? .955 : .3,
      );
      expect(arenaOf(alley()).route!.geysers[0].kind, SteamKind.hop);
      expect(sim.steamScalds, 0);
      expect(sim.steamClears, 1, reason: 'it never touched the column');
    });

    test('the hit box is the drawn column: a bird and a half-width wide', () {
      // The first touch comes no sooner than when the vent is a half-width
      // and a bird radius away, from the side the course brings it.
      double? away;
      passVent(
        alley(),
        0,
        y: (v) => v.top + .15,
        watch: (s, v) {
          if (away == null && s.steamScalds == 1) away = v.x - birdX;
        },
      );
      expect(away, isNotNull);
      expect(
        away!,
        lessThanOrEqualTo(hit + FlightSimulation.birdRadius + 1e-9),
      );
      // (The plume is still rising as it arrives, so it is hit a little
      // later than that; never sooner.)
      expect(away!, greaterThan(0));
    });

    test(
      'the top of the column is the plume top: a bird\'s circle clears it',
      () {
        // Just above: the bird's circle passes over the standing plume.
        // Just inside: the circle reaches it.
        const r = FlightSimulation.birdRadius;
        final over = passVent(alley(), 0, y: (v) => v.top - r - .004);
        final into = passVent(alley(), 0, y: (v) => v.top - r + .004);
        expect(over.steamScalds, 0);
        expect(over.steamClears, 1);
        expect(into.steamScalds, 1);
      },
    );

    for (final shift in [-.6, .55, .8, 1.9, 2.4]) {
      test(
        'only the burst scalds: a vent met $shift s off its cycle does not',
        () {
          // The route clock moved on: at arrival the vent is hissing,
          // billowing or asleep instead of bursting.
          final sim = passVent(alley(), 0, y: (v) => v.top + .15, shift: shift);
          expect(sim.steamScalds, 0, reason: 'shift $shift');
          expect(sim.shield, isTrue);
        },
      );
    }

    test(
      'a burst met a little early or late still scalds inside its half second',
      () {
        var scalded = 0;
        for (final shift in [-.3, -.2, 0.0, .2]) {
          final sim = passVent(alley(), 0, y: (v) => v.top + .15, shift: shift);
          scalded += sim.steamScalds;
        }
        expect(scalded, greaterThan(0));
      },
    );

    test('a ride vent\'s soft steam never scalds', () {
      for (final shift in [-.5, 0.0, .3]) {
        final sim = passVent(alley(), 1, y: (v) => v.top + .15, shift: shift);
        expect(sim.steamScalds, 0, reason: 'shift $shift');
        expect(sim.shield, isTrue);
        expect(sim.hearts, 3);
      }
    });

    test(
      'Sprint does not smash steam: the vent stands and scalds a sprinter',
      () {
        late SteamVent seen;
        var rammingAtVent = false;
        final sim = passVent(
          alley(),
          0,
          y: (v) => v.top + .15,
          watch: (s, v) {
            seen = v;
            // A sprint kept up for the whole approach.
            if (s.elapsed - s.lastSprintAt > .8 && v.x - birdX < 1.2) {
              s.lastSprintAt = s.elapsed;
            }
            if ((v.x - birdX).abs() < .09 && s.ramming) rammingAtVent = true;
          },
        );
        expect(rammingAtVent, isTrue, reason: 'it sprinted into the column');
        expect(sim.steamScalds, 1);
        expect(seen.scalded, isTrue);
      },
    );

    test(
      'a sprinter, a ring sprinter and a cruiser meet the vent in one state',
      () {
        final phases = <String, SteamPhase>{};
        for (final mode in ['cruise', 'sprint', 'ring']) {
          final sim = arenaOf(alley());
          final geyser = sim.route!.geysers[0];
          runUntil(
            sim,
            (s) => s.steamVents.any((v) => v.geyser == geyser),
            holdY: .3,
            immortal: true,
            watch: clearAway,
          );
          final vent = sim.steamVents.first;
          SteamPhase? at;
          runUntil(
            sim,
            (s) {
              if (at == null && vent.x <= birdX) {
                at = vent.phaseAt(s.routeSeconds);
              }
              return vent.x < birdX - .3;
            },
            holdY: .3,
            immortal: true,
            watch: (s) {
              clearAway(s);
              if (mode == 'sprint' && s.canSprint) s.sprint();
              if (mode == 'ring' && !s.ringSprinting) {
                s.ringSprintFrom = s.elapsed;
                s.ringSprintUntil = s.elapsed + 2;
              }
            },
          );
          phases[mode] = at!;
        }
        expect(phases['cruise'], SteamPhase.burst);
        expect(phases['sprint'], phases['cruise']);
        expect(phases['ring'], phases['cruise']);
      },
    );
  });

  group('the cool billow', () {
    test('lifts a bird under the plume\'s line and pays a ride two points', () {
      late double fastest;
      fastest = 0;
      final sim = passVent(
        alley(),
        1,
        y: (v) => v.top + .10,
        watch: (s, v) {
          if (s.velocity < fastest) fastest = s.velocity;
        },
      );
      expect(sim.steamRides, 1);
      expect(sim.score, SteamCycle.ridePoints);
      expect(fastest, lessThan(-.3), reason: 'the billow pushes up');
      expect(fastest, greaterThanOrEqualTo(-SteamCycle.liftSpeed - 1e-9));
      expect(sim.steamScalds, 0);
    });

    test('never lifts a bird above the plume top minus a margin', () {
      // A bird held above the line gets nothing: no lift, no ride points.
      var fastest = 0.0;
      final sim = passVent(
        alley(),
        1,
        y: (v) => v.top - SteamCycle.liftMargin - .02,
        watch: (s, v) {
          if (s.velocity < fastest) fastest = s.velocity;
        },
      );
      expect(fastest, 0, reason: 'nothing pushed it up');
      expect(sim.steamRides, 0);
      expect(sim.score, 0);
    });

    test('lifts only inside its column and only while it billows', () {
      // Out of the column (a whole lift half-width and more aside), or met
      // in another phase: no lift.
      for (final shift in [.9, 1.6, -.8]) {
        var fastest = 0.0;
        passVent(
          alley(),
          1,
          y: (v) => v.top + .10,
          shift: shift,
          watch: (s, v) {
            if (s.velocity < fastest) fastest = s.velocity;
          },
        );
        expect(fastest, greaterThan(-.01), reason: 'shift $shift');
      }
    });

    test('the lift fades with the bird\'s height: stronger lower down', () {
      const top = .5, env = 1.0;
      expect(SteamCycle.liftFor(env, top - .03, top), closeTo(0, 1e-12));
      expect(SteamCycle.liftFor(env, top - .2, top), 0);
      expect(
        SteamCycle.liftFor(env, top + .07, top),
        closeTo(SteamCycle.liftSpeed, 1e-12),
      );
      expect(
        SteamCycle.liftFor(env, top + .02, top),
        inExclusiveRange(0, SteamCycle.liftSpeed),
      );
      expect(
        SteamCycle.liftFor(.5, top + .3, top),
        closeTo(SteamCycle.liftSpeed * .5, 1e-12),
      );
      expect(SteamCycle.liftFor(0, top + .3, top), 0);
    });

    test('a flap still wins: the lift never pushes a bird down', () {
      final sim = passVent(
        alley(),
        1,
        y: (v) => v.top + .10,
        watch: (s, v) {
          // Whatever the lift did, it never left the bird falling faster
          // than gravity alone would have.
          if ((v.x - birdX).abs() < .05) {
            expect(s.velocity, lessThanOrEqualTo(1.1 * (1 / 60) + 1e-9));
          }
        },
      );
      expect(sim.steamRides, 1);
      // A tap during the billow: the flap (-.54) stays at least as strong
      // as the flap alone, and the lift (up to -.55) may add a little.
      final flapper = arenaOf(alley());
      final geyser = flapper.route!.geysers[1];
      runUntil(
        flapper,
        (s) => s.steamVents.any((v) => v.geyser == geyser),
        holdY: .3,
        immortal: true,
        watch: clearAway,
      );
      final vent = flapper.steamVents.firstWhere((v) => v.geyser == geyser);
      runUntil(
        flapper,
        (s) => (vent.x - birdX).abs() < .02 && vent.liftAt(s.routeSeconds) > .9,
        steer: (s) => vent.top + .10,
        immortal: true,
        watch: clearAway,
      );
      flapper.velocity = 0;
      flapper.birdY = vent.top + .10;
      frame(flapper, flap: true);
      expect(flapper.velocity, lessThanOrEqualTo(-.5));
    });

    test('a hop vent\'s billow (after the bird has passed) pays nothing', () {
      final sim = passVent(alley(), 0, y: (v) => v.top - .10);
      expect(sim.steamRides, 0);
      expect(sim.score, SteamCycle.hopPoints);
    });
  });

  group('counters and the clock', () {
    test('each vent the bird passes hisses and bursts once, in order', () {
      final sim = arenaOf(alley());
      var hisses = 0, bursts = 0;
      var order = <String>[];
      runUntil(
        sim,
        (s) => s.phase == RunPhase.ended,
        steer: vacuumY,
        immortal: true,
        seconds: 200,
        watch: (s) {
          if (s.steamHisses != hisses) {
            order.add('hiss');
            hisses = s.steamHisses;
          }
          if (s.steamBursts != bursts) {
            order.add('burst');
            bursts = s.steamBursts;
          }
        },
      );
      expect(sim.steamHisses, 8);
      expect(sim.steamBursts, 8);
      expect(order, [
        for (var i = 0; i < 8; i++) ...['hiss', 'burst'],
      ]);
      // A level without steam never moves a counter.
      final plain = arenaOf(alley(steam: SteamPlan.none));
      runUntil(
        plain,
        (s) => s.phase == RunPhase.ended,
        holdY: .5,
        immortal: true,
        seconds: 200,
      );
      expect([
        plain.steamHisses,
        plain.steamBursts,
        plain.steamRides,
        plain.steamScalds,
        plain.steamClears,
      ], everyElement(0));
      expect(plain.steamVents, isEmpty);
    });

    test('scalds, clears and rides add up over a whole level', () {
      // A bird that flies the lane: some vents it clears, some it does not.
      final sim = arenaOf(alley());
      runUntil(
        sim,
        (s) => s.phase == RunPhase.ended,
        holdY: .6,
        seconds: 200,
        watch: (s) {
          if (s.hearts < 2) s.hearts = 3;
        },
      );
      final hops = sim.route!.geysers
          .where((g) => g.kind == SteamKind.hop)
          .length;
      expect(sim.steamScalds + sim.steamClears, lessThanOrEqualTo(hops + 2));
      expect(sim.steamRides, lessThanOrEqualTo(4));
    });

    test('vents are pruned when they have scrolled away', () {
      final sim = arenaOf(alley());
      var most = 0;
      runUntil(
        sim,
        (s) => s.phase == RunPhase.ended,
        holdY: .5,
        immortal: true,
        seconds: 200,
        watch: (s) {
          most = math.max(most, s.steamVents.length);
          for (final v in s.steamVents) {
            expect(v.x, greaterThanOrEqualTo(SteamCycle.vanishX));
          }
        },
      );
      expect(most, lessThanOrEqualTo(3));
      expect(sim.steamVents.length, lessThanOrEqualTo(1));
    });

    test('a boss\'s arrival clears the vents and lays no more', () {
      final plan = alley(
        steam: SteamPlan.sparse,
        length: 30,
        boss: BossKind.kingCoo,
        lineup: const [EnemyKind.alleyPigeon, EnemyKind.simpleBat],
      );
      expect(plan.problem, isNull);
      final sim = arenaOf(plan);
      expect(sim.route!.geysers, hasLength(3));
      expect(plan.steam.routeProblem(sim.route!, plan.length), isNull);
      var seen = 0;
      runUntil(
        sim,
        (s) => s.boss != null,
        holdY: .5,
        immortal: true,
        seconds: 80,
        watch: (s) => seen = math.max(seen, s.steamVents.length),
      );
      expect(seen, greaterThan(0));
      expect(sim.steamVents, isEmpty);
      for (var i = 0; i < 120; i++) {
        frame(sim);
        sim.birdY = .5;
        sim.velocity = 0;
        sim.invulnerableUntil = 1e9;
      }
      expect(sim.steamVents, isEmpty);
      expect(sim.steamScalds, 0);
    });

    test('steam needs rules 43 and a Star Trail', () {
      final sim = arenaOf(alley());
      expect(sim.supportsSteamGeysers, isTrue);
      expect(() => arenaOf(alley(), version: 41), throwsArgumentError);
      expect(() => arenaOf(alley(), version: 42), throwsArgumentError);
    });
  });

  group('route rules', () {
    test('the last vent is passed two seconds before the goal or the boss', () {
      final ok = alley(steam: SteamPlan.sparse, length: 30);
      expect(ok.steam.routeProblem(arenaOf(ok).route!, ok.length), isNull);
      // 3-4's run-up: the last slot (passage 12) arrives at 27.6 s.
      final last = arenaOf(ok).route!.geysers.last;
      expect(last.burstAt + SteamCycle.arrival(last.kind), closeTo(27.6, .3));
      // The verdict is exactly the two-second rule, for every length.
      const layer = SteamPlan(first: 4, every: 4, last: 12, pattern: 'H');
      var refused = 0;
      for (var length = 24.0; length <= 34; length += .25) {
        final plan = alley(steam: layer, length: length);
        final route = arenaOf(plan).route!;
        final tooLate = route.geysers.any(
          (g) => length - (g.burstAt + SteamCycle.arrival(g.kind)) < 2,
        );
        expect(
          layer.routeProblem(route, length),
          tooLate ? 'steam' : isNull,
          reason: 'length $length',
        );
        if (tooLate) refused++;
      }
      expect(refused, greaterThan(0));
    });

    test('no vent within a passage of a set piece', () {
      const layer = SteamPlan(first: 4, every: 4, last: 12, pattern: 'HR');
      var refused = 0, allowed = 0;
      for (var at = 4.0; at < 40; at += 1.0) {
        final piece = LevelPlan(
          id: '3-3',
          region: WorldRegion.newYork,
          length: 60,
          start: 100,
          seed: 3103,
          families: alley().families,
          steam: layer,
          pieces: [SetPiece(SetPieceKind.swarm, at: at)],
          marks: const StarMarks(40, 70),
        );
        final route = arenaOf(piece).route!;
        final problem = layer.routeProblem(route, piece.length);
        // A problem exactly when a slot is within one passage of the piece.
        final start = route.pieces.single.start;
        final before = route.passages.lastIndexWhere((x) => x < start);
        final near = route.geysers.any(
          (g) => g.slot - 1 >= before - 1 && g.slot - 1 <= before + 2,
        );
        expect(problem == 'steam', near, reason: 'piece at $at s');
        if (near) {
          refused++;
        } else {
          allowed++;
        }
      }
      expect(refused, greaterThan(0));
      expect(allowed, greaterThan(0));
    });
  });
}
