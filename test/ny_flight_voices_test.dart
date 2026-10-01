import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/campaign.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/tracking.dart';
import 'package:push_up_bird/game/campaign_voice_clips.dart';
import 'package:push_up_bird/game/campaign_voices.dart';
import 'package:push_up_bird/game/flight_voices.dart';

import 'touch_combat_test.dart' show playing;

/// New York's guardians and the Alley Pigeon in the in-flight voices (rules
/// version 43): they have no recorded in-flight lines yet, so they stay
/// silent, never borrow another boss's or enemy's voice, and a pool with no
/// clips is tolerated (the story's guardian clips are pending, too).

/// A bank with every boss pool a flight asks for the five voiced bosses and
/// their bird, plus the bat spot: only the guardians' and the pigeon's are
/// missing (nothing else is voiced, so any line heard is a boss's or a spot).
FlightVoiceBank everythingButNewYork() {
  final pools = <String>[
    for (final bird in CampaignVoices.birds) ...[
      '$bird-spot-bat',
      '$bird-boss-again',
      '$bird-boss-mad',
      '$bird-retort',
      '$bird-boss-down',
      for (final boss in FlightVoices.voicedBosses) ...[
        '$bird-boss-${FlightVoices.bossKey(boss)}',
        '$bird-boss-down-${FlightVoices.bossKey(boss)}',
      ],
    ],
    for (final boss in FlightVoices.voicedBosses)
      for (final moment in const [
        'arrive',
        'taunt',
        'attack',
        'summon',
        'hurt',
        'gloat',
        'mad',
        'defeated',
        'card',
      ])
        '${FlightVoices.bossKey(boss)}-$moment',
  ];
  return FlightVoiceBank.of({
    for (final pool in pools) '$pool-01': 1000,
    for (final pool in pools) '$pool-02': 1000,
  });
}

FlightVoices voices({FlightVoiceBank? bank, CampaignLevel? level}) =>
    FlightVoices(
      talk: 1,
      bird: 0,
      mode: PlayMode.touch,
      level: level,
      retry: false,
      best: 0,
      bank: bank ?? everythingButNewYork(),
      random: Random(1),
    );

void main() {
  group('keys', () {
    test('every boss has its own clip key; the guardians never borrow one', () {
      final keys = {for (final b in BossKind.values) FlightVoices.bossKey(b)};
      expect(keys, hasLength(BossKind.values.length));
      expect(FlightVoices.bossKey(BossKind.kingCoo), 'coo');
      expect(FlightVoices.bossKey(BossKind.searchlightGargoyle), 'gargoyle');
      for (final guardian in [
        BossKind.kingCoo,
        BossKind.searchlightGargoyle,
      ]) {
        for (final voiced in FlightVoices.voicedBosses) {
          expect(
            FlightVoices.bossKey(guardian),
            isNot(FlightVoices.bossKey(voiced)),
          );
        }
      }
    });

    test('the voiced bosses are exactly the endless five', () {
      expect(FlightVoices.voicedBosses, {
        for (final kind in BossKind.values)
          if (!kind.campaignOnly) kind,
      });
    });

    test('a guardian card pool is empty until its take is recorded', () {
      // `before-3-2-6` and `before-3-4-4` are the cards' lines; they are
      // pending recording, so their pools hold no clip (and so no voice).
      for (final (kind, clip) in [
        (BossKind.kingCoo, 'before-3-2-6'),
        (BossKind.searchlightGargoyle, 'before-3-4-4'),
      ]) {
        final pool = FlightVoices.recorded['${FlightVoices.bossKey(kind)}-card'];
        expect(
          pool.map((c) => c.name),
          campaignVoiceClips.containsKey(clip) ? [clip] : isEmpty,
          reason: kind.name,
        );
      }
    });
  });

  group('guardians in flight', () {
    for (final (kind, id) in [
      (BossKind.kingCoo, '3-2'),
      (BossKind.searchlightGargoyle, '3-4'),
    ]) {
      for (final real in [false, true]) {
        test(
          '${kind.name} says nothing in flight '
          '(${real ? 'the real bank' : 'every other boss voiced'})',
          () {
            final sim = playing();
            final v = voices(
              bank: real ? FlightVoices.recorded : null,
              level: Campaign.level(id),
            );
            v.update(sim, mute: true);
            sim.boss = SkyBoss(
              number: kind.index + 1,
              x: 1.2,
              kind: kind,
              cinematic: true,
            );
            final said = <String>[];
            // Arrival, the fight, fury, taunt time, then the defeat.
            for (var step = 0; step < 120; step++) {
              sim.elapsed += .5;
              sim.boss!.age += .5;
              if (step == 40) sim.boss!.hp = sim.boss!.maxHp ~/ 2;
              if (step == 100) sim.boss!.defeatedAt = sim.boss!.age;
              final line = v.update(sim);
              if (line != null) said.add(line.clip.name);
            }
            expect(
              said.where(
                (name) =>
                    name.startsWith('${FlightVoices.bossKey(kind)}-') ||
                    name.contains('-boss-${FlightVoices.bossKey(kind)}'),
              ),
              isEmpty,
              reason: 'no guardian line',
            );
            for (final other in FlightVoices.voicedBosses) {
              expect(
                said.where(
                  (name) => name.startsWith('${FlightVoices.bossKey(other)}-'),
                ),
                isEmpty,
                reason: '${other.name} lends no voice',
              );
            }
            expect(v.speech?.boss, isNull);
          },
        );
      }
    }
  });

  group('the Alley Pigeon in flight', () {
    SkyEnemy enemy(EnemyKind kind) => SkyEnemy(
      x: .9,
      y: .5,
      appearance: kind.index,
      flightPhase: 0,
    );

    test('is not spotted aloud, and never as a bat', () {
      final sim = playing();
      final v = voices();
      v.update(sim, mute: true);
      sim.enemies.add(enemy(EnemyKind.alleyPigeon));
      for (var step = 0; step < 10; step++) {
        sim.elapsed += 1;
        expect(v.update(sim), isNull, reason: 'step $step');
      }
    });

    test('a bat beside it is spotted as usual', () {
      final sim = playing();
      final v = voices();
      v.update(sim, mute: true);
      sim.enemies
        ..add(enemy(EnemyKind.alleyPigeon))
        ..add(enemy(EnemyKind.caveBat));
      sim.elapsed += 1;
      expect(v.update(sim)?.clip.name, startsWith('pip-spot-bat'));
    });
  });
}
