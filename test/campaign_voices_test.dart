import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/campaign.dart';
import 'package:push_up_bird/domain/campaign_story.dart';
import 'package:push_up_bird/game/campaign_voice_clips.dart';
import 'package:push_up_bird/game/campaign_voices.dart';
import 'package:push_up_bird/ui/story_scene.dart';
import 'package:push_up_bird/ui/theme.dart';
import 'package:push_up_bird/ui/ui_sounds.dart';

/// What a clip's sources entry says while its take has not been recorded.
const _pending = 'pending recording';

/// Every clip the game asks for, with the words it prints for it.
Map<String, String> _printed() => {
  for (final scene in CampaignStory.scenes)
    for (var i = 0; i < scene.lines.length; i++)
      for (final name in CampaignVoices.lineNames(scene, i))
        name: scene.lines[i].text,
  for (final level in Campaign.levels)
    CampaignVoices.thanksName(level): level.delivery.thanks,
};

/// The words a prompt makes the voice say: the audio tags ([chuckles],
/// [whispers]…) are directions, not words. A word pinned in IPA between
/// slashes (`/læmps/`) stands for the one printed word it pronounces.
List<String> _spokenWords(String prompt) => _words(
  prompt
      .replaceAll(RegExp(r'\[[^\]]*\]'), ' ')
      .replaceAllMapped(RegExp(r'/[^/\s]+/'), (_) => ' § '),
);

List<String> _printedWords(String text) => _words(text);

/// Lower-case words without punctuation, quotes or ellipses. A stretched
/// word ("Wheeee") counts as the same word however long it is stretched.
List<String> _words(String text) => [
  for (final m in RegExp(
    r"[\p{L}\p{N}’']+|§",
    unicode: true,
  ).allMatches(text.toLowerCase()))
    m[0]!
        .replaceAll(RegExp(r"[’']"), '')
        .replaceAllMapped(RegExp(r'(.)\1{2,}'), (x) => x[1]! * 2),
];

bool _sameWords(List<String> spoken, List<String> printed) {
  if (spoken.length != printed.length) return false;
  for (var i = 0; i < spoken.length; i++) {
    if (spoken[i] != '§' && spoken[i] != printed[i]) return false;
  }
  return true;
}

/// What is wrong with the sources file, the table of recorded clips and the
/// game's own lines, as sentences; empty when they agree.
///
/// A clip is **recorded** (no status: it has a voice, a generation and the
/// hash of its take, and is in [recorded]) or **pending recording** (every
/// one of those empty, and not in [recorded]). Pending is not a fault, but
/// anything in between is: a recorded clip that the table lacks or that says
/// other words than the game prints, or a clip in the table that the sources
/// still call pending. Every line, pending or not, must say the words the
/// game prints.
List<String> _voiceProblems({
  required List<Map<String, Object?>> clips,
  required Map<String, int> recorded,
  required Set<String> wanted,
  required Map<String, String> printed,
}) {
  final problems = <String>[];
  final names = <String>{};
  bool filled(Object? value) => value is String && value.isNotEmpty;
  for (final clip in clips) {
    final name = clip['name'] as String;
    final text = clip['text'] as String, prompt = clip['prompt'] as String;
    if (!names.add(name)) problems.add('$name: listed twice');
    if (!wanted.contains(name)) {
      problems.add('$name: the game never asks for this clip');
    }
    if (printed.containsKey(name) && printed[name] != text) {
      problems.add(
        '$name: text differs from the printed line "${printed[name]}"',
      );
    }
    if (!_sameWords(_spokenWords(prompt), _printedWords(text))) {
      problems.add('$name: the prompt speaks other words than its text');
    }
    final status = clip['status'];
    if (status != null && status != _pending) {
      problems.add('$name: unknown status "$status"');
    } else if (status == _pending) {
      for (final field in ['voice_id', 'generation_id', 'source_sha256']) {
        if (clip[field] != null) {
          problems.add('$name: pending recording, yet $field is filled in');
        }
      }
      if (recorded.containsKey(name)) {
        problems.add(
          '$name: is in the clip table but still says "$_pending"; fill in '
          'its entry and delete the status',
        );
      }
    } else {
      if (!filled(clip['voice_id']) || !filled(clip['voice'])) {
        problems.add('$name: recorded without a voice');
      }
      if (!filled(clip['generation_id'])) {
        problems.add('$name: recorded without a generation id');
      }
      final hash = clip['source_sha256'];
      if (hash is! String || !RegExp(r'^[0-9a-f]{64}$').hasMatch(hash)) {
        problems.add('$name: recorded without the hash of its take');
      }
      if (!recorded.containsKey(name)) {
        problems.add(
          '$name: recorded, but not in the clip table '
          '(run tool/prepare_story_voices.py)',
        );
      }
    }
  }
  for (final name in wanted.difference(names)) {
    problems.add('$name: the game asks for it, the sources file has no entry');
  }
  for (final name in recorded.keys.where((name) => !names.contains(name))) {
    problems.add('$name: in the clip table, not in the sources file');
  }
  return problems;
}

Map<String, Object?> _sources() =>
    jsonDecode(File('docs/story-voices-sources.json').readAsStringSync())
        as Map<String, Object?>;

List<Map<String, Object?>> _clips(Map<String, Object?> sources) => [
  for (final clip in sources['clips'] as List)
    Map<String, Object?>.of(clip as Map<String, Object?>),
];

List<String> _problemsOf(
  List<Map<String, Object?>> clips, {
  Map<String, int>? recorded,
  Map<String, String>? printed,
  Set<String>? wanted,
}) => _voiceProblems(
  clips: clips,
  recorded: recorded ?? campaignVoiceClips,
  wanted: wanted ?? CampaignVoices.wanted,
  printed: printed ?? _printed(),
);

void main() {
  test('every line, thank-you and sprint call is recorded or pending', () {
    for (final scene in CampaignStory.scenes) {
      for (final (i, line) in scene.lines.indexed) {
        // The courier is recorded once per bird; everyone else once.
        final names = CampaignVoices.lineNames(scene, i);
        expect(
          names,
          hasLength(line.speaker == StorySpeaker.courier ? 4 : 1),
          reason: '${scene.id} $i',
        );
        // What the game plays is exactly what is recorded: a pending line
        // gives null and stays silent, a recorded one its asset.
        for (var bird = 0; bird < 4; bird++) {
          final name = CampaignVoices.lineName(scene, i, bird: bird);
          expect(names, contains(name));
          expect(
            CampaignVoices.line(scene, i, bird: bird),
            campaignVoiceClips.containsKey(name)
                ? 'audio/story/$name.ogg'
                : isNull,
            reason: name,
          );
        }
      }
    }
    for (final level in Campaign.levels) {
      expect(
        CampaignVoices.thanks(level) == null,
        !campaignVoiceClips.containsKey(CampaignVoices.thanksName(level)),
        reason: level.id,
      );
    }
    for (var bird = 0; bird < 4; bird++) {
      expect(
        CampaignVoices.sprints(bird),
        hasLength(
          CampaignVoices.sprintNames(
            bird,
          ).where(campaignVoiceClips.containsKey).length,
        ),
      );
    }
  });

  test('the sources, the recordings and the story agree', () {
    final sources = _sources();
    expect(sources['model'], 'eleven_v4');
    expect(_problemsOf(_clips(sources)), isEmpty);
    // Every line and thank-you the game prints has a sources entry that says
    // the same words, and every recorded clip is one of them.
    final printed = _printed();
    final named = {for (final clip in _clips(sources)) clip['name'] as String};
    expect(named.containsAll(printed.keys), isTrue);
  });

  test('a clip that is recorded but does not match fails the check', () {
    final real = _clips(_sources());
    int at(String name) => real.indexWhere((c) => c['name'] == name);
    List<Map<String, Object?>> changed(
      String name,
      void Function(Map<String, Object?> clip) edit,
    ) => [
      for (final clip in real)
        if (clip['name'] == name)
          () {
            final copy = Map<String, Object?>.of(clip);
            edit(copy);
            return copy;
          }()
        else
          clip,
    ];
    void flagged(List<String> problems, String name, Pattern what) {
      expect(
        problems.where((p) => p.startsWith('$name:') && p.contains(what)),
        isNotEmpty,
        reason: '$name / $what in $problems',
      );
    }

    final pending = real.firstWhere((c) => c['status'] == _pending);
    final pendingName = pending['name'] as String;
    const recordedName = 'before-1-1-1';
    expect(at(recordedName), greaterThanOrEqualTo(0));

    // A recording without its table entry.
    flagged(
      _problemsOf(
        real,
        recorded: {...campaignVoiceClips}..remove(recordedName),
      ),
      recordedName,
      'not in the clip table',
    );
    // A table entry the sources still call pending.
    flagged(
      _problemsOf(real, recorded: {...campaignVoiceClips, pendingName: 1500}),
      pendingName,
      'still says',
    );
    // A table entry nothing in the sources explains.
    expect(
      _problemsOf(real, recorded: {...campaignVoiceClips, 'before-9-9-0': 900}),
      contains(startsWith('before-9-9-0: in the clip table')),
    );
    // Recorded, but its text or its words drifted from the printed line.
    flagged(
      _problemsOf(changed(recordedName, (c) => c['text'] = 'Hello there!')),
      recordedName,
      'differs from the printed line',
    );
    flagged(
      _problemsOf(
        changed(
          recordedName,
          (c) =>
              c['prompt'] = (c['prompt'] as String).replaceAll('Bill', 'Bob'),
        ),
      ),
      recordedName,
      'other words',
    );
    // A recorded clip with nothing to show for it.
    for (final field in ['voice_id', 'generation_id', 'source_sha256']) {
      expect(
        _problemsOf(changed(recordedName, (c) => c[field] = null)),
        isNotEmpty,
        reason: field,
      );
    }
    // A pending clip with half a recording, or one that claims to be
    // recorded when the table has no audio for it.
    flagged(
      _problemsOf(changed(pendingName, (c) => c['voice_id'] = 'abc')),
      pendingName,
      'voice_id is filled in',
    );
    flagged(
      _problemsOf(changed(pendingName, (c) => c.remove('status'))),
      pendingName,
      'recorded',
    );
    flagged(
      _problemsOf(changed(pendingName, (c) => c['status'] = 'recorded')),
      pendingName,
      'unknown status',
    );
    // A pending line must still say the words the game prints.
    flagged(
      _problemsOf(changed(pendingName, (c) => c['text'] = 'Something else.')),
      pendingName,
      'differs from the printed line',
    );
    // A line the game asks for with no entry, and an entry no line asks for.
    expect(
      _problemsOf([...real]..removeAt(at(pendingName))),
      contains(startsWith('$pendingName: the game asks for it')),
    );
    expect(
      _problemsOf(real, wanted: CampaignVoices.wanted..remove(recordedName)),
      contains(startsWith('$recordedName: the game never asks')),
    );
  });

  test('spoken words are the printed words, whatever the direction', () {
    bool same(String prompt, String text) =>
        _sameWords(_spokenWords(prompt), _printedWords(text));
    expect(
      same('[chuckles] Hello, rookie! [sighs] Fly.', 'Hello, rookie! Fly.'),
      isTrue,
    );
    // Curly quotes, ellipses and stretched words are not other words.
    expect(same('[softly] You’re… late.', 'You’re late.'), isTrue);
    expect(same('[excited] Wheeeee!', 'Wheeee!'), isTrue);
    // A word pinned in IPA stands for the printed word.
    expect(
      same(
        '[whispers] Shh. You will wake the /læmps/.',
        'Shh. You will wake the lamps.',
      ),
      isTrue,
    );
    expect(
      same(
        '[whispers] Shh. You will wake the /læmps/.',
        'Shh. You will wake the lamps now.',
      ),
      isFalse,
    );
    // Other words, or a word more or less, are caught.
    expect(same('[angrily] Hold still!', 'Hold on!'), isFalse);
    expect(same('Hold still!', 'Hold still, darling!'), isFalse);
    expect(same('[pause] Hold [pause] still!', 'Hold still!'), isTrue);
  });

  test('a pending clip has no audio and plays nothing', () {
    final pending = {
      for (final clip in _clips(_sources()))
        if (clip['status'] == _pending) clip['name'] as String,
    };
    // The New York guardians' four scenes were written before they were
    // recorded: 47 clips (6 courier lines in each bird's voice, 23 more),
    // pending until their takes are in. Recording one moves it out of the
    // pending set, never out of the sources file.
    final guardianClips = {
      for (final clip in _clips(_sources()))
        if (RegExp('^(before|last)-3-[24]-').hasMatch(clip['name'] as String))
          clip['name'] as String,
    };
    expect(guardianClips, hasLength(47));
    // Egypt's guardian (rules 50): Neferhoo's two scenes and the pyramid
    // caretaker's thank-you on 2-6 are written and pending until the owner
    // has picked his voice (the renamed Arabian clips stay recorded): 31
    // clips (18 lines, the courier's 4 in each bird's voice, and the note).
    final egyptClips = {
      for (final clip in _clips(_sources()))
        if (RegExp(
          r'^((before|last)-2-6-|thanks-2-6$)',
        ).hasMatch(clip['name'] as String))
          clip['name'] as String,
    };
    expect(egyptClips, hasLength(31));
    expect(egyptClips.difference(pending), isEmpty);
    // His 8 wait for the audition (the placeholder voice, no id yet); the
    // rest are in voices the cast already has.
    final egyptVoices = {
      for (final clip in _clips(_sources()))
        if (egyptClips.contains(clip['name']))
          clip['name'] as String: clip['voice'] as String,
    };
    expect(
      egyptVoices.values.where((v) => v == 'Neferhoo (audition)'),
      hasLength(8),
    );
    for (final clip in _clips(_sources())) {
      if (!egyptClips.contains(clip['name'])) continue;
      expect(
        clip['planned_voice_id'] == null,
        clip['voice'] == 'Neferhoo (audition)',
        reason: '${clip['name']}',
      );
    }
    // The tolerance is for these clips only: a pending mark on any other
    // clip (a recorded chapter 1 to 3 line, `before-3-5`, `before-3-8`,
    // `after-3`, a thank-you or a sprint call) is a fault, so a missing clip
    // anywhere else still fails the suite.
    expect(
      pending.difference(guardianClips).difference(egyptClips),
      isEmpty,
      reason: 'only the guardians\' clips may be pending recording',
    );
    for (final name in pending) {
      expect(campaignVoiceClips, isNot(contains(name)), reason: name);
      expect(
        File('assets/audio/story/$name.ogg').existsSync(),
        isFalse,
        reason: name,
      );
      expect(CampaignVoices.length('audio/story/$name.ogg'), isNull);
    }
    for (final scene in CampaignStory.scenes) {
      for (var i = 0; i < scene.lines.length; i++) {
        for (var bird = 0; bird < 4; bird++) {
          final name = CampaignVoices.lineName(scene, i, bird: bird);
          if (pending.contains(name)) {
            expect(
              CampaignVoices.line(scene, i, bird: bird),
              isNull,
              reason: name,
            );
          }
        }
      }
    }
  });

  group('tool/prepare_story_voices.py', () {
    // The tool needs Python 3 to run; without it there is nothing to check.
    Future<ProcessResult?> python(List<String> args, {String? cwd}) async {
      try {
        return await Process.run(
          'python3',
          args,
          workingDirectory: cwd,
          stdoutEncoding: utf8,
        );
      } on ProcessException {
        return null;
      }
    }

    final pending = [
      for (final clip in _clips(_sources()))
        if (clip['status'] == _pending) clip['name'] as String,
    ];

    test('--status and --checklist list exactly the pending clips', () async {
      final status = await python(['tool/prepare_story_voices.py', '--status']);
      if (status == null) return markTestSkipped('python3 is not installed');
      expect(status.exitCode, 0, reason: '${status.stderr}');
      expect(
        status.stdout,
        contains('Pending recording: ${pending.length} clips'),
      );
      final checklist = await python([
        'tool/prepare_story_voices.py',
        '--checklist',
        '-',
      ]);
      expect(checklist!.exitCode, 0, reason: '${checklist.stderr}');
      final out = checklist.stdout as String;
      expect(
        RegExp(r'^- \[ \] ', multiLine: true).allMatches(out),
        hasLength(pending.length),
      );
      final byName = {
        for (final clip in _clips(_sources())) clip['name'] as String: clip,
      };
      for (final name in pending) {
        expect(status.stdout, contains(name));
        expect(out, contains('`$name`'), reason: name);
        // The prompt is printed exactly, ready to paste.
        expect(out, contains(byName[name]!['prompt'] as String), reason: name);
        expect(out, contains('build/story-voices/source/$name.mp3'));
      }
    });

    test('the recording document is as fresh as the sources file', () async {
      final doc = File('docs/story-voices-recording.md').readAsStringSync();
      const begin = '<!-- checklist:begin', end = '<!-- checklist:end -->';
      final a = doc.indexOf('\n', doc.indexOf(begin)) + 1, b = doc.indexOf(end);
      expect(a, greaterThan(0));
      expect(b, greaterThan(a));
      final printed = await python([
        'tool/prepare_story_voices.py',
        '--checklist',
        '-',
      ]);
      if (printed == null) return markTestSkipped('python3 is not installed');
      // Regenerate with `python3 tool/prepare_story_voices.py --checklist`
      // after any change to a line, a prompt, a voice or a recording.
      expect(
        doc.substring(a, b).trim(),
        (printed.stdout as String).trim(),
        reason: 'run: python3 tool/prepare_story_voices.py --checklist',
      );
      // The hand-written parts of the document name the audition lines and
      // every audio tag that no recorded take has used.
      final byName = {
        for (final clip in _clips(_sources())) clip['name'] as String: clip,
      };
      for (final name in [
        'before-3-2-0',
        'before-3-2-4',
        'last-3-2-6',
        'before-3-4-1',
        'before-3-4-3',
        'last-3-4-2',
      ]) {
        expect(doc, contains(byName[name]!['prompt'] as String), reason: name);
      }
      // Neferhoo's five auditions are made: the document says where, with
      // the line they say and how to put the chosen voice on his clips.
      expect(
        doc,
        contains(
          '[haughtily] Neferhoo, Royal Courier. [clears throat] Four thousand '
          'years on this route. [shouting] Return to sender!',
        ),
      );
      expect(doc, contains('egypt-int/auditions/'));
      expect(doc, contains("'neferhoo': (None, 'Neferhoo (audition)')"));
      final tagged = RegExp(r'\[([^\]]+)\]');
      final proven = {
        for (final clip in byName.values)
          if (clip['status'] != _pending)
            for (final m in tagged.allMatches(clip['prompt'] as String))
              m[1]!.toLowerCase(),
      };
      final unproven = {
        for (final clip in byName.values)
          if (clip['status'] == _pending)
            for (final m in tagged.allMatches(clip['prompt'] as String))
              if (!proven.contains(m[1]!.toLowerCase())) m[1]!.toLowerCase(),
      };
      final tags = await python(['tool/prepare_story_voices.py', '--tags']);
      for (final tag in unproven) {
        expect(doc, contains('`[$tag]`'), reason: 'stand-in for [$tag]');
        expect(tags!.stdout, contains('[$tag]'), reason: tag);
      }
    });

    test('--checklist rewrites only what is between its markers', () async {
      if (pending.isEmpty) return markTestSkipped('nothing is pending');
      final root = Directory.systemTemp.createTempSync('story_voices_');
      addTearDown(() => root.deleteSync(recursive: true));
      for (final path in [
        'tool/prepare_story_voices.py',
        'docs/story-voices-sources.json',
        'lib/game/campaign_voice_clips.dart',
        'docs/story-voices-recording.md',
      ]) {
        File('${root.path}/$path')
          ..createSync(recursive: true)
          ..writeAsBytesSync(File(path).readAsBytesSync());
      }
      final doc = File('${root.path}/docs/story-voices-recording.md');
      const begin = '<!-- checklist:begin', end = '<!-- checklist:end -->';
      final original = doc.readAsStringSync();
      final head = original.substring(
        0,
        original.indexOf('\n', original.indexOf(begin)) + 1,
      );
      final tail = original.substring(original.indexOf(end));
      // Wreck the generated part and add a hand-written note around it.
      doc.writeAsStringSync('$head\nSTALE\n$tail\nMY NOTE\n');
      final run = await python([
        '${root.path}/tool/prepare_story_voices.py',
        '--checklist',
      ]);
      if (run == null) return markTestSkipped('python3 is not installed');
      expect(run.exitCode, 0, reason: '${run.stdout}${run.stderr}');
      final after = doc.readAsStringSync();
      expect(after, startsWith(head));
      expect(after, contains('MY NOTE'));
      expect(after, isNot(contains('STALE')));
      expect(
        RegExp(r'^- \[ \] ', multiLine: true).allMatches(after),
        hasLength(pending.length),
      );
      expect(after, '$original\nMY NOTE\n');
      // Without the markers it refuses, and changes nothing.
      doc.writeAsStringSync('no markers here\n');
      final refused = await python([
        '${root.path}/tool/prepare_story_voices.py',
        '--checklist',
      ]);
      expect(refused!.exitCode, isNot(0));
      expect(doc.readAsStringSync(), 'no markers here\n');
    });

    test('--status on a clone without the takes says so once', () async {
      if (Directory('build/story-voices/source').existsSync()) {
        return markTestSkipped('the takes are here');
      }
      final status = await python(['tool/prepare_story_voices.py', '--status']);
      if (status == null) return markTestSkipped('python3 is not installed');
      final lines = (status.stdout as String).split('\n');
      expect(lines.where((l) => l.contains('is missing from')), isEmpty);
      expect(
        lines.where((l) => l.contains('recorded takes are missing from')),
        hasLength(1),
      );
    });

    test('mastering skips pending clips without failing', () async {
      if (pending.isEmpty) return markTestSkipped('nothing is pending');
      // A copy of the tool's tree, so nothing in the project is rewritten.
      final root = Directory.systemTemp.createTempSync('story_voices_');
      addTearDown(() => root.deleteSync(recursive: true));
      for (final path in [
        'tool/prepare_story_voices.py',
        'docs/story-voices-sources.json',
        'lib/game/campaign_voice_clips.dart',
      ]) {
        File('${root.path}/$path')
          ..createSync(recursive: true)
          ..writeAsBytesSync(File(path).readAsBytesSync());
      }
      // Naming only a pending clip leaves every recorded clip as it is (no
      // FFmpeg, no takes needed) and must not fail for the pending ones.
      final run = await python([
        '${root.path}/tool/prepare_story_voices.py',
        '--only',
        pending.first,
      ]);
      if (run == null) return markTestSkipped('python3 is not installed');
      expect(run.exitCode, 0, reason: '${run.stdout}${run.stderr}');
      expect(
        run.stdout,
        contains('${pending.length} clips pending recording, skipped'),
      );
      // The table is what it was: no pending clip crept in, no recorded one left.
      expect(
        File(
          '${root.path}/lib/game/campaign_voice_clips.dart',
        ).readAsStringSync(),
        File('lib/game/campaign_voice_clips.dart').readAsStringSync(),
      );
      // A name that is not in the sources file is an error, not a skip.
      final unknown = await python([
        '${root.path}/tool/prepare_story_voices.py',
        '--only',
        'before-9-9-9',
      ]);
      expect(unknown!.exitCode, isNot(0));
    });
  });

  test('each clip is a mono Ogg file of a believable length', () {
    final sources = _sources();
    final texts = {
      for (final clip in sources['clips'] as List)
        clip['name'] as String: clip['text'] as String,
    };
    expect(texts.keys.toSet().containsAll(campaignVoiceClips.keys), isTrue);
    for (final MapEntry(key: name, value: ms) in campaignVoiceClips.entries) {
      final file = File('assets/audio/story/$name.ogg');
      final bytes = file.readAsBytesSync();
      expect(String.fromCharCodes(bytes.take(4)), 'OggS', reason: name);
      // The length the game paces a line by is the file's.
      expect(bytes.length, greaterThan(ms * 3), reason: name);
      expect(bytes.length, lessThan(ms * 16), reason: name);
      // Spoken at a pace a player can follow: neither rushed nor dragging.
      final perLetter = ms / texts[name]!.length;
      expect(perLetter, inInclusiveRange(25, 240), reason: '$name $perLetter');
      expect(ms, inInclusiveRange(500, 9000), reason: name);
    }
    // Nothing sits in the folder that the table does not know.
    final files = Directory(
      'assets/audio/story',
    ).listSync().whereType<File>().toList();
    expect(
      {for (final file in files) file.uri.pathSegments.last},
      {for (final name in campaignVoiceClips.keys) '$name.ogg'},
    );
    // The whole voice-over stays a modest part of the app.
    final total = files.fold<int>(0, (sum, file) => sum + file.lengthSync());
    expect(total, lessThan(12 * 1024 * 1024));
  });

  group('a scene speaks', () {
    Future<(List<String>, List<int>)> play(
      WidgetTester tester,
      StoryScene scene, {
      required bool voices,
      int bird = 0,
      bool reduced = true,
    }) async {
      final said = <String>[], hushed = <int>[0];
      tester.view.physicalSize = const Size(800, 360);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var done = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: skyTheme(),
          home: UiSounds(
            play: (_) {},
            speak: said.add,
            hush: () => hushed[0]++,
            child: StatefulBuilder(
              builder: (context, setState) => done
                  ? const SizedBox()
                  : StoryScenePlayer(
                      scene: scene,
                      bird: bird,
                      voices: voices,
                      reducedMotion: reduced,
                      onDone: () => setState(() => done = true),
                    ),
            ),
          ),
        ),
      );
      await tester.pump();
      return (said, hushed);
    }

    testWidgets('each line in its speaker\'s voice, the courier as the '
        'equipped bird, and silence when the scene ends', (tester) async {
      final scene = CampaignStory.prologue;
      final (said, hushed) = await play(tester, scene, voices: true, bird: 2);
      for (var i = 1; i < scene.lines.length; i++) {
        await tester.tap(find.byKey(const ValueKey('story-advance')));
        await tester.pump();
      }
      expect(said, [
        for (var i = 0; i < scene.lines.length; i++)
          CampaignVoices.line(scene, i, bird: 2)!,
      ]);
      expect(said[2], 'audio/story/before-1-1-2-minty.ogg');
      expect(hushed[0], 0);
      await tester.tap(find.byKey(const ValueKey('story-advance')));
      await tester.pump();
      expect(find.byType(StoryScenePlayer), findsNothing);
      expect(hushed[0], 1);
    });

    testWidgets('Skip cuts the line short', (tester) async {
      final (said, hushed) = await play(
        tester,
        CampaignStory.after(Campaign.chapters.first),
        voices: true,
      );
      expect(said, ['audio/story/after-1-0.ogg']);
      await tester.tap(find.byKey(const ValueKey('story-skip')));
      await tester.pump();
      expect(hushed[0], 1);
    });

    testWidgets('with voices off it says nothing', (tester) async {
      final (said, hushed) = await play(
        tester,
        CampaignStory.prologue,
        voices: false,
      );
      await tester.tap(find.byKey(const ValueKey('story-skip')));
      await tester.pump();
      expect(said, isEmpty);
      expect(hushed[0], 0);
    });

    testWidgets('a line with no recording is silent and is written out at '
        'the pace of voices off', (tester) async {
      const text = 'Nobody has recorded this line yet, but you can read it.';
      const scene = StoryScene(
        id: 'test-pending',
        lines: [
          StoryLine.bill(text),
          StoryLine.courier('Then I shall read it aloud myself.'),
        ],
      );
      // Nothing is recorded under these names, as for a pending clip.
      for (final name in CampaignVoices.lineNames(scene, 1)) {
        expect(campaignVoiceClips, isNot(contains(name)));
      }
      expect(CampaignVoices.line(scene, 0, bird: 0), isNull);
      final paced = (text.length * 26).clamp(260, 1700);
      final cue = find.byKey(const ValueKey('story-cue'));
      for (final voices in [true, false]) {
        final (said, _) = await play(
          tester,
          scene,
          voices: voices,
          reduced: false,
        );
        await tester.pump(Duration(milliseconds: (paced * .9).round()));
        expect(cue, findsNothing, reason: 'voices: $voices');
        await tester.pump(Duration(milliseconds: (paced * .2).round()));
        expect(cue, findsOneWidget, reason: 'voices: $voices');
        // The next line is the courier's: silent in every bird's voice.
        await tester.tap(find.byKey(const ValueKey('story-advance')));
        await tester.pump();
        expect(find.textContaining('read it aloud'), findsWidgets);
        expect(said, isEmpty, reason: 'voices: $voices');
        await tester.tap(find.byKey(const ValueKey('story-skip')));
        await tester.pump(const Duration(seconds: 1));
      }
    });

    testWidgets('the guardians\' scenes play in full, each line with only '
        'the voice that has been recorded', (tester) async {
      for (final id in [
        'before-2-6',
        'last-2-6',
        'before-3-2',
        'last-3-2',
        'before-3-4',
        'last-3-4',
      ]) {
        final scene = CampaignStory.scene(id)!;
        final (said, _) = await play(tester, scene, voices: true, bird: 1);
        for (var i = 1; i < scene.lines.length; i++) {
          // Every line is on the page while it is being said.
          expect(find.text(scene.lines[i - 1].text), findsWidgets, reason: id);
          await tester.tap(find.byKey(const ValueKey('story-advance')));
          await tester.pump();
        }
        expect(find.text(scene.lines.last.text), findsWidgets, reason: id);
        expect(find.byType(StoryScenePlayer), findsOneWidget, reason: id);
        await tester.tap(find.byKey(const ValueKey('story-advance')));
        await tester.pump();
        expect(find.byType(StoryScenePlayer), findsNothing, reason: id);
        expect(said, [
          for (var i = 0; i < scene.lines.length; i++)
            ?CampaignVoices.line(scene, i, bird: 1),
        ], reason: id);
      }
    });

    testWidgets('Neferhoo\'s scenes, unrecorded, are written out at the '
        'pace of voices off with voices on', (tester) async {
      final cue = find.byKey(const ValueKey('story-cue'));
      for (final id in ['before-2-6', 'last-2-6']) {
        final scene = CampaignStory.scene(id)!;
        final text = scene.lines.first.text;
        expect(CampaignVoices.line(scene, 0, bird: 0), isNull, reason: id);
        final paced = (text.length * 26).clamp(260, 1700);
        final (said, _) = await play(
          tester,
          scene,
          voices: true,
          reduced: false,
        );
        await tester.pump(Duration(milliseconds: (paced * .9).round()));
        expect(cue, findsNothing, reason: id);
        await tester.pump(Duration(milliseconds: (paced * .2).round()));
        expect(cue, findsOneWidget, reason: id);
        expect(said, isEmpty, reason: id);
        await tester.tap(find.byKey(const ValueKey('story-skip')));
        await tester.pump(const Duration(seconds: 1));
      }
    });

    testWidgets('a spoken line is written out just ahead of its voice', (
      tester,
    ) async {
      final scene = CampaignStory.prologue;
      final line = CampaignVoices.line(scene, 0, bird: 0)!;
      final length = CampaignVoices.length(line)!;
      await play(tester, scene, voices: true, reduced: false);
      final cue = find.byKey(const ValueKey('story-cue'));
      await tester.pump(length * .8);
      expect(cue, findsNothing);
      await tester.pump(length * .15);
      expect(cue, findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('story-skip')));
      await tester.pump(const Duration(seconds: 1));
    });
  });
}
