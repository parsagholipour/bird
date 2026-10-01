import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';

import 'king_coo_helpers.dart';
import 'king_coo_viability.dart';

/// King Coo's fairness proof (R2), as a test: a bird that taps at most five
/// times a second has a safe escape from EVERY state that can survive the
/// course edges alone, for every telegraphed hazard he has, at every height
/// the ring can lock on, at the narrowest, widest and usual phone widths. See
/// `king_coo_viability.dart` for the search (a port of the report's
/// `proof/fair.dart`) and how it differs. The hazards' geometry is the game's
/// own ([CrumbLob], [SquadTrack], [KingCoo.squad]); the closed-loop test at
/// the end flies the search's own policy through the real simulation and
/// must never be hurt.

/// The bird's exact radius, and the comfort margin of the report: a bird
/// inflated by .05, a hover wobble's worth.
const exact = .038, comfort = .038 + .05;

/// The audits below need the edge kernel once per radius.
final kernels = {exact: edgeKernel(), comfort: edgeKernel(rb: comfort)};

/// Seconds the bomb hazards run from the ring's lock.
final lobHorizon = KingCoo.telegraph + KingCoo.cloudSeconds + .1;

/// The narrowest allowed screen (1.6), the two test phones and the widest
/// (2.4 = 864 px at 360); the comfort margin is checked at the extremes.
const widths = [1.6, 640 / 360, 800 / 360, 2.4];

void expectFair(
  String label,
  List<Hazard> hazards,
  double seconds, {
  required double rb,
  double minSlack = 0,
}) {
  final via = solve(hazards, seconds, rb: rb);
  final kernel = kernels[rb]!;
  final a = audit(via, kernel);
  expect(
    a.fair,
    isTrue,
    reason:
        '$label (bird r=$rb): ${a.bad} of ${a.total} states have no safe '
        'tap sequence, at heights ${a.badHeights.join(' ')}',
  );
  final slack = ignoreSlack(via, kernel);
  expect(
    slack,
    greaterThanOrEqualTo(minSlack),
    reason: '$label (bird r=$rb): the bird may ignore it only $slack s',
  );
}

void main() {
  group('the search has teeth', () {
    test('the course edges alone leave a bird alive from most states', () {
      for (final rb in [exact, comfort]) {
        final kernel = kernels[rb]!;
        var alive = 0, doomed = 0;
        for (var iy = 0; iy < ny; iy++) {
          for (var k = 0; k < nk; k++) {
            kernel.isReady(0, iy, k) ? alive++ : doomed++;
          }
        }
        expect(alive, greaterThan(doomed ~/ 2));
        expect(doomed, greaterThan(0), reason: 'a fast fall at the floor');
      }
      // A bird that has just tapped cannot tap again for 0.2 s: near the
      // ceiling it rises into the edge, and far from it there is room.
      final kernel = kernels[exact]!;
      expect(kernel.isCooling(0, rowOf(.06), 1), isFalse);
      expect(kernel.isCooling(0, rowOf(.5), 1), isTrue);
      expect(kernel.isReady(0, rowOf(.5), kTap), isTrue);
    });

    test('a bomb with no telegraph is not fair, a telegraphed one is', () {
      // A cloud that appears on the bird at the moment of the lock: the
      // states in its middle cannot get out.
      Hazard instant(double y) =>
          (t) => t < 1.0 ? (x: birdX, y: y, r: KingCoo.cloudRadius) : null;
      final via = solve([instant(.5)], 1.2, rb: exact);
      expect(audit(via, kernels[exact]!).fair, isFalse);
      // The same cloud with a 0.4 s warning (a ring that locked late).
      Hazard late(double y) =>
          (t) => t >= .4 && t < 1.4
          ? (x: birdX, y: y, r: KingCoo.cloudRadius)
          : null;
      final warned = solve([late(.5)], 1.6, rb: exact);
      expect(audit(warned, kernels[exact]!, nearY: .5).fair, isFalse);
      // With the real 2.2 s it is fair from everywhere.
      expectFair(
        'the real bomb',
        cloudHazards(.5, fury: false),
        lobHorizon,
        rb: exact,
      );
    });

    test('a picket wall with no gap is not fair', () {
      final wall = squadHazards(1, .2, fury: false, bossX: bossColumn(2.2));
      // The real picket (gap .30 tall) is fair; closing the gap is not.
      expectFair(
        'picket',
        wall,
        squadEndsAt(bossColumn(2.2), fury: false),
        rb: exact,
      );
      final closed = [
        ...wall,
        for (final y in [.35, .5, .65])
          (double t) {
            final x = bossColumn(2.2) - KingCoo.squadSpeed * (t - 1.6);
            return (x - birdX).abs() > .25
                ? null
                : (x: x, y: y, r: SkyEnemy.radius);
          },
      ];
      final via = solve(
        closed,
        squadEndsAt(bossColumn(2.2), fury: false),
        rb: exact,
      );
      expect(audit(via, kernels[exact]!).fair, isFalse);
    });
  });

  for (final rb in [exact, comfort]) {
    final label = rb == exact ? 'exact bird' : 'comfort bird (+.05)';
    group('every state is viable: $label', () {
      test('a crumb bomb locked at any height', () {
        for (final y in [.14, .2, .3, .4, .5, .6, .7, .8, .86]) {
          expectFair(
            'bomb locked at $y',
            cloudHazards(y, fury: false),
            lobHorizon,
            rb: rb,
            minSlack: rb == exact ? .7 : .5,
          );
        }
      });

      test('the fury bracket: two clouds around the bird\'s own height', () {
        for (final y in [.14, .2, .3, .4, .5, .6, .7, .8, .86]) {
          expectFair(
            'bracket locked at $y',
            cloudHazards(y, fury: true),
            lobHorizon,
            rb: rb,
            minSlack: rb == exact ? .7 : .5,
          );
        }
      });

      for (final width in rb == exact ? widths : [widths.first, widths.last]) {
        test('the V squadron at width ${width.toStringAsFixed(2)}', () {
          final bossX = bossColumn(width);
          for (final tip in [.25, .3, .4, .5, .6, .7, .75]) {
            expectFair(
              'V, tip $tip',
              squadHazards(0, tip, fury: false, bossX: bossX),
              squadEndsAt(bossX, fury: false),
              rb: rb,
              minSlack: rb == exact ? 1.2 : 1.0,
            );
          }
          // The tip follows the bird: a bird anywhere gets a V whose tip is
          // clamped to .25-.75, so every bird height is covered too.
          for (final bird in [.05, .1, .9, .95]) {
            expectFair(
              'V for a bird at $bird',
              squadHazards(0, bird, fury: false, bossX: bossX),
              squadEndsAt(bossX, fury: false),
              rb: rb,
            );
          }
        });

        test('the picket wall at width ${width.toStringAsFixed(2)}', () {
          final bossX = bossColumn(width);
          // Odd cycles, every bird height: the gap is .50, and .30 or .70
          // alternate when the bird sits in the middle (cycle mod 4).
          for (final (cycle, bird) in [
            (1, .1),
            (1, .2),
            (1, .3),
            (1, .385),
            (1, .5),
            (1, .615),
            (1, .8),
            (3, .385),
            (3, .5),
            (3, .615),
            (3, .9),
          ]) {
            expectFair(
              'picket, cycle $cycle, bird $bird',
              squadHazards(cycle, bird, fury: false, bossX: bossX),
              squadEndsAt(bossX, fury: false),
              rb: rb,
              minSlack: rb == exact ? 1.0 : .9,
            );
          }
        });

        test('fury\'s V then a centred picket at width '
            '${width.toStringAsFixed(2)}', () {
          final bossX = bossColumn(width);
          for (final tip in [.25, .35, .5, .65, .75]) {
            expectFair(
              'fury squadron, tip $tip',
              squadHazards(2, tip, fury: true, bossX: bossX),
              squadEndsAt(bossX, fury: true),
              rb: rb,
              minSlack: rb == exact ? 1.2 : 1.0,
            );
          }
        });
      }

      test('rings that lock while the last bomb is pending or live', () {
        // The next ring locks on the bird's height while the previous bomb's
        // clouds are still to burst (fury: 0.4 s before) or standing (calm:
        // 0.2 s after). A bird that could still escape the first bomb at the
        // lock must be able to escape both. The offsets come from the cycle.
        final calmGap =
            KingCoo.calmLaunches[0] +
            KingCoo.lobFlight -
            KingCoo.locks(fury: false)[1];
        final furyGap =
            KingCoo.furyLaunches[0] +
            KingCoo.lobFlight -
            KingCoo.locks(fury: true)[1];
        expect(calmGap, closeTo(-.2, 1e-9));
        expect(furyGap, closeTo(.4, 1e-9));
        for (final (fury, burst) in [(false, calmGap), (true, furyGap)]) {
          // burst: when the first bomb's clouds burst, from the next lock.
          final tb2 = KingCoo.telegraph;
          for (final b1 in [.2, .35, .5, .65, .8]) {
            List<Hazard> first() => [
              for (final y in KingCoo.cloudHeights(b1, fury: fury))
                (double t) => t >= burst && t < burst + KingCoo.cloudSeconds
                    ? (x: birdX, y: y, r: KingCoo.cloudRadius)
                    : null,
            ];
            final horizon = math.max(burst + 1.0, tb2 + 1.0) + .1;
            final only = solve(first(), horizon, rb: rb);
            for (var b2 = .14; b2 <= .86 + 1e-9; b2 += .09) {
              final both = solve(
                [...first(), ...cloudHazards(b2, fury: fury)],
                horizon,
                rb: rb,
              );
              var total = 0, bad = 0;
              final kernel = kernels[rb]!;
              for (var iy = 0; iy < ny; iy++) {
                if ((heightAt(iy) - b2).abs() > .012) continue;
                for (var k = 0; k < nk; k++) {
                  final v = velocityAt(k);
                  if (v < flapVelocity - 1e-9 || v > 1.0) continue;
                  if (!kernel.isReady(0, iy, k) || !only.isReady(0, iy, k)) {
                    continue;
                  }
                  total++;
                  if (!both.isReady(0, iy, k)) bad++;
                }
                for (var c = 1; c <= nc; c++) {
                  if (!kernel.isCooling(0, iy, c) ||
                      !only.isCooling(0, iy, c)) {
                    continue;
                  }
                  total++;
                  if (!both.isCooling(0, iy, c)) bad++;
                }
              }
              expect(
                bad,
                0,
                reason:
                    '${fury ? 'fury' : 'calm'} chain b1=$b1 b2=${b2.toStringAsFixed(2)}: '
                    '$bad of $total states are trapped',
              );
            }
          }
        }
      });
    });
  }

  test(
    'his hazards never overlap: clouds, then squadrons, then next rings',
    () {
      const eps = 1e-9;
      for (final fury in [false, true]) {
        final launches = KingCoo.launches(fury: fury);
        var previousEnd = -double.infinity;
        for (final launch in launches) {
          final burst = launch + KingCoo.lobFlight;
          expect(
            burst,
            greaterThanOrEqualTo(previousEnd - eps),
            reason: 'one cloud at a time (fury $fury)',
          );
          previousEnd = burst + KingCoo.cloudSeconds;
        }
        expect(
          previousEnd,
          lessThan(KingCoo.puffAt),
          reason: 'clouds end first',
        );
      }
      // The last cloud of fury ends at 7.4 s, the puff opens at 7.6 s.
      expect(
        KingCoo.furyLaunches.last + KingCoo.lobFlight + KingCoo.cloudSeconds,
        closeTo(7.4, 1e-9),
      );
      for (final width in widths) {
        final bossX = bossColumn(width);
        final crossing = (bossX - birdX) / KingCoo.squadSpeed;
        final first = KingCoo.whistleAt + crossing - .25 / KingCoo.squadSpeed;
        final lastCrossing =
            KingCoo.whistleAt + KingCoo.furyPicketDelay + crossing;
        final last = lastCrossing + .25 / KingCoo.squadSpeed;
        expect(
          first,
          greaterThan(KingCoo.puffAt + 1.0),
          reason: 'width $width',
        );
        expect(lastCrossing, lessThanOrEqualTo(KingCoo.squadCrossesBy + eps));
        // The next cycle's first ring locks 0.6 s into it, after every pigeon.
        expect(
          last,
          lessThan(KingCoo.period + KingCoo.locks(fury: false).first),
          reason: 'width $width',
        );
      }
      // A screen of 864 px at 360 (width 2.4): the widest phone, 13.0 s.
      final widest =
          KingCoo.whistleAt +
          KingCoo.furyPicketDelay +
          (bossColumn(2.4) - birdX) / KingCoo.squadSpeed;
      expect(widest, closeTo(9.2 + 1.4 + 2.2258, 1e-3));
    },
  );

  group('following the search through the real simulation', () {
    /// One scenario kind, flown [runs] times in one fight: the bird is held
    /// at a chosen height until the ring locks (or the chest puffs), then
    /// set to a random state that survives the edges and flies the search's
    /// cautious policy (the widest safety margin in which it is still
    /// viable). Returns how many runs hurt it. With [ignoring] the bird
    /// instead hovers at the ring's own height, as if it never saw the
    /// telegraph.
    int closedLoop({
      required String kind,
      required double width,
      required int runs,
      bool fury = false,
      bool ignoring = false,
    }) {
      final sim = cooFight(plan: cooPlan(length: 10), width: width);
      final boss = sim.boss!;
      if (fury) boss.hp = KingCoo.furyHp;
      final bossX = bossColumn(width);
      final rng = math.Random(
        kind.codeUnits.fold<int>(7, (h, c) => h * 31 + c) ^
            (width * 100).round(),
      );
      final kernel = kernels[comfort]!;
      final bombs = kind == 'lob' || kind == 'bracket';
      var cycle = kind == 'picket' ? 1 : 0;
      var hurtRuns = 0;
      for (
        var i = 0;
        i < runs;
        i++, cycle += kind == 'V' || kind == 'picket' ? 2 : 1
      ) {
        final start = cycle * KingCoo.period;
        final event = start + (bombs ? .6 : KingCoo.puffAt);
        int count() => bombs ? boss.lobs.length : boss.puffsLatched;
        // Hold at the ring's height until it locks (or the chest puffs).
        final b = .14 + rng.nextDouble() * (.86 - .14);
        runTo(sim, event - .3, hold: .5, protect: true);
        final before = count();
        run(sim, 2, hold: b, protect: true, until: (sim) => count() != before);
        expect(count(), before + 1, reason: '$kind run $i: no ring or puff');
        final hazards = switch (kind) {
          'lob' => cloudHazards(b, fury: false),
          'bracket' => cloudHazards(b, fury: true),
          _ => squadHazards(cycle, b, fury: fury, bossX: bossX),
        };
        final seconds = bombs ? lobHorizon : squadEndsAt(bossX, fury: fury);
        // The widest margin first: a bird that keeps .1 of clearance, then
        // .05, then none.
        final tables = [
          for (final rb in [exact + .10, comfort, exact])
            solve(hazards, seconds, rb: rb),
        ];
        final frames = tables.first.frames;
        // A random state that survives the edges: ready or cooling.
        double y0, v0;
        var since = 99;
        while (true) {
          y0 = .09 + rng.nextDouble() * .82;
          if (rng.nextInt(4) == 0) {
            since = 1 + rng.nextInt(nc);
            v0 = flapVelocity + gdt * since;
            if (!kernel.isCooling(0, rowOf(y0), since)) continue;
          } else {
            since = 99;
            v0 = flapVelocity + rng.nextDouble() * (1.0 - flapVelocity);
            final k = ((v0 - velocityMin) / gdt).round().clamp(0, nk - 1);
            if (!kernel.isReady(0, rowOf(y0), k)) continue;
          }
          break;
        }
        sim
          ..invulnerableUntil = 0
          ..hearts = 3
          ..shield = true
          ..birdY = y0
          ..velocity = v0;
        final crumbs = boss.crumbHits, since0 = since;
        final trace = <String>[];
        var hurt = false;
        for (var f = 0; f < frames && !hurt; f++) {
          final tap = ignoring
              ? since >= coolFrames &&
                    sim.birdY > b + .06 &&
                    sim.velocity > -.25
              : followCautiously(tables, f, sim.birdY, sim.velocity, since);
          trace.add(
            '$f y=${sim.birdY.toStringAsFixed(3)} '
            'v=${sim.velocity.toStringAsFixed(3)} c=$since tap=$tap',
          );
          tick(sim, dt: dtFrame, width: width, flap: tap);
          since = tap ? 1 : math.min(since + 1, 99);
          if (sim.phase != RunPhase.playing) break;
          hurt = !sim.shield || sim.hearts < 3 || boss.crumbHits > crumbs;
        }
        if (hurt) {
          hurtRuns++;
          if (!ignoring) {
            final pigeons = [
              for (final e in squadOf(sim))
                '(${e.x.toStringAsFixed(3)}, ${e.y.toStringAsFixed(3)})',
            ];
            final clouds = [
              for (final lob in boss.liveLobs)
                if (lob.hurts(boss.age))
                  for (final y in lob.cloudHeights) y.toStringAsFixed(3),
            ];
            fail(
              '$kind at width $width, run $i: hurt following the search from '
              'y=${y0.toStringAsFixed(3)} v=${v0.toStringAsFixed(3)} '
              '(since $since0), the ring/puff at height '
              '${b.toStringAsFixed(3)}; clouds $clouds, pigeons $pigeons; '
              'last frames:\n${trace.reversed.take(10).toList().reversed.join('\n')}',
            );
          }
        }
        // Nothing else hurts while it waits for the next cycle.
        sim.invulnerableUntil = double.infinity;
      }
      return hurtRuns;
    }

    for (final (kind, widths, runs, fury) in [
      ('lob', [2.2], 16, false),
      ('bracket', [2.2], 16, true),
      ('V', [1.6, 800 / 360, 2.4], 8, false),
      ('picket', [1.6, 800 / 360, 2.4], 8, false),
      ('fury', [1.6, 800 / 360, 2.4], 8, true),
    ]) {
      for (final width in widths) {
        final w = width.toStringAsFixed(2);
        test('$kind at width $w: never hurt', () {
          expect(
            closedLoop(kind: kind, width: width, runs: runs, fury: fury),
            0,
          );
        });
      }
    }

    test('a bird that ignores the telegraph is hurt (the loop has teeth)', () {
      // (Not the bracket: in fury the bird's own height is the safe corridor
      // between its two clouds, by design.)
      for (final (kind, fury) in [
        ('lob', false),
        ('V', false),
        ('fury', true),
      ]) {
        final hurt = closedLoop(
          kind: kind,
          width: 2.2,
          runs: 10,
          fury: fury,
          ignoring: true,
        );
        expect(hurt, greaterThanOrEqualTo(8), reason: '$kind: $hurt of 10');
      }
    });
  });
}
