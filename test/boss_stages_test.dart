import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/campaign.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/session_replay.dart';
import 'package:push_up_bird/domain/tracking.dart';

import 'campaign_flight.dart';
import 'endless_plan_baseline_test.dart' show stateOf;
import 'recorded_flight.dart';

/// Rules version 44: campaign boss fights are long and staged, and four
/// bosses send a vanguard first. See docs/campaign.md, "Boss fights".

// Egypt's guardian is 2-6 (rules 50); the Spitter King's lair is 2-9 since
// then.
const bossLevels = ['1-8', '2-6', '2-9', '3-2', '3-4', '3-8', '4-8', '5-8'];

CampaignLevel level(String id) => Campaign.level(id)!;

/// [level] flown by the shared bot (hearts topped up) until [until] holds.
FlightSimulation flyUntil(
  CampaignLevel level,
  bool Function(FlightSimulation sim) until, {
  int version = FlightSimulation.currentRulesVersion,
  double width = 2.2,
  bool shoot = true,
  void Function(FlightSimulation sim)? watch,
}) {
  final sim = FlightSimulation(
    rules: TapFlyMode(rulesVersion: version),
    practice: false,
    course: FlightCourse.starTrail,
    rulesVersion: version,
    plan: level.plan,
  );
  flyLevel(
    sim,
    viewportWidth: width,
    until: until,
    watch: watch,
    shootWhen: shoot ? null : (_) => false,
    sprintWhen: shoot ? null : (_, _) => false,
  );
  return sim;
}

/// A staged boss of [kind], fighting ([age] seconds old, past its arrival).
SkyBoss stagedBoss(BossKind kind, {double fighting = 1}) {
  final boss = SkyBoss(
    number: kind.index + 1,
    x: 1.6,
    cinematic: true,
    kind: kind,
    debut: true,
    staged: true,
    maxHp: SkyBoss.campaignHealthFor(kind),
  );
  boss.age = boss.arrivalDuration + fighting;
  return boss;
}

void main() {
  test('rules 44 staged the bosses, 45 toughened King Coo and 46 the '
      'Gargoyle; endless, co-op and duel ignore them', () {
    expect(FlightSimulation.currentRulesVersion, greaterThanOrEqualTo(55));
    expect(FlightSimulation.bossStagesRulesVersion, 44);
    expect(FlightSimulation.tougherCooRulesVersion, 45);
    expect(FlightSimulation.fiercerGargoyleRulesVersion, 46);
    // An endless flight meets the first endless boss as before.
    final endless = FlightSimulation(
      rules: TapFlyMode(),
      practice: false,
      course: FlightCourse.starTrail,
    );
    expect(endless.supportsBossStages, isFalse);
    var now = 0.0;
    for (var frame = 0; frame < 60 * 50 && endless.boss == null; frame++) {
      now += 20;
      endless.apply(
        MovementInput(valid: true, height: .5, flap: rideTheSky(endless)),
        touchAt(now),
        now,
      );
      if (endless.hearts < 2) endless.hearts = 3;
      endless.tick(.02, now);
    }
    final boss = endless.boss!;
    expect(boss.staged, isFalse);
    expect(boss.maxHp, SkyBoss.healthFor(boss.kind, 1));
    expect(endless.vanguard, isNull);
  });

  test('a rules 43 flight of a boss level keeps the old short fight', () {
    final sim = flyUntil(
      level('1-8'),
      (sim) => sim.boss != null,
      version: FlightSimulation.newYorkRulesVersion,
    );
    expect(sim.vanguard, isNull);
    expect(sim.boss!.staged, isFalse);
    expect(sim.boss!.maxHp, 120);
  });

  group('the vanguard', () {
    test('rules 56 pairs King Coo returns in campaign flights', () {
      expect(FlightSimulation.cooPairsRulesVersion, 56);
      expect(FlightSimulation.currentRulesVersion, greaterThanOrEqualTo(56));
      expect(ReplayTape.version, FlightSimulation.currentRulesVersion);
      for (final version in [55, 56]) {
        final campaign = levelFlight(level('3-2'), version: version);
        expect(campaign.supportsCooPairs, version >= 56);
        final endless = FlightSimulation(
          rules: TapFlyMode(rulesVersion: version),
          practice: false,
          course: FlightCourse.starTrail,
          rulesVersion: version,
        );
        expect(endless.supportsCooPairs, isFalse);
      }
    });

    test('Baron Bat, the Spitter King, the Dusk Empress and King Coo send '
        'one; the others do not', () {
      expect(
        [
          for (final kind in BossKind.values)
            if (BossVanguard.wavesOf(kind).isNotEmpty) kind,
        ],
        [
          BossKind.baronBat,
          BossKind.spitterBeetle,
          BossKind.duskMoth,
          BossKind.kingCoo,
        ],
      );
      for (final kind in BossKind.values) {
        final waves = BossVanguard.wavesOf(kind);
        for (final wave in waves) {
          for (final member in wave.members) {
            expect(member.y, inInclusiveRange(.2, .8), reason: '$kind');
          }
        }
        // Waves come in order, a few seconds apart.
        for (var i = 1; i < waves.length; i++) {
          expect(waves[i].at - waves[i - 1].at, greaterThan(2.5));
        }
      }
    });

    for (final id in ['1-8', '2-9', '3-2', '3-8']) {
      test('$id: its waves fly first, then the boss shows up', () {
        double? bossAt;
        final sim = flyUntil(
          level(id),
          (sim) => sim.boss?.phase == BossPhase.attacking,
          watch: (sim) {
            if (sim.boss != null) bossAt ??= sim.elapsed;
            // The boss never arrives while a member is still flying.
            if (sim.boss == null && sim.vanguard != null) {
              expect(sim.vanguardFlying || sim.vanguard!.cleared, isTrue);
            }
          },
        );
        final guard = sim.vanguard!;
        expect(guard.boss, level(id).boss);
        expect(guard.allSent, isTrue);
        expect(guard.members, hasLength(guard.total));
        expect(guard.cleared, isTrue);
        expect(guard.members.where(sim.enemies.contains), isEmpty);
        // The run-up's 30 s, then the vanguard, then the boss.
        expect(guard.startedAt, greaterThan(25));
        expect(
          bossAt! - guard.clearedAt!,
          closeTo(BossVanguard.bossDelay, .02),
        );
        expect(guard.clearedAt! - guard.startedAt, inInclusiveRange(9.0, 20.0));
        expect(sim.boss!.staged, isTrue);
        expect(sim.boss!.maxHp, SkyBoss.campaignHealthFor(level(id).boss!));
        expect(sim.bossFight, isTrue);
      });
    }

    test('shooting a member counts it down', () {
      final sim = flyUntil(level('1-8'), (sim) => sim.vanguard != null);
      flyLevel(
        sim,
        until: (sim) =>
            sim.vanguard!.members.any((enemy) => sim.enemies.contains(enemy)),
      );
      final member = sim.vanguard!.members.firstWhere(sim.enemies.contains);
      final before = sim.vanguard!.downed;
      // A rock right in front of it.
      sim.rocks.add(BirdRock(x: member.x - .02, y: member.y, damage: 100));
      flyLevel(sim, seconds: .1, shootWhen: (_) => false);
      expect(sim.vanguard!.downed, before + 1);
      expect(sim.enemies.contains(member), isFalse);
    });

    test("King Coo's pigeons throw crusts from rules 45, one after another, "
        'and he has twice the health', () {
      for (final version in [44, 45]) {
        final thrown = <SkyEnemy, double>{};
        var crusts = 0;
        final sim = flyUntil(
          level('3-2'),
          (sim) => sim.boss != null,
          version: version,
          watch: (sim) {
            if (!sim.vanguardFlying) return;
            for (final enemy in sim.vanguard!.members) {
              if (enemy.lastShotAt.isFinite) {
                thrown.putIfAbsent(enemy, () => enemy.lastShotAt);
              }
            }
            crusts = math.max(
              crusts,
              sim.enemyAmmo
                  .where((ammo) => ammo.attack == EnemyAttack.crumb)
                  .length,
            );
          },
        );
        final members = sim.vanguard!.members;
        final throws = version >= 45;
        expect(members.every((enemy) => enemy.throwsCrumbs == throws), isTrue);
        expect(
          sim.boss!.maxHp,
          SkyBoss.campaignHealthFor(BossKind.kingCoo, tougherCoo: throws),
        );
        expect(sim.boss!.maxHp, throws ? 840 : 420);
        if (!throws) {
          expect(thrown, isEmpty);
          continue;
        }
        expect(crusts, greaterThan(0));
        // Most of them get a throw in.
        expect(thrown.length, greaterThan(members.length ~/ 2));
        // A wave's members wind up one after another, never as one volley.
        // (All three were sent in one step, so their ages agree.)
        final times = [for (final enemy in members.take(3)) ?thrown[enemy]]
          ..sort();
        expect(times.length, greaterThan(1));
        for (var i = 1; i < times.length; i++) {
          expect(times[i] - times[i - 1], greaterThan(.2));
        }
      }
    });

    test("King Coo's stragglers come back in his fight until every one is "
        'shot (rules 45)', () {
      // A pilot that never shoots or sprints: the whole vanguard gets away.
      final sim = flyUntil(
        level('3-2'),
        (sim) => sim.boss?.phase == BossPhase.attacking,
        version: 45,
        shoot: false,
      );
      final guard = sim.vanguard!;
      expect(guard.downed, 0);
      expect(guard.escaped, guard.total);
      expect(guard.owed, guard.total);
      final boss = sim.boss!;
      final returns = <(double, double)>[];
      var sent = 0;
      flyLevel(
        sim,
        seconds: 30,
        shootWhen: (_) => false,
        sprintWhen: (_, _) => false,
        watch: (sim) {
          while (guard.stragglers.length > sent) {
            final enemy = guard.stragglers[sent++];
            returns.add((boss.combatTime % KingCoo.period, enemy.y));
            expect(enemy.throwsCrumbs, isTrue);
            expect(enemy.maxHp, BossVanguard.stragglerHp);
          }
        },
      );
      // Twice a cycle, one at a time, never level with his body.
      expect(returns.length, greaterThanOrEqualTo(4));
      for (final (at, y) in returns) {
        expect(
          BossVanguard.returnTimes.any((t) => (at - t).abs() < .05),
          isTrue,
          reason: '$at',
        );
        expect((y - .5).abs(), greaterThan(.2));
      }
      // Nobody shot them: all still owed, those that flew past included.
      expect(guard.owed, guard.total);
      expect(guard.stragglerGoneAt, isNotEmpty);
      // One shot downs a straggler, and it is owed no more.
      flyLevel(
        sim,
        shootWhen: (_) => false,
        sprintWhen: (_, _) => false,
        until: (sim) => guard.stragglers.any(
          (e) => sim.enemies.contains(e) && e.x < 1.4 && e.x > .9,
        ),
      );
      final target = guard.stragglers.firstWhere(
        (e) => sim.enemies.contains(e) && e.x < 1.4,
      );
      sim.rocks.add(BirdRock(x: target.x - .02, y: target.y));
      flyLevel(sim, seconds: .1, shootWhen: (_) => false);
      expect(guard.stragglerDownedAt.keys, contains(target));
      expect(guard.owed, guard.total - 1);
    });

    for (final version in [55, FlightSimulation.cooPairsRulesVersion]) {
      test('King Coo returns simultaneous pairs only from rules 56 '
          '(rules $version)', () {
        final sim = flyUntil(
          level('3-2'),
          (sim) => sim.boss?.phase == BossPhase.attacking,
          version: version,
          shoot: false,
        );
        final guard = sim.vanguard!;
        final paired = version >= FlightSimulation.cooPairsRulesVersion;
        final size = paired ? 2 : 1;
        var sent = 0;
        var waves = 0;
        flyLevel(
          sim,
          seconds: 30,
          shootWhen: (_) => false,
          sprintWhen: (_, _) => false,
          watch: (sim) {
            if (guard.stragglers.length == sent) return;
            final wave = guard.stragglers.skip(sent).toList();
            expect(wave, hasLength(size));
            expect(wave.every(sim.enemies.contains), isTrue);
            if (paired) {
              expect(wave.first.x, wave.last.x);
              expect(wave.first.y, lessThan(.3));
              expect(wave.last.y, greaterThan(.7));
              expect(
                wave.last.fireIn - wave.first.fireIn,
                closeTo(BossVanguard.throwStagger, 1e-9),
              );
            }
            for (final (i, enemy) in wave.indexed) {
              expect(
                enemy.y,
                closeTo(
                  BossVanguard.returnHeights[(waves * size + i) %
                      BossVanguard.returnHeights.length],
                  .01, // The pigeon's normal flight bob.
                ),
              );
              expect(enemy.maxHp, BossVanguard.stragglerHp);
              expect(enemy.throwsCrumbs, isTrue);
            }
            expect(
              BossVanguard.returnTimes.any(
                (at) => (sim.boss!.cooCycle - at).abs() < .05,
              ),
              isTrue,
            );
            sent += size;
            waves++;
          },
        );
        expect(waves, greaterThanOrEqualTo(4));
        expect(guard.owed, guard.total);
        expect(guard.stragglerGoneAt, isNotEmpty);
      });
    }

    test('paired returns send only the last pigeon when one remains, '
        'and stop once all are downed', () {
      final sim = flyUntil(
        level('3-2'),
        (sim) => sim.boss?.phase == BossPhase.attacking,
        shoot: false,
      );
      final guard = sim.vanguard!;
      final waves = <int>[];
      SkyEnemy? survivor;
      var sent = 0;
      flyLevel(
        sim,
        seconds: 150,
        shootWhen: (_) => false,
        sprintWhen: (_, _) => false,
        until: (_) => guard.owed == 0,
        watch: (sim) {
          if (guard.stragglers.length > sent) {
            final wave = guard.stragglers.skip(sent).toList();
            waves.add(wave.length);
            sent = guard.stragglers.length;
            // Let one of the last pair escape so it must return alone.
            if (guard.owed == 2 && survivor == null) survivor = wave.last;
          }
          for (final enemy in guard.stragglers) {
            if (enemy == survivor || !sim.enemies.contains(enemy)) continue;
            // Shoot after it enters the screen, through normal collision rules.
            if (enemy.x < 2.1 && enemy.x > FlightSimulation.birdX) {
              sim.rocks.add(BirdRock(x: enemy.x - .02, y: enemy.y));
            }
          }
          expect(guard.waiting, greaterThanOrEqualTo(0));
        },
      );
      expect(guard.owed, 0);
      expect(guard.stragglerGoneAt, contains(survivor));
      expect(waves, [...List.filled(guard.total ~/ 2, 2), 1]);
      expect(guard.stragglerDownedAt, hasLength(guard.total));
      flyLevel(
        sim,
        seconds: 30,
        shootWhen: (_) => false,
        sprintWhen: (_, _) => false,
      );
      expect(guard.stragglers, hasLength(sent));
      expect(guard.waiting, 0);
    });

    test('no stragglers at rules 44, nor for the other bosses', () {
      final at44 = flyUntil(
        level('3-2'),
        (sim) => (sim.boss?.combatTime ?? 0) > 20,
        version: 44,
        shoot: false,
      );
      expect(at44.vanguard!.stragglers, isEmpty);
      final baron = flyUntil(
        level('1-8'),
        (sim) => (sim.boss?.combatTime ?? 0) > 20,
        shoot: false,
      );
      expect(BossVanguard.returnsOf(BossKind.baronBat), isFalse);
      expect(baron.vanguard!.stragglers, isEmpty);
    });

    test('the Pirate, the Dragon and the Gargoyle arrive straight away', () {
      for (final id in ['3-4', '4-8', '5-8']) {
        final sim = flyUntil(level(id), (sim) => sim.boss != null);
        expect(sim.vanguard, isNull, reason: id);
        expect(sim.boss!.staged, isTrue, reason: id);
      }
    });
  });

  test('a staged fight and its vanguard replay and seek exactly', () {
    for (final id in ['1-8', '3-2', '4-8']) {
      // The shared bot with a strong weapon, its hearts not topped up: it
      // wins or falls, and either way the tape must replay.
      final (:tape, :simulation) = recordLevel(level(id));
      expect(simulation.phase, RunPhase.ended, reason: id);
      expect(simulation.vanguard != null, level(id).boss != BossKind.pirate);
      final saved = ReplayTape.fromJson(tape.toJson());
      expect(saved.recordedVersion, FlightSimulation.currentRulesVersion);
      final player = ReplayPlayer(saved)..seek(saved.durationMs);
      expect(stateOf(player.simulation), stateOf(simulation), reason: id);
      // Back into the fight, then on to the end.
      player.seek(saved.durationMs * .7);
      expect(player.simulation.phase, isNot(RunPhase.ended), reason: id);
      player.seek(saved.durationMs);
      expect(stateOf(player.simulation), stateOf(simulation), reason: id);
    }
  });

  group('three stages', () {
    test('a third of the bar each: warm-up, full fight, fury', () {
      for (final kind in BossKind.values) {
        final boss = stagedBoss(kind);
        final max = boss.maxHp;
        expect(boss.stage, 0, reason: '$kind');
        expect(boss.calm, isTrue);
        boss.hp = (max * 2 / 3).ceil() + 1;
        expect(boss.stage, 0, reason: '$kind');
        boss.hp = (max * 2 / 3).floor();
        expect(boss.stage, 1, reason: '$kind');
        expect(boss.enraged, isFalse);
        boss.hp = (max / 3).ceil() + 1;
        expect(boss.stage, 1, reason: '$kind');
        boss.hp = (max / 3).floor();
        expect(boss.stage, 2, reason: '$kind');
        expect(boss.enraged, isTrue);
      }
      // An endless boss has no warm-up and its fury still starts at half.
      final endless = SkyBoss(number: 1, x: 1.6, kind: BossKind.baronBat);
      expect(endless.stage, 1);
      endless.hp = endless.maxHp ~/ 2;
      expect(endless.stage, 2);
      expect(endless.stageMarks, [.5]);
      expect(stagedBoss(BossKind.baronBat).stageMarks, [2 / 3, 1 / 3]);
    });

    test('the warm-up is gentler than the full fight', () {
      for (final kind in [
        BossKind.baronBat,
        BossKind.spitterBeetle,
        BossKind.duskMoth,
        BossKind.pirate,
        BossKind.dragon,
      ]) {
        final boss = stagedBoss(kind);
        final calmShots = boss.volleyOffsets.length;
        final calmInterval = boss.volleyInterval;
        final calmSpeed = boss.projectileSpeed;
        expect(boss.summonIn, double.infinity, reason: '$kind');
        boss.hp = boss.maxHp * 2 ~/ 3;
        var most = 0;
        for (var volley = 0; volley < 4; volley++) {
          boss.volleys = volley;
          if (boss.volleyOffsets.length > most) {
            most = boss.volleyOffsets.length;
          }
        }
        expect(most, greaterThan(calmShots), reason: '$kind');
        expect(boss.volleyInterval, lessThan(calmInterval), reason: '$kind');
        expect(boss.projectileSpeed, greaterThan(calmSpeed), reason: '$kind');
      }
    });

    for (final id in bossLevels) {
      test('$id: a long fight that grows stronger twice, with a heart each '
          'time', () {
        double? start, strong, fury, end;
        var hearts = 0;
        var seen = <SkyHeart>{};
        final sim = flyUntil(
          level(id),
          (sim) => sim.boss?.phase == BossPhase.defeated,
          watch: (sim) {
            final boss = sim.boss;
            if (boss == null) return;
            if (boss.phase == BossPhase.attacking) start ??= sim.elapsed;
            if (boss.stageReached >= 1) strong ??= sim.elapsed;
            if (boss.stageReached >= 2) fury ??= sim.elapsed;
            if (boss.phase == BossPhase.defeated) end ??= sim.elapsed;
            for (final heart in sim.heartPickups) {
              if (seen.add(heart)) hearts++;
            }
          },
        );
        expect(sim.boss!.phase, BossPhase.defeated, reason: id);
        final fight = end! - start!;
        // The bot shoots about as fast as the weapon allows: a real player
        // takes longer.
        // King Coo has twice as much health from rules 45, and from 46 the
        // Gargoyle fights as long (this bot: about 143 s).
        final most = switch (id) {
          '3-2' => 130.0,
          '3-4' => 170.0,
          _ => 80.0,
        };
        // Neferhoo's damage is the letters the bird sends back: this bot,
        // firing from the lane his mail call locked on it, sends back every
        // one (a charged rock a whole stream), so it ends his warm-up with
        // his first letters and fights him like a practised player (his
        // pilots: 27 s practised, 59 s family, 119 s first-timer at 640 px;
        // neferhoo_pilot_test.dart).
        final least = id == '2-6' ? 20.0 : 35.0;
        expect(fight, inInclusiveRange(least, most), reason: id);
        expect(strong! - start!, greaterThan(id == '2-6' ? 2 : 8), reason: id);
        expect(fury! - strong!, greaterThan(8), reason: id);
        expect(end! - fury!, greaterThan(8), reason: id);
        expect(hearts, 2, reason: id);
      });
    }

    test('growing stronger: a roar with no shots, then helpers', () {
      final sim = flyUntil(
        level('1-8'),
        (sim) => sim.boss?.phase == BossPhase.attacking,
      );
      final boss = sim.boss!;
      expect(boss.summons, 0);
      // Into the full fight.
      boss.takeDamage(boss.hp - boss.maxHp * 2 ~/ 3);
      final volleys = boss.volleys;
      flyLevel(sim, seconds: .04, shootWhen: (_) => false);
      expect(boss.stageReached, 1);
      final roarAt = boss.stageUpAt;
      expect(boss.stageHint, contains('STRONGER'));
      flyLevel(sim, seconds: SkyBoss.stageRoar - .2, shootWhen: (_) => false);
      expect(boss.volleys, volleys);
      flyLevel(sim, seconds: SkyBoss.stageHelperDelay, shootWhen: (_) => false);
      expect(boss.summons, greaterThan(0));
      expect(boss.lastSummonAt - roarAt, closeTo(SkyBoss.stageHelperDelay, .1));
      expect(boss.stageHint, isNull);
    });
  });

  group('signature attacks wait for the full fight', () {
    /// A staged boss of [kind] at [id]'s fight, stepped [seconds] with the
    /// bird kept alive, [hit] taking it below two thirds after [hitAfter].
    FlightSimulation fight(
      String id, {
      required double seconds,
      double? hitAfter,
      void Function(FlightSimulation sim)? watch,
      int version = FlightSimulation.currentRulesVersion,
    }) {
      final sim = flyUntil(
        level(id),
        (sim) => sim.boss?.phase == BossPhase.attacking,
        version: version,
      );
      final boss = sim.boss!;
      flyLevel(
        sim,
        seconds: seconds,
        shootWhen: (_) => false,
        watch: (sim) {
          final t = boss.combatTime;
          if (hitAfter != null && t >= hitAfter && boss.stage == 0) {
            boss.takeDamage(boss.hp - boss.maxHp * 2 ~/ 3);
          }
          watch?.call(sim);
        },
      );
      return sim;
    }

    test('the Pirate Captain keeps a calm sea in his warm-up', () {
      double? firstWarning;
      final sim = fight(
        '4-8',
        seconds: 40,
        hitAfter: 25,
        watch: (sim) {
          final boss = sim.boss!;
          if (boss.stage == 0) {
            expect(boss.tide, 0);
            expect(boss.tideWarning, 0);
            expect(boss.tideSurges, 0);
            expect(boss.waterLevel, closeTo(SkyBoss.seaLevel, 1e-9));
          }
          if (boss.tideWarning > 0) firstWarning ??= boss.combatTime;
        },
      );
      final boss = sim.boss!;
      expect(firstWarning, isNotNull);
      final stagedAt = boss.stageUpAt - boss.arrivalDuration;
      expect(
        firstWarning! - stagedAt,
        greaterThanOrEqualTo(SkyBoss.signatureLead - .02),
      );
      expect(firstWarning! - stagedAt, lessThan(SkyBoss.tidePeriod + 1.7));
      expect(boss.tideSurges, greaterThan(0));
    });

    test('the Ember Dragon neither breathes nor calls a flock in its '
        'warm-up', () {
      double? firstQuiet;
      final sim = fight(
        '5-8',
        seconds: 45,
        hitAfter: 26,
        watch: (sim) {
          final boss = sim.boss!;
          if (boss.stage == 0) {
            expect(boss.breathQuiet, isFalse);
            expect(boss.breaths, 0);
            expect(boss.swarmCallsDue, 0);
            expect(sim.swarm, isEmpty);
          }
          if (boss.breathQuiet) firstQuiet ??= boss.combatTime;
        },
      );
      final boss = sim.boss!;
      final stagedAt = boss.stageUpAt - boss.arrivalDuration;
      expect(
        firstQuiet! - stagedAt,
        greaterThanOrEqualTo(SkyBoss.signatureLead - .02),
      );
      expect(boss.breathBlasts, greaterThan(0));
      expect(boss.swarmCalls, greaterThan(0));
    });

    test('King Coo puffs in his warm-up but calls no squadron', () {
      final sim = fight(
        '3-2',
        seconds: 50,
        hitAfter: 30,
        watch: (sim) {
          final boss = sim.boss!;
          if (boss.stage == 0) {
            expect(boss.squad, isEmpty);
            expect(boss.whistles, 0);
            // His squadron flies on its tracks; the stragglers (rules 45) do
            // not.
            expect(sim.enemies.where((enemy) => enemy.track != null), isEmpty);
          }
        },
      );
      final boss = sim.boss!;
      expect(boss.puffs, greaterThan(2));
      expect(boss.whistles + boss.pops, greaterThan(0));
    });

    test("King Coo's fury throws three rings but keeps a single V", () {
      final sim = flyUntil(
        level('3-2'),
        (sim) => sim.boss?.phase == BossPhase.attacking,
      );
      final boss = sim.boss!;
      // Straight into fury: the full fight's squadron is armed on the way.
      boss.takeDamage(boss.hp - boss.maxHp ~/ 3);
      var squads = 0, furyRings = 0;
      flyLevel(
        sim,
        seconds: 45,
        shootWhen: (_) => false,
        watch: (sim) {
          expect(boss.squad.length, lessThanOrEqualTo(1));
          if (boss.squadCalled) squads++;
          furyRings = boss.lobs.where((lob) => lob.fury).length;
        },
      );
      expect(boss.enraged, isTrue);
      expect(squads, greaterThan(0));
      expect(furyRings, greaterThan(2));
    });

    test('the Searchlight Gargoyle sweeps in his warm-up but drops no '
        'feathers (rules 44 and 45; from 46 his warm-up drops the calm '
        'cycle\'s: fiercer_gargoyle_test)', () {
      final sim = fight(
        '3-4',
        seconds: 40,
        hitAfter: 20,
        version: FlightSimulation.tougherCooRulesVersion,
        watch: (sim) {
          final boss = sim.boss!;
          if (boss.stage == 0) {
            expect(boss.feathersLaunched, 0);
            expect(boss.featherSchedule, isEmpty);
          }
        },
      );
      final boss = sim.boss!;
      expect(boss.sweepWarnings, greaterThan(2));
      expect(boss.feathersLaunched, greaterThan(0));
    });
  });
}
