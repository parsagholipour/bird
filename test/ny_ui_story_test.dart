// The end card that closes the New York stop: the caption "To be continued…
// Next stop: Paris, the City of Light." that ends the Searchlight Gargoyle's
// last scene. The scene's own data is the story step's; `nyLastWord` stands
// in for it here, with the closing caption the design settles on. The card
// must play like any other line of a scene: whole in the panel's frame, at
// 15 px or more, nothing running under Reduced Motion, the keys and labels
// the campaign relies on.
@Timeout(Duration(minutes: 4))
library;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/campaign_story.dart';
import 'package:push_up_bird/ui/story_scene.dart';
import 'package:push_up_bird/ui/story_speech.dart';
import 'package:push_up_bird/ui/story_stage.dart';
import 'package:push_up_bird/ui/story_to_be_continued.dart';

import 'ny_ui_support.dart';

const _sizes = [Size(640, 360), Size(800, 360), Size(1000, 450)];
const _notch = EdgeInsets.fromLTRB(44, 0, 34, 21);
const _caption = 'To be continued… Next stop: Paris, the City of Light.';

Future<void> _play(
  WidgetTester tester,
  StoryScene scene,
  Size size, {
  bool reduced = true,
  EdgeInsets padding = EdgeInsets.zero,
  VoidCallback? onDone,
  bool voices = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MediaQuery(
        data: MediaQueryData(size: size, padding: padding),
        child: Scaffold(
          body: StoryScenePlayer(
            key: UniqueKey(),
            scene: scene,
            bird: 0,
            reducedMotion: reduced,
            voices: voices,
            onDone: onDone ?? () {},
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

Future<void> _toLast(WidgetTester tester, StoryScene scene) async {
  for (var i = 0; i < scene.lines.length - 1; i++) {
    await tester.tap(find.byKey(const ValueKey('story-advance')));
    await tester.pump();
  }
}

void main() {
  setUpAll(() async {
    for (final family in ['Fredoka', 'Nunito']) {
      await (FontLoader(
        family,
      )..addFont(rootBundle.load('assets/fonts/$family.ttf'))).load();
    }
  });

  group('which captions it is for', () {
    test('only a caption that begins "To be continued"', () {
      expect(ToBeContinued.matches(nyLastWord.lines.last), isTrue);
      expect(
        ToBeContinued.matches(const StoryLine.caption('TO BE CONTINUED...')),
        isTrue,
      );
      expect(
        ToBeContinued.matches(
          const StoryLine.caption('  To be continued… soon.'),
        ),
        isTrue,
      );
      // Not another caption, and not anybody's speech.
      expect(
        ToBeContinued.matches(
          const StoryLine.caption(
            'The Sky Club post. Sunrise. Your first day.',
          ),
        ),
        isFalse,
      );
      expect(
        ToBeContinued.matches(const StoryLine.caption('“Dear courier, …”')),
        isFalse,
      );
      expect(
        ToBeContinued.matches(const StoryLine.bill('To be continued… rookie.')),
        isFalse,
      );
      // None of the campaign's existing lines is one.
      for (final scene in CampaignStory.scenes) {
        for (final line in scene.lines) {
          expect(
            ToBeContinued.matches(line),
            line.speaker == StorySpeaker.caption &&
                line.text.toLowerCase().startsWith('to be continued'),
            reason: line.text,
          );
        }
      }
    });

    test('its head ends at the ellipsis', () {
      expect(
        _caption.substring(0, ToBeContinued.headEnd(_caption)),
        'To be continued…',
      );
      expect(
        'To be continued... Next stop: Rome'.substring(
          0,
          ToBeContinued.headEnd('To be continued... Next stop: Rome'),
        ),
        'To be continued...',
      );
      // With no punctuation it keeps the first three words.
      expect(
        'To be continued next time'.substring(
          0,
          ToBeContinued.headEnd('To be continued next time'),
        ),
        'To be continued',
      );
      expect(ToBeContinued.headEnd('To be'), 'To be'.length);
    });
  });

  group('the scene ends on the card', () {
    for (final (size, padding, name) in [
      for (final size in _sizes)
        (size, EdgeInsets.zero, '${size.width.round()}'),
      (_sizes.first, _notch, '640 with a notch'),
    ]) {
      testWidgets('whole in the panel\'s frame at $name', (tester) async {
        final k = StoryScenePlayer.scaleFor(size);
        final panel = StoryLayout(size / k, padding / k, lair: true).panel;
        await _play(tester, nyLastWord, size, padding: padding);
        // The lines before it are the speech panel's, not the card's.
        for (var i = 0; i < nyLastWord.lines.length - 1; i++) {
          expect(find.byType(ToBeContinued), findsNothing, reason: 'line $i');
          await tester.tap(find.byKey(const ValueKey('story-advance')));
          await tester.pump();
        }
        expect(find.byType(ToBeContinued), findsOneWidget);
        expect(tester.takeException(), isNull);
        // Whole, set at 15 px or more, in one text.
        final text = find.byKey(const ValueKey('story-line'));
        expect(find.text(_caption), findsOneWidget);
        final paragraph = tester.renderObject<RenderParagraph>(
          find.descendant(of: text, matching: find.byType(RichText)),
        );
        expect(paragraph.didExceedMaxLines, isFalse);
        expect(paragraph.text.style!.fontSize, greaterThanOrEqualTo(15));
        // The size is the speech panel's own for the line.
        final fitted = StorySpeech.fit(
          _caption,
          StoryVoice.place,
          StorySpeech.room(StoryVoice.place, panel.width),
        );
        expect(paragraph.text.style!.fontSize, fitted);
        // Every part of the line is set at 15 px or more.
        final sizes = <double>[];
        paragraph.text.visitChildren((span) {
          if (span is TextSpan && (span.text ?? '').isNotEmpty) {
            sizes.add(span.style!.fontSize!);
          }
          return true;
        });
        expect(sizes, isNotEmpty);
        expect(sizes.reduce((a, b) => a < b ? a : b), greaterThanOrEqualTo(15));
        // It fills the panel's frame exactly, and keeps inside its border.
        final speech = tester.getRect(
          find.byKey(const ValueKey('story-speech')),
        );
        expect(speech.size, Size(panel.width * k, panel.height * k));
        expect(speech.left, closeTo(panel.left * k, .5));
        expect(speech.top, closeTo(panel.top * k, .5));
        final words = tester.getRect(text);
        expect(
          speech.deflate(8 * k).contains(words.topLeft) &&
              speech.deflate(8 * k).contains(words.bottomRight),
          isTrue,
          reason: '$words in $speech',
        );
        // It is nobody's line: no speaker tag; Reduced Motion: the cue is up
        // and nothing is left running.
        expect(find.byKey(const ValueKey('story-speaker')), findsNothing);
        expect(find.byKey(const ValueKey('story-cue')), findsOneWidget);
        expect(tester.binding.transientCallbackCount, 0);
        expect(tester.binding.hasScheduledFrame, isFalse);
        // The skip key and the panel stay on screen, off the notch.
        final safe = padding.deflateRect(Offset.zero & size);
        expect(safe.contains(speech.topLeft), isTrue);
        expect(safe.contains(speech.bottomRight), isTrue);
        final skip = tester.getRect(find.byKey(const ValueKey('story-skip')));
        expect(safe.contains(skip.topLeft), isTrue);
        expect(safe.contains(skip.bottomRight), isTrue);
      });
    }

    testWidgets('the medallion sits inside the plate, left of the words', (
      tester,
    ) async {
      await _play(tester, nyLastWord, _sizes[1]);
      await _toLast(tester, nyLastWord);
      final speech = tester.getRect(find.byKey(const ValueKey('story-speech')));
      final words = tester.getRect(find.byKey(const ValueKey('story-line')));
      expect(words.left, greaterThan(speech.left + ToBeContinued.medallion));
    });

    testWidgets('the last tap finishes the scene, and Skip too', (
      tester,
    ) async {
      var done = 0;
      await _play(tester, nyLastWord, _sizes[1], onDone: () => done++);
      await _toLast(tester, nyLastWord);
      expect(done, 0);
      await tester.tap(find.byKey(const ValueKey('story-advance')));
      await tester.pump();
      expect(done, 1);
      await _play(tester, nyLastWord, _sizes[1], onDone: () => done++);
      await _toLast(tester, nyLastWord);
      await tester.tap(find.byKey(const ValueKey('story-skip')));
      await tester.pump();
      expect(done, 2);
    });

    testWidgets('it reads aloud as the line, and Finish is the last tap', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _play(tester, nyLastWord, _sizes[1]);
      await _toLast(tester, nyLastWord);
      expect(find.bySemanticsLabel(_caption), findsOneWidget);
      expect(find.bySemanticsLabel('Finish'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('with motion it writes the line out, head first, and the '
        'words never move', (tester) async {
      await _play(tester, nyLastWord, _sizes[1], reduced: false);
      for (var i = 0; i < nyLastWord.lines.length - 1; i++) {
        await tester.pump(const Duration(seconds: 4));
        await tester.tap(find.byKey(const ValueKey('story-advance')));
        await tester.pump(const Duration(milliseconds: 50));
      }
      final line = find.byKey(const ValueKey('story-line'));
      // The panel dips a touch as it arrives; the words are measured once it
      // has settled.
      await tester.pump(const Duration(milliseconds: 200));
      final start = tester.getRect(line);
      expect(find.byKey(const ValueKey('story-cue')), findsNothing);
      String shown() {
        final paragraph = tester.renderObject<RenderParagraph>(
          find.descendant(of: line, matching: find.byType(RichText)),
        );
        final out = StringBuffer();
        paragraph.text.visitChildren((span) {
          if (span is TextSpan &&
              (span.text ?? '').isNotEmpty &&
              span.style!.color != Colors.transparent) {
            out.write(span.text);
          }
          return true;
        });
        return out.toString();
      }

      await tester.pump(const Duration(milliseconds: 400));
      final early = shown();
      expect(early, isNotEmpty);
      expect(early.length, lessThan(_caption.length));
      expect(_caption.startsWith(early), isTrue);
      expect(tester.getRect(line), start);
      await tester.pump(const Duration(seconds: 3));
      expect(shown(), _caption);
      expect(tester.getRect(line), start);
      expect(find.byKey(const ValueKey('story-cue')), findsOneWidget);
    });

    testWidgets('a tap finishes the writing before it moves on', (
      tester,
    ) async {
      var done = 0;
      await _play(
        tester,
        nyLastWord,
        _sizes[1],
        reduced: false,
        onDone: () => done++,
      );
      for (var i = 0; i < nyLastWord.lines.length - 1; i++) {
        await tester.pump(const Duration(seconds: 4));
        await tester.tap(find.byKey(const ValueKey('story-advance')));
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(find.byKey(const ValueKey('story-cue')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('story-advance')));
      await tester.pump();
      expect(done, 0);
      expect(find.byKey(const ValueKey('story-cue')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('story-advance')));
      await tester.pump();
      expect(done, 1);
    });
  });

  testWidgets('a small phone (568 x 320) plays the end card whole', (
    tester,
  ) async {
    const small = Size(568, 320);
    await _play(tester, nyLastWord, small);
    await _toLast(tester, nyLastWord);
    expect(find.byType(ToBeContinued), findsOneWidget);
    expect(find.text(_caption), findsOneWidget);
    expect(tester.takeException(), isNull);
    final speech = tester.getRect(find.byKey(const ValueKey('story-speech')));
    final words = tester.getRect(find.byKey(const ValueKey('story-line')));
    expect(speech.contains(words.topLeft), isTrue);
    expect(speech.contains(words.bottomRight), isTrue);
  });

  testWidgets('a scene without the caption plays exactly as before', (
    tester,
  ) async {
    final scene = CampaignStory.scene('before-1-8')!;
    await _play(tester, scene, _sizes[1]);
    for (var i = 0; i < scene.lines.length; i++) {
      expect(find.byType(ToBeContinued), findsNothing);
      expect(find.byType(StorySpeech), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('story-advance')));
      await tester.pump();
    }
  });
}
