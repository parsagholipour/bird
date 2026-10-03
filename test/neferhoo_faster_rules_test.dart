import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/campaign.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/session_replay.dart';

import 'campaign_flight.dart' show levelFlight;
import 'gargoyle_pilot.dart' show frame;
import 'neferhoo_art_support.dart';
import 'neferhoo_pilot.dart';

/// Rules 55, the faster Neferhoo. The owner beat the tougher one (rules 52)
/// in about 49 s and said: "It is still stall for too long. It should call
/// the bats more and from the beginning. It needs 100 more HP. It needs to
/// shoot more." So in 2-6 at 55 ([SkyBoss.fasterNeferhoo],
/// [NeferhooBeats.faster]):
///
/// - 700 health (600 at 52 to 54; rules 53's boss growth is endless only);
/// - a 10.5 s cycle: the first mail call at .6 with its mummy bats from the
///   warm-up on (a pair, a trio, fury's four); the ankh at 5.4 as before; a
///   second mail call at 9.6, once the ankh's return pass is over; in the
///   warm-up, a wave of two bats at 5.9 instead of the ankh and that call;
/// - a returned letter deals 18 (twice the letters a cycle, each worth less,
///   so a practised player's fight grows longer: the pilots).
///
/// Everything at 50 to 54 flies as before (`frozen_rules54_test.dart`).
const _faster = FlightSimulation.fasterNeferhooRulesVersion;
const _before = FlightSimulation.cooRestartRulesVersion;

bool _isBat(SkyEnemy e) => e.kind == EnemyKind.mummyBat;

void main() {
  test('55 comes after King Coo\'s 54, and only 2-6 '
      'meets the faster Neferhoo', () {
    expect(_faster, 55);
    expect(FlightSimulation.currentRulesVersion, greaterThanOrEqualTo(_faster));
    expect(_faster, greaterThan(FlightSimulation.cooRestartRulesVersion));
    expect(ReplayTape.version, FlightSimulation.currentRulesVersion);
    // 2-6 still needs only Neferhoo's 50: a saved 50 to 54 tape replays.
    expect(Campaign.level('2-6')!.plan.minRulesVersion, 50);
    for (final version in [50, 52, 53, 54, 55]) {
      final sim = levelFlight(Campaign.level('2-6')!, version: version);
      expect(sim.supportsFasterNeferhoo, version >= 55, reason: '$version');
      expect(sim.supportsTougherNeferhoo, version >= 52, reason: '$version');
    }
  });

  test('a hundred more health: 700 at 55, 600 at 52 to 54', () {
    expect(Neferhoo.fasterHp, 700);
    expect(Neferhoo.fasterHp, Neferhoo.tougherHp + 100);
    expect(SkyBoss.campaignHealthFor(BossKind.neferhoo), 700);
    expect(
      SkyBoss.campaignHealthFor(BossKind.neferhoo, fasterNeferhoo: false),
      600,
    );
    expect(
      SkyBoss.campaignHealthFor(
        BossKind.neferhoo,
        tougherNeferhoo: false,
        fasterNeferhoo: true,
      ),
      300,
    );
    for (final kind in BossKind.values.where((k) => k != BossKind.neferhoo)) {
      expect(
        SkyBoss.campaignHealthFor(kind, fasterNeferhoo: false),
        SkyBoss.campaignHealthFor(kind),
        reason: kind.name,
      );
    }
    final now = neferhooArena(version: _faster).boss!;
    expect(now.maxHp, 700);
    expect(now.fasterNeferhoo, isTrue);
    expect(now.tougherNeferhoo, isTrue);
    expect(now.neferhooBeats, same(NeferhooBeats.faster));
    for (final version in [52, 53, 54]) {
      final then = neferhooArena(version: version).boss!;
      expect(then.maxHp, 600, reason: '$version');
      expect(then.fasterNeferhoo, isFalse, reason: '$version');
      expect(then.neferhooBeats, same(NeferhooBeats.classic));
    }
  });

  test('the clocks: the classic one is the rules 50 constants, the faster '
      'one a 10.5 s cycle', () {
    const c = NeferhooBeats.classic, f = NeferhooBeats.faster;
    expect(c.isFaster, isFalse);
    expect(c.period, Neferhoo.period);
    expect(c.ankhLockAt, Neferhoo.ankhLockAt);
    expect(c.ankhThrowAt, Neferhoo.ankhThrowAt);
    expect(c.secondMailAt, isNull);
    expect(c.waveAt, isNull);
    expect(c.callMoments, [(Neferhoo.mailLockAt, NeferhooCallKind.first)]);
    expect(f.isFaster, isTrue);
    expect(f.period, 10.5);
    expect((f.ankhLockAt, f.ankhThrowAt), (5.4, 6.8));
    expect(f.callMoments, [
      (.6, NeferhooCallKind.first),
      (5.9, NeferhooCallKind.wave),
      (9.6, NeferhooCallKind.second),
    ]);
    expect(
      [
        for (final s in [0, 1, 2]) Neferhoo.batsFor(s, faster: true),
      ],
      [2, 3, 4],
    );
    expect(
      [
        for (final s in [0, 1, 2]) Neferhoo.batsFor(s),
      ],
      [0, 2, 3],
    );
    expect(Neferhoo.returnDamageOf(faster: true), 18);
    expect(Neferhoo.returnDamageOf(), 25);
  });

  for (final px in [640.0, 792.0]) {
    test('${px.round()} px: what each stage latches, cycle by cycle', () {
      // the warm-up: the first call with its pair, the wave of two; no ankh
      // and no second call
      final warm = courier(px: px, stage: 0);
      fightTo(warm, 2 * 10.5 - .05);
      var f = warm.neferhoo;
      expect(
        [for (final c in f.calls) c.kind],
        [
          NeferhooCallKind.first,
          NeferhooCallKind.wave,
          NeferhooCallKind.first,
          NeferhooCallKind.wave,
        ],
      );
      expect(
        [for (final c in f.calls) c.lockedAt - warm.arrivalDuration],
        [
          for (final at in [.6, 5.9, 11.1, 16.4]) closeTo(at, 1e-9),
        ],
      );
      expect(f.ankhs, isEmpty);
      expect(f.letters.length, 6);
      expect(f.bats.length, 8);
      for (final c in f.calls) {
        final bats = f.bats.where((b) => b.call == c.number).toList();
        expect(bats.length, 2, reason: '${c.kind}');
        expect(bats.every((b) => b.lane == c.lane), isTrue);
        expect(
          f.letters.where((l) => l.call == c.number).length,
          c.wave ? 0 : 3,
        );
      }
      // the wave's bats fly in .3 and .8 s after its lock
      final wave = f.calls[1];
      expect(
        [
          for (final b in f.bats.where((b) => b.call == wave.number))
            b.launchAt - wave.lockedAt,
        ],
        [closeTo(.3, 1e-9), closeTo(.8, 1e-9)],
      );
      expect(f.waves, 2);
      expect(f.mailLocks, 2);

      // the full fight: the first call with a trio, the ankh, the second
      // call (letters alone); no wave
      final full = courier(px: px, stage: 1);
      fightTo(full, 2 * 10.5 - .05);
      f = full.neferhoo;
      expect(
        [for (final c in f.calls) c.kind],
        [
          NeferhooCallKind.first,
          NeferhooCallKind.second,
          NeferhooCallKind.first,
          NeferhooCallKind.second,
        ],
      );
      expect(
        [for (final c in f.calls) c.lockedAt - full.arrivalDuration],
        [
          for (final at in [.6, 9.6, 11.1, 20.1]) closeTo(at, 1e-9),
        ],
      );
      expect(
        [for (final a in f.ankhs) a.lockedAt - full.arrivalDuration],
        [closeTo(5.4, 1e-9), closeTo(15.9, 1e-9)],
      );
      for (final c in f.calls) {
        expect(
          f.bats.where((b) => b.call == c.number).length,
          c.kind == NeferhooCallKind.first ? 3 : 0,
        );
        expect(f.letters.where((l) => l.call == c.number).length, 3);
      }

      // fury: the express post in both calls, four bats, two ankhs
      final fury = courier(px: px, stage: 2);
      fightTo(fury, 10.5 - .05);
      f = fury.neferhoo;
      expect([for (final c in f.calls) c.express], [true, true]);
      expect(f.letters.length, 10);
      expect(f.bats.length, 4);
      expect(f.ankhs.length, 2);
    });
  }

  test('every lane locks on the bird, the second call\'s too', () {
    final boss = courier(px: 792, stage: 1);
    fightTo(boss, 9.5, birdY: .3);
    fightTo(boss, 9.7, birdY: .7);
    final second = boss.neferhoo.calls.last;
    expect(second.kind, NeferhooCallKind.second);
    expect(second.lane, closeTo(.7, .02));
    fightTo(boss, 11.2, birdY: .2);
    expect(boss.neferhoo.calls.last.lane, closeTo(.2, .02));
    // clamped like the classic call
    fightTo(boss, 20.0, birdY: .05);
    fightTo(boss, 20.2, birdY: .05);
    expect(boss.neferhoo.calls.last.lane, Neferhoo.laneTop);
  });

  test('a returned letter deals 18 at 55 and its line says so; 25 at 54', () {
    for (final (version, damage, line) in [
      (_faster, 18, Neferhoo.fasterReturnHint),
      (_before, 25, Neferhoo.returnHint),
    ]) {
      final boss = courier(px: 792, stage: 0, version: version);
      fightTo(boss, 2.2);
      final letter = boss.liveLetters.first;
      final hp = boss.hp;
      returnLetter(boss, letter);
      expect(boss.neferhooHint, line, reason: '$version');
      fightTo(boss, boss.combatTime + 1.2);
      expect(letter.landedAt, isNotNull);
      expect(hp - boss.hp, damage, reason: '$version');
    }
    expect(Neferhoo.fasterReturnHint, contains('−18'));
  });

  test('the warm-up\'s wave reads MUMMY BATS while its bats come', () {
    final boss = courier(px: 792, stage: 0);
    fightTo(boss, 6.5, birdY: .3);
    expect(boss.neferhoo.waves, 1);
    expect(boss.neferhooHint, Neferhoo.batsHint);
  });

  test('less stall: on the app\'s 2.2 sky the longest stretch with nothing '
      'crossing the bird\'s column drops in every stage', () {
    double longest(int version, int stage) {
      final boss = courier(px: 792, stage: stage, version: version);
      final start = boss.combatTime;
      fightTo(boss, start + 63);
      final f = boss.neferhoo;
      const bx = FlightSimulation.birdX;
      final a0 = boss.arrivalDuration, hand = boss.handX;
      final t = <double>[
        for (final l in f.letters) l.releaseAt + (hand - bx) / l.speed - a0,
        for (final b in f.bats)
          b.launchAt + (Neferhoo.batStartX(2.2) - bx) / b.pace - a0,
        for (final a in f.ankhs) ...[
          a.passes(handX: hand, turnX: Neferhoo.turnX(bx), column: bx).$1 - a0,
          a.passes(handX: hand, turnX: Neferhoo.turnX(bx), column: bx).$2 - a0,
        ],
      ]..sort();
      final w = t.where((x) => x > start + 12 && x < start + 60).toList();
      var most = 0.0;
      for (var i = 1; i < w.length; i++) {
        if (w[i] - w[i - 1] > most) most = w[i] - w[i - 1];
      }
      return most;
    }

    for (final (stage, before, now) in [
      (0, 11.0, 4.5),
      (1, 6.0, 3.2),
      (2, 5.5, 2.8),
    ]) {
      final then = longest(_before, stage), faster = longest(_faster, stage);
      // ignore: avoid_print
      print(
        'stage $stage: longest open sky ${then.toStringAsFixed(1)} s at '
        '54, ${faster.toStringAsFixed(1)} s at 55',
      );
      expect(then, greaterThan(before), reason: 'stage $stage at 54');
      expect(faster, lessThan(now), reason: 'stage $stage at 55');
    }
  });

  for (final px in [640.0, 792.0]) {
    test('${px.round()} px, a real fight: no mummy bat is still to pass the '
        'bird at any mail call\'s lock, and none is near its column while '
        'an ankh is', () {
      final sim = neferhooArena(width: px / 360, version: _faster);
      final boss = sim.boss!;
      final pilot = NeferhooPilot(family, seed: 3, careful: true);
      var calls = 0, locks = 0, ankhFrames = 0, batsSeen = 0;
      for (var i = 0; i < 60 * 300; i++) {
        if (boss.phase != BossPhase.attacking) break;
        if (sim.hearts < 2) sim.hearts = 3;
        pilot.plan(sim);
        final tap = pilot.flap(sim);
        if (pilot.shoot(sim)) sim.shoot();
        frame(sim, flap: tap, width: px / 360);
        final f = boss.neferhoo;
        final bats = sim.enemies.where(_isBat).toList();
        if (bats.isNotEmpty) batsSeen++;
        if (f.calls.length > calls) {
          calls = f.calls.length;
          if (!f.calls.last.wave) {
            locks++;
            for (final b in bats) {
              expect(
                b.x,
                lessThan(FlightSimulation.birdX - .1),
                reason:
                    'a bat ahead of the bird at a lock, '
                    'cycle ${boss.mailCycle.toStringAsFixed(2)}',
              );
            }
          }
        }
        for (final a in boss.liveAnkhs) {
          final at = a.at(
            boss.age,
            handX: boss.handX,
            turnX: Neferhoo.turnX(FlightSimulation.birdX),
          );
          if (at == null || (at.$1 - FlightSimulation.birdX).abs() > .5) {
            continue;
          }
          ankhFrames++;
          for (final b in bats) {
            expect(
              (b.x - FlightSimulation.birdX).abs(),
              greaterThan(.25),
              reason: 'a bat by the bird while the ankh passes',
            );
          }
        }
        if (sim.phase == RunPhase.ended) break;
      }
      expect(boss.defeatedAt, isNotNull);
      expect(locks, greaterThan(8));
      expect(ankhFrames, greaterThan(100));
      expect(batsSeen, greaterThan(100));
    });
  }
}
