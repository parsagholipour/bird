// Polish checks and captures for the story scenes. The checks always run:
// every line of every scene shows whole in its panel at the three phone
// sizes and with a notch, at 15 px or more, with nothing overflowing;
// Reduced Motion leaves nothing running; and the keys and labels the
// campaign relies on are there.
//
// The captures are a cast sheet (Postmaster Bill, the four couriers and the
// five bosses in every mood, before and after their defeat), every scene's
// most telling line, the prologue, a lair and a boss's last word at the
// three sizes, the captions, the longest lines, a line being written and a
// change of speaker frame by frame, Reduced Motion, a notch, and each bird
// as the courier.
//
// Run with `--dart-define=CAPTURE_POLISH=true` to write PNGs to
// build/visual-review/campaign/polish/story/.
@Timeout(Duration(minutes: 10))
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/campaign_story.dart';
import 'package:push_up_bird/domain/sky_boss.dart';
import 'package:push_up_bird/ui/story_cast_art.dart';
import 'package:push_up_bird/ui/story_scene.dart';
import 'package:push_up_bird/ui/story_speech.dart';
import 'package:push_up_bird/ui/story_stage.dart';
import 'package:push_up_bird/ui/theme.dart';

const _capture = bool.fromEnvironment('CAPTURE_POLISH');
const _folder = 'build/visual-review/campaign/polish/story';

const _sizes = [Size(640, 360), Size(800, 360), Size(1000, 450)];

/// A phone held with its camera notch on the left and the home bar below.
const _notch = EdgeInsets.fromLTRB(44, 0, 34, 21);

StoryScene _scene(String id) => CampaignStory.scene(id)!;

/// A story scene over a stand-in for the map, at [size].
Future<void> _play(
  WidgetTester tester,
  StoryScene scene,
  Size size, {
  int bird = 0,
  bool reduced = true,
  EdgeInsets padding = EdgeInsets.zero,
  VoidCallback? onDone,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: skyTheme(),
      home: MediaQuery(
        data: MediaQueryData(size: size, padding: padding),
        child: RepaintBoundary(
          key: const ValueKey('polish-capture'),
          child: Scaffold(
            backgroundColor: SkyColors.sky,
            body: StoryScenePlayer(
              key: ValueKey('${scene.id}-$size-$bird-$reduced-$padding'),
              scene: scene,
              bird: bird,
              reducedMotion: reduced,
              onDone: onDone ?? () {},
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

Future<void> _next(WidgetTester tester, [int lines = 1]) async {
  for (var i = 0; i < lines; i++) {
    await tester.tap(find.byKey(const ValueKey('story-advance')));
    await tester.pump();
  }
}

Future<void> _save(WidgetTester tester, String name, {double ratio = 1}) async {
  if (!_capture) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('polish-capture')),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: ratio);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('$_folder/$name.png');
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

/// The line of [scene] that shows it best: a boss's fury at a lair, its
/// change of heart after, and otherwise the first line with a feeling.
int _telling(StoryScene scene) {
  final lines = scene.lines;
  int first(bool Function(StoryLine line) test) => lines.indexWhere(test);
  final boss = scene.bossBeaten
      ? first((l) => l.speaker == StorySpeaker.boss)
      : first(
          (l) => l.speaker == StorySpeaker.boss && l.mood == StoryMood.angry,
        );
  if (boss >= 0) return boss;
  final felt = first(
    (l) => l.speaker != StorySpeaker.caption && l.mood != StoryMood.plain,
  );
  return felt >= 0 ? felt : 0;
}

/// A sheet of [rows] of the cast, one column per mood, at twice life size.
Future<void> _sheet(
  String name,
  List<(String, StoryActor, double)> rows,
  Color ground, {
  int mouth = 0,
  bool blink = false,
}) async {
  const cell = Size(330, 300), k = 2.0;
  final w = cell.width * 5, h = cell.height * rows.length;
  final recorder = ui.PictureRecorder();
  final c = Canvas(recorder);
  c.scale(k);
  c.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = ground);
  for (final (r, (label, actor, dx)) in rows.indexed) {
    for (final mood in StoryMood.values) {
      c.save();
      c.translate(mood.index * cell.width, r * cell.height);
      c.clipRect(Offset.zero & cell);
      // The speech panel's top edge, which the cast stands on.
      c.drawRect(
        Rect.fromLTWH(0, 262, cell.width, 38),
        Paint()..color = SkyColors.cream,
      );
      c.drawLine(
        const Offset(0, 262),
        Offset(cell.width, 262),
        Paint()
          ..color = SkyColors.ink
          ..strokeWidth = 3,
      );
      final caption = TextPainter(
        text: TextSpan(
          text: '$label · ${mood.name}',
          style: bodyText(11, weight: FontWeight.w800),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      caption.paint(c, const Offset(8, 280));
      c.translate(cell.width / 2 + dx, 262);
      actor.paint(c, (mood: mood, mouth: mouth, blink: blink));
      c.restore();
    }
  }
  final image = await recorder.endRecording().toImage(
    (w * k).round(),
    (h * k).round(),
  );
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  File('$_folder/$name.png')
    ..parent.createSync(recursive: true)
    ..writeAsBytesSync(bytes!.buffer.asUint8List());
  image.dispose();
}

void main() {
  setUpAll(() async {
    for (final family in ['Fredoka', 'Nunito']) {
      await (FontLoader(
        family,
      )..addFont(rootBundle.load('assets/fonts/$family.ttf'))).load();
    }
  });

  group('every line', () {
    for (final (size, padding, name) in [
      for (final size in _sizes)
        (size, EdgeInsets.zero, '${size.width.round()} wide'),
      (_sizes.first, _notch, '640 wide with a notch'),
    ]) {
      testWidgets('shows whole in its panel at $name', (tester) async {
        final k = StoryScenePlayer.scaleFor(size);
        for (final scene in CampaignStory.scenes) {
          await _play(tester, scene, size, padding: padding);
          final panel = StoryLayout(
            size / k,
            padding / k,
            lair: scene.boss != null,
          ).panel;
          for (final (i, line) in scene.lines.indexed) {
            final where = '${scene.id} line $i at $name';
            expect(tester.takeException(), isNull, reason: where);
            final text = find.byKey(const ValueKey('story-line'));
            expect(find.text(line.text), findsOneWidget, reason: where);
            // Set at 15 px or more even before the stage grows.
            final paragraph = tester.renderObject<RenderParagraph>(
              find.descendant(of: text, matching: find.byType(RichText)),
            );
            final voice = StoryVoice.of(
              StoryScenePlayer.speakerName(scene, line, 0),
              line.text,
            );
            final fitted = StorySpeech.fit(
              line.text,
              voice,
              StorySpeech.room(voice, panel.width),
            );
            expect(fitted, isNotNull, reason: '$where runs past two rows');
            expect(
              paragraph.text.style!.fontSize,
              allOf(fitted, greaterThanOrEqualTo(15)),
              reason: where,
            );
            expect(paragraph.didExceedMaxLines, isFalse, reason: where);
            // Every row of it lies inside the panel, clear of its border.
            final speech = tester.getRect(
              find.byKey(const ValueKey('story-speech')),
            );
            final words = tester.getRect(text);
            expect(
              speech.deflate(8 * k).contains(words.topLeft) &&
                  speech.deflate(8 * k).contains(words.bottomRight),
              isTrue,
              reason: '$where: $words in $speech',
            );
            // The panel and the Skip key stay on the screen, clear of the
            // notch.
            final safe = padding.deflateRect(Offset.zero & size);
            expect(safe.contains(speech.topLeft), isTrue, reason: where);
            expect(safe.contains(speech.bottomRight), isTrue, reason: where);
            final skip = tester.getRect(
              find.byKey(const ValueKey('story-skip')),
            );
            expect(safe.contains(skip.topLeft), isTrue, reason: where);
            expect(safe.contains(skip.bottomRight), isTrue, reason: where);
            expect(skip.height, greaterThanOrEqualTo(48), reason: where);
            // Its speaker is named, once, on a tag that stays on the panel.
            final speaker = StoryScenePlayer.speakerName(scene, line, 0);
            if (speaker != null) {
              expect(find.text(speaker), findsOneWidget, reason: where);
              final tag = tester.getRect(find.text(speaker));
              expect(tag.left, greaterThan(speech.left), reason: where);
              expect(tag.right, lessThan(speech.right), reason: where);
            } else {
              expect(
                find.byKey(const ValueKey('story-speaker')),
                findsNothing,
                reason: where,
              );
            }
            // Reduced Motion: the line is whole at once, its cue is up and
            // nothing is left running.
            expect(
              find.byKey(const ValueKey('story-cue')),
              findsOneWidget,
              reason: where,
            );
            expect(tester.binding.transientCallbackCount, 0, reason: where);
            expect(tester.binding.hasScheduledFrame, isFalse, reason: where);
            await _next(tester);
          }
          expect(tester.takeException(), isNull, reason: scene.id);
        }
      });
    }
  });

  group('contract', () {
    testWidgets('the keys, labels and taps the campaign relies on', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      var done = 0;
      final scene = _scene('before-1-8');
      await _play(tester, scene, _sizes[1], bird: 2, onDone: () => done++);
      expect(find.byKey(const ValueKey('story-advance')), findsOneWidget);
      expect(find.byKey(const ValueKey('story-skip')), findsOneWidget);
      expect(find.byKey(const ValueKey('story-line')), findsOneWidget);
      expect(find.byKey(const ValueKey('story-cue')), findsOneWidget);
      expect(
        find.bySemanticsLabel('Baron Bat: ${scene.lines[0].text}'),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('Next line'), findsOneWidget);
      expect(find.bySemanticsLabel('Skip'), findsOneWidget);
      // The courier speaks under the equipped bird's name.
      await _next(tester);
      expect(find.text('Minty'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Minty: ${scene.lines[1].text}'),
        findsOneWidget,
      );
      // Enter and Space move on like a tap; the last line finishes.
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(find.text(scene.lines[2].text), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(find.text(scene.lines[3].text), findsOneWidget);
      await _next(tester, 2);
      expect(find.bySemanticsLabel('Finish'), findsOneWidget);
      expect(done, 0);
      await _next(tester);
      expect(done, 1);
      // Skip ends it from anywhere.
      await tester.tap(find.byKey(const ValueKey('story-skip')));
      expect(done, 2);
      // A caption is read without a name.
      await _play(tester, CampaignStory.prologue, _sizes[1]);
      expect(
        find.bySemanticsLabel(CampaignStory.prologue.lines[0].text),
        findsOneWidget,
      );
      semantics.dispose();
    });

    testWidgets('with motion a line writes out, the cue follows, and the '
        'scene is readable within 0.4 s', (tester) async {
      final scene = _scene('before-1-4');
      await _play(tester, scene, _sizes[1], reduced: false);
      final cue = find.byKey(const ValueKey('story-cue'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(cue, findsNothing);
      // The panel has settled and words are on it.
      final line = tester.widget<Text>(
        find.byKey(const ValueKey('story-line')),
      );
      final spans = (line.textSpan! as TextSpan).children!.cast<TextSpan>();
      expect(spans.first.text!.length, greaterThan(8));
      expect(spans.first.text! + spans.last.text!, scene.lines[0].text);
      final speech = find.byKey(const ValueKey('story-speech'));
      final at = tester.getRect(speech);
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.getRect(speech), at);
      // Left alone it finishes; idle life goes on, and stops with the scene.
      await tester.pump(const Duration(seconds: 3));
      expect(cue, findsOneWidget);
      expect(tester.binding.transientCallbackCount, greaterThan(0));
      await tester.pumpWidget(const SizedBox());
      expect(tester.binding.transientCallbackCount, 0);
    });

    testWidgets('animations turned off system-wide hold it still too', (
      tester,
    ) async {
      tester.view.physicalSize = _sizes[1];
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: skyTheme(),
          home: MediaQuery(
            data: MediaQueryData(size: _sizes[1], disableAnimations: true),
            child: Scaffold(
              body: StoryScenePlayer(
                scene: _scene('after-5'),
                bird: 1,
                onDone: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byKey(const ValueKey('story-cue')), findsOneWidget);
      expect(tester.binding.transientCallbackCount, 0);
      await _next(tester, 3);
      expect(find.byKey(const ValueKey('story-cue')), findsOneWidget);
      expect(tester.binding.transientCallbackCount, 0);
      expect(tester.takeException(), isNull);
    });

    test('every actor keeps to a box the stage can bound', () {
      for (final actor in <StoryActor>[
        const StoryPostmaster(),
        const StoryPostmaster(facingLeft: true),
        for (var bird = 0; bird < 4; bird++) StoryCourier(bird),
        for (final kind in BossKind.values) ...[
          StoryBoss(kind),
          StoryBoss(kind, beaten: true),
        ],
      ]) {
        expect(actor.box.isEmpty, isFalse);
        expect(actor.box.isFinite, isTrue);
        expect(actor.heart, greaterThan(0));
      }
    });
  });

  group('capture', skip: !_capture, () {
    test('cast sheets', () async {
      const day = Color(0xffbfe3ee), night = Color(0xff2a2f55);
      await _sheet('cast-bill-and-couriers', [
        ('Bill', const StoryPostmaster(), -20),
        ('Bill, facing left', const StoryPostmaster(facingLeft: true), 20),
        for (final (bird, name) in ['Pip', 'Peaches', 'Minty', 'Orbit'].indexed)
          (name, StoryCourier(bird), 0),
      ], day);
      await _sheet(
        'cast-bill-and-couriers-talking',
        [
          ('Bill', const StoryPostmaster(), -20),
          for (final (bird, name) in [
            'Pip',
            'Peaches',
            'Minty',
            'Orbit',
          ].indexed)
            (name, StoryCourier(bird), 0),
        ],
        night,
        mouth: 2,
      );
      await _sheet(
        'cast-bill-and-couriers-blink',
        [
          ('Bill', const StoryPostmaster(), -20),
          for (final (bird, name) in [
            'Pip',
            'Peaches',
            'Minty',
            'Orbit',
          ].indexed)
            (name, StoryCourier(bird), 0),
        ],
        day,
        mouth: 1,
        blink: true,
      );
      for (final (name, ground, mouth, beaten) in [
        ('cast-bosses', day, 0, false),
        ('cast-bosses-talking', night, 2, false),
        ('cast-bosses-beaten', night, 0, true),
        ('cast-bosses-beaten-talking', day, 2, true),
      ]) {
        await _sheet(
          name,
          [
            for (final kind in BossKind.values)
              (kind.name, StoryBoss(kind, beaten: beaten), 0),
          ],
          ground,
          mouth: mouth,
        );
      }
    });

    testWidgets('every scene at its most telling line', (tester) async {
      for (final scene in CampaignStory.scenes) {
        final line = _telling(scene);
        await _play(tester, scene, _sizes[1], bird: scene.id.hashCode % 4);
        await _next(tester, line);
        await _save(tester, 'scene-${scene.id}-line-$line-800');
      }
    });

    for (final size in _sizes) {
      final w = size.width.round();
      testWidgets('the prologue, a lair and a last word at $w', (tester) async {
        for (final (id, lines, bird) in [
          ('before-1-1', [0, 1, 2, 3, 5], 0),
          ('before-1-8', [0, 1, 2, 5], 1),
          ('after-1', [0, 1, 6, 7], 1),
          ('before-4-8', [0, 3, 4, 5], 2),
          ('after-4', [0, 3, 5], 2),
          ('before-5-8', [0, 2, 3], 3),
          ('after-5', [0, 2, 3, 4, 6, 8], 3),
          ('before-2-8', [0, 4], 0),
          ('after-2', [0, 4, 7], 0),
          ('before-3-8', [0, 2, 4], 1),
          ('after-3', [0, 3, 5], 1),
        ]) {
          final scene = _scene(id);
          await _play(tester, scene, size, bird: bird);
          var at = 0;
          for (final line in lines) {
            await _next(tester, line - at);
            at = line;
            await _save(tester, 'sizes-$id-line-$line-$w');
          }
        }
      });
    }

    testWidgets('the longest lines', (tester) async {
      final longest = [
        for (final scene in CampaignStory.scenes)
          for (final (i, line) in scene.lines.indexed) (scene, i, line),
      ]..sort((a, b) => b.$3.text.length.compareTo(a.$3.text.length));
      for (final (scene, i, line) in longest.take(4)) {
        for (final (size, padding, name) in [
          (_sizes[0], EdgeInsets.zero, '640'),
          (_sizes[0], _notch, '640-notch'),
          (_sizes[2], EdgeInsets.zero, '1000'),
        ]) {
          await _play(tester, scene, size, padding: padding, bird: 1);
          await _next(tester, i);
          await _save(
            tester,
            'longest-${line.text.length}-${scene.id}-line-$i-$name',
          );
        }
      }
    });

    testWidgets('a notch on either side', (tester) async {
      for (final (name, padding) in [
        ('left', _notch),
        ('right', const EdgeInsets.fromLTRB(34, 0, 44, 21)),
      ]) {
        for (final (id, line) in [('before-2-1', 2), ('before-5-8', 2)]) {
          await _play(tester, _scene(id), _sizes[1], padding: padding, bird: 3);
          await _next(tester, line);
          await _save(tester, 'notch-$name-$id-800');
        }
      }
    });

    testWidgets('each bird as the courier', (tester) async {
      for (var bird = 0; bird < 4; bird++) {
        for (final (id, line) in [
          ('before-1-1', 2),
          ('before-2-6', 3),
          ('before-4-4', 3),
          ('before-3-8', 1),
        ]) {
          await _play(tester, _scene(id), _sizes[1], bird: bird);
          await _next(tester, line);
          await _save(tester, 'courier-$bird-$id-line-$line');
        }
      }
    });

    testWidgets('a scene opening, a line being written and a change of '
        'speaker, frame by frame', (tester) async {
      final scene = _scene('before-1-4');
      await _play(tester, scene, _sizes[1], reduced: false);
      var ms = 0;
      Future<void> frames(String name, List<int> at) async {
        for (final t in at) {
          await tester.pump(Duration(milliseconds: t - ms));
          ms = t;
          await _save(tester, 'motion-$name-${'$t'.padLeft(4, '0')}');
        }
      }

      await frames('open', [0, 60, 120, 200, 300, 400, 700, 1100]);
      await tester.pump(const Duration(seconds: 3));
      await _save(tester, 'motion-open-idle');
      await tester.tap(find.byKey(const ValueKey('story-advance')));
      await tester.pump();
      ms = 0;
      await frames('turn', [0, 50, 100, 160, 240, 400, 800]);
      await tester.pump(const Duration(seconds: 3));
      // Bill again: the same speaker takes a second line.
      await tester.tap(find.byKey(const ValueKey('story-advance')));
      await tester.pump();
      ms = 0;
      await frames('turn-back', [0, 60, 140, 260]);
      await tester.pump(const Duration(seconds: 3));
      await tester.tap(find.byKey(const ValueKey('story-advance')));
      await tester.pump();
      ms = 0;
      await frames('same-speaker', [0, 60, 140, 600]);
      // The prologue opens on a caption; the cast comes on with line two.
      await _play(tester, CampaignStory.prologue, _sizes[1], reduced: false);
      ms = 0;
      await frames('prologue', [0, 150, 400, 1200]);
      await tester.pump(const Duration(seconds: 2));
      await tester.tap(find.byKey(const ValueKey('story-advance')));
      await tester.pump();
      ms = 0;
      await frames('prologue-enter', [0, 80, 160, 260, 400, 900]);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('Reduced Motion', (tester) async {
      for (final (id, line) in [
        ('before-1-1', 0),
        ('before-1-1', 1),
        ('before-3-1', 1),
        ('after-5', 3),
      ]) {
        await _play(tester, _scene(id), _sizes[0], bird: 1);
        await _next(tester, line);
        await _save(tester, 'reduced-$id-line-$line-640');
      }
    });

    testWidgets('details at 2x', (tester) async {
      for (final (id, line, bird) in [
        ('before-1-1', 1, 0),
        ('before-1-1', 0, 0),
        ('after-5', 3, 3),
        ('before-1-8', 0, 1),
        ('before-5-3', 2, 2),
      ]) {
        await _play(tester, _scene(id), _sizes[1], bird: bird);
        await _next(tester, line);
        await _save(tester, 'detail-$id-line-$line', ratio: 2);
      }
    });
  });
}
