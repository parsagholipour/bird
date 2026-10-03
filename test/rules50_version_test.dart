import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/campaign.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/session_replay.dart';
import 'package:push_up_bird/domain/tracking.dart';

import 'campaign_flight.dart';
import 'endless_plan_baseline_test.dart' show CountingRandom, touchPilot;

/// Rules version 50, "Egypt": Neferhoo, the Mummy Courier, guards the new
/// level 2-6 (the number is `FlightSimulation.neferhooRulesVersion` everywhere
/// below: if he lands under another number, only that constant moves). His
/// level's plan is the only one that needs it (`LevelPlan.minRulesVersion`);
/// everything else flies as at 49 (`frozen_rules49_test.dart` pins that
/// against a recording of the main tree made before the change). The program
/// was built as rules 46 and took 50 when it landed, after the fiercer
/// Gargoyle (46), fair hearts (47), the tougher endless Baron (48) and the
/// level feathers (49). See egypt-int/MASTER-PLAN.md.

CampaignLevel level(String id) => Campaign.level(id)!;

FlightSimulation fly(LevelPlan plan, int version) => FlightSimulation(
  rules: TapFlyMode(rulesVersion: version),
  practice: false,
  course: FlightCourse.starTrail,
  rulesVersion: version,
  plan: plan,
);

void main() {
  test('Neferhoo\'s version came after the level feathers (the all-rings '
      'bonus, 51, and his tougher fight, 52, came after him)', () {
    // The all-rings bonus (51) came after him, and rules 52 made him tougher
    // (neferhoo_tougher_rules_test.dart); 2-6 still needs only 50, and a
    // rules 50 tape of it replays as it flew. Rules 53 grows endless bosses
    // (boss_growth_test.dart), 54 starts King Coo's fury quickly
    // (king_coo_restart_test.dart), and 55 makes Neferhoo faster
    // (neferhoo_faster_rules_test.dart).
    expect(
      FlightSimulation.currentRulesVersion,
      greaterThanOrEqualTo(FlightSimulation.fasterNeferhooRulesVersion),
    );
    expect(FlightSimulation.neferhooRulesVersion, 50);
    expect(
      FlightSimulation.neferhooRulesVersion,
      greaterThan(FlightSimulation.levelFeathersRulesVersion),
    );
    expect(ReplayTape.version, FlightSimulation.currentRulesVersion);
    expect(FlightSimulation.tougherCooRulesVersion, 45);
    expect(FlightSimulation.bossStagesRulesVersion, 44);
  });

  test('Neferhoo is appended after the guardians and is campaign only', () {
    expect(BossKind.values.last, BossKind.neferhoo);
    expect(BossKind.neferhoo.index, 7);
    expect(BossKind.neferhoo.campaignOnly, isTrue);
    expect(BossKind.endlessCycle, 5);
    final boss = SkyBoss(
      number: 1,
      x: 1.5,
      kind: BossKind.neferhoo,
      cinematic: true,
    );
    expect(boss.isNeferhoo, isTrue);
    expect(boss.isMiniBoss, isTrue);
    expect(boss.name, 'Neferhoo');
    expect(boss.title, 'KEEPER OF THE LOST LETTER');
    expect(boss.maxHp, Neferhoo.maxHp);
    expect(
      SkyBoss.campaignHealthFor(BossKind.neferhoo, tougherNeferhoo: false),
      Neferhoo.campaignHp,
    );
    // R1's pilots pinned it (the plan's estimate was 270); rules 52 doubles
    // it (Neferhoo.tougherHp).
    expect(Neferhoo.campaignHp, 300);
    // No volleys, no helpers, no boss ammo: he fights on his own clock.
    expect(boss.fireIn, double.infinity);
    expect(boss.summonIn, double.infinity);
    expect(boss.volleyInterval, double.infinity);
    expect(boss.summonInterval, double.infinity);
    expect(boss.volleyOffsets, isEmpty);
    expect(BossVanguard.wavesOf(BossKind.neferhoo), isEmpty);
    expect(BossVanguard.returnsOf(BossKind.neferhoo), isFalse);
  });

  test(
    'only the plan of 2-6 needs 50; every other level keeps its version',
    () {
      for (final l in Campaign.levels) {
        final expected = l.id == '2-6'
            ? FlightSimulation.neferhooRulesVersion
            : l.plan.usesNewYork
            ? 43
            : 41;
        expect(l.plan.minRulesVersion, expected, reason: l.id);
        expect(l.plan.usesNeferhoo, l.id == '2-6', reason: l.id);
      }
      expect(FlightPlan.endless.minRulesVersion, 0);
    },
  );

  test('older rules refuse to fly or replay 2-6', () {
    final plan = level('2-6').plan;
    for (final version in [41, 43, 44, 45, 46, 47, 48, 49]) {
      expect(() => fly(plan, version), throwsArgumentError, reason: '$version');
    }
    expect(
      fly(plan, FlightSimulation.neferhooRulesVersion).supportsNeferhoo,
      isTrue,
    );
    final tape = ReplayTape(
      mode: PlayMode.touch,
      practice: false,
      seed: 1,
      cycleSeconds: 3,
      bird: 0,
      reducedMotion: false,
      originMs: 0,
      course: FlightCourse.starTrail,
      plan: plan,
    );
    final json = jsonDecode(jsonEncode(tape.toJson())) as Map<String, dynamic>;
    expect(ReplayTape.fromJson(json).plan!.boss, BossKind.neferhoo);
    json['version'] = FlightSimulation.neferhooRulesVersion - 1;
    expect(() => ReplayTape.fromJson(json), throwsFormatException);
  });

  test('no plan JSON key was added: 2-6 writes the keys every boss level '
      'writes', () {
    expect(level('2-6').plan.toJson().keys, level('2-9').plan.toJson().keys);
    expect(level('2-6').plan.toJson()['boss'], 'neferhoo');
    final back = LevelPlan.fromJson(
      jsonDecode(jsonEncode(level('2-6').plan.toJson()))
          as Map<String, dynamic>,
    );
    expect(back.toJson(), level('2-6').plan.toJson());
  });

  test('no endless flight, at any version, meets Neferhoo', () {
    for (final version in [
      34, 38, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, //
      FlightSimulation.neferhooRulesVersion,
    ]) {
      for (var defeated = 0; defeated < 200; defeated++) {
        final encounter = FlightPlan.endless.bossEncounter(defeated, version);
        expect(encounter.kind, isNot(BossKind.neferhoo));
        expect(encounter.kind.campaignOnly, isFalse);
      }
    }
    // And a long flight at the current rules with a weapon that downs every boss fast.
    final sim = FlightSimulation(
      rules: TapFlyMode(),
      practice: false,
      course: FlightCourse.starTrail,
      weaponDamage: 60,
      random: CountingRandom(7),
    );
    final bosses = <BossKind>{};
    var now = 0.0;
    for (var frame = 1; frame <= 560 * 50; frame++) {
      now += 20;
      touchPilot(sim, frame, now, keepAlive: true);
      sim.tick(.02, now);
      if (sim.boss case final boss?) bosses.add(boss.kind);
    }
    expect(bosses, isNotEmpty);
    expect(bosses.where((kind) => kind.campaignOnly), isEmpty);
    expect(sim.supportsNeferhoo, isFalse, reason: 'endless is not staged');
  });

  test('2-6 flies a 30 s run-up, then Neferhoo arrives staged, with no '
      'vanguard, and the shared bot beats him', () {
    final sim = fly(level('2-6').plan, FlightSimulation.neferhooRulesVersion);
    flyLevel(sim, until: (sim) => sim.boss != null, seconds: 120);
    final boss = sim.boss!;
    expect(sim.vanguard, isNull);
    expect(boss.kind, BossKind.neferhoo);
    expect(boss.staged, isTrue);
    expect(boss.cinematic, isTrue);
    expect(boss.maxHp, Neferhoo.campaignHp);
    expect(sim.route!.stars, 36);
    // He holds his anchor and bobs on his clock through the fight, and
    // falls, growing stronger twice on the way (his letters and ankh:
    // neferhoo_rules_test.dart).
    var stages = 0;
    flyLevel(
      sim,
      until: (sim) => sim.phase == RunPhase.ended,
      watch: (sim) {
        final b = sim.boss;
        if (b != null && b.stageReached > stages) stages = b.stageReached;
        if (b != null && b.phase == BossPhase.attacking) {
          expect(
            b.x,
            closeTo(Neferhoo.anchorX(FlightSimulation.birdX, 2.2), 1e-9),
          );
          expect(b.y, closeTo(Neferhoo.hoverY(b.combatTime), 1e-9));
        }
      },
    );
    expect(sim.bossesDefeated, 1);
    expect(sim.endReason, EndReason.completed);
    expect(stages, 2);
  });

  test(
    'his signature is the ankh, armed on its lock once the warm-up ends',
    () {
      final boss = SkyBoss(
        number: 1,
        x: 1.5,
        kind: BossKind.neferhoo,
        cinematic: true,
        staged: true,
        maxHp: Neferhoo.campaignHp,
      )..age = 4.6 + 13; // combat 13 s: cycle 1, .99 s in
      expect(boss.signatureCycle, isNull, reason: 'the warm-up holds it back');
      expect(boss.signatureArmed(1), isFalse);
      boss.armSignature();
      // Cycle 1's ankh locks at 12 + 5.4 = 17.4, at least 1.6 s away.
      expect(boss.signatureCycle, 1);
      expect(boss.signatureArmed(0), isFalse);
      expect(boss.signatureArmed(1), isTrue);
      expect(boss.stageHint, isNull, reason: 'stage 1 not reached yet');
      boss
        ..stageReached = 1
        ..stageUpAt = boss.age;
      expect(boss.stageHint, contains('ankh'));
    },
  );

  test('the ankh flies out on its lane, turns behind the bird and comes '
      'back on the other', () {
    const handX = 1.2, turnX = FlightSimulation.birdX - Neferhoo.ankhBehind;
    final ankh = NeferhooAnkh(
      cycle: 0,
      laneA: .3,
      laneB: Neferhoo.backLane(.3),
      lockedAt: 10,
      thrownAt: 11.4,
      speed: Neferhoo.ankhSpeed,
    );
    expect(ankh.laneB, closeTo(.62, 1e-12));
    expect(ankh.at(11.3, handX: handX, turnX: turnX), isNull);
    expect(ankh.at(11.4, handX: handX, turnX: turnX), (handX, .3));
    final length = ankh.length(handX, turnX);
    final home = 11.4 + length / ankh.speed;
    final back = ankh.at(home - 1e-9, handX: handX, turnX: turnX)!;
    expect(back.$1, closeTo(handX, 1e-6));
    expect(back.$2, .62);
    expect(ankh.at(home + .01, handX: handX, turnX: turnX), isNull);
    // At the turn it is a whole loop's radius behind the turning column.
    final out = handX - turnX;
    final r = (ankh.laneB - ankh.laneA) / 2;
    final turn = ankh.at(
      11.4 + (out + 3.14159265 * r / 2) / ankh.speed,
      handX: handX,
      turnX: turnX,
    )!;
    expect(turn.$1, closeTo(turnX - r, 1e-6));
    expect(turn.$2, closeTo(.46, 1e-6));
  });

  test('the pure numbers of the spec', () {
    expect(
      Neferhoo.anchorX(FlightSimulation.birdX, 640 / 360),
      closeTo(1.2277, 1e-3),
    );
    expect(
      Neferhoo.anchorX(FlightSimulation.birdX, 800 / 360) * 360,
      closeTo(602, .5),
    );
    expect(Neferhoo.wrapsDamage(10), 3);
    expect(Neferhoo.wrapsDamage(40), 13);
    expect(Neferhoo.wrapsDamage(1), 1);
    expect(Neferhoo.laneFor(.05), Neferhoo.laneTop);
    expect(Neferhoo.ankhLaneFor(.9), Neferhoo.ankhBottom);
    expect(Neferhoo.backLane(.7), closeTo(.38, 1e-12));
    expect(Neferhoo.streamCount(fury: false), 3);
    expect(Neferhoo.streamCount(fury: true), 5);
    expect(Neferhoo.count(0, .6), 0);
    expect(Neferhoo.count(.6, .6), 1);
    expect(Neferhoo.count(12.6, .6), 2);
    expect(Neferhoo.returnSeconds(.1), .35);
    expect(Neferhoo.returnSeconds(5), .8);
  });
}
