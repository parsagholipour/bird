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
  for (final boss in _scripted) ...[
    'boss-${FlightVoices.bossKey(boss)}',
    'boss-down-${FlightVoices.bossKey(boss)}',
  ],
};

/// The bosses whose lines the script holds: the recorded ones and those
/// written but still pending recording.
final _scripted = {...FlightVoices.voicedBosses, ...FlightVoices.pendingBosses};

/// A line is recorded once it has a take's generation; until then it is
/// pending (`tool/prepare_flight_voices.py pending` lists it).
bool _recorded(Map<String, dynamic> clip) => clip['generation_id'] != null;

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
      for (final boss in _scripted)
        for (final moment in bossMoments(boss))
          '${FlightVoices.bossKey(boss)}-$moment',
    };
    expect(written.difference(asked), isEmpty, reason: 'never played');
    expect(asked.difference(written), isEmpty, reason: 'never written');
  });

  test('every line is its speaker\'s own, in its voice', () {
    final voices = <String, String?>{};
    final texts = <String>{};
    for (final clip in clips) {
      final speaker = clip['speaker'] as String;
      expect(
        voices.putIfAbsent(speaker, () => clip['voice_id'] as String?),
        clip['voice_id'],
        reason: clip['name'] as String,
      );
      // A voice still to audition has no id, and no line in it is recorded.
      if (clip['voice_id'] == null) {
        expect(
          clip['voice'],
          endsWith('(audition)'),
          reason: '${clip['name']}',
        );
        expect(_recorded(clip), isFalse, reason: '${clip['name']}');
      }
      final text = (clip['text'] as String).toLowerCase();
      expect(texts.add(text), isTrue, reason: 'repeated: ${clip['name']}');
      final prompt = (clip['prompt'] as String)
          .replaceAll(RegExp(r'\[[^\]]*\]'), ' ')
          .split(RegExp(r'\s+'))
          .where((w) => w.isNotEmpty)
          .join(' ');
      expect(prompt, (clip['text'] as String).split(' ').join(' '));
    }
    // Four birds, the five endless bosses, and Neferhoo in his chosen voice.
    expect(voices, hasLength(10));
    expect(voices.values.nonNulls.toSet(), hasLength(10), reason: 'ten voices');
    expect(voices['neferhoo'], 'Kz0DA4tCctbPjLay2QT1');
  });

  test('all flight lines are recorded, including the Egyptian guardian', () {
    final pending = {
      for (final c in clips)
        if (!_recorded(c)) c['name'] as String,
    };
    // His 16 lines and each bird's greetings, farewell and cargo are recorded.
    final egypt = RegExp(
      r'^(neferhoo-|\w+-boss-(down-)?neferhoo-|\w+-cargo-2-6-)',
    );
    expect(pending, isEmpty);
    // A boss is voiced once every line of it is recorded, and pending
    // until then: never both, never neither while the script has it.
    expect(
      FlightVoices.voicedBosses.intersection(FlightVoices.pendingBosses),
      isEmpty,
    );
    for (final boss in _scripted) {
      final key = FlightVoices.bossKey(boss);
      final lines = [
        for (final c in clips)
          if (c['speaker'] == key ||
              RegExp('-boss-(down-)?$key-').hasMatch(c['name'] as String))
            c,
      ];
      expect(lines, isNotEmpty, reason: key);
      expect(
        FlightVoices.voicedBosses.contains(boss),
        lines.every(_recorded),
        reason: key,
      );
      expect(
        FlightVoices.pendingBosses.contains(boss),
        lines.any((c) => !_recorded(c)),
        reason: key,
      );
    }
    // The recording document lists each of them with its exact prompt
    // (docs/story-voices-recording.md, section 7).
    final doc = File('docs/story-voices-recording.md').readAsStringSync();
    final listed = doc.substring(doc.indexOf('## 7. Neferhoo'));
    for (final clip in clips.where(
      (c) => egypt.hasMatch(c['name'] as String),
    )) {
      final name = clip['name'] as String;
      expect(listed, contains('| `$name` |'), reason: name);
      expect(listed, contains('| ${clip['prompt']} |'), reason: name);
    }
    expect(RegExp(r'^\| `', multiLine: true).allMatches(listed), hasLength(32));
    for (final moment in bossMoments(BossKind.neferhoo)) {
      expect(
        FlightVoices.recorded['neferhoo-$moment'],
        hasLength(2),
        reason: moment,
      );
    }
    expect(FlightVoices.recorded['neferhoo-card'].map((c) => c.name), [
      'before-2-6-7',
    ]);
    for (final bird in CampaignVoices.birds) {
      for (final MapEntry(key: moment, value: count) in const {
        'boss-neferhoo': 2,
        'boss-down-neferhoo': 1,
        'cargo-2-6': 1,
      }.entries) {
        expect(FlightVoices.recorded['$bird-$moment'], hasLength(count));
      }
    }
  });

  test('the tool checks the script and lists the pending lines', () async {
    ProcessResult? run;
    try {
      run = await Process.run('python3', [
        '-c',
        'import sys, json; sys.path.insert(0, "tool"); '
            'import prepare_flight_voices as f; '
            'lines = json.load(open("docs/flight-voices-sources.json"))["clips"]; '
            'problems = f.check(lines); print("\\n".join(problems)); '
            'sys.exit(1 if problems else 0)',
      ]);
    } on ProcessException {
      return markTestSkipped('python3 is not installed');
    }
    expect(run.exitCode, 0, reason: '${run.stdout}${run.stderr}');
    final pending = await Process.run('python3', [
      'tool/prepare_flight_voices.py',
      'pending',
    ]);
    expect(pending.exitCode, 0, reason: '${pending.stderr}');
    expect(
      (pending.stdout as String).split('\n').where((n) => n.isNotEmpty).toSet(),
      {
        for (final c in clips)
          if (!_recorded(c)) c['name'] as String,
      },
    );
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
