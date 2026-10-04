import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/campaign.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/session_replay.dart';

import 'campaign_flight.dart' show levelFlight;
import 'neferhoo_art_support.dart';

/// Rules 61, the wilder Neferhoo. The owner found the faster one (rules 55)
/// too easy: "make it more challenging by ammo in unexpected directions and
/// sending more mummy bats in different directions". So in 2-6 at 61
/// ([SkyBoss.wilderNeferhoo]), on the faster clock:
///
/// - each call's letters fan out: one straight down the lane, the others
///   slanted up or down ([Neferhoo.slantOf]), bouncing off the sky's edges;
/// - more mummy bats: a trio, four, fury's five with a first call, a wave of
///   three in the warm-up, and a third of them dive in from above or climb
///   in from below the sky ([Neferhoo.batEntryOf]).
///
/// Everything at 55 to 60 flies as before.
const _wilder = FlightSimulation.wilderNeferhooRulesVersion;
const _before = FlightSimulation.upgradesRulesVersion;

void main() {
  test('61 comes after the upgrades\' 60, and only 2-6 meets the wilder '
      'Neferhoo', () {
    expect(_wilder, 61);
    expect(_wilder, greaterThan(_before));
    expect(FlightSimulation.currentRulesVersion, greaterThanOrEqualTo(_wilder));
    expect(ReplayTape.version, FlightSimulation.currentRulesVersion);
    expect(Campaign.level('2-6')!.plan.minRulesVersion, 50);
    for (final version in [52, 55, 60, 61]) {
      final sim = levelFlight(Campaign.level('2-6')!, version: version);
      expect(sim.supportsWilderNeferhoo, version >= 61, reason: '$version');
      expect(sim.supportsFasterNeferhoo, version >= 55, reason: '$version');
    }
    expect(courier(stage: 0).wilderNeferhoo, isTrue);
    expect(courier(stage: 0, version: _before).wilderNeferhoo, isFalse);
  });

  test('the slants: one straight, the rest each way, turning with the call',
      () {
    for (var call = 0; call < 6; call++) {
      for (final count in [3, 5]) {
        final slants = [
          for (var i = 0; i < count; i++) Neferhoo.slantOf(call, i, count),
        ];
        expect(slants.where((s) => s == 0).length, 1, reason: '$call $count');
        expect(
          slants.where((s) => s < 0).length,
          (count - 1) ~/ 2,
          reason: '$call $count',
        );
        expect(
          slants.where((s) => s > 0).length,
          (count - 1) ~/ 2,
          reason: '$call $count',
        );
      }
    }
    // Two calls in a row never deal the same pattern.
    for (var call = 0; call < 6; call++) {
      final a = [for (var i = 0; i < 3; i++) Neferhoo.slantOf(call, i, 3)];
      final b = [for (var i = 0; i < 3; i++) Neferhoo.slantOf(call + 1, i, 3)];
      expect(a, isNot(b), reason: '$call');
    }
  });

  test('a slanted letter is its spread off the lane at the bird\'s column',
      () {
    for (final handX in [1.13, 1.55, 1.85]) {
      for (final fury in [false, true]) {
        final speed = Neferhoo.letterSpeedOf(fury: fury, tougher: true);
        final letter = NeferhooLetter(
          cycle: 0,
          index: 1,
          lane: .5,
          releaseAt: 0,
          speed: speed,
          express: fury,
          climb: Neferhoo.letterClimb(
            slant: 1,
            speed: speed,
            handX: handX,
            fury: fury,
          ),
        );
        final atColumn = (handX - Neferhoo.birdColumn) / speed;
        expect(letter.xAt(atColumn, handX), closeTo(Neferhoo.birdColumn, 1e-9));
        expect(
          letter.yAt(atColumn) - .5,
          closeTo(fury ? Neferhoo.furySlantSpread : Neferhoo.slantSpread, 1e-9),
        );
        // Past the band a straight letter of the lane covers.
        expect(
          Neferhoo.slantSpread,
          greaterThan(Neferhoo.letterHalfHeight * 2),
        );
      }
    }
    expect(
      Neferhoo.letterClimb(slant: 0, speed: .6, handX: 1.5, fury: false),
      0,
    );
  });

  test('a slanted letter bounces off the sky\'s edges', () {
    expect(Neferhoo.bounce(.5), closeTo(.5, 1e-12));
    expect(Neferhoo.bounce(Neferhoo.bounceTop - .1), closeTo(.16, 1e-12));
    expect(Neferhoo.bounce(Neferhoo.bounceBottom + .1), closeTo(.84, 1e-12));
    for (var y = -3.0; y < 4; y += .013) {
      final b = Neferhoo.bounce(y);
      expect(b, inInclusiveRange(Neferhoo.bounceTop, Neferhoo.bounceBottom));
    }
    final straight = NeferhooLetter(
      cycle: 0,
      index: 0,
      lane: .37,
      releaseAt: 2,
      speed: .6,
      express: false,
    );
    expect(straight.yAt(5), .37);
  });

  test('more bats, some diving in', () {
    expect([for (final s in [0, 1, 2]) Neferhoo.wilderBatsFor(s)], [3, 4, 5]);
    for (final s in [0, 1, 2]) {
      expect(
        Neferhoo.wilderBatsFor(s),
        greaterThan(Neferhoo.batsFor(s, faster: true)),
      );
    }
    expect(Neferhoo.wilderWaveBats, greaterThan(Neferhoo.waveBats));
    for (var call = 0; call < 4; call++) {
      expect(
        {for (var i = 0; i < 3; i++) Neferhoo.batEntryOf(call, i)},
        {-1, 0, 1},
      );
    }
    final dive = Neferhoo.batDive(-1, .4, 2.2);
    expect(dive.yAt(Neferhoo.batStartX(2.2)), closeTo(-Neferhoo.diveOutside, 1e-12));
    expect(dive.yAt(Neferhoo.birdColumn), closeTo(.4, 1e-12));
    final rise = Neferhoo.batDive(1, .4, 2.2);
    expect(rise.yAt(Neferhoo.batStartX(2.2)), closeTo(1 + Neferhoo.diveOutside, 1e-12));
    expect(rise.yAt(Neferhoo.birdColumn), closeTo(.4, 1e-12));
  });

  for (final px in [640.0, 792.0]) {
    test('${px.round()} px: what the warm-up latches', () {
      final boss = courier(px: px, stage: 0);
      fightTo(boss, 10.5 - .05);
      final f = boss.neferhoo;
      expect([for (final c in f.calls) c.kind], [
        NeferhooCallKind.first,
        NeferhooCallKind.wave,
      ]);
      final first = f.calls.first.number;
      expect(f.letters.length, 3);
      expect(
        [for (final l in f.letters) l.climb.sign.toInt()],
        [for (var i = 0; i < 3; i++) Neferhoo.slantOf(first, i, 3)],
      );
      final bats = f.bats;
      expect(bats.where((b) => b.call == first).length, 3);
      expect(bats.where((b) => b.call != first).length, 3);
      for (final bat in bats) {
        expect(bat.entry, Neferhoo.batEntryOf(bat.call, bat.index));
        final enemy = bat.enemy!;
        expect(enemy.dive == null, bat.entry == 0);
      }
      expect(bats.map((b) => b.entry).toSet(), {-1, 0, 1});
    });

    test('${px.round()} px: the full fight and fury send more bats', () {
      for (final (stage, count, letters) in [(1, 4, 3), (2, 5, 5)]) {
        final boss = courier(px: px, stage: stage);
        fightTo(boss, 3);
        final f = boss.neferhoo;
        final first = f.calls.first;
        expect(first.kind, NeferhooCallKind.first);
        expect(first.letters, letters, reason: '$stage');
        expect(
          f.bats.where((b) => b.call == first.number).length,
          count,
          reason: '$stage',
        );
        expect(
          f.letters.where((l) => l.climb != 0).length,
          letters - 1,
          reason: '$stage',
        );
      }
    });
  }

  test('a diving bat reaches the lane as it reaches the bird\'s column', () {
    final boss = courier(px: 792, stage: 0);
    final sim = flightOf(boss);
    fightTo(boss, 3);
    final diving = boss.neferhoo.bats.firstWhere((b) => b.entry != 0);
    final enemy = diving.enemy!;
    // It flies in from beyond the sky's top or bottom edge.
    expect(enemy.dive!.fromY, anyOf(lessThan(0), greaterThan(1)));
    // Fly on (bird held well clear of every lane) until it reaches the
    // column.
    for (var t = 3.0; t < 9 && enemy.x > Neferhoo.birdColumn + .02; t += .05) {
      fightTo(boss, t, birdY: diving.lane > .5 ? .15 : .85);
      if (!sim.enemies.contains(enemy)) break;
    }
    expect(enemy.x, lessThan(Neferhoo.birdColumn + .1));
    expect(enemy.y, closeTo(diving.lane, .05));
  });

  test('a slanted letter hurts a bird that only dodged out of the lane', () {
    final boss = courier(px: 792, stage: 0);
    fightTo(boss, 1, birdY: .5);
    final f = boss.neferhoo;
    final call = f.calls.first;
    expect(call.lane, closeTo(.5, .02));
    final slanted = f.letters.firstWhere((l) => l.climb > 0);
    final atColumn =
        slanted.releaseAt +
        (boss.handX - Neferhoo.birdColumn) / slanted.speed;
    final dodge = slanted.yAt(atColumn);
    expect(dodge - call.lane, closeTo(Neferhoo.slantSpread, .01));
    fightTo(boss, 6, birdY: dodge);
    expect(slanted.delivered, isTrue);
    expect(f.letterHits, greaterThan(0));
  });

  test('a rock at a slanted letter\'s height sends it back', () {
    final boss = courier(px: 792, stage: 0);
    fightTo(boss, 2.3);
    final slanted = boss.neferhoo.letters.firstWhere(
      (l) => l.climb != 0 && l.dealtBy(boss.age),
    );
    returnLetter(boss, slanted);
    expect(slanted.returned, isTrue);
    expect(slanted.struckY, isNot(closeTo(slanted.lane, 1e-6)));
  });

  test('rules 60 flies 2-6 exactly as before: straight letters, bats down '
      'the lane', () {
    final boss = courier(px: 792, stage: 2, version: _before);
    fightTo(boss, 10);
    final f = boss.neferhoo;
    expect(f.letters, isNotEmpty);
    expect(f.letters.every((l) => l.climb == 0), isTrue);
    expect(f.bats.every((b) => b.entry == 0 && b.enemy?.dive == null), isTrue);
    expect(
      f.bats.where((b) => b.call == f.calls.first.number).length,
      Neferhoo.batsFor(2, faster: true),
    );
  });
}
