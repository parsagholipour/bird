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

/// The recorded clip names the story, the thank-you notes and the sprints
/// ask for.
Set<String> _wanted() => {
  for (final scene in CampaignStory.scenes)
    for (var i = 0; i < scene.lines.length; i++)
      for (var bird = 0; bird < CampaignVoices.birds.length; bird++)
        CampaignVoices.line(scene, i, bird: bird)!,
  for (final level in Campaign.levels) CampaignVoices.thanks(level)!,
  for (var bird = 0; bird < CampaignVoices.birds.length; bird++)
    ...CampaignVoices.sprints(bird),
};

void main() {
  test('every line, thank-you and sprint call has its recording', () {
    for (final scene in CampaignStory.scenes) {
      for (final (i, line) in scene.lines.indexed) {
        final takes = {
          for (var bird = 0; bird < 4; bird++)
            CampaignVoices.line(scene, i, bird: bird),
        };
        expect(takes, isNot(contains(null)), reason: '${scene.id} $i');
        // The courier is recorded once per bird; everyone else once.
        expect(
          takes,
          hasLength(line.speaker == StorySpeaker.courier ? 4 : 1),
          reason: '${scene.id} $i',
        );
      }
    }
    for (final level in Campaign.levels) {
      expect(CampaignVoices.thanks(level), isNotNull, reason: level.id);
    }
    for (var bird = 0; bird < 4; bird++) {
      expect(CampaignVoices.sprints(bird), hasLength(4));
    }
    // Nothing is recorded that the game never plays.
    final wanted = _wanted();
    expect(wanted, hasLength(campaignVoiceClips.length));
    expect({
      for (final name in campaignVoiceClips.keys) 'audio/story/$name.ogg',
    }, wanted);
  });

  test('each clip is a mono Ogg file of a believable length', () {
    final sources = jsonDecode(
      File('docs/story-voices-sources.json').readAsStringSync(),
    );
    final texts = {
      for (final clip in sources['clips'] as List)
        clip['name'] as String: clip['text'] as String,
    };
    expect(sources['model'], 'eleven_v4');
    expect(texts.keys.toSet(), campaignVoiceClips.keys.toSet());
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
    // The whole voice-over stays a modest part of the app.
    final total = Directory('assets/audio/story')
        .listSync()
        .whereType<File>()
        .fold<int>(0, (sum, file) => sum + file.lengthSync());
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
