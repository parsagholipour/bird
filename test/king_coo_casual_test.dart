import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';

import 'king_coo_helpers.dart';
import 'king_coo_viability.dart' as v;

/// King Coo's squadron for a CASUAL pilot (R2 fix round): one who taps at
/// most 2.5 times a second, reacts 0.7 to 1.2 s late and has a thumb that
/// lands a tap 80 ms after the decision. The hostile play review found the
/// shared `CooBot` at that tempo hit by the squadron in every fight; this
/// file is the diagnosis, as tests:
///
///  1. the exhaustive search at 2.5 taps a second finds a safe tap sequence
///     from every state, with at least the slack below (the lanes light at
///     the puff, 2.7 to 3.8 s before the first pigeon crosses);
///  2. a pilot that follows the search's own plan (reaction up to 1.4 s,
///     thumb lag included) is never hurt, in the real simulation, and one
///     that reacts after the whole telegraph is;
///  3. the hits of the default `CooBot` come from its policy, not from the
///     rules: it looks at every lane of fury's V and picket at once (they
///     never reach the bird together, but their lanes together shade the
///     whole sky, so it finds no height to go to and stays), while
///     `CooBot(sequential: true)`, at the same tempo and reaction, handles
///     the V and then the picket and is hurt at most one time in three.

/// Heights the ring may lock on, and the widths at which the proof is run.
const _widths = [1.6, 640 / 360, 800 / 360, 2.4];

void main() {
  tearDown(() => v.useTapRate(5));

  group('2.5 taps a second: every state has a safe sequence', () {
    test('bombs, V, picket and fury, at every width, with their slack', () {
      v.useTapRate(2.5);
      expect(v.coolFrames, 24);
      final kernel = v.edgeKernel();
      final slack = <String, double>{};
      void check(String family, List<v.Hazard> hazards, double seconds) {
        final via = v.solve(hazards, seconds);
        final a = v.audit(via, kernel);
        expect(
          a.fair,
          isTrue,
          reason:
              '$family: ${a.bad} of ${a.total} states unsafe at heights '
              '${a.badHeights.join(' ')}',
        );
        final s = v.ignoreSlack(via, kernel, upTo: 3);
        slack[family] = math.min(slack[family] ?? s, s);
      }

      final bombs = KingCoo.telegraph + KingCoo.cloudSeconds + .1;
      for (final y in [.14, .2, .3, .4, .5, .6, .7, .8, .86]) {
        check('bomb', v.cloudHazards(y, fury: false), bombs);
        check('bracket', v.cloudHazards(y, fury: true), bombs);
      }
      for (final width in _widths) {
        final bossX = bossColumn(width);
        final tag = width.toStringAsFixed(2);
        for (final tip in [.25, .3, .4, .5, .6, .7, .75]) {
          check(
            'V@$tag',
            v.squadHazards(0, tip, fury: false, bossX: bossX),
            v.squadEndsAt(bossX, fury: false),
          );
        }
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
          check(
            'picket@$tag',
            v.squadHazards(cycle, bird, fury: false, bossX: bossX),
            v.squadEndsAt(bossX, fury: false),
          );
        }
        for (final tip in [.25, .35, .5, .65, .75]) {
          check(
            'fury@$tag',
            v.squadHazards(2, tip, fury: true, bossX: bossX),
            v.squadEndsAt(bossX, fury: true),
          );
        }
      }
      // How long a 2.5 taps a second pilot may ignore a telegraph before no
      // sequence is safe from some state (worst height, worst width in the
      // family). Measured 0.7 / 1.3 / 0.9 / 1.2 s at the narrowest screen;
      // the lead from the puff to the first crossing is 2.2 s for a bomb and
      // 2.7 to 3.8 s for a squadron.
      expect(slack['bomb'], greaterThanOrEqualTo(.6));
      expect(slack['bracket'], greaterThanOrEqualTo(.6));
      for (final tag in ['1.60', '1.78', '2.22', '2.40']) {
        expect(slack['V@$tag'], greaterThanOrEqualTo(1.2), reason: 'V@$tag');
        expect(
          slack['picket@$tag'],
          greaterThanOrEqualTo(.8),
          reason: 'picket@$tag',
        );
        expect(
          slack['fury@$tag'],
          greaterThanOrEqualTo(1.1),
          reason: 'fury@$tag',
        );
      }
      // Wider screens only give more.
      expect(slack['picket@2.40']!, greaterThan(slack['picket@1.60']!));
    });
  });

  group('a casual pilot that plans follows the lanes', () {
    /// A pilot at 2.5 taps a second: it hovers at a height until the puff,
    /// decides [react] seconds after it and from then on follows the search
    /// tables (the widest clearance still viable, as the closed loop of the
    /// fairness test), every tap landing [lag] seconds after its decision
    /// and the decision made for the state it will land in. Returns how
    /// many of [runs] squadrons hurt it.
    int hurtRuns({
      required String kind,
      required double width,
      required double react,
      required int runs,
      double lag = .08,
    }) {
      v.useTapRate(2.5);
      final fury = kind == 'fury';
      final sim = cooFight(plan: cooPlan(length: 10), width: width);
      final boss = sim.boss!;
      if (fury) boss.hp = KingCoo.furyHp;
      final bossX = bossColumn(width);
      final rng = math.Random(kind.length * 31 + (width * 100).round());
      var cycle = kind == 'picket' ? 1 : 0;
      var hurt = 0;
      final lagFrames = (lag * 60).round();
      for (var i = 0; i < runs; i++, cycle += kind == 'fury' ? 1 : 2) {
        final event = cycle * KingCoo.period + KingCoo.puffAt;
        final b = .3 + rng.nextDouble() * .4;
        var lastTap = -10.0;
        bool hover() =>
            sim.elapsed - lastTap >= .4 - 1e-9 &&
            sim.birdY > b + .05 &&
            sim.velocity > -.25;
        bool tapHover(FlightSimulation s) {
          final tap = hover();
          if (tap) lastTap = s.elapsed;
          return tap;
        }

        runTo(sim, event - 1.5, hold: .5, protect: true);
        final before = boss.puffsLatched;
        sim
          ..birdY = b
          ..velocity = 0
          ..invulnerableUntil = double.infinity;
        run(sim, 1.4, protect: true, flap: tapHover);
        run(
          sim,
          1,
          protect: true,
          flap: tapHover,
          until: (s) => boss.puffsLatched != before,
        );
        final hazards = v.squadHazards(
          cycle,
          sim.birdY,
          fury: fury,
          bossX: bossX,
        );
        final seconds = v.squadEndsAt(bossX, fury: fury);
        final tables = [
          for (final rb in [.038 + .10, .038 + .05, .038])
            v.solve(hazards, seconds, rb: rb),
        ];
        sim
          ..invulnerableUntil = 0
          ..hearts = 3
          ..shield = true;
        final reactFrames = (react * 60).round();
        final due = <int>[];
        var since = ((sim.elapsed - lastTap) * 60).round().clamp(0, 99);
        var hit = false;
        for (var f = 0; f < tables.first.frames && !hit; f++) {
          bool want;
          if (f < reactFrames) {
            want = hover();
          } else {
            // Decide for the state the tap will land in.
            var y = sim.birdY, vel = sim.velocity, c = since;
            for (var k = 0; k < lagFrames; k++) {
              if (due.contains(f + k)) {
                vel = v.flapVelocity;
                c = 0;
              }
              vel += v.gdt;
              y += vel * v.dtFrame;
              c = math.min(c + 1, 99);
            }
            want = v.followCautiously(tables, f + lagFrames, y, vel, c);
          }
          var landed = false;
          if (want && due.isEmpty && sim.elapsed - lastTap >= .4 - 1e-9) {
            due.add(f + lagFrames);
            lastTap = sim.elapsed;
          }
          if (due.isNotEmpty && due.first <= f) {
            due.removeAt(0);
            landed = true;
          }
          tick(sim, dt: v.dtFrame, width: width, flap: landed);
          since = landed ? 1 : math.min(since + 1, 99);
          hit = !sim.shield || sim.hearts < 3;
        }
        if (hit) hurt++;
        sim.invulnerableUntil = double.infinity;
      }
      return hurt;
    }

    for (final width in [1.6, 800 / 360]) {
      for (final kind in ['V', 'picket', 'fury']) {
        test('$kind at width ${width.toStringAsFixed(2)}: reacting 1.0 s and '
            '1.4 s after the puff, it is never hurt', () {
          for (final react in [1.0, 1.4]) {
            expect(
              hurtRuns(kind: kind, width: width, react: react, runs: 6),
              0,
              reason: '$kind, reaction $react s',
            );
          }
        });
      }
    }

    test('a pilot that reacts after the whole telegraph is hurt', () {
      // 2.4 s into a 2.7 s telegraph (the narrowest screen): the squadron is
      // a real threat to a bird that does not read the lanes.
      var hurt = 0, runs = 0;
      for (final kind in ['V', 'fury']) {
        hurt += hurtRuns(kind: kind, width: 1.6, react: 2.4, runs: 6);
        runs += 6;
      }
      expect(hurt, greaterThanOrEqualTo(runs ~/ 2), reason: '$hurt of $runs');
    });
  });

  group('the hits of the default CooBot are its policy', () {
    /// Fights up to the end of one squadron's crossing: [kind] 'V' is cycle
    /// 0 (calm), 'picket' cycle 1 (calm), 'fury' cycle 0 at fury's health.
    /// The bird holds still under protection until the bombs are over, then
    /// flies the bot at 2.5 taps a second. Returns the runs that lost a
    /// shield or a heart to anything but a cloud.
    int hurtRuns(
      CooBot Function() bot, {
      required String kind,
      double width = 640 / 360,
      int runs = 12,
    }) {
      var hurt = 0;
      for (var k = 0; k < runs; k++) {
        final sim = cooFight(width: width, weaponDamage: 10);
        final boss = sim.boss!;
        if (kind == 'fury') boss.hp = KingCoo.furyHp;
        final start = kind == 'picket' ? KingCoo.period : 0.0;
        run(sim, k * .09, hold: .5, protect: true);
        runTo(sim, start + 7.5, hold: .5, protect: true);
        sim.invulnerableUntil = 0;
        final pilot = bot();
        final crumbs = boss.crumbHits;
        var lost = false;
        run(
          sim,
          12,
          width: width,
          flap: pilot.flap,
          until: (s) => boss.combatTime > start + 13.5 || lost,
          each: (s) => lost = lost || !s.shield || s.hearts < 3,
        );
        expect(boss.crumbHits, crumbs, reason: 'no cloud in this window');
        if (lost) hurt++;
      }
      return hurt;
    }

    for (final react in [.7, .9, 1.2]) {
      test('fury\'s V then picket, reaction $react s: the default bot is hit, '
          'the sequential one is not (2.5 taps/s)', () {
        CooBot staticBot() =>
            CooBot(react: react, margin: .07, tapsPerSecond: 2.5, aim: .06);
        CooBot sequentialBot() => CooBot(
          react: react,
          margin: .05,
          tapsPerSecond: 2.5,
          aim: .06,
          sequential: true,
        );
        expect(
          hurtRuns(staticBot, kind: 'fury'),
          greaterThanOrEqualTo(8),
          reason: 'the default bot has no height for fury\'s two formations',
        );
        expect(hurtRuns(sequentialBot, kind: 'fury'), lessThanOrEqualTo(4));
      });
    }

    test('calm V and picket: both bots, at 2.5 taps a second, are not hit', () {
      for (final kind in ['V', 'picket']) {
        for (final sequential in [false, true]) {
          expect(
            hurtRuns(
              () => CooBot(
                react: 1.0,
                margin: .05,
                tapsPerSecond: 2.5,
                aim: .06,
                sequential: sequential,
              ),
              kind: kind,
              runs: 8,
            ),
            lessThanOrEqualTo(2),
            reason: '$kind, sequential $sequential',
          );
        }
      }
    });
  });
}
