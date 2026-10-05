import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/campaign.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/tracking.dart';
import 'package:push_up_bird/game/campaign_voices.dart';
import 'package:push_up_bird/game/flight_voices.dart';

import 'touch_combat_test.dart' show playing;

/// Neferhoo in the in-flight voices (Egypt's guardian, rules 50). His lines
/// are recorded in Herbie's voice (docs/flight-voices-sources.json).
/// The director knows his fight:
/// his attack is the mail call (as a lane locks), his summon is the ankh
/// (thrown), and he cries out when one of his own letters lands home, never
/// for a rock on his padded wraps.

/// A bank with his own pools only (no taunt, so quiet moments stay quiet),
/// two clips each: any line heard is one of his.
FlightVoiceBank _his() => FlightVoiceBank.of({
  for (final moment in const [
    'arrive',
    'card',
    'attack',
    'summon',
    'hurt',
    'gloat',
    'mad',
    'defeated',
  ])
    for (final n in const ['01', '02']) 'neferhoo-$moment-$n': 800,
});

FlightVoices _voices(FlightVoiceBank bank) => FlightVoices(
  // Every chance rolled in, every cooldown short: what is said follows from
  // what happens alone.
  talk: 10,
  bird: 0,
  mode: PlayMode.touch,
  level: Campaign.level('2-6'),
  bank: bank,
  random: Random(3),
);

void main() {
  late FlightSimulation sim;
  late FlightVoices v;
  late SkyBoss boss;

  /// Seconds of flight, as the director hears them; the lines said.
  List<String> fly(double seconds) {
    final said = <String>[];
    for (var t = 0.0; t < seconds; t += .25) {
      sim.elapsed += .25;
      boss.age += .25;
      final line = v.update(sim);
      if (line != null) said.add(line.clip.name);
    }
    return said;
  }

  void meet(FlightVoiceBank bank) {
    sim = playing();
    v = _voices(bank);
    v.update(sim, mute: true);
    boss = sim.boss = SkyBoss(
      number: 1,
      x: 1.2,
      kind: BossKind.neferhoo,
      cinematic: true,
    );
  }

  String pool(String clip) => FlightVoiceBank.poolOf(clip);

  test('his fight speaks each moment in his own pools', () {
    meet(_his());
    // He arrives with his card line (or an arrival line).
    final arrival = fly(boss.arrivalDuration + 2);
    expect(arrival.map(pool), isNotEmpty);
    expect(arrival.map(pool).toSet(), {'neferhoo-card'});
    expect(boss.phase, BossPhase.attacking);
    expect(fly(3), isEmpty, reason: 'nothing happens, nothing is said');

    // MAIL CALL: the lane locks.
    boss.neferhoo.mailLocks += 1;
    expect(fly(2).map(pool), ['neferhoo-attack']);
    // The ankh, thrown (twice in fury: one line).
    boss.neferhoo.ankhThrows += 1;
    expect(fly(2).map(pool), ['neferhoo-summon']);
    // A rock on his wraps (his hit clock moves, no letter came home):
    // nothing.
    boss.lastHitAt = boss.age;
    boss.neferhoo.wrapScuffs += 1;
    expect(fly(2), isEmpty);
    // One of his letters lands home.
    boss.neferhoo.returnsLanded += 1;
    expect(fly(2).map(pool), ['neferhoo-hurt']);
    // The fury stage.
    boss.hp = boss.maxHp ~/ 4;
    expect(boss.enraged, isTrue);
    expect(fly(2).map(pool), ['neferhoo-mad']);
    // The bird is hit while he fights: he gloats.
    sim.hearts -= 1;
    expect(fly(2).map(pool), contains('neferhoo-gloat'));
    // Down.
    boss.defeatedAt = boss.age;
    expect(fly(2).map(pool), ['neferhoo-defeated']);
  });

  test('a stretch of counters that do not move says nothing again', () {
    meet(_his());
    fly(boss.arrivalDuration + 2);
    boss.neferhoo
      ..mailLocks = 3
      ..ankhThrows = 2
      ..returnsLanded = 1;
    final burst = fly(1);
    expect(burst, isNotEmpty);
    // Nothing new happens: nothing more is said.
    expect(fly(6), isEmpty);
  });

  test('with the real bank he and the bird speak in their own voices', () {
    meet(FlightVoices.recorded);
    final said = <String>[
      ...fly(boss.arrivalDuration + 2),
      for (var cycle = 0; cycle < 6; cycle++)
        ...() {
          boss.neferhoo
            ..mailLocks += 1
            ..ankhThrows += 1
            ..returnsLanded += 1;
          if (cycle == 4) boss.hp = boss.maxHp ~/ 4;
          return fly(4);
        }(),
    ];
    boss.defeatedAt = boss.age;
    said.addAll(fly(4));
    final key = FlightVoices.bossKey(BossKind.neferhoo);
    // The first-try cargo can occupy the arrival, so check the fight's
    // recorded calls rather than requiring its card to win that slot.
    expect(
      said.map(pool),
      containsAll([
        'neferhoo-attack',
        'neferhoo-summon',
        'neferhoo-mad',
        'neferhoo-defeated',
      ]),
    );
    expect(said.where((n) => n.startsWith('$key-')), isNotEmpty);
    expect(said, contains('pip-cargo-2-6-01'));
    for (final other in FlightVoices.voicedBosses) {
      if (other == BossKind.neferhoo) continue;
      expect(
        said.where((n) => n.startsWith('${FlightVoices.bossKey(other)}-')),
        isEmpty,
        reason: '${other.name} lends no voice',
      );
    }
    expect(FlightVoices.recorded['$key-card'].map((c) => c.name), [
      'before-2-6-7',
    ]);
    for (final bird in CampaignVoices.birds) {
      expect(FlightVoices.recorded['$bird-boss-$key'], hasLength(2));
      expect(FlightVoices.recorded['$bird-boss-down-$key'], hasLength(1));
      expect(FlightVoices.recorded['$bird-cargo-2-6'], hasLength(1));
    }
  });

  test('his key and recorded pools are his own', () {
    expect(FlightVoices.bossKey(BossKind.neferhoo), 'neferhoo');
    expect(FlightVoices.voicedBosses, contains(BossKind.neferhoo));
    expect(FlightVoices.pendingBosses, isEmpty);
  });
}
