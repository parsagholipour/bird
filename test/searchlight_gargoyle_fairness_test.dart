import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';

import 'gargoyle_lag.dart';
import 'gargoyle_viability.dart';

/// The Searchlight Gargoyle's fairness proof (report 04 §2): a bird tapping at
/// most five times a second has a safe escape from every survivable start
/// state, for every kind of sweep, and the 1.5 s warning is fair down to 1.3 s.
/// Exhaustive search over tap sequences in `gargoyle_viability.dart`, reading
/// the shipped `SearchlightGargoyle` rules; `searchlight_gargoyle_test` flies
/// the found escapes through the real simulation.

void main() {
  test('the dark side and the slit are wide enough to hold', () {
    const r = birdRadius;
    final (hiA, hiB) = SearchlightGargoyle.darkSide(
      BeamSide.high,
      half: SearchlightGargoyle.litHalf,
      radius: r,
    );
    final (loA, loB) = SearchlightGargoyle.darkSide(
      BeamSide.low,
      half: SearchlightGargoyle.litHalf,
      radius: r,
    );
    // Report: HIGH .548-.962, LOW .038-.452 (.414 tall). The slit was
    // .393-.607 (.214 tall) and is .343-.657 (.314) since the fix round.
    expect(hiB - hiA, closeTo(.414, 1e-9));
    expect(loB - loA, closeTo(.414, 1e-9));
    const half = SearchlightGargoyle.furyLitHalf;
    final slitTop = SearchlightGargoyle.slitUpper.$2 + half + r;
    final slitBottom = SearchlightGargoyle.slitLower.$2 - half - r;
    expect(slitTop, closeTo(SearchlightGargoyle.slitTop, 1e-9));
    expect(slitBottom, closeTo(SearchlightGargoyle.slitBottom, 1e-9));
    expect(slitBottom - slitTop, closeTo(.314, 1e-9));
    expect(SlitGeometry.shipped.corridor, closeTo(.314, 1e-9));
    expect(SlitGeometry.before.corridor, closeTo(.214, 1e-9));
    // The feather's flight is the same at every width: 1.72 s calm, 1.41 s fury.
    expect(
      SearchlightGargoyle.featherShot(.5, enraged: false).flight,
      closeTo(1.72, .01),
    );
    expect(
      SearchlightGargoyle.featherShot(.5, enraged: true).flight,
      closeTo(1.41, .01),
    );
  });

  test('the 351 survivable starts are the report\'s 117 per kind of sweep', () {
    expect(survivableStarts(), hasLength(117));
    // The search walks the same Tap & Fly physics the simulation flies.
    expect(gravity, 1.1);
    expect(flapImpulse, -.54);
    expect(birdRadius, .038);
  });

  group('exhaustive search over tap sequences at 5 taps a second', () {
    for (final sweep in Sweep.values) {
      test('${sweep.name}: a safe path from all 117 starts', () {
        final result = unwinnable(sweep);
        expect(result.searched, 117);
        expect(result.unwinnable, isEmpty, reason: '${result.unwinnable}');
      });
    }

    for (final (idle, searched) in [(.30, 108), (.45, 101)]) {
      test('${idle}s without a tap after the warning starts: still safe', () {
        // A slow reaction: the bird only falls for [idle] seconds first.
        var total = 0;
        for (final sweep in Sweep.values) {
          final result = unwinnable(sweep, idle: idle);
          total += result.searched;
          expect(result.unwinnable, isEmpty, reason: '$sweep ${result.unwinnable}');
        }
        expect(total, searched * 3);
      });
    }

    for (final sweep in Sweep.values) {
      test('${sweep.name}: the whole cycle from the perch feather\'s launch', () {
        // The report's search starts at the warning, with the perch feather
        // already gone; this one starts as it leaves (its lane is the bird's
        // height) and lets the bird's height at 2.0 s aim the sweep, so the
        // feather's last .1 s in the bird's column is in the proof too.
        final bad = <Start>[];
        for (final start in survivableStarts()) {
          final search = Search(sweep, withPerch: true, tail: .5);
          if (!search.fromPerch(start).safe) bad.add(start);
        }
        expect(bad, isEmpty, reason: '$sweep $bad');
      });
    }

    test('with a wider margin (.012) and a longer tail the paths still exist', () {
      for (final sweep in Sweep.values) {
        final result = unwinnable(sweep, margin: .012, tail: .5);
        expect(result.unwinnable, isEmpty, reason: '$sweep ${result.unwinnable}');
      }
    });
  });

  group('the fury slit: a corridor a tapping thumb can hold', () {
    // The play review (reports/21 D1): the slit's .214 corridor against a .13
    // hover bob was a coin flip for a player hovering by tapping with a late,
    // jittery thumb. The inner ends moved from .26/.74 to .21/.79 (corridor
    // .314); the review's own pick was .22/.78 (.294).
    test('the geometry: beams from .12/.88 to .21/.79, a .314 corridor', () {
      expect(SearchlightGargoyle.slitUpper, (.12, .21));
      expect(SearchlightGargoyle.slitLower, (.88, .79));
      expect(SlitGeometry.shipped.corridor, closeTo(.314, 1e-9));
      expect(SlitGeometry.shipped.top, closeTo(SearchlightGargoyle.slitTop, 1e-9));
      expect(
        SlitGeometry.shipped.bottom,
        closeTo(SearchlightGargoyle.slitBottom, 1e-9),
      );
      expect(SlitGeometry.before.corridor, closeTo(.214, 1e-9));
      // The hover bob (a flap climbs .135) fits with room to spare.
      expect(SlitGeometry.shipped.corridor - .135, greaterThan(.17));
    });

    test('the lag sweep: a thumb 50 to 100 ms late holds the slit at least '
        '90% of the time (it held it 52 to 70% before)', () {
      // Share of 4000 hovering birds that get through one slit sweep; thumb
      // lag 0/50/100 ms, jitter 0 and 40 ms (the review's table).
      final before = <String, double>{}, after = <String, double>{};
      for (final lag in [0.0, .05, .10]) {
        for (final sigma in [0.0, .04]) {
          final key = '${(lag * 1000).round()}/${(sigma * 1000).round()}';
          before[key] = survival(
            Kind.furySlit,
            lag: lag,
            sigma: sigma,
            geometry: SlitGeometry.before,
            n: 4000,
          );
          after[key] = survival(
            Kind.furySlit,
            lag: lag,
            sigma: sigma,
            n: 4000,
          );
        }
      }
      // ignore: avoid_print
      print('slit survival before: $before\nslit survival after: $after');
      for (final key in ['50/40', '100/40', '100/0']) {
        expect(before[key]!, lessThan(.82), reason: 'before, lag/jitter $key');
      }
      expect(before['100/40']!, lessThan(.60));
      for (final entry in after.entries) {
        expect(entry.value, greaterThanOrEqualTo(.90), reason: entry.key);
      }
      for (final key in before.keys) {
        expect(after[key]!, greaterThanOrEqualTo(before[key]!), reason: key);
      }
    });

    test('the zone sweeps stay as forgiving as they were', () {
      for (final kind in [Kind.calmZone, Kind.furyZone]) {
        for (final lag in [0.0, .05, .10]) {
          expect(
            survival(kind, lag: lag, sigma: .04, n: 2000),
            greaterThanOrEqualTo(.97),
            reason: '${kind.name} at ${(lag * 1000).round()} ms',
          );
        }
      }
    });

    test('the exhaustive search tolerates a .08 margin of error (it tolerated '
        '.05 before), at 5 and at 2.5 taps a second', () {
      for (final gap in [12, 24]) {
        double safe(SlitGeometry geometry, double margin) {
          final r = unwinnable(
            Sweep.furySlit,
            margin: margin,
            tapGap: gap,
            slitGeometry: geometry,
          );
          return (r.searched - r.unwinnable.length) / r.searched;
        }

        for (final margin in [.002, .04, .06, .08]) {
          expect(
            safe(SlitGeometry.shipped, margin),
            1,
            reason: 'after, margin $margin, gap $gap',
          );
        }
        expect(safe(SlitGeometry.before, .04), 1, reason: 'gap $gap');
        expect(safe(SlitGeometry.before, .06), 0, reason: 'gap $gap');
      }
    });
  });

  group('the warning is fair down to 1.3 s; 1.5 s ships', () {
    test('the shipped warning is 1.5 s and never below the proven floor', () {
      expect(SearchlightGargoyle.warnSeconds, closeTo(1.5, 1e-12));
      expect(SearchlightGargoyle.minWarnSeconds, 1.3);
      expect(
        SearchlightGargoyle.warnSeconds,
        greaterThanOrEqualTo(SearchlightGargoyle.minWarnSeconds),
      );
    });

    test('1.5 s and 1.3 s leave no unwinnable start; 1.1 s and shorter do', () {
      for (final warn in [1.5, 1.3]) {
        for (final sweep in Sweep.values) {
          final result = unwinnable(sweep, warnSeconds: warn);
          expect(
            result.unwinnable,
            isEmpty,
            reason: '$warn s $sweep ${result.unwinnable}',
          );
        }
      }
      // The search has teeth: shorten the warning and it finds starts from
      // which no player could reach the dark side in time (the report counts
      // 31, 14 and 2 unwinnable starts at 0.7, 0.9 and 1.1 s).
      for (final (warn, count) in [(.7, 31), (.9, 14), (1.1, 2)]) {
        var bad = 0;
        for (final sweep in Sweep.values) {
          bad += unwinnable(sweep, warnSeconds: warn).unwinnable.length;
        }
        expect(bad, count, reason: '$warn s leaves $count of 351 unwinnable');
      }
    });
  });
}
