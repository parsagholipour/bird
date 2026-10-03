import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/game/boss_motion.dart';
import 'package:push_up_bird/game/neferhoo_fight_art.dart';
import 'package:push_up_bird/game/neferhoo_kit.dart';
import 'package:push_up_bird/game/neferhoo_pose.dart';
import 'package:push_up_bird/game/neferhoo_timeline.dart';

import 'neferhoo_art_support.dart';
import 'neferhoo_stage_support.dart';

/// The faster Neferhoo's art (rules 55): the art reads the boss's own clock
/// ([NeferhooBoss.neferhooBeats]) and the calls the rules latched
/// ([NeferhooFight.calls]). Each call's lane is drawn from its lock until
/// what it sent has passed the bird, two at once at the cycle's join; the
/// pose acts the second call; a blink keeps off the faster lock moments; and
/// no fight frame builds a cached picture (his mummy bats from the warm-up
/// on, prewarmed in the countdown). The pose's frame-to-frame guard runs on
/// this clock in `neferhoo_motion_test.dart`.
const _faster = FlightSimulation.fasterNeferhooRulesVersion;

void main() {
  test('every call\'s lane shows from its lock until what it sent has '
      'passed, two at once at the join; the wave\'s until its bats have', () {
    // the full fight: the second call's letters are still coming as the next
    // cycle's first call locks on another lane
    final boss = courier(px: 792, stage: 1, version: _faster);
    fightTo(boss, 9.65, birdY: .3);
    var lanes = NeferhooFightArt.mailLanes(boss);
    expect(lanes.length, 1);
    expect(lanes.single.y, closeTo(.3, .02));
    fightTo(boss, 11.0, birdY: .3);
    fightTo(boss, 11.2, birdY: .7);
    lanes = NeferhooFightArt.mailLanes(boss);
    expect([for (final l in lanes) l.y], [closeTo(.3, .02), closeTo(.7, .02)]);
    // the second call's lane goes once its last letter is past
    final second = boss.neferhoo.calls[boss.neferhoo.calls.length - 2];
    final last = boss.neferhoo.letters.lastWhere((l) => l.call == second.number);
    final gone = last.releaseAt + (boss.handX - FlightSimulation.birdX + .15) / last.speed;
    fightTo(boss, gone - boss.arrivalDuration + .05, birdY: .7);
    lanes = NeferhooFightArt.mailLanes(boss);
    expect([for (final l in lanes) l.y], [closeTo(.7, .02)]);

    // the warm-up: the wave's lane, from its lock (5.9) until its bats pass
    final warm = courier(px: 792, stage: 0, version: _faster);
    fightTo(warm, 5.85, birdY: .25);
    expect(NeferhooFightArt.mailLanes(warm), isEmpty);
    fightTo(warm, 6.0, birdY: .25);
    lanes = NeferhooFightArt.mailLanes(warm);
    expect([for (final l in lanes) l.y], [closeTo(.25, .02)]);
    final waveBats = warm.neferhoo.bats.where((b) => b.call == warm.neferhoo.calls.last.number).toList();
    expect(waveBats.length, 2);
    fightTo(warm, 9.0, birdY: .6);
    expect(NeferhooFightArt.mailLanes(warm), isNotEmpty, reason: 'the wave\'s bats are still coming');
    fightTo(warm, 10.4, birdY: .6);
    expect(NeferhooFightArt.mailLanes(warm), isEmpty, reason: 'the wave\'s bats are past');
  });

  test('he acts the second call: the satchel opens and the letters are '
      'flicked from 9.6 s, as the ankh comes home', () {
    for (final px in [640.0, 792.0, 864.0]) {
      final boss = courier(px: px, stage: 1, version: _faster);
      fightTo(boss, 9.55);
      final before = NeferhooPose.fight(boss, BossMotion(boss, reducedMotion: false));
      expect(before.satchelOpen, lessThan(.05), reason: '$px');
      fightTo(boss, 10.3);
      final dealing = NeferhooPose.fight(boss, BossMotion(boss, reducedMotion: false));
      expect(dealing.satchelOpen, greaterThan(.5), reason: '$px');
      expect(dealing.reach, greaterThan(.5), reason: '$px');
      expect(boss.lettersInHand, greaterThan(0), reason: '$px');
    }
  });

  test('no blink at the faster lock moments, for every alignment of the '
      'blink clock, the join included', () {
    const beats = NeferhooBeats.faster;
    final starts = [for (var k = 0; k < 37; k++) for (final o in [0.0, .1, .2]) 21 + 10.5 * k + o];
    // (the two calls of this cycle, and the previous cycle's second whose
    // deal runs into this one; then the throw to the catch)
    final deals = <NeferhooDeal>[
      (lock: 9.6 - 10.5, release: 10.6 - 10.5, express: false, count: 3),
      (lock: .6, release: 1.6, express: false, count: 3),
      (lock: 9.6, release: 10.6, express: false, count: 3),
    ];
    final windows = [(0.0, .3), (.45, 1.05), (1.5, 1.8), (5.25, 5.9), (6.5, 7.5), (9.45, 10.05), (10.3, 10.49)];
    for (final fury in [false, true]) {
      NeferhooTimeline at(double ct, double cs) => NeferhooTimeline(
        ct: ct,
        phase: cs + ct,
        bx: 1.228,
        express: fury,
        fury: fury,
        beats: beats,
        deals: deals,
        ankhs: [NeferhooFlight(laneA: .3, laneB: Neferhoo.backLane(.3), throwAt: 6.8, speed: fury ? Neferhoo.furyAnkhSpeed : Neferhoo.ankhSpeed)],
      );
      for (final (a, z) in windows) {
        final n = ((z - a) * 60).round();
        var extra = 0.0;
        for (var i = 0; i <= n; i++) {
          final lids = [for (final cs in starts) at(a + i / 60, cs).pose().lid];
          final base = lids.reduce(math.min);
          extra = math.max(extra, lids.map((l) => l - base).reduce(math.max));
        }
        expect(extra, lessThan(.05), reason: '${fury ? 'fury' : 'calm'} $a-$z stays open');
      }
    }
  });

  testWidgets('the arrival warms his caches: no fight frame of the faster '
      'fight records a picture, his bats from the warm-up on', (tester) async {
    final stage = await neferhooStage(tester, 800, version: _faster);
    await tester.runAsync(() async => (await stage.render()).dispose());
    stage.runTo(1.0);
    await tester.runAsync(() async => (await stage.render()).dispose());
    var recorded = 0;
    final where = <String>[];
    NeferhooKit.debugWrap = (c) {
      recorded++;
      where.add('${stage.boss.combatTime.toStringAsFixed(2)} s');
      return c;
    };
    addTearDown(() => NeferhooKit.debugWrap = null);
    final boss = stage.boss;
    Future<void> at(List<double> ts) async {
      for (final t in ts) {
        stage.fightTo(t);
        await tester.runAsync(() async => (await stage.render()).dispose());
      }
    }

    // the warm-up: the call and its pair, the wave; the full fight: its
    // trio, the ankh, the second call at the join; a letter sent home; fury
    await at([.5, 2.0, 4.6]);
    expect(stage.sim.enemies.where((e) => e.kind == EnemyKind.mummyBat), isNotEmpty);
    await at([6.5, 8.5, 9.6, 11.6]);
    boss.takeDamage(boss.hp - boss.maxHp * 2 ~/ 3);
    await at([12.4, 14.0, 15.4, 16.6, 18.5, 20.3, 21.0, 22.9]);
    final letter = boss.liveLetters.firstWhere((l) => !l.returned);
    stage.sim.rocks.add(BirdRock(x: letter.xAt(boss.age, boss.handX) - .08, y: letter.lane));
    await at([23.1, 23.4, 23.9, 24.4]);
    expect(boss.neferhoo.returnsLanded, greaterThan(0));
    boss.takeDamage(boss.hp - boss.maxHp ~/ 3);
    await at([25, 26.5, 27.2, 33.0, 35.2, 37.5]);
    expect(boss.enraged, isTrue);
    expect(boss.neferhoo.calls.where((c) => c.kind == NeferhooCallKind.second), isNotEmpty);
    expect(boss.neferhoo.waves, greaterThan(0));
    expect(recorded, 0, reason: 'a fight frame built a cached picture: ${where.join(', ')}');
  });
}
