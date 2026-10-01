import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/campaign.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/game/campaign_voices.dart';
import 'package:push_up_bird/game/flight_voice_clips.dart';
import 'package:push_up_bird/game/flight_voices.dart';

/// Every pool [FlightVoices] may ask a bird for, by moment.
Set<String> birdMoments() => {
  'takeoff', 'retry', 'knockout', 'delivered', 'last-heart', 'hit', //
  'hit-fire', 'hit-water', 'shield-pop', 'shield-back', 'heart-pickup',
  'streak', 'magnet', 'record', 'reps-pushup', 'reps-squat', 'reps-jump',
  'spot-bat', 'spot-beetle', 'spot-moth', 'enemy-down', 'incoming',
  'deflect', 'no-ammo', 'panel-break', 'sprint', 'rush-escaped', 'gale',
  'gale-over', 'final-stretch', 'stars-two', 'stars-three', 'retort',
  'idle', 'boss-again', 'boss-mad', 'dragon-fire', 'screech', 'tide-bell',
  'cannon', 'moth-shield', 'boss-down',
  for (final level in Campaign.levels) 'cargo-${level.id}',
  for (final kind in RushPathKind.values) ...[
    'rush-${kind.name}',
    'rush-first-${kind.name}',
  ],
  for (final region in WorldRegion.values)
    'region-${FlightVoices.regionKey(region)}',
  for (final boss in BossKind.values) ...[
    'boss-${FlightVoices.bossKey(boss)}',
    'boss-down-${FlightVoices.bossKey(boss)}',
  ],
};

/// Every pool [FlightVoices] may ask [boss] for, by moment. The campaign's
/// `card` comes from the story recordings.
Set<String> bossMoments(BossKind boss) => {
  'arrive', 'taunt', 'attack', 'summon', 'hurt', 'gloat', 'mad', //
  'defeated',
  if (boss == BossKind.pirate) 'tide',
};

void main() {
  final sources =
      jsonDecode(File('docs/flight-voices-sources.json').readAsStringSync())
          as Map<String, dynamic>;
  final clips = (sources['clips'] as List).cast<Map<String, dynamic>>();

  test('the script and the game ask for the same pools', () {
    final written = {for (final c in clips) '${c['speaker']}-${c['moment']}'};
    final asked = {
      for (final bird in CampaignVoices.birds)
        for (final moment in birdMoments()) '$bird-$moment',
      for (final boss in BossKind.values)
        for (final moment in bossMoments(boss))
          '${FlightVoices.bossKey(boss)}-$moment',
    };
    expect(written.difference(asked), isEmpty, reason: 'never played');
    expect(asked.difference(written), isEmpty, reason: 'never written');
  });

  test('every line is its speaker\'s own, in its voice', () {
    final voices = <String, String>{};
    final texts = <String>{};
    for (final clip in clips) {
      final speaker = clip['speaker'] as String;
      expect(
        voices.putIfAbsent(speaker, () => clip['voice_id'] as String),
        clip['voice_id'],
        reason: clip['name'] as String,
      );
      final text = (clip['text'] as String).toLowerCase();
      expect(texts.add(text), isTrue, reason: 'repeated: ${clip['name']}');
      final prompt = (clip['prompt'] as String)
          .replaceAll(RegExp(r'\[[^\]]*\]'), ' ')
          .split(RegExp(r'\s+'))
          .where((w) => w.isNotEmpty)
          .join(' ');
      expect(prompt, (clip['text'] as String).split(' ').join(' '));
    }
    expect(voices, hasLength(9));
    expect(voices.values.toSet(), hasLength(9), reason: 'nine voices');
  });

  test('every recorded line is in the script, bundled and short', () {
    final names = {for (final c in clips) c['name'] as String};
    expect(names.containsAll(flightVoiceClips.keys), isTrue);
    for (final MapEntry(key: name, value: ms) in flightVoiceClips.entries) {
      expect(
        File('assets/audio/flight/$name.ogg').existsSync(),
        isTrue,
        reason: name,
      );
      expect(ms, inInclusiveRange(250, 8500), reason: name);
      final clip = clips.firstWhere((c) => c['name'] == name);
      expect(clip['generation_id'], isNotNull, reason: name);
    }
    final bundled = Directory('assets/audio/flight').existsSync()
        ? Directory('assets/audio/flight').listSync().length
        : 0;
    expect(bundled, flightVoiceClips.length);
  });
}
