import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/campaign.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/session_replay.dart';
import 'package:push_up_bird/domain/tracking.dart';

import 'endless_plan_baseline_test.dart' show CountingRandom, touchPilot;
import 'frozen_rules50_flights.dart' show Frozen50Tape;
import 'gargoyle_pilot.dart' show frame;
import 'neferhoo_pilot.dart';
import 'neferhoo_rules_test.dart' show holdUntil, hurtTo, w640;

/// The tougher Neferhoo (rules version 52, level 2-6), on the REAL
/// simulation: twice the health, letters [Neferhoo.tougherPace] times faster
/// there and back, and his mummy bats ([EnemyKind.mummyBat]): none in the
/// warm-up, a pair down each mail call's lane after its letters in the full
/// fight, fury's trio a bit faster. A bat flies as a small bat (the simple
/// bat's arc, settling into the lane), hurts on touch, and a rock or a
/// sprint's ram downs it for a simple bat's score; his defeat clears them.
/// The rules 50 fight is untouched (`frozen_rules50_test.dart`; here: a 50
/// fight still meets no bat), and nothing outside his tougher fight ever
/// meets a mummy bat.
///
/// Every fight starts as he begins to fight ([neferhooArena], 640 px wide)
/// and is stepped at 60 Hz with the bird held where each test puts it.

const _tougher = FlightSimulation.tougherNeferhooRulesVersion;
const _fifty = FlightSimulation.neferhooRulesVersion;

bool _isBat(SkyEnemy e) => e.kind == EnemyKind.mummyBat;

/// Steps until the next mail call has locked (combat time just past
/// [lock]), the bird held at [y].
void lockAt(FlightSimulation sim, double lock, {required double y}) =>
    holdUntil(sim, lock + .02, y: y, keepAlive: true);

/// Everything the rules latched for his bats and the bats in the sky.
String batState(FlightSimulation sim) {
  final boss = sim.boss!;
  final f = boss.neferhoo;
  return [
    'hp=${boss.hp} stage=${boss.stageReached} launched=${f.batsLaunched} '
        'last=${f.lastBatAt} defeated=${sim.enemiesDefeated} '
        'score=${sim.score} hearts=${sim.hearts} shield=${sim.shield}',
    for (final b in f.bats)
      'B ${b.cycle}/${b.index} ${b.lane} ${b.launchAt} ${b.pace} ${b.fury} '
          '${b.goneAt} ${b.enemy?.x} ${b.enemy?.y} ${b.enemy?.hp}',
    for (final e in sim.enemies) 'E ${e.kind.name} ${e.x} ${e.y} ${e.hp}',
    for (final l in f.letters)
      'L ${l.cycle}/${l.index} ${l.speed} ${l.returnedAt} ${l.homeAt} '
          '${l.landedAt} ${l.spentAt}',
  ].join('\n');
}

void main() {
  group('rules 52', () {
    test('came after Neferhoo\'s 50 and the all-rings bonus\'s 51 (53, '
        'growing endless bosses, 54, King Coo\'s quick fury, and 55, a faster '
        'Neferhoo, came after it)', () {
      expect(_tougher, 52);
      expect(FlightSimulation.currentRulesVersion, greaterThanOrEqualTo(55));
      expect(_tougher, greaterThan(_fifty));
      expect(_tougher, greaterThan(FlightSimulation.allRingsRulesVersion));
      expect(ReplayTape.version, FlightSimulation.currentRulesVersion);
      // 2-6 still flies (and replays) at 50: the plan needs 50, not 52.
      expect(Campaign.level('2-6')!.plan.minRulesVersion, _fifty);
    });

    test('the mummy bat is appended, campaign only, a simple bat in the '
        'rules', () {
      expect(EnemyKind.values.last, EnemyKind.mummyBat);
      expect(EnemyKind.mummyBat.index, 5);
      expect(EnemyKind.mummyBat.campaignOnly, isTrue);
      expect(EnemyKind.values.where((k) => k.campaignOnly), [
        EnemyKind.alleyPigeon,
        EnemyKind.mummyBat,
      ]);
      final i = EnemyKind.mummyBat.index;
      expect(SkyEnemy.healthFor(i), 10);
      expect(Neferhoo.batHp, BirdRock.baseDamage, reason: 'one rock');
      for (final phase in [0.0, 1.3, 7.7]) {
        final bat = SkyEnemy(x: 1.6, y: .4, appearance: i, flightPhase: phase);
        final simple = SkyEnemy(
          x: 1.6,
          y: .4,
          appearance: EnemyKind.simpleBat.index,
          flightPhase: phase,
        );
        expect(bat.kind, EnemyKind.mummyBat);
        expect(bat.attack, EnemyAttack.none);
        expect(bat.pigeon, isNull);
        for (final age in [0.0, .4, 1.1, 2.9]) {
          bat.age = simple.age = age;
          expect(bat.y, simple.y, reason: 'the simple bat\'s arc');
          expect(bat.flightBank, simple.flightBank);
        }
      }
    });

    test('his health doubles, and only his tougher fight is tougher', () {
      expect(Neferhoo.tougherHp, 600);
      expect(Neferhoo.tougherHp, 2 * Neferhoo.campaignHp);
      // (rules 55's faster fight adds 100: neferhoo_faster_rules_test.dart)
      expect(
        SkyBoss.campaignHealthFor(BossKind.neferhoo, fasterNeferhoo: false),
        600,
      );
      expect(
        SkyBoss.campaignHealthFor(BossKind.neferhoo, tougherNeferhoo: false),
        300,
      );
      for (final kind in BossKind.values.where((k) => k != BossKind.neferhoo)) {
        expect(
          SkyBoss.campaignHealthFor(kind, tougherNeferhoo: false),
          SkyBoss.campaignHealthFor(kind),
          reason: kind.name,
        );
      }
      final now = neferhooArena(version: _tougher).boss!;
      expect(now.tougherNeferhoo, isTrue);
      expect(now.maxHp, 600);
      final before = neferhooArena(version: _fifty).boss!;
      expect(before.tougherNeferhoo, isFalse);
      expect(before.maxHp, 300);
      // A boss built by hand is not.
      expect(
        SkyBoss(
          number: 1,
          x: 1.5,
          kind: BossKind.neferhoo,
          cinematic: true,
        ).tougherNeferhoo,
        isFalse,
      );
    });

    test('growing stronger names the ankh and the bats', () {
      for (final (version, hint) in [
        (_tougher, Neferhoo.tougherStageHint),
        (_fifty, 'STRONGER · The golden ankh comes back!'),
      ]) {
        final sim = neferhooArena(version: version);
        final boss = sim.boss!;
        hurtTo(boss, 2 / 3);
        holdUntil(sim, 1, y: .5, keepAlive: true);
        expect(boss.stageReached, 1);
        expect(boss.stageHint, hint);
      }
      // As long as the card's longest line (the Dusk Empress's).
      expect(
        Neferhoo.tougherStageHint.length,
        lessThanOrEqualTo(
          'STRONGER · Seven-shot fans, and her moths join in!'.length,
        ),
      );
    });
  });

  group('faster letters', () {
    test('every stream flies tougherPace times faster', () {
      expect(Neferhoo.tougherPace, 1.4);
      expect(
        Neferhoo.letterSpeedOf(fury: false, tougher: true),
        closeTo(.63, 1e-9),
      );
      expect(
        Neferhoo.letterSpeedOf(fury: true, tougher: true),
        closeTo(.728, 1e-9),
      );
      expect(Neferhoo.letterSpeedOf(fury: false), Neferhoo.letterSpeed);
      expect(Neferhoo.letterSpeedOf(fury: true), Neferhoo.furyLetterSpeed);
      final sim = neferhooArena(version: _tougher);
      final boss = sim.boss!;
      final f = boss.neferhoo;
      lockAt(sim, .6, y: .3);
      expect(f.letters.map((l) => l.speed).toSet(), {
        Neferhoo.letterSpeedOf(fury: false, tougher: true),
      });
      hurtTo(boss, 1 / 3);
      lockAt(sim, 12.6, y: .3);
      expect(f.express, isTrue);
      expect(f.letters.skip(3).map((l) => l.speed).toSet(), {
        Neferhoo.letterSpeedOf(fury: true, tougher: true),
      });
      // At 50 they fly as they did.
      final old = neferhooArena(version: _fifty);
      lockAt(old, .6, y: .3);
      expect(old.boss!.neferhoo.letters.map((l) => l.speed).toSet(), {
        Neferhoo.letterSpeed,
      });
    });

    test('a returned letter flies home tougherPace times sooner and lands '
        'once for 25', () {
      final sim = neferhooArena(version: _tougher);
      final boss = sim.boss!;
      final f = boss.neferhoo;
      lockAt(sim, .6, y: .5);
      final lane = f.laneY;
      holdUntil(sim, 1.75, y: lane, keepAlive: true);
      expect(sim.shoot(), isTrue);
      for (var i = 0; i < 120 && f.lettersReturned == 0; i++) {
        holdUntil(sim, boss.combatTime + 1 / 60, y: lane, keepAlive: true);
      }
      final letter = f.letters.firstWhere((l) => l.returned);
      final dx = boss.x - letter.struckX, dy = boss.y - letter.lane;
      // (the chest moves as he bobs: the distance at the catch's step)
      final seconds = letter.homeAt! - letter.returnedAt!;
      expect(
        seconds,
        closeTo(
          Neferhoo.returnSecondsOf(math.sqrt(dx * dx + dy * dy), tougher: true),
          .02,
        ),
      );
      expect(
        Neferhoo.returnSecondsOf(1, tougher: true),
        closeTo(1 / 1.4 / 1.4, 1e-9),
      );
      expect(
        Neferhoo.returnSecondsOf(.1, tougher: true),
        closeTo(.35 / 1.4, 1e-9),
      );
      expect(Neferhoo.returnSecondsOf(1), Neferhoo.returnSeconds(1));
      final hp = boss.hp;
      holdUntil(sim, boss.combatTime + 1.2, y: .2, keepAlive: true);
      expect(f.returnsLanded, 1);
      expect(boss.hp, hp - Neferhoo.returnDamage);
    });
  });

  group('the mummy bats', () {
    test('the warm-up sends none; each mail call of the full fight latches a '
        'pair down its lane after its letters, fury a faster trio', () {
      final sim = neferhooArena(version: _tougher);
      final boss = sim.boss!;
      final f = boss.neferhoo;
      final start = boss.arrivalDuration;
      holdUntil(sim, 12.7, y: .5, keepAlive: true);
      expect(f.mailLocks, 2);
      expect(f.bats, isEmpty, reason: 'a calm warm-up');
      expect(sim.enemies.where(_isBat), isEmpty);
      expect(boss.batsWaiting, 0);

      hurtTo(boss, 2 / 3);
      lockAt(sim, 24.6, y: .3);
      expect(boss.stageReached, 1);
      expect(f.express, isFalse);
      expect(f.bats, hasLength(2));
      final lock = start + 24.6;
      for (final (k, bat) in f.bats.indexed) {
        expect(bat.cycle, 2);
        expect(bat.index, k);
        expect(bat.lane, f.laneY);
        expect(bat.fury, isFalse);
        expect(bat.pace, Neferhoo.batPace);
        expect(
          bat.launchAt,
          closeTo(lock + Neferhoo.batLaunch(k, fury: false, width: w640), 1e-9),
        );
        expect(bat.launched, isFalse);
      }
      // .8 and 1.2 s after the lock (the first trails the last letter by
      // .15 as it leaves his hand, 1.8 s after the lock).
      expect(
        Neferhoo.batLaunch(0, fury: false, width: w640),
        closeTo(.8, 1e-9),
      );
      expect(
        Neferhoo.batLaunch(1, fury: false, width: w640),
        closeTo(1.2, 1e-9),
      );
      expect(boss.batsWaiting, 2);
      expect(boss.neferhooHint, Neferhoo.mailHint);

      holdUntil(sim, 24.6 + .8 + .01, y: .3, keepAlive: true);
      expect(f.batsLaunched, 1);
      expect(boss.batsWaiting, 1);
      final first = f.bats.first.enemy!;
      expect(sim.enemies, contains(first));
      expect(first.kind, EnemyKind.mummyBat);
      expect(first.maxHp, Neferhoo.batHp);
      // Its pace on the screen, whatever the scroll speed.
      expect(first.drift * sim.speed, closeTo(Neferhoo.batPace, .002));
      expect(first.flightPhase, isNotNull);
      expect(
        first.x,
        closeTo(Neferhoo.batStartX(w640), .02),
        reason: 'in from the right edge',
      );
      expect(first.y, closeTo(f.laneY, .012), reason: 'in the lane');
      expect(f.lastBatAt, closeTo(f.bats.first.launchAt, 1 / 60 + 1e-9));
      holdUntil(sim, 24.6 + 1.2 + .01, y: .3, keepAlive: true);
      expect(f.batsLaunched, 2);
      expect(boss.batsWaiting, 0);

      hurtTo(boss, 1 / 3);
      lockAt(sim, 36.6, y: .7);
      expect(boss.stageReached, 2);
      expect(f.express, isTrue);
      final trio = f.bats.skip(2).toList();
      expect(trio, hasLength(3));
      for (final (k, bat) in trio.indexed) {
        expect(bat.fury, isTrue);
        expect(bat.pace, Neferhoo.furyBatPace);
        expect(bat.lane, f.laneY);
        expect(
          bat.launchAt,
          closeTo(
            start + 36.6 + Neferhoo.batLaunch(k, fury: true, width: w640),
            1e-9,
          ),
        );
      }
      // From 1.40 s, .32 apart (the last letter leaves his hand at 2.28).
      expect(
        Neferhoo.batLaunch(0, fury: true, width: w640),
        closeTo(2.28 - .6 / .68, 1e-9),
      );
      expect(
        Neferhoo.batLaunch(2, fury: true, width: w640),
        closeTo(2.28 - .6 / .68 + .64, 1e-9),
      );
      expect(Neferhoo.furyBatPace, greaterThan(Neferhoo.batPace));
      // Slower than the letters they follow.
      expect(
        Neferhoo.batPace,
        lessThan(Neferhoo.letterSpeedOf(fury: false, tougher: true)),
      );
      expect(
        Neferhoo.furyBatPace,
        lessThan(Neferhoo.letterSpeedOf(fury: true, tougher: true)),
      );
    });

    for (final px in [640, 792, 864]) {
      test('$px px: they fly behind their letters, settle into the lane, and '
          'are past the bird long before an ankh can reach it', () {
        final width = px / 360;
        final sim = neferhooArena(version: _tougher, width: width);
        final boss = sim.boss!;
        final f = boss.neferhoo;
        final turnX = Neferhoo.turnX(FlightSimulation.birdX);
        var checked = 0, frames = 0;
        var nearest = double.infinity;
        // Two full cycles in the full fight, two in fury, the bird held
        // far from every lane (top or bottom, away from the call).
        hurtTo(boss, 2 / 3);
        for (var cycle = 0; cycle < 4; cycle++) {
          if (cycle == 2) hurtTo(boss, 1 / 3);
          // (to just before the next call's lock)
          final until = (cycle + 1) * Neferhoo.period + .3;
          for (var i = 0; i < 60 * 13 && boss.combatTime < until; i++) {
            final away = f.laneY < .5 ? .85 : .15;
            holdUntil(
              sim,
              boss.combatTime + 1 / 60,
              y: away,
              width: width,
              keepAlive: true,
            );
            frames++;
            for (final bat in f.bats) {
              final enemy = bat.enemy;
              if (enemy == null || bat.goneAt != null) continue;
              if (!sim.enemies.contains(enemy)) continue;
              // Behind every letter of its call still flying out.
              for (final letter in f.letters) {
                if (letter.cycle != bat.cycle || letter.returned) continue;
                if (letter.gone || !letter.dealtBy(boss.age)) continue;
                expect(
                  enemy.x,
                  greaterThan(letter.xAt(boss.age, boss.handX)),
                  reason: 'cycle ${bat.cycle}',
                );
                checked++;
              }
              // Level in its lane near the bird (its flight bob settles
              // .22 before the bird's column, as every small enemy's).
              if (enemy.x <= FlightSimulation.birdX + .22) {
                expect(enemy.y, closeTo(bat.lane, 1e-9));
              }
              // No ankh within reach of the bird's column while a bat is.
              if ((enemy.x - FlightSimulation.birdX).abs() <
                  SkyEnemy.radius + FlightSimulation.birdRadius) {
                for (final ankh in f.ankhs) {
                  final at = ankh.at(boss.age, handX: boss.handX, turnX: turnX);
                  if (at == null) continue;
                  final gap = (at.$1 - FlightSimulation.birdX).abs();
                  nearest = gap < nearest ? gap : nearest;
                }
              }
            }
          }
        }
        expect(frames, greaterThan(60 * 40));
        expect(checked, greaterThan(100));
        expect(f.batsLaunched, 2 + 2 + 3 + 3);
        expect(sim.hearts, 3, reason: 'held clear: nothing touched it');
        // An ankh in flight is never near the column while a bat crosses it.
        expect(nearest, greaterThan(.5));
      });
    }

    test('a bat that meets the bird hurts it; a rock downs it for a simple '
        'bat\'s score; a sprint\'s ram downs it', () {
      // Touch: the bird dodges the letters, then sits in the lane.
      var sim = neferhooArena(version: _tougher);
      var boss = sim.boss!;
      var f = boss.neferhoo;
      // (Stronger from the start: the first call, at .6, sends a pair.)
      hurtTo(boss, 2 / 3);
      lockAt(sim, .6, y: .3);
      final lane = f.laneY;
      // Out of the lane until the letters have passed, then back in it.
      holdUntil(sim, .6 + 3.15, y: .75, keepAlive: true);
      expect(sim.shield, isTrue);
      expect(f.batsLaunched, 2);
      final first = f.bats.first.enemy!;
      var defeated = sim.enemiesDefeated;
      for (var i = 0; i < 60 * 4 && sim.enemies.contains(first); i++) {
        holdUntil(sim, boss.combatTime + 1 / 60, y: lane);
      }
      expect(sim.enemies, isNot(contains(first)));
      expect(sim.shield, isFalse, reason: 'it hurt the bird');
      expect(sim.enemiesDefeated, defeated, reason: 'not downed');
      holdUntil(sim, boss.combatTime + .1, y: .75);
      expect(f.bats.first.goneAt, isNotNull);

      // Rocks: the bird stays in the lane and fires as fast as it may: it
      // sends the letters back, then downs the bats behind them.
      sim = neferhooArena(version: _tougher);
      boss = sim.boss!;
      f = boss.neferhoo;
      hurtTo(boss, 2 / 3);
      lockAt(sim, .6, y: .3);
      defeated = sim.enemiesDefeated;
      final score = sim.score;
      bool coming() =>
          f.letters.any((l) => l.dealtBy(boss.age) && !l.returned && !l.gone) ||
          f.bats.any((b) => b.launched && sim.enemies.contains(b.enemy));
      for (var i = 0; i < 60 * 6 && f.bats.any((b) => b.goneAt == null); i++) {
        if (coming() && sim.canShoot) sim.shoot();
        holdUntil(sim, boss.combatTime + 1 / 60, y: f.laneY, keepAlive: true);
      }
      expect(f.lettersReturned, 3);
      expect(f.bats.map((b) => b.enemy!.hp), [0, 0], reason: 'one rock each');
      expect(sim.shield, isTrue, reason: 'nothing reached the bird');
      expect(sim.enemiesDefeated, defeated + 2);
      expect(sim.score, greaterThanOrEqualTo(score + 6));
      expect(
        sim.events.where(
          (e) =>
              e.kind == FlightEventKind.enemyHit &&
              e.enemyKind == EnemyKind.mummyBat,
        ),
        isNotEmpty,
      );

      // A ram: a sprint into the bat.
      sim = neferhooArena(version: _tougher);
      boss = sim.boss!;
      f = boss.neferhoo;
      hurtTo(boss, 2 / 3);
      lockAt(sim, .6, y: .3);
      // (out of the lane until the letters and the first bat have passed)
      holdUntil(sim, .6 + 3.3, y: .75, keepAlive: true);
      final rammed = f.bats[1].enemy!;
      defeated = sim.enemiesDefeated;
      var sprinted = false;
      for (var i = 0; i < 60 * 4 && sim.enemies.contains(rammed); i++) {
        if (!sprinted &&
            rammed.x - FlightSimulation.birdX < .3 &&
            sim.canSprint) {
          sprinted = sim.sprint();
        }
        holdUntil(sim, boss.combatTime + 1 / 60, y: f.laneY, keepAlive: true);
      }
      expect(sprinted, isTrue);
      expect(sim.enemiesDefeated, defeated + 1);
      expect(sim.shield, isTrue, reason: 'a ram does not hurt');
      expect(
        sim.events.where(
          (e) =>
              e.kind == FlightEventKind.enemyRammed &&
              e.enemyKind == EnemyKind.mummyBat,
        ),
        isNotEmpty,
      );
    });

    test('the hint names them while they are still coming', () {
      final sim = neferhooArena(version: _tougher);
      final boss = sim.boss!;
      final f = boss.neferhoo;
      hurtTo(boss, 2 / 3);
      lockAt(sim, .6, y: .3);
      holdUntil(sim, .6 + 2.0, y: .75, keepAlive: true);
      expect(boss.neferhooHint, Neferhoo.mailHint);
      // The letters have passed; the bats are still on their way.
      final last = f.letters.last;
      final passed =
          last.releaseAt +
          (boss.handX - (Neferhoo.birdColumn - .1)) / last.speed -
          boss.arrivalDuration;
      holdUntil(sim, passed + .05, y: .75, keepAlive: true);
      expect(f.bats.any((b) => b.goneAt == null), isTrue);
      expect(boss.neferhooHint, Neferhoo.batsHint);
      // Gone past the bird: the open sky's line.
      holdUntil(sim, .6 + 5.2, y: .75, keepAlive: true);
      expect(boss.neferhooHint, isNot(Neferhoo.batsHint));
    });

    test('his defeat clears his bats, and none leaves his hand after it', () {
      for (final early in [false, true]) {
        final sim = neferhooArena(version: _tougher);
        final boss = sim.boss!;
        final f = boss.neferhoo;
        hurtTo(boss, 2 / 3);
        // A high lane, far from his chest: rocks at him meet no bat.
        lockAt(sim, .6, y: .2);
        holdUntil(sim, .6 + (early ? .3 : 2.75), y: .2, keepAlive: true);
        expect(f.batsLaunched, early ? 0 : 2);
        if (!early) expect(sim.enemies.where(_isBat), hasLength(2));
        boss.takeDamage(boss.hp - 1);
        final y = boss.y;
        for (var i = 0; i < 120 && boss.phase == BossPhase.attacking; i++) {
          if (sim.canShoot) sim.shoot();
          holdUntil(sim, boss.combatTime + 1 / 60, y: y, keepAlive: true);
        }
        expect(boss.phase, BossPhase.defeated);
        expect(sim.enemies.where(_isBat), isEmpty);
        final launched = f.batsLaunched;
        for (var i = 0; i < 60 * 8 && sim.phase != RunPhase.ended; i++) {
          sim
            ..birdY = .5
            ..velocity = 0;
          frame(sim, width: w640);
          expect(sim.enemies.where(_isBat), isEmpty);
        }
        expect(f.batsLaunched, launched, reason: early ? 'none left' : '');
        expect(boss.batsWaiting, 0);
      }
    });
  });

  group('determinism', () {
    test('a replay with bats in flight seeks backward and forward to the '
        'same fight, as a fresh replay does', () {
      final tape = const Frozen50Tape(
        'family-2-6-640',
        skill: family,
        width: 640 / 360,
        seed: 1,
      ).record(version: _tougher);
      expect(tape.recordedVersion, _tougher);
      final text = jsonEncode(tape.toJson());
      final again = ReplayTape.fromJson(
        jsonDecode(text) as Map<String, dynamic>,
      );
      expect(jsonEncode(again.toJson()), text);
      // Moments with bats in flight.
      final scan = ReplayPlayer(tape);
      final moments = <double>[];
      for (var ms = 1000.0; ms <= tape.durationMs; ms += 250) {
        scan.seek(ms);
        if (scan.simulation.enemies.any(_isBat)) moments.add(ms);
      }
      expect(moments.length, greaterThan(10));
      final player = ReplayPlayer(again);
      for (final ms in [
        moments[moments.length ~/ 4],
        moments[moments.length ~/ 2],
        moments.last,
      ]) {
        final fresh = ReplayPlayer(tape)..seek(ms);
        final want = batState(fresh.simulation);
        expect(fresh.simulation.enemies.any(_isBat), isTrue);
        player.seek(ms);
        expect(batState(player.simulation), want, reason: 'forward $ms');
        player.seek(ms / 3);
        player.seek(ms);
        expect(batState(player.simulation), want, reason: 'back again $ms');
      }
    }, timeout: const Timeout(Duration(minutes: 5)));
  });

  group('gating', () {
    test('no endless, co-op or duel flight meets a mummy bat, at any '
        'version, over 200 boss numbers', () {
      final versions = [
        for (var v = 19; v <= FlightSimulation.currentRulesVersion; v++) v,
      ];
      for (final plan in [FlightPlan.endless, const DuelPlan()]) {
        for (final version in versions) {
          for (var defeated = 0; defeated < 200; defeated++) {
            final encounter = plan.bossEncounter(defeated, version);
            expect(encounter.kind, isNot(BossKind.neferhoo));
          }
        }
        for (var index = 0; index < 200; index++) {
          for (final helper in [false, true]) {
            final appearance = plan.enemyAppearance(index, bossHelper: helper);
            expect(
              EnemyKind.values[appearance],
              isNot(EnemyKind.mummyBat),
              reason: '$index',
            );
            expect(EnemyKind.values[appearance].campaignOnly, isFalse);
          }
        }
      }
      // Long flights at the current rules: solo, roped, free, a duel.
      for (final coop in [null, CoopMode.roped, CoopMode.free, CoopMode.duel]) {
        final sim = FlightSimulation(
          rules: TapFlyMode(),
          practice: false,
          course: FlightCourse.starTrail,
          weaponDamage: 60,
          coop: coop,
          random: CountingRandom(7),
        );
        var now = 0.0, bosses = 0;
        for (var frame = 1; frame <= 400 * 50; frame++) {
          now += 20;
          if (coop == null) {
            touchPilot(sim, frame, now, keepAlive: true);
          } else {
            for (final bird in sim.flock) {
              if (bird.hearts < 2) bird.hearts = 3;
            }
            sim.apply(const MovementInput(valid: true), _touch(now), now);
            for (final (i, _) in sim.flock.indexed) {
              if (frame % 25 == i * 12) sim.flap(i);
              if ((frame + i * 45) % 90 == 30) sim.shoot(player: i);
            }
          }
          sim.tick(.02, now);
          expect(sim.enemies.where(_isBat), isEmpty);
          if (sim.boss case final boss?) {
            expect(boss.tougherNeferhoo, isFalse);
            bosses = sim.bossesDefeated + 1;
          }
          if (sim.phase == RunPhase.ended) break;
        }
        expect(sim.supportsTougherNeferhoo, isFalse, reason: 'not staged');
        if (coop == null) expect(bosses, greaterThan(0));
      }
    }, timeout: const Timeout(Duration(minutes: 5)));

    test('no level lays one: the catalog\'s lineups hold none, and a plan '
        'that names one is refused', () {
      for (final level in Campaign.levels) {
        expect(level.plan.lineup, isNot(contains(EnemyKind.mummyBat)));
        expect(level.plan.problem, isNull, reason: level.id);
      }
      final json =
          jsonDecode(jsonEncode(Campaign.level('2-6')!.plan.toJson()))
              as Map<String, dynamic>;
      json['lineup'] = ['simpleBat', 'mummyBat'];
      expect(() => LevelPlan.fromJson(json), throwsFormatException);
    });

    test('only 2-6 at 52 is tougher; 2-6 at 50 meets no bat and flies his '
        'rules 50 fight (as 2-6 at 51 does)', () {
      for (final level in Campaign.levels) {
        expect(level.plan.usesNeferhoo, level.id == '2-6', reason: level.id);
      }
      final old = neferhooArena(version: _fifty);
      expect(old.supportsTougherNeferhoo, isFalse);
      final run = flyNeferhoo(
        old,
        NeferhooPilot(family, seed: 1, careful: true),
        seconds: 200,
        keepAlive: true,
      );
      expect(run.fight, isNotNull);
      final f = old.boss!.neferhoo;
      expect(f.bats, isEmpty);
      expect(f.batsLaunched, 0);
      expect(f.letters.map((l) => l.speed).toSet(), {
        Neferhoo.letterSpeed,
        Neferhoo.furyLetterSpeed,
      });
      expect(old.boss!.maxHp, Neferhoo.campaignHp);
      final rings = neferhooArena(
        version: FlightSimulation.allRingsRulesVersion,
      );
      expect(rings.supportsTougherNeferhoo, isFalse);
      expect(rings.boss!.maxHp, Neferhoo.campaignHp);
      final now = neferhooArena(version: _tougher);
      expect(now.supportsTougherNeferhoo, isTrue);
    });
  });
}

TrackingSample _touch(double now) => TrackingSample(
  mode: PlayMode.touch,
  timestampMs: now,
  receivedMs: now,
  joints: const [],
);
