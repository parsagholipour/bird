import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/campaign.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/game/boss_motion.dart';
import 'package:push_up_bird/game/king_coo_layout.dart';
import 'package:push_up_bird/game/king_coo_pose.dart';

import 'campaign_flight.dart';
import 'king_coo_helpers.dart';

/// Rules version 54: King Coo starts his fury quickly. The cycle he grows
/// furious in (the last of his three stages) ends as soon as its quiet tail
/// begins: his roar is over, he has got over any pop, and the squadron has
/// passed the bird. His first fury cycle begins there, instead of after the
/// rest of the 14 s, which left him idle for up to six seconds.

const _restart = FlightSimulation.cooRestartRulesVersion;
const _step = 1 / 120;

/// The real 3-2 at [version], flown by the shared bot until King Coo
/// fights, then his full fight (stage 1) with [hp] health left and a fresh
/// bird, from the start of a cycle that calls his squadron.
FlightSimulation _fight(int version, {int hp = 300}) {
  final sim = levelFlight(Campaign.level('3-2')!, version: version);
  flyLevel(sim, until: (sim) => sim.boss?.phase == BossPhase.attacking);
  expectFighting(sim);
  final boss = sim.boss!;
  expect(boss.staged, isTrue);
  boss.hp = hp;
  tick(sim);
  expect(boss.stageReached, 1);
  sim
    ..hearts = 3
    ..shield = true
    ..invulnerableUntil = 0;
  _until(sim, (boss) => boss.signatureArmed(boss.cooCycleNumber));
  return sim;
}

/// Runs the protected bird at mid-height until [until] holds.
void _until(FlightSimulation sim, bool Function(SkyBoss boss) until) =>
    run(sim, 60, hold: .5, protect: true, until: (sim) => until(sim.boss!));

/// Runs on to cycle time [at] of the next cycle that reaches it.
void _toCycle(FlightSimulation sim, double at) {
  final boss = sim.boss!;
  if (boss.cooCycle >= at) {
    final cycle = boss.cooCycleNumber;
    _until(sim, (boss) => boss.cooCycleNumber > cycle);
  }
  _until(sim, (boss) => boss.cooCycle >= at);
}

/// Hits his chest directly [times] times with a rock of [damage], then
/// steps once (the rules see the stage on the next step).
void _strike(FlightSimulation sim, int damage, {int times = 1}) {
  for (var i = 0; i < times; i++) {
    sim.boss!.strike(damage);
  }
  tick(sim);
}

/// Boss age at which the next ring locks from here.
double _nextLock(FlightSimulation sim) {
  final boss = sim.boss!;
  final locked = boss.lobs.length;
  _until(sim, (boss) => boss.lobs.length > locked);
  return boss.lobs[locked].lockedAt;
}

void main() {
  test('54 came after the growing endless bosses\' 53 (55, a faster '
      'Neferhoo, came after it)', () {
    expect(_restart, 54);
    expect(FlightSimulation.currentRulesVersion, greaterThanOrEqualTo(55));
    expect(FlightSimulation.fasterNeferhooRulesVersion, greaterThan(_restart));
    expect(_restart, greaterThan(FlightSimulation.bossGrowthRulesVersion));
  });

  test('his pop takes as long as the art\'s dizzy spell and recovery', () {
    expect(
      KingCoo.popRecovery,
      closeTo(KingCooTimeline.popDizzy + KingCooTimeline.popRecover, 1e-9),
    );
  });

  test('only a campaign King Coo restarts, and only from 54', () {
    for (final version in [53, 54]) {
      final boss = _fight(version).boss!;
      expect(boss.quickRestart, version >= _restart, reason: '$version');
    }
    final endless = FlightSimulation(
      rules: TapFlyMode(rulesVersion: _restart),
      practice: false,
      course: FlightCourse.starTrail,
      rulesVersion: _restart,
    );
    expect(endless.supportsCooRestart, isFalse);
    for (final version in [53, 54]) {
      final campaign = levelFlight(Campaign.level('3-2')!, version: version);
      expect(campaign.supportsCooRestart, version >= _restart);
    }
  });

  test('a pop that brings his fury: his first fury ring locks .6 s after he '
      'has got over it, not at the next 14 s cycle', () {
    final locks = <int, double>{};
    for (final version in [53, 54]) {
      final sim = _fight(version);
      final boss = sim.boss!;
      _toCycle(sim, 8);
      final cycle = boss.cooCycleNumber;
      // Three puffed rocks (20 each) pop him and take him under a third.
      _strike(sim, 10, times: 3);
      expect(boss.popped, isTrue);
      expect(boss.stageReached, 2);
      final poppedAt = boss.poppedAt!;
      final lock = _nextLock(sim);
      final lob = boss.lobs.last;
      expect(lob.fury, isTrue, reason: 'a fury bracket');
      if (version < _restart) {
        expect(boss.cooRestartAt, double.infinity);
        expect(lock, closeTo(boss.cooCycleStart(cycle + 1) + .6, _step));
        expect(
          boss.cooCycleStart(cycle + 1),
          boss.arrivalDuration + (cycle + 1) * KingCoo.period,
        );
      } else {
        expect(boss.cooRestartCycle, cycle + 1);
        expect(
          boss.cooRestartAt,
          inInclusiveRange(
            poppedAt + KingCoo.popRecovery,
            poppedAt + KingCoo.popRecovery + _step + 1e-9,
          ),
        );
        expect(lock, closeTo(boss.cooRestartAt + .6, _step));
      }
      locks[version] = lock - poppedAt;
    }
    // Over two seconds sooner: 3.2 s after the pop instead of about 6.
    expect(locks[54], closeTo(KingCoo.popRecovery + .6, 3 * _step));
    expect(locks[53]! - locks[54]!, greaterThan(2));
  });

  test('with his squadron out he waits for it to pass the bird, then '
      'restarts at once', () {
    final sim = _fight(_restart, hp: 290);
    final boss = sim.boss!;
    _toCycle(sim, 8);
    // One puffed rock (20) brings his fury; no pop.
    _strike(sim, 10);
    expect(boss.stageReached, 2);
    expect(boss.popped, isFalse);
    final furyAt = boss.age;
    final cycle = boss.cooCycleNumber;
    final locked = boss.lobs.length;
    var latest = double.negativeInfinity;
    _until(sim, (boss) {
      // Every squadron pigeon's last moment within reach of the bird.
      for (final enemy in sim.enemies) {
        if (enemy.track case final track?) {
          final clear =
              track.crossesAt(FlightSimulation.birdX) +
              KingCoo.pigeonReach / KingCoo.squadSpeed;
          if (clear > latest) latest = clear;
        }
      }
      return boss.cooRestartAt.isFinite;
    });
    expect(boss.whistles, greaterThan(0), reason: 'a squadron flew');
    expect(latest.isFinite, isTrue);
    expect(boss.lobs.length, locked, reason: 'no ring before the restart');
    final at = boss.cooRestartAt;
    expect(at, greaterThanOrEqualTo(latest));
    expect(at, lessThan(latest + _step + 1e-9));
    expect(at, greaterThan(furyAt + SkyBoss.stageRoar));
    // The tail he skipped is the rest of the old cycle.
    expect(at, lessThan(boss.cooCycleStart(cycle) + KingCoo.period - 1.5));
    expect(_nextLock(sim), closeTo(at + .6, _step));
  });

  test('the clock skips no beat: every counter carries on through the '
      'restart, and the art reads the same cycle', () {
    final sim = _fight(_restart);
    final boss = sim.boss!;
    _toCycle(sim, 8);
    _strike(sim, 10, times: 3);
    final guard = sim.vanguard!;
    (int, int, int, int) counters() =>
        (boss.puffs, boss.whistlesDue, boss.lobs.length, guard.returnSlots);
    var before = counters();
    run(
      sim,
      10,
      hold: .5,
      protect: true,
      until: (sim) => boss.cooRestartAt.isFinite,
      each: (sim) => before = boss.cooRestartAt.isFinite ? before : counters(),
    );
    expect(boss.cooRestartAt, boss.age);
    expect(counters(), before);
    expect(boss.cooCycle, 0);
    expect(boss.cooCycleNumber, boss.cooRestartCycle);
    expect(boss.cooCycleStart(boss.cooRestartCycle), boss.cooRestartAt);
    expect(boss.popped, isFalse, reason: 'the pop was last cycle\'s');
    expect(boss.puffWindow, isFalse);
    // The pose's clock is the rules'.
    for (final ahead in [0.0, 2.0, 8.0, 15.0]) {
      if (ahead > 0) run(sim, ahead, hold: .5, protect: true);
      final pose = KingCooPose(boss, BossMotion(boss, reducedMotion: false));
      expect(pose.cycle, closeTo(boss.cooCycle, 1e-9), reason: '+$ahead');
      expect(pose.cycleNumber, boss.cooCycleNumber, reason: '+$ahead');
    }
  });

  test('a fury begun early in a cycle still runs that cycle to its tail', () {
    final sim = _fight(_restart, hp: 285);
    final boss = sim.boss!;
    _toCycle(sim, 1);
    final cycle = boss.cooCycleNumber;
    // One fluffed rock (5) takes him to a third.
    _strike(sim, 10);
    expect(boss.stageReached, 2);
    _until(sim, (boss) => boss.cooRestartAt.isFinite);
    expect(boss.cooRestartCycle, cycle + 1);
    expect(boss.whistles, greaterThan(0), reason: 'the puff and the whistle');
    final tail = boss.cooRestartAt - boss.cooCycleStart(cycle);
    expect(tail, greaterThanOrEqualTo(KingCoo.windowEnd + KingCoo.puffRelease));
    expect(tail, lessThan(KingCoo.period));
  });

  test('once a fight: his later fury cycles are 14 s, pop or not', () {
    final sim = _fight(_restart);
    final boss = sim.boss!;
    _toCycle(sim, 8);
    _strike(sim, 10, times: 3);
    _until(sim, (boss) => boss.cooRestartAt.isFinite);
    final from = boss.cooRestartAt;
    final restartCycle = boss.cooRestartCycle;
    // Pop him again in the next fury cycle.
    _toCycle(sim, 8);
    _strike(sim, 10, times: 3);
    expect(boss.popped, isTrue);
    _until(sim, (boss) => boss.cooCycleNumber > restartCycle);
    expect(boss.cooRestartAt, from);
    expect(
      boss.cooCycleStart(restartCycle + 1),
      closeTo(from + KingCoo.period, 1e-9),
    );
    expect(_nextLock(sim), closeTo(from + KingCoo.period + .6, _step));
  });

  test('the same fight flown twice restarts on the same step', () {
    double restart() {
      final sim = _fight(_restart);
      _toCycle(sim, 8);
      _strike(sim, 10, times: 3);
      _until(sim, (boss) => boss.cooRestartAt.isFinite);
      return sim.boss!.cooRestartAt;
    }

    expect(restart(), restart());
  });
}
