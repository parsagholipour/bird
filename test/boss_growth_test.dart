import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/session_replay.dart';

import 'boss_fight_test.dart' show arena, step;
import 'endless_plan_baseline_test.dart'
    show CountingRandom, stateOf, touchPilot;

/// Rules version 53: an endless boss keeps growing. The endless health
/// formula stops climbing after the first lap of the boss cycle, so before 53
/// a kind's third meeting (encounters 11 to 15) and every later one had its
/// second meeting's health. From 53 each meeting after the second has
/// `SkyBoss.growthPercent` more health than the one before.

const _growth = FlightSimulation.bossGrowthRulesVersion;

/// The boss an endless flight meets once [defeated] bosses have fallen.
SkyBoss meet(int defeated, {int version = _growth}) {
  final sim = arena(version: version)..bossesDefeated = defeated;
  step(sim);
  return sim.boss!;
}

void main() {
  test('53 came after the tougher Neferhoo\'s 52 (54, King Coo\'s quick '
      'fury, and 55, a faster Neferhoo, came after it)', () {
    expect(_growth, 53);
    expect(
      FlightSimulation.currentRulesVersion,
      greaterThanOrEqualTo(FlightSimulation.fasterNeferhooRulesVersion),
    );
    expect(FlightSimulation.currentRulesVersion, greaterThan(_growth));
    expect(_growth, greaterThan(FlightSimulation.tougherNeferhooRulesVersion));
    expect(ReplayTape.version, FlightSimulation.currentRulesVersion);
    expect(SkyBoss.growthPercent, 25);
  });

  test('every endless meeting after the second has 25 % more health than '
      'the one before, rounded to 10', () {
    // Meetings 1 to 6 of each kind; the Baron returns upgraded from 2 on.
    const expected = {
      BossKind.baronBat: [120, 480, 600, 750, 940, 1180],
      BossKind.spitterBeetle: [210, 330, 410, 510, 640, 800],
      BossKind.duskMoth: [240, 360, 450, 560, 700, 880],
      BossKind.pirate: [300, 420, 530, 660, 830, 1040],
      BossKind.dragon: [360, 480, 600, 750, 940, 1180],
    };
    for (final MapEntry(key: kind, value: health) in expected.entries) {
      for (var m = 1; m <= health.length; m++) {
        final number = kind.index + 1 + (m - 1) * BossKind.endlessCycle;
        expect(SkyBoss.meeting(kind, number), m, reason: '#$number');
        int hp({required bool growing}) => SkyBoss.healthFor(
          kind,
          number,
          tougherBaron: kind == BossKind.baronBat && m > 1,
          growing: growing,
        );
        final reason = '${kind.name} meeting $m';
        expect(hp(growing: true), health[m - 1], reason: reason);
        // Before 53 the second meeting's health held from then on.
        expect(hp(growing: false), health[math.min(m, 2) - 1], reason: reason);
      }
    }
    // The campaign-only guardians keep one health at every number.
    for (final kind in BossKind.values.where((kind) => kind.campaignOnly)) {
      expect(
        SkyBoss.healthFor(kind, 16, growing: true),
        SkyBoss.healthFor(kind, 16),
      );
    }
  });

  test('an endless flight meets its bosses with that health; 52 keeps the '
      'old', () {
    for (var defeated = 0; defeated < 20; defeated++) {
      final grown = meet(defeated), before = meet(defeated, version: 52);
      expect(grown.kind, before.kind);
      expect(grown.number, defeated + 1);
      expect(grown.hp, grown.maxHp);
      final reason = '${grown.kind.name} #${grown.number}';
      if (SkyBoss.meeting(grown.kind, grown.number) <= 2) {
        expect(grown.maxHp, before.maxHp, reason: reason);
      } else {
        expect(grown.maxHp, greaterThan(before.maxHp), reason: reason);
      }
    }
    // The third Baron (encounter 11) and the fourth (16), both upgraded.
    expect((meet(10).maxHp, meet(10, version: 52).maxHp), (600, 480));
    expect((meet(15).maxHp, meet(15, version: 52).maxHp), (750, 480));
    expect(meet(15).upgraded, isTrue);
  });

  test('a rules 53 endless flight flies exactly as 52 until encounter 11, '
      'whose Baron has 25 % more health', () {
    for (final width in [1.6, 2.2]) {
      final randoms = [CountingRandom(7), CountingRandom(7)];
      final [v52, v53] = [
        for (final (i, version) in [52, 53].indexed)
          FlightSimulation(
            rules: TapFlyMode(rulesVersion: version),
            practice: false,
            course: FlightCourse.starTrail,
            rulesVersion: version,
            weaponDamage: 60,
            random: randoms[i],
          ),
      ];
      expect((v52.supportsBossGrowth, v53.supportsBossGrowth), (false, true));
      var now = 0.0;
      for (var frame = 1; ; frame++) {
        expect(frame, lessThan(1600 * 50), reason: 'no encounter 11');
        now += 20;
        for (final sim in [v52, v53]) {
          touchPilot(sim, frame, now, keepAlive: true);
          sim.tick(.02, now, viewportWidth: width);
        }
        if ((v53.boss?.number ?? 0) > 10) break;
        if (frame % 50 == 0) {
          expect(
            stateOf(v53, draws: randoms[1].draws),
            stateOf(v52, draws: randoms[0].draws),
            reason: 'width $width at ${frame ~/ 50} s',
          );
        }
      }
      // He arrives on the same frame, the third Baron of the flight.
      final (old, grown) = (v52.boss!, v53.boss!);
      expect(
        (old.kind, old.number, old.upgraded),
        (BossKind.baronBat, 11, true),
      );
      expect((grown.kind, grown.number), (BossKind.baronBat, 11));
      expect((old.maxHp, grown.maxHp), (480, 600));
      expect(grown.hp, 600);
    }
  });
}
