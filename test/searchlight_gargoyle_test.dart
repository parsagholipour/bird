import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/campaign.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/session_replay.dart';
import 'package:push_up_bird/domain/tracking.dart';

import 'boss_fight_test.dart' as endless show arena, snapshot, step;
import 'campaign_flight.dart';
import 'gargoyle_pilot.dart';
import 'gargoyle_viability.dart';
import 'ny_plans.dart';
import 'recorded_flight.dart';

/// The Searchlight Gargoyle's rules (report 04 §2), flown through the real
/// simulation: the aim latch, the beam that hurts like a course edge, the
/// lamp that only opens in the vent, fury's alternating sweeps, the stone
/// feathers, arrival and defeat, determinism, replays and seeks, the
/// campaign-only guardian path. The pure cycle and geometry are in
/// `searchlight_gargoyle_scaffold_test`; the fairness proof in
/// `searchlight_gargoyle_fairness_test`; the fight's length in
/// `searchlight_gargoyle_fight_test`.

const _period = SearchlightGargoyle.period;

/// Everything the Gargoyle's fight latches and counts, on top of the shared
/// boss snapshot: two runs that agree here flew the same fight.
Object gargoyleSnapshot(FlightSimulation sim) => [
  endless.snapshot(sim),
  if (sim.boss case final b?)
    [
      b.beamSide,
      b.slitSweep,
      b.sweepsAimed,
      b.sweepZone,
      b.sweepSlit,
      b.furySweeps,
      b.feathersLaunched,
      b.featherCycle,
      b.featherSlot,
      b.lastGlanceAt,
      b.spots,
      b.lastHitAt,
      b.enragedAt,
      b.beamCentres,
    ],
  sim.bossAmmo
      .map((a) => [a.x, a.y, a.vx, a.vy, a.radius, a.gravity, a.feather])
      .toList(),
  sim.invulnerableUntil,
  sim.flaps,
  sim.rockImpacts,
];

/// Keeps the bird where it is and unhurtable, for a test of something else.
void ghost(FlightSimulation sim) => sim.invulnerableUntil = 1e9;

/// A frame of [dt] with the bird held at [y].
void hold(
  FlightSimulation sim,
  double y, {
  double dt = 1 / 120,
  double width = 2.2,
}) {
  sim
    ..birdY = y
    ..velocity = 0;
  frame(sim, dt: dt, width: width);
}

/// Advances the fight to combat time [t] (cycle time, in cycle [cycle]) in
/// one jump of the clock: the catch-up the rules do at the next step is what
/// is under test. The step that follows lands just past [t].
void jumpTo(SkyBoss boss, double t, {int cycle = 0}) =>
    fightAt(boss, cycle * _period + t - 1 / 120);

/// A rock level with his lamp, about to touch it.
BirdRock rockAtLamp(SkyBoss boss, {int damage = 10, double charge = 0}) =>
    BirdRock(
      x: boss.x - .07,
      y: boss.y,
      damage: damage,
      charge: charge,
    );

void main() {
  group('the pure geometry the rules and the art share', () {
    test('a fury zone sweep glides in 1.5 s like the slit, a calm one in 1.8',
        () {
      const ignite = SearchlightGargoyle.sweepAt;
      for (final side in BeamSide.values) {
        final to = side == BeamSide.high ? .42 : .58;
        expect(
          SearchlightGargoyle.centre(side, ignite + 1.5, fury: true),
          closeTo(to, 1e-12),
        );
        expect(
          SearchlightGargoyle.centre(side, ignite + 1.5),
          isNot(closeTo(to, .005)),
        );
        expect(
          SearchlightGargoyle.centre(side, ignite + 1.8),
          closeTo(to, 1e-12),
        );
        // Never faster than .26 screen heights a second.
        var last = SearchlightGargoyle.centre(side, ignite, fury: true)!;
        for (var t = ignite + .01; t < SearchlightGargoyle.ventAt; t += .01) {
          final c = SearchlightGargoyle.centre(side, t, fury: true)!;
          expect((c - last).abs() / .01, lessThan(.27), reason: '$t');
          last = c;
        }
      }
    });

    test('centres() is one function for zone sweeps, slits and silence', () {
      for (var x = 0.0; x < _period; x += .07) {
        for (final fury in [false, true]) {
          expect(
            SearchlightGargoyle.centres(
              x,
              side: BeamSide.low,
              slit: false,
              fury: fury,
            ),
            [
              ?SearchlightGargoyle.centre(BeamSide.low, x, fury: fury),
            ],
          );
        }
        final pair = SearchlightGargoyle.slitCentres(x);
        expect(
          SearchlightGargoyle.centres(
            x,
            side: BeamSide.high,
            slit: true,
            fury: true,
          ),
          pair == null ? isEmpty : [pair.$1, pair.$2],
        );
        if (!SearchlightGargoyle.beamOn(x)) {
          expect(
            SearchlightGargoyle.centres(
              x,
              side: BeamSide.high,
              slit: false,
              fury: false,
            ),
            isEmpty,
          );
        }
      }
    });

    test('feathers due by the clock: none in the vent, the perch one always', () {
      int due(double x, {bool enraged = false, bool slit = false}) =>
          SearchlightGargoyle.launchesDue(x, enraged: enraged, slit: slit);
      expect(due(.19), 0);
      expect(due(.2), 1);
      expect(due(4.59), 1);
      expect(due(4.6), 2);
      expect(due(6.39), 2);
      expect(due(6.4), 0, reason: 'the vent is quiet');
      expect(due(8.9), 0);
      expect(due(4.5, enraged: true), 2);
      expect(due(5.2, enraged: true), 3);
      expect(due(6.3, enraged: true, slit: true), 1);
      // A fury begun in the vent adds no late feather there.
      expect(due(7.0, enraged: true), 0);
    });
  });

  group('the fight begins and ends like the other bosses', () {
    test('he arrives for 4.6 s, never swoops, and fights from then', () {
      final sim = nyFlight(gargoylePlan());
      var arriving = 0;
      var saw = false;
      flyLevel(
        sim,
        sprintWhen: (sim, frame) => false,
        until: (sim) {
          final boss = sim.boss;
          if (boss == null) return false;
          saw = true;
          expect(boss.cinematic, isTrue);
          expect(boss.arrivalDuration, 4.6);
          expect(boss.departureDuration, 3.8);
          expect(boss.kind, BossKind.searchlightGargoyle);
          expect(boss.maxHp, 160);
          if (boss.phase == BossPhase.arriving) {
            arriving++;
            expect(sim.bossCutscene, isTrue);
            expect(boss.inCutscene, isTrue);
            expect(boss.y, SearchlightGargoyle.anchorY, reason: 'no swoop');
            expect(boss.age, lessThan(4.6 + .03));
            // Nothing burns, leaves or latches during the cutscene.
            expect(boss.beamOn, isFalse);
            expect(boss.beamCentres, isEmpty);
            expect(boss.lampOpen, isFalse);
            expect(sim.bossAmmo, isEmpty);
            expect(boss.sweepsAimed, 0);
            expect(boss.feathersLaunched, 0);
          }
          return boss.phase == BossPhase.attacking;
        },
      );
      expect(saw, isTrue);
      // 4.6 s of arrival at the flight's 50 frames a second.
      expect(arriving, inInclusiveRange(229, 231));
      expect(sim.boss!.phase, BossPhase.attacking);
      expect(sim.bossCutscene, isFalse);
    });

    test('he stands on his ledge: no hover, at the anchor from the start', () {
      for (final width in [1.6, 1.78, 2.2, 2.4]) {
        final sim = arena(width: width);
        final boss = sim.boss!;
        final anchor = math.max(birdX + .74, width - .50);
        expect(boss.x, closeTo(anchor, 1e-9), reason: '$width');
        ghost(sim);
        for (var i = 0; i < 600; i++) {
          hold(sim, .5, dt: 1 / 60, width: width);
          expect(boss.y, SearchlightGargoyle.anchorY);
          expect(boss.x, closeTo(anchor, 1e-9));
        }
      }
    });

    test('the cycle runs on his clock: aim at 2.0, ignition at 3.5, vent at 6.4',
        () {
      final sim = arena();
      final boss = sim.boss!;
      ghost(sim);
      final edges = <String, double>{};
      var before = (
        boss.sweepWarnings,
        boss.sweepIgnitions,
        boss.lampOpens,
        boss.feathersLaunched,
        boss.gargoylePhase,
      );
      for (var i = 0; i < 60 * 19; i++) {
        hold(sim, .5, dt: 1 / 60);
        final now = (
          boss.sweepWarnings,
          boss.sweepIgnitions,
          boss.lampOpens,
          boss.feathersLaunched,
          boss.gargoylePhase,
        );
        final at = boss.combatTime;
        if (now.$1 != before.$1) edges['warn ${now.$1}'] = at;
        if (now.$2 != before.$2) edges['ignite ${now.$2}'] = at;
        if (now.$3 != before.$3) edges['vent ${now.$3}'] = at;
        if (now.$4 != before.$4) edges['feather ${now.$4}'] = at;
        if (now.$5 != before.$5) edges['phase ${now.$5.name} @${at.floor()}'] = at;
        before = now;
      }
      double e(String key) => edges[key]!;
      expect(e('warn 1'), closeTo(2.0, .02));
      expect(e('ignite 1'), closeTo(3.5, .02));
      expect(e('vent 1'), closeTo(6.4, .02));
      expect(e('warn 2'), closeTo(_period + 2.0, .02));
      expect(e('ignite 2'), closeTo(_period + 3.5, .02));
      expect(e('vent 2'), closeTo(_period + 6.4, .02));
      // The aim is latched in the same step its warning begins.
      expect(boss.sweepsAimed, boss.sweepWarnings);
      // Two feathers a calm cycle: .2 and 4.6.
      expect(e('feather 1'), closeTo(.2, .02));
      expect(e('feather 2'), closeTo(4.6, .02));
      expect(e('feather 3'), closeTo(_period + .2, .02));
      expect(e('feather 4'), closeTo(_period + 4.6, .02));
    });

    test('each sweep is aimed once, from the bird as its warning begins', () {
      for (final (y, side) in [
        (.12, BeamSide.high),
        (.3, BeamSide.high),
        (.4999, BeamSide.high),
        (.5, BeamSide.low),
        (.7, BeamSide.low),
        (.92, BeamSide.low),
      ]) {
        final sim = arena();
        ghost(sim);
        final boss = sim.boss!;
        jumpTo(boss, SearchlightGargoyle.warnAt - .02);
        hold(sim, y, dt: 1 / 120);
        expect(boss.sweepsAimed, 0, reason: 'not yet, at $y');
        jumpTo(boss, SearchlightGargoyle.warnAt);
        hold(sim, y, dt: 1 / 120);
        expect(boss.sweepWarnings, 1);
        expect(boss.sweepsAimed, 1, reason: '$y');
        expect(boss.beamSide, side, reason: '$y');
        expect((boss.sweepZone, boss.sweepSlit), (1, 0));
        expect(boss.slitSweep, isFalse, reason: 'a calm sweep is a zone sweep');
        // Moving afterwards does not re-aim it; nor does the ignition.
        for (var i = 0; i < 200; i++) {
          hold(sim, 1 - y, dt: 1 / 120);
        }
        expect(boss.beamSide, side);
        expect(boss.sweepsAimed, 1);
        expect(boss.gargoyleHint, contains('BEAM'));
      }
    });

    test('sweeps are aimed in step with the clock through a whole fight', () {
      final sim = arena();
      final boss = sim.boss!;
      final pilot = Pilot();
      var aimed = 0, frames = 0;
      while (boss.phase == BossPhase.attacking && frames < 60 * 300) {
        pilot.fly(sim);
        frames++;
        if (boss.phase != BossPhase.attacking) break;
        expect(boss.sweepsAimed, boss.sweepWarnings);
        expect(boss.sweepZone + boss.sweepSlit, boss.sweepsAimed);
        aimed = boss.sweepsAimed;
      }
      expect(boss.phase, BossPhase.defeated);
      expect(aimed, greaterThanOrEqualTo(3));
    });
  });

  group('the counters the audio reads', () {
    test('they only rise, one edge at a time; a rock on the circle glances '
        'exactly while the shutters are closed', () {
      final sim = arena();
      final boss = sim.boss!;
      final pilot = Pilot(fireFrom: 99); // the pilot never fires: rocks are ours
      List<num> read() => [
        boss.sweepWarnings,
        boss.sweepIgnitions,
        boss.lampOpens,
        boss.feathersLaunched,
        boss.spots,
        boss.sweepsAimed,
        boss.lastGlanceAt,
      ];
      var last = read();
      var glances = 0, frames = 0, hitsInVent = 0;
      while (boss.combatTime < 3 * _period) {
        pilot.fly(sim);
        frames++;
        if (frames % 25 == 0) {
          // A rock on the circle every 0.4 s: it glances off shutters or
          // lands in the vent, never both and never neither.
          final hp = boss.hp, glance = boss.lastGlanceAt;
          sim.rocks.add(rockAtLamp(boss, damage: 1));
          final open = boss.lampOpen;
          frame(sim, dt: 1 / 60);
          frames++;
          if (boss.lampOpen == open) {
            expect(hp - boss.hp, open ? 1 : 0, reason: 'at ${boss.combatTime}');
            expect(
              boss.lastGlanceAt > glance,
              !open,
              reason: 'at ${boss.combatTime}',
            );
            if (open) {
              hitsInVent++;
            } else {
              glances++;
            }
          }
        }
        final now = read();
        for (var i = 0; i < now.length; i++) {
          expect(now[i], greaterThanOrEqualTo(last[i]), reason: 'counter $i');
          if (i < 6) {
            expect(now[i] - last[i], lessThanOrEqualTo(2), reason: 'counter $i');
          }
        }
        last = now;
      }
      expect(glances, greaterThan(20));
      expect(hitsInVent, greaterThan(5));
      expect(boss.hp, 160 - hitsInVent);
      expect(boss.spots, 0);
    });

    test('a seek replays the fight silently: counters come back the same', () {
      // The recorded fight's replay (see the seek tests) re-simulates from the
      // start, so an edge detector that snapshots with silent: true sees a
      // counter that has simply caught up, never one that fired again.
      final sim = arena();
      final boss = sim.boss!;
      ghost(sim);
      jumpTo(boss, 7.0, cycle: 2);
      hold(sim, .5);
      expect(boss.sweepWarnings, 3);
      expect(boss.sweepIgnitions, 3);
      expect(boss.lampOpens, 3);
      expect(boss.lampOpen, isTrue);
    });
  });

  group('the beam hurts like a course edge', () {
    /// A fight [sweep] standing at cycle time [t], the bird at [y].
    FlightSimulation inSweep(
      double t, {
      BeamSide side = BeamSide.high,
      bool slit = false,
      bool fury = false,
      FlightSimulation? from,
    }) {
      final sim = from ?? arena();
      final boss = sim.boss!
        ..beamSide = side
        ..slitSweep = slit
        ..sweepsAimed = 1
        ..featherCycle = 0
        ..featherSlot = 9;
      if (fury || slit) boss.hp = SearchlightGargoyle.furyHp;
      sim.invulnerableUntil = 0;
      jumpTo(boss, t);
      return sim;
    }

    test('the lit band hurts and the dark side is safe, to the last hair', () {
      const r = birdR;
      for (final fury in [false, true]) {
        final half = fury ? .095 : .09;
        for (final side in BeamSide.values) {
          // The beam holds at its inner end from 5.3 s (fury 5.0).
          final inner = side == BeamSide.high ? .42 : .58;
          final edge = side == BeamSide.high
              ? inner + half + r
              : inner - half - r;
          final dark = side == BeamSide.high ? edge + .003 : edge - .003;
          final lit = side == BeamSide.high ? edge - .003 : edge + .003;
          final safe = inSweep(5.6, side: side, fury: fury);
          final boss = safe.boss!;
          hold(safe, dark);
          expect(boss.beamOn, isTrue);
          expect(boss.beamLit(dark, r), isFalse);
          expect((safe.shield, safe.hearts, boss.spots), (true, 3, 0));
          final spotted = inSweep(5.6, side: side, fury: fury);
          hold(spotted, lit);
          expect(spotted.boss!.beamLit(lit, r), isTrue);
          expect(
            (spotted.shield, spotted.hearts, spotted.boss!.spots),
            (false, 3, 1),
            reason: '$side fury=$fury',
          );
        }
      }
    });

    test('a bird in the beam loses the shield, then a heart, with 1.5 s between',
        () {
      final sim = inSweep(4.5);
      final boss = sim.boss!;
      hold(sim, .42);
      expect((sim.shield, sim.hearts, boss.spots), (false, 3, 1));
      expect(sim.invulnerableUntil, closeTo(sim.elapsed + 1.5, .02));
      // Still in the light while recovering: no second hurt, no second spot.
      for (var i = 0; i < 100; i++) {
        hold(sim, .42);
      }
      expect((sim.hearts, boss.spots), (3, 1));
      // Recovered and still lit: a heart goes.
      final recovered = sim.invulnerableUntil + .01;
      while (sim.elapsed < recovered) {
        hold(sim, .42);
      }
      hold(sim, .42);
      expect((sim.hearts, boss.spots), (2, 2));
      expect(
        sim.events.where((e) => e.kind == FlightEventKind.shieldUsed),
        hasLength(1),
      );
      expect(
        sim.events.where((e) => e.kind == FlightEventKind.hit),
        hasLength(1),
      );
    });

    test('the last heart ends the flight', () {
      final sim = inSweep(5.0);
      sim
        ..shield = false
        ..hearts = 1;
      hold(sim, .42);
      expect(sim.phase, RunPhase.ended);
      expect(sim.endReason, EndReason.collision);
    });

    test('in a Classic flight touching the light ends the run', () {
      final sim = endless.arena(
        version: FlightSimulation.currentRulesVersion,
        course: FlightCourse.classic,
      );
      final boss = SkyBoss(
        number: 7,
        x: 1.7,
        kind: BossKind.searchlightGargoyle,
        cinematic: true,
      );
      sim.boss = boss;
      boss
        ..beamSide = BeamSide.high
        ..sweepsAimed = 1
        ..featherCycle = 0
        ..featherSlot = 9;
      fightAt(boss, 5.0);
      sim
        ..birdY = .8
        ..velocity = 0;
      endless.step(sim, 1 / 120);
      expect(sim.phase, RunPhase.playing);
      sim.birdY = .42;
      sim.velocity = 0;
      endless.step(sim, 1 / 120);
      expect(sim.phase, RunPhase.ended);
      expect(sim.endReason, EndReason.collision);
    });

    test('the warning is fair: nothing burns before ignition or in the vent', () {
      final sim = arena();
      final boss = sim.boss!
        ..beamSide = BeamSide.high
        ..sweepsAimed = 1
        ..featherCycle = 0
        ..featherSlot = 9;
      sim.invulnerableUntil = 0;
      // Right in the middle of where the beam will be, through the perch, the
      // warning (to the very last instant) and the vent.
      for (final (from, to) in [(.0, 3.49), (6.41, 8.99)]) {
        jumpTo(boss, from);
        while (boss.gargoyleCycle < to) {
          hold(sim, .3, dt: 1 / 120);
          if (boss.gargoyleCycle < 2.0 || boss.gargoyleCycle > 6.4) {
            expect(boss.beamOn, isFalse);
          }
          expect(sim.phase, RunPhase.playing);
        }
      }
      expect((sim.shield, sim.hearts, boss.spots), (true, 3, 0));
      // Ignition lights the beam at its outer end, away from the middle.
      jumpTo(boss, 3.5);
      hold(sim, .5, dt: 1 / 120);
      expect(boss.beamOn, isTrue);
      expect(boss.beamCentres.single, closeTo(.16, .002));
      expect(sim.shield, isTrue, reason: 'nothing burns at .5 yet');
    });

    test('the beam glides into a waiting bird and finds it', () {
      // A bird at .3 under a high beam: the band reaches it on the way down.
      final sim = arena();
      ghost(sim);
      final boss = sim.boss!
        ..beamSide = BeamSide.high
        ..sweepsAimed = 1
        ..featherCycle = 0
        ..featherSlot = 9;
      sim.invulnerableUntil = 0;
      jumpTo(boss, 3.5);
      var foundAt = -1.0;
      while (boss.gargoyleCycle < 6.39) {
        hold(sim, .3, dt: 1 / 120);
        if (sim.shield == false && foundAt < 0) foundAt = boss.gargoyleCycle;
      }
      // |.3 - c| < .09 + .038 first holds for c > .172, well into the glide.
      expect(foundAt, inInclusiveRange(3.5, 4.3));
      final c = SearchlightGargoyle.centre(BeamSide.high, foundAt)!;
      expect(c, closeTo(.172, .01));
    });

    test('his cutscenes never hurt: not his arrival, not his defeat', () {
      final sim = nyFlight(gargoylePlan());
      var arrivalFrames = 0;
      flyLevel(
        sim,
        sprintWhen: (sim, frame) => false,
        keepAlive: false,
        watch: (sim) {
          final boss = sim.boss;
          if (boss == null || boss.phase != BossPhase.arriving) return;
          arrivalFrames++;
          // The bot's own shield is still up: no beam at any height.
          expect(boss.beamLit(sim.birdY, birdR), isFalse);
          expect(sim.shield, isTrue);
        },
        until: (sim) => sim.boss?.phase == BossPhase.attacking,
      );
      expect(arrivalFrames, greaterThan(200));
      // Beaten in the middle of a sweep: the beam goes out with him.
      final boss = sim.boss!;
      sim
        ..birdY = .5
        ..velocity = 0
        ..invulnerableUntil = 0;
      boss
        ..beamSide = BeamSide.high
        ..sweepsAimed = 1
        ..featherCycle = 0
        ..featherSlot = 9;
      jumpTo(boss, 5.0);
      hold(sim, .8);
      expect(boss.beamOn, isTrue);
      boss.hp = 1; // the lamp is shuttered: only the vent takes damage
      jumpTo(boss, 7.0);
      sim.rocks.add(rockAtLamp(boss));
      hold(sim, .8);
      expect(boss.phase, BossPhase.defeated);
      expect(boss.beamOn, isFalse);
      expect(boss.beamCentres, isEmpty);
      expect(boss.lampOpen, isFalse);
      expect(sim.bossAmmo, isEmpty);
      // The defeat's 3.8 s have nothing in the sky to fear.
      for (var i = 0; i < 380; i++) {
        hold(sim, .42, dt: .01);
        expect(boss.beamLit(.42, birdR), isFalse);
      }
      expect(sim.shield, isTrue, reason: 'beaten boss pays the shield back');
      expect(sim.hearts, 3);
    });
  });

  group('the lamp: shuttered, then open in the vent', () {
    FlightSimulation fightAtCycle(double t, {int cycle = 0, int hp = 160}) {
      final sim = arena();
      ghost(sim);
      final boss = sim.boss!
        ..sweepsAimed = cycle + 1
        ..featherCycle = cycle
        ..featherSlot = 9
        ..hp = hp;
      jumpTo(boss, t, cycle: cycle);
      return sim;
    }

    test('a rock on the shuttered lamp clinks off and does nothing', () {
      for (final t in [.5, 1.9, 2.1, 3.4, 3.6, 5.0, 6.3]) {
        final sim = fightAtCycle(t);
        final boss = sim.boss!;
        sim.rocks.add(rockAtLamp(boss, damage: 40));
        hold(sim, .3);
        expect(boss.hp, 160, reason: 'at $t');
        expect(boss.lastHitAt, double.negativeInfinity, reason: 'at $t');
        expect(boss.lastDamage, 0);
        expect(boss.lastGlanceAt, boss.age, reason: 'a glance at $t');
        expect(sim.rocks, isEmpty, reason: 'the rock is spent');
        expect(boss.phase, BossPhase.attacking);
      }
    });

    test('the lamp opens at 6.4 s and shuts at 9.0 s: hits count in between', () {
      final hits = <double, int>{};
      for (final t in [6.39, 6.41, 7.0, 8.0, 8.99, 9.02, 9.3]) {
        final sim = fightAtCycle(t - (t >= 9 ? _period : 0));
        final boss = sim.boss!;
        sim.rocks.add(rockAtLamp(boss, damage: 10));
        hold(sim, .3);
        hits[t] = 160 - boss.hp;
      }
      expect(hits, {
        6.39: 0,
        6.41: 10,
        7.0: 10,
        8.0: 10,
        8.99: 10,
        9.02: 0,
        9.3: 0,
      });
      // The second cycle's vent is the same.
      final sim = fightAtCycle(7.0, cycle: 1);
      sim.rocks.add(rockAtLamp(sim.boss!, damage: 10));
      hold(sim, .3);
      expect(sim.boss!.hp, 150);
    });

    test('open, every weapon hits in full; charged shots too; no bonus', () {
      for (final (damage, charge) in [(10, 0.0), (30, 0.0), (90, .7), (40, 1.0)]) {
        final sim = fightAtCycle(7.0);
        final boss = sim.boss!;
        sim.rocks.add(rockAtLamp(boss, damage: damage, charge: charge));
        hold(sim, .3);
        expect(160 - boss.hp, damage, reason: '$damage charge $charge');
        expect(boss.lastDamage, damage);
        expect(boss.lastHitAt, boss.age);
        expect(boss.lastGlanceAt, double.negativeInfinity);
      }
    });

    test('a charged shot\'s shattering blast is gated like a rock', () {
      for (final (t, expected) in [(5.0, 160), (7.0, 145)]) {
        final sim = fightAtCycle(t);
        final boss = sim.boss!;
        // A pellet well short of his circle: the blast reaches him, the rock
        // does not.
        sim.enemyAmmo.add(
          EnemyAmmo(
            x: boss.x - .30,
            y: boss.y,
            vx: 0,
            vy: 0,
            attack: EnemyAttack.aimed,
            bornAt: sim.elapsed,
          ),
        );
        sim.rocks.add(
          BirdRock(
            x: boss.x - .30,
            y: boss.y,
            damage: 30,
            charge: 1,
          ),
        );
        hold(sim, .3);
        expect(sim.ammoShattered, 1, reason: 'at $t');
        expect(boss.hp, expected, reason: 'the blast deals half: 15 open');
        if (t < 6.4) {
          expect(boss.lastGlanceAt, boss.age);
        } else {
          expect(boss.lastGlanceAt, double.negativeInfinity);
        }
      }
    });

    test('fury begins at half health, in the vent, and only then', () {
      final sim = fightAtCycle(7.0, hp: 90);
      final boss = sim.boss!;
      expect(boss.enraged, isFalse);
      sim.rocks.add(rockAtLamp(boss, damage: 10));
      hold(sim, .3);
      expect(boss.hp, 80);
      expect(boss.enraged, isTrue);
      expect(boss.enragedAt, boss.lastHitAt);
      // A rock that glances cannot start it.
      final calm = fightAtCycle(5.0, hp: 81);
      calm.rocks.add(rockAtLamp(calm.boss!, damage: 10));
      hold(calm, .3);
      expect(calm.boss!.hp, 81);
      expect(calm.boss!.enraged, isFalse);
    });

    test('a shuttered glance does not flash the health bar or start fury', () {
      final sim = fightAtCycle(5.0, hp: 81);
      final boss = sim.boss!;
      final hitAt = boss.lastHitAt, enragedAt = boss.enragedAt;
      for (var i = 0; i < 5; i++) {
        sim.rocks.add(rockAtLamp(boss, damage: 30));
        hold(sim, .3);
      }
      expect((boss.lastHitAt, boss.enragedAt), (hitAt, enragedAt));
      expect(boss.hp, 81);
    });

    test('the kill pays once, and only in the vent; a level then glides home',
        () {
      final sim = arena(weaponDamage: 200);
      final boss = sim.boss!;
      final score = sim.score;
      // He cannot be killed through shutters, however hard the hit.
      sim.rocks.add(rockAtLamp(boss, damage: 500));
      hold(sim, .5, dt: 1 / 60);
      expect(boss.hp, 160);
      expect(sim.bossesDefeated, 0);
      jumpTo(boss, 7.0);
      sim.rocks.add(rockAtLamp(boss, damage: 500));
      sim.rocks.add(rockAtLamp(boss, damage: 500));
      hold(sim, .5, dt: 1 / 60);
      expect(boss.hp, 0);
      expect(boss.phase, BossPhase.defeated);
      expect(sim.bossesDefeated, 1);
      expect(sim.score - score, FlightSimulation.bossBonus);
      expect(sim.victoryGlide, isTrue);
    });
  });

  group('fury: two beams close on a slit the bird must hold', () {
    /// Flies through [cycles] cycles with a pilot that stays alive, from a
    /// fight whose health is [hp]; returns each sweep's kind as aimed.
    List<String> aimedSweeps(int cycles, {required int hp}) {
      final sim = arena();
      final boss = sim.boss!..hp = hp;
      final pilot = Pilot(fireFrom: 99); // never shoots: health stays put
      final kinds = <String>[];
      var aimed = 0;
      while (aimed < cycles) {
        pilot.fly(sim);
        if (boss.sweepsAimed > aimed) {
          aimed = boss.sweepsAimed;
          kinds.add(boss.slitSweep ? 'slit' : 'zone');
        }
        expect(sim.phase, RunPhase.playing);
        expect(boss.spots, 0);
      }
      expect(boss.enraged, hp <= 80);
      return kinds;
    }

    test('a calm fight is all zone sweeps', () {
      expect(aimedSweeps(4, hp: 160), ['zone', 'zone', 'zone', 'zone']);
      expect(aimedSweeps(2, hp: 81), ['zone', 'zone']);
    });

    test('fury alternates: zone first, then slit, zone, slit', () {
      expect(aimedSweeps(4, hp: 80), ['zone', 'slit', 'zone', 'slit']);
      expect(aimedSweeps(3, hp: 1), ['zone', 'slit', 'zone']);
    });

    test('the counters say the same: zone + slit, and fury sweeps', () {
      final sim = arena();
      final boss = sim.boss!..hp = 80;
      final pilot = Pilot(fireFrom: 99);
      while (boss.sweepsAimed < 5) {
        pilot.fly(sim);
      }
      expect((boss.sweepZone, boss.sweepSlit), (3, 2));
      expect(boss.furySweeps, 5);
      expect(boss.sweepsAimed, 5);
    });

    test('fury begun in the vent takes effect at the next warning', () {
      final sim = arena();
      final boss = sim.boss!..hp = 90;
      final pilot = Pilot(fireFrom: 99);
      // Run the first cycle calm, then take the health to 80 in its vent.
      while (boss.gargoyleCycleNumber < 1 || boss.gargoyleCycle < 6.6) {
        pilot.fly(sim);
        if (boss.gargoyleCycleNumber == 1) break;
      }
      expect(boss.sweepsAimed, 1);
      expect(boss.slitSweep, isFalse);
      expect(boss.furySweeps, 0, reason: 'calm sweeps are not fury sweeps');
      while (boss.gargoyleCycleNumber == 0 && boss.gargoyleCycle < 7.0) {
        pilot.fly(sim);
      }
      boss.takeDamage(10);
      expect(boss.enraged, isTrue);
      // The next sweep (cycle 1's) is the first of fury: a zone sweep; the
      // one after is the slit.
      while (boss.sweepsAimed < 2) {
        pilot.fly(sim);
      }
      expect(boss.slitSweep, isFalse);
      expect(boss.furySweeps, 1);
      while (boss.sweepsAimed < 3) {
        pilot.fly(sim);
      }
      expect(boss.slitSweep, isTrue);
    });

    test('a slit burns two beams that hold a .314 tall gap', () {
      final sim = arena();
      ghost(sim);
      final boss = sim.boss!
        ..hp = 80
        ..slitSweep = true
        ..sweepsAimed = 1
        ..featherCycle = 0
        ..featherSlot = 9;
      jumpTo(boss, 3.5);
      hold(sim, .5);
      expect(boss.beamCentres, hasLength(2));
      expect(boss.beamCentres[0], closeTo(.12, .003));
      expect(boss.beamCentres[1], closeTo(.88, .003));
      // The gap closes in 1.5 s (fury), then holds.
      jumpTo(boss, 3.5 + 1.5);
      hold(sim, .5);
      expect(boss.beamCentres[0], closeTo(.21, 1e-6));
      expect(boss.beamCentres[1], closeTo(.79, 1e-6));
      jumpTo(boss, 6.0);
      hold(sim, .5);
      expect(boss.beamCentres[0], closeTo(.21, 1e-9));
      // The gap, for the bird's centre: .343 to .657, to the hair.
      sim.invulnerableUntil = 0;
      for (final (y, hurt) in [
        (.343 + .002, false),
        (.657 - .002, false),
        (.343 - .003, true),
      ]) {
        final trial = sim.shield;
        hold(sim, y);
        expect(!sim.shield, hurt || !trial, reason: '$y');
        sim
          ..shield = true
          ..invulnerableUntil = 0;
      }
      hold(sim, .657 + .003);
      expect(sim.shield, isFalse);
    });

    test('a fury zone sweep is .095 tall and glides in 1.5 s, not 1.8', () {
      final calm = arena();
      final fury = arena();
      for (final (sim, enraged) in [(calm, false), (fury, true)]) {
        ghost(sim);
        final boss = sim.boss!
          ..hp = enraged ? 80 : 160
          ..beamSide = BeamSide.high
          ..sweepsAimed = 1
          ..featherCycle = 0
          ..featherSlot = 9;
        jumpTo(boss, 3.5 + 1.5);
        hold(sim, .9);
        final c = boss.beamCentres.single;
        if (enraged) {
          expect(c, closeTo(.42, 1e-6), reason: 'arrived');
          expect(boss.beamHalf, .095);
        } else {
          expect(c, lessThan(.42 - .01), reason: 'still gliding');
          expect(boss.beamHalf, .09);
        }
      }
    });

    test('health only changes in the vent (and as its last rocks land in the '
        'next perch), so fury is constant from each warning to the end of its '
        'sweep', () {
      final sim = arena(weaponDamage: 30);
      final boss = sim.boss!;
      final pilot = Pilot(cadence: .2);
      final hpAt = <int, int>{};
      var frames = 0, last = boss.hp;
      while (boss.phase == BossPhase.attacking && frames < 60 * 300) {
        pilot.fly(sim);
        frames++;
        final x = boss.gargoyleCycle;
        if (boss.hp != last) {
          // Rocks released in the vent land up to .8 s into the next cycle.
          expect(
            x >= SearchlightGargoyle.ventAt || x < .8,
            isTrue,
            reason: 'health changed at cycle time $x',
          );
          last = boss.hp;
        }
        if (x >= SearchlightGargoyle.warnAt && x < SearchlightGargoyle.ventAt) {
          hpAt.putIfAbsent(boss.gargoyleCycleNumber, () => boss.hp);
          expect(
            boss.hp,
            hpAt[boss.gargoyleCycleNumber],
            reason: 'hit through the shutters at $x',
          );
        }
      }
      expect(boss.phase, BossPhase.defeated);
    });
  });

  group('stone feathers fall from the cornice', () {
    /// Flies on with the bird held at [away] (out of any lane, and unhurtable)
    /// for [seconds]; returns the feathers that crossed the bird's column, each
    /// with the height and the combat time at which it did.
    List<({double crossY, double crossAt, BossAmmo feather})> crossings(
      FlightSimulation sim,
      double away,
      double seconds, {
      double width = 2.2,
    }) {
      ghost(sim);
      final seen = <BossAmmo, (double, double)>{};
      final boss = sim.boss!;
      final until = boss.age + seconds;
      final last = <BossAmmo, double>{};
      for (final f in sim.bossAmmo.where((a) => a.feather)) {
        last[f] = f.x;
      }
      while (boss.age < until) {
        hold(sim, away, dt: 1 / 120, width: width);
        for (final f in sim.bossAmmo.where((a) => a.feather)) {
          final previous = last[f];
          last[f] = f.x;
          if (previous != null && previous > birdX && f.x <= birdX) {
            seen[f] = (f.y, boss.combatTime);
          }
        }
      }
      return [
        for (final e in seen.entries)
          (crossY: e.value.$1, crossAt: e.value.$2, feather: e.key),
      ];
    }

    test('one leaves the perch at .2 s and one at 4.6 s, then two a cycle', () {
      final sim = arena();
      final boss = sim.boss!;
      ghost(sim);
      final launches = <double>[];
      var count = 0;
      while (boss.combatTime < 2 * _period) {
        hold(sim, .5, dt: 1 / 60);
        if (boss.feathersLaunched > count) {
          count = boss.feathersLaunched;
          launches.add(boss.combatTime);
        }
      }
      expect(launches.length, 4);
      for (final (i, at) in [.2, 4.6, _period + .2, _period + 4.6].indexed) {
        expect(launches[i], closeTo(at, .02), reason: '$i');
      }
    });

    test('fury drops three on a zone cycle and one on a slit cycle', () {
      final sim = arena();
      final boss = sim.boss!..hp = 80;
      final pilot = Pilot(fireFrom: 99);
      final perCycle = <int, List<double>>{};
      var seen = 0;
      while (boss.gargoyleCycleNumber < 4) {
        pilot.fly(sim);
        if (boss.feathersLaunched > seen) {
          seen = boss.feathersLaunched;
          perCycle
              .putIfAbsent(boss.gargoyleCycleNumber, () => [])
              .add(boss.gargoyleCycle);
        }
      }
      // Cycle 0 zone (.2, 4.5, 5.2), cycle 1 slit (.2), cycle 2 zone, cycle 3
      // slit. The perch feather leaves before the sweep's kind is known, so
      // it is in every cycle.
      expect(perCycle[0]!.length, 3);
      expect(perCycle[0]![0], closeTo(.2, .02));
      expect(perCycle[0]![1], closeTo(4.5, .02));
      expect(perCycle[0]![2], closeTo(5.2, .02));
      expect(perCycle[1]!.length, 1);
      expect(perCycle[2]!.length, 3);
      expect(perCycle[3]!.length, 1);
    });

    test('it leaves just above and ahead of the bird and crosses its column '
        'at the height the bird had as it left', () {
      for (final width in [1.6, 1.78, 2.2, 2.4]) {
        for (final y in [.12, .3, .5, .7, .9]) {
          final sim = arena(width: width);
          final boss = sim.boss!;
          ghost(sim);
          // Until the perch feather has left.
          while (boss.feathersLaunched == 0) {
            hold(sim, y, dt: 1 / 120);
          }
          final f = sim.bossAmmo.single;
          expect(f.feather, isTrue);
          expect(f.x, closeTo(birdX + .62, .01), reason: 'width $width');
          expect(f.y, closeTo(-.06, .01));
          expect(f.vx, -.36);
          expect(f.radius, .028);
          expect(f.gravity, .30);
          expect(f.cannonball, isTrue);
          final seen = crossings(sim, y < .5 ? .95 : .05, 2.2, width: width);
          expect(seen, hasLength(1), reason: '$y');
          final c = seen.single;
          expect(c.crossY, closeTo(y, .01), reason: 'width $width, y $y');
          // 1.72 s of flight from the launch at .2: the column at 1.92 s.
          expect(c.crossAt, closeTo(.2 + 1.72, .03));
        }
      }
    });

    test('it is faster in fury: .44 a second, 1.41 s to the column', () {
      final sim = arena();
      final boss = sim.boss!..hp = 80;
      ghost(sim);
      while (boss.feathersLaunched == 0) {
        hold(sim, .6, dt: 1 / 120);
      }
      expect(sim.bossAmmo.single.vx, -.44);
      final seen = crossings(sim, .95, 2.0);
      expect(seen.single.crossAt, closeTo(.2 + 1.41, .03));
      expect(seen.single.crossY, closeTo(.6, .01));
    });

    test('a bird that stays in its lane is struck; one that leaves is not', () {
      for (final dodge in [false, true]) {
        final sim = arena();
        final boss = sim.boss!;
        sim.invulnerableUntil = 0;
        while (boss.feathersLaunched == 0) {
          hold(sim, .5, dt: 1 / 120);
        }
        // Stay, or drop well out of the lane (the feather needs about .13).
        final y = dodge ? .75 : .5;
        while (boss.combatTime < 2.0) {
          hold(sim, y, dt: 1 / 120);
        }
        expect(sim.shield, dodge, reason: dodge ? 'dodged' : 'struck');
        expect(sim.hearts, 3);
        expect(boss.spots, 0, reason: 'a feather is not a spot');
      }
    });

    test('a feather aimed from the very top climbs out of sight and still '
        'falls back to its lane', () {
      final sim = arena();
      final boss = sim.boss!;
      ghost(sim);
      while (boss.feathersLaunched == 0) {
        hold(sim, .05, dt: 1 / 120);
      }
      final f = sim.bossAmmo.single;
      expect(f.vy, lessThan(0), reason: 'it is thrown upward');
      var apex = 0.0;
      // The bird leaves; the feather flies on to the column.
      while (sim.bossAmmo.contains(f) && f.x > birdX) {
        hold(sim, .95, dt: 1 / 120);
        apex = math.min(apex, f.y);
      }
      expect(apex, lessThan(-.1), reason: 'above the top edge, not culled');
      expect(sim.bossAmmo, contains(f), reason: 'still in flight at the column');
      expect(f.y, closeTo(.05, .02), reason: 'back at the bird\'s old height');
    });

    test('feathers that leave the screen are gone', () {
      final sim = arena();
      ghost(sim);
      var peak = 0;
      for (var i = 0; i < 60 * 40; i++) {
        hold(sim, .5, dt: 1 / 60);
        peak = math.max(peak, sim.bossAmmo.length);
        for (final a in sim.bossAmmo) {
          expect(a.x, greaterThan(-.11));
          expect(a.y, lessThan(1.1));
        }
      }
      expect(peak, lessThanOrEqualTo(2));
    });

    test('none is thrown during his arrival and all are swept up at his end',
        () {
      final sim = arena();
      final boss = sim.boss!;
      ghost(sim);
      while (boss.feathersLaunched < 1) {
        hold(sim, .5, dt: 1 / 60);
      }
      expect(sim.bossAmmo, isNotEmpty);
      jumpTo(boss, 7.0);
      sim.rocks.add(rockAtLamp(boss, damage: 500));
      hold(sim, .5);
      expect(boss.phase, BossPhase.defeated);
      expect(sim.bossAmmo, isEmpty);
      for (var i = 0; i < 400; i++) {
        hold(sim, .5, dt: .01);
        expect(sim.bossAmmo, isEmpty);
      }
    });
  });

  group('a player who taps five times a second can always get away', () {
    test('every start of the proof, flown through the real simulation', () {
      var flown = 0;
      for (final sweep in Sweep.values) {
        final sim = arena();
        final boss = sim.boss!;
        for (final start in survivableStarts()) {
          final search = Search(
            sweep,
            margin: .012,
            tail: .5,
            substeps: 2, // the simulation's 1/120 s substeps
          );
          final result = search.from(start)!;
          expect(result.safe, isTrue, reason: '$sweep $start');
          // The start of a warning, the sweep not yet aimed, the perch
          // feather gone by, this cycle's lane-setting feathers to come.
          sim.bossAmmo.clear();
          sim.rocks.clear();
          boss
            ..hp = sweep.fury ? SearchlightGargoyle.furyHp : 160
            ..sweepsAimed = 0
            ..slitSweep = false
            ..beamSide = BeamSide.high
            ..furySweeps = sweep.slit ? 1 : 0
            ..featherCycle = 0
            ..featherSlot = 1
            ..spots = 0;
          fightAt(boss, SearchlightGargoyle.warnAt - 1e-6);
          sim
            ..birdY = start.y
            ..velocity = start.velocity
            ..hearts = 3
            ..shield = true
            ..invulnerableUntil = 0;
          var step = (SearchlightGargoyle.warnAt / dt).round();
          final taps = result.taps.toSet();
          final end = (SearchlightGargoyle.ventAt + .5) / dt;
          while (step < end) {
            frame(sim, flap: taps.contains(step));
            step++;
            expect(sim.phase, RunPhase.playing, reason: '$sweep $start');
          }
          expect(
            (sim.hearts, sim.shield, boss.spots),
            (3, true, 0),
            reason: '$sweep $start: ${boss.sweepsAimed} ${boss.beamSide}',
          );
          expect(boss.slitSweep, sweep.slit, reason: '$sweep');
          expect(boss.beamSide, SearchlightGargoyle.aimAt(start.y));
          flown++;
        }
      }
      expect(flown, 351);
    });

    test('a pilot that re-plans with the search wins without a scratch, at '
        'phone widths', () {
      for (final width in [1.78, 2.2]) {
        final sim = arena(width: width);
        final boss = sim.boss!;
        final pilot = Pilot();
        var frames = 0;
        while (boss.phase == BossPhase.attacking && frames < 60 * 300) {
          pilot.fly(sim, width: width);
          frames++;
        }
        expect(boss.phase, BossPhase.defeated, reason: '$width');
        expect(boss.spots, 0, reason: '$width');
        expect((sim.hearts, sim.shield), (3, true), reason: '$width');
        expect(boss.hp, 0);
        // He went through both kinds of fury sweep on the way.
        expect(boss.sweepSlit, greaterThan(0));
      }
    });
  });

  group('determinism, pause, replays and seeks', () {
    test('a whole fight flown twice is identical, frame for frame', () {
      List<Object> run() {
        final sim = arena();
        final boss = sim.boss!;
        final pilot = Pilot(cadence: .45, fireFrom: .6, window: .3, offTarget: .3, seed: 7);
        final states = <Object>[];
        var frames = 0;
        while (boss.phase == BossPhase.attacking && frames < 60 * 300) {
          pilot.fly(sim);
          frames++;
          if (frames % 30 == 0) states.add(gargoyleSnapshot(sim));
        }
        states.add(gargoyleSnapshot(sim));
        return states;
      }

      final a = run();
      expect(a.length, greaterThan(60));
      expect(run(), a);
    });

    test('the fight draws no random numbers: fights of any length leave the '
        'flight\'s random where it was', () {
      int after(Pilot pilot, {required int weaponDamage}) {
        final sim = arena(weaponDamage: weaponDamage);
        final boss = sim.boss!;
        var frames = 0;
        while (boss.phase == BossPhase.attacking && frames < 60 * 300) {
          pilot.fly(sim);
          frames++;
        }
        expect(boss.phase, BossPhase.defeated);
        // Run out the glide to the finish and the end of his defeat.
        while (sim.boss != null && frames < 60 * 320) {
          frame(sim, dt: 1 / 60);
          frames++;
        }
        return sim.random.nextInt(1 << 30);
      }

      final quick = after(Pilot(), weaponDamage: 60);
      final slow = after(
        Pilot(cadence: .6, window: .1, offTarget: .1),
        weaponDamage: 10,
      );
      final other = after(Pilot(fireFrom: -.2, seed: 9), weaponDamage: 25);
      expect(slow, quick);
      expect(other, quick);
    });

    test('pause and resume freeze the beam and the feathers', () {
      final sim = arena();
      final boss = sim.boss!;
      ghost(sim);
      jumpTo(boss, 4.7);
      boss
        ..sweepsAimed = 1
        ..featherCycle = 0
        ..featherSlot = 1;
      for (var i = 0; i < 30; i++) {
        hold(sim, .8, dt: 1 / 60);
      }
      final before = gargoyleSnapshot(sim);
      sim.takeBreak();
      frame(sim, dt: .5);
      frame(sim, dt: 2);
      sim.resume();
      frame(sim, dt: 2);
      frame(sim, dt: 1.1);
      expect(gargoyleSnapshot(sim), before);
    });

    test('a level plan with him round-trips and needs rules 43', () {
      final plan = gargoylePlan();
      expect(plan.problem, isNull);
      expect(plan.hasMiniBoss, isTrue);
      expect(plan.boss, BossKind.searchlightGargoyle);
      expect(plan.minRulesVersion, 43);
      final copy = LevelPlan.fromJson(
        jsonDecode(jsonEncode(plan.toJson())) as Map<String, dynamic>,
      );
      expect(copy.toJson(), plan.toJson());
      expect(copy.boss, BossKind.searchlightGargoyle);
      expect(() => nyFlight(plan, version: 41), throwsArgumentError);
      expect(() => nyFlight(plan, version: 42), throwsArgumentError);
      expect(nyFlight(plan).supportsMiniBosses, isTrue);
    });

    /// A recorded flight of the Gargoyle's level at 60 frames a second: the
    /// shared bot for the run-up, the pilot for the fight.
    ({ReplayTape tape, FlightSimulation sim, Map<double, Object> marks})
    record({int weaponDamage = 30, double stopAfterCycles = 99}) {
      var now = 0.0;
      final tape = ReplayTape(
        mode: PlayMode.touch,
        practice: false,
        seed: 5,
        cycleSeconds: 3,
        bird: 2,
        reducedMotion: false,
        originMs: 0,
        course: FlightCourse.starTrail,
        weaponDamage: weaponDamage,
        plan: gargoylePlan(),
      );
      final recorder = FlightRecorder(tape, () => now);
      final sim = recorder.simulation;
      final pilot = Pilot(cadence: .3);
      final marks = <double, Object>{};
      final seen = <String>{};
      for (var frame = 1; frame <= 60 * 240; frame++) {
        now += 1000 / 60;
        final boss = sim.boss;
        final fighting = boss != null && boss.phase == BossPhase.attacking;
        final flap = fighting ? pilot.flap(sim) : rideTheSky(sim);
        recorder.apply(
          MovementInput(valid: true, height: .5, flap: flap),
          touchAt(now),
          now,
        );
        if (fighting && pilot.shoot(sim)) recorder.command('shoot');
        recorder.tick(1 / 60, now, 2.2);
        if (boss != null) {
          final state = boss.phase != BossPhase.attacking
              ? boss.phase.name
              : boss.slitSweep && boss.beamOn
              ? 'slit beam'
              : boss.beamOn
              ? 'beam ${boss.enraged ? 'fury' : 'calm'}'
              : boss.sweepWarning > 0
              ? 'warning'
              : boss.lampOpen
              ? 'vent'
              : boss.lastGlanceAt > boss.age - .05
              ? 'glance'
              : 'perch';
          if (seen.add(state)) marks[now] = gargoyleSnapshot(sim);
          // Mid-flight feathers and the first fury are worth a mark too.
          if (sim.bossAmmo.isNotEmpty && seen.add('feather')) {
            marks[now] = gargoyleSnapshot(sim);
          }
          if (boss.enraged && seen.add('enraged')) {
            marks[now] = gargoyleSnapshot(sim);
          }
        }
        if (sim.phase == RunPhase.ended) break;
        if (sim.boss == null && sim.bossesDefeated > 0) break;
      }
      if (sim.phase != RunPhase.ended) {
        recorder.command('end', EndReason.quit);
      }
      marks[now] = gargoyleSnapshot(sim);
      return (tape: tape, sim: sim, marks: marks);
    }

    test('a recorded level survives a JSON round trip and replays exactly', () {
      final (:tape, :sim, :marks) = record();
      expect(sim.bossesDefeated, 1);
      expect(tape.recordedVersion, 43);
      expect(tape.levelId, '3-4');
      final json = jsonEncode(tape.toJson());
      final loaded = ReplayTape.fromJson(
        jsonDecode(json) as Map<String, dynamic>,
      );
      expect(jsonEncode(loaded.toJson()), json);
      final player = ReplayPlayer(loaded);
      player.seek(loaded.durationMs);
      expect(
        gargoyleSnapshot(player.simulation),
        marks[marks.keys.last],
      );
    });

    test('seeking back and forth through the fight lands on the same state '
        '(aim latch, lamp, feathers, fury, defeat)', () {
      final (:tape, :sim, :marks) = record();
      expect(
        marks.length,
        greaterThanOrEqualTo(8),
        reason: 'every state of the fight was visited',
      );
      final replay = ReplayPlayer(ReplayTape.fromJson(tape.toJson()));
      final times = marks.keys.toList()..removeLast();
      for (final time in [...times.reversed, ...times, times[times.length ~/ 2]]) {
        replay.seek(time);
        expect(gargoyleSnapshot(replay.simulation), marks[time], reason: '$time');
      }
    });

    test('a backward seek into the middle of a sweep re-aims from the recorded '
        'bird, not from where the bird is now', () {
      final (:tape, :sim, :marks) = record();
      final replay = ReplayPlayer(ReplayTape.fromJson(tape.toJson()));
      // Find a time when a beam holds, then go past the end and come back.
      final beamTimes = [
        for (final e in marks.entries)
          if (e.key != marks.keys.last) e.key,
      ];
      replay.seek(tape.durationMs);
      final end = gargoyleSnapshot(replay.simulation);
      for (final time in beamTimes) {
        replay.seek(time);
        replay.seek(tape.durationMs);
        expect(gargoyleSnapshot(replay.simulation), end, reason: '$time');
      }
    });
  });

  group('he belongs to the campaign, not the endless cycle', () {
    test('no endless flight, at any boss number or rules version, meets him',
        () {
      for (final version in [38, 39, 40, 41, 42, 43]) {
        for (var n = 0; n < 120; n++) {
          final encounter = FlightPlan.endless.bossEncounter(n, version);
          expect(
            encounter.kind,
            isNot(BossKind.searchlightGargoyle),
            reason: 'v$version #$n',
          );
          expect(encounter.kind.campaignOnly, isFalse);
        }
      }
      expect(BossKind.searchlightGargoyle.index, BossKind.endlessCycle + 1);
    });

    test('his level is a guardian: a 3-4 that ends a stop, not a chapter', () {
      const delivery = Delivery(
        'A weather vane for the tallest tower',
        from: 'The tower keeper',
        thanks: 'It spins! It points! It is perfect.',
      );
      final level = CampaignLevel(
        name: 'Storm Warning',
        delivery: delivery,
        plan: gargoylePlan(),
      );
      expect(level.id, '3-4');
      expect(level.isBoss, isTrue);
      expect(level.isGuardian, isTrue);
      expect(level.isChapterBoss, isFalse);
      expect(level.boss, BossKind.searchlightGargoyle);
      // Beating him opens the next level only: the chapter's boss level is
      // the Dusk Empress's 3-8.
      expect(Campaign.chapterOf(level).bossLevel.id, '3-8');
      expect(Campaign.chapterOf(level).boss, BossKind.duskMoth);
    });

    test('a guardian level flown by the shared bot reaches its finish line',
        () {
      // The shared sky-riding bot knows no beams: with its hearts topped up
      // it still beats him, through the same rules.
      for (final width in [1.78, 2.2]) {
        final sim = nyFlight(gargoylePlan(), weaponDamage: 30);
        flyLevel(
          sim,
          viewportWidth: width,
          sprintWhen: (sim, frame) => false,
        );
        expect(sim.endReason, EndReason.completed, reason: '$width');
        expect(sim.bossesDefeated, 1);
        expect(sim.victoryGlide, isTrue);
        expect(sim.levelStars, greaterThanOrEqualTo(1), reason: 'delivered');
      }
    });

    test('a pigeon or steam in the same run-up does not change the fight', () {
      final withPigeons = gargoylePlan(
        lineup: const [
          EnemyKind.alleyPigeon,
          EnemyKind.simpleBat,
          EnemyKind.alleyPigeon,
          EnemyKind.duskMoth,
        ],
      );
      final sim = arena(plan: withPigeons);
      expect(sim.boss!.kind, BossKind.searchlightGargoyle);
      expect(sim.enemies, isEmpty, reason: 'his arrival clears the sky');
      expect(sim.steamVents, isEmpty);
      final pilot = Pilot();
      var frames = 0;
      while (sim.boss!.phase == BossPhase.attacking && frames < 60 * 300) {
        pilot.fly(sim);
        frames++;
      }
      expect(sim.boss!.phase, BossPhase.defeated);
      expect(sim.boss!.spots, 0);
    });
  });
}
