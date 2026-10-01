import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/campaign_story.dart';
import 'package:push_up_bird/domain/sky_boss.dart';
import 'package:push_up_bird/game/gargoyle_kit.dart';
import 'package:push_up_bird/game/gargoyle_layout.dart';
import 'package:push_up_bird/game/gargoyle_pose.dart';
import 'package:push_up_bird/game/gargoyle_story_art.dart';
import 'package:push_up_bird/ui/campaign_keepsake_art.dart';
import 'package:push_up_bird/ui/story_boss_art.dart';
import 'package:push_up_bird/ui/story_cast_art.dart';
import 'package:push_up_bird/ui/story_scene.dart';
import 'package:push_up_bird/ui/theme.dart';

/// The Searchlight Gargoyle in the story scenes: the six moods (the five of
/// `StoryMood` and the beaten look after his fall), through the real cast
/// painter, on the lair's stage, with the keepsake's visor.
///
/// `GARGOYLE_STORY_REVIEW=1` also writes `build/visual-review/g8-staging/`
/// `story-*.png`: the six moods at 2x on a night ground, and the real scenes
/// `before-3-4` and `last-3-4` at 640 and 800.
final _review = Platform.environment['GARGOYLE_STORY_REVIEW'] == '1';
final _folder = Directory('build/visual-review/g8-staging');

const _night = Color(0xff2a2f55);
const _ground = Color(0xff3a3f6b);

Future<ui.Image> _draw(void Function(Canvas c) paint, {int w = 330, int h = 300, double k = 1}) async {
  final recorder = ui.PictureRecorder();
  final c = Canvas(recorder);
  c.scale(k);
  paint(c);
  final image = await recorder.endRecording().toImage((w * k).round(), (h * k).round());
  return image;
}

Future<List<int>> _bytes(ui.Image image) async => (await image.toByteData())!.buffer.asUint8List();


/// One boss on the cast stage at [mood] / [beaten] (a 330 x 300 cell, the
/// floor 262 px down, as the cast sheets of the polish tests).
Future<ui.Image> _cell(StoryMood mood, {bool beaten = false, int mouth = 0, bool blink = false, double k = 1}) => _draw((c) {
  c.drawRect(const Rect.fromLTWH(0, 0, 330, 300), Paint()..color = _night);
  c.drawRect(const Rect.fromLTWH(0, 262, 330, 38), Paint()..color = SkyColors.cream);
  c.translate(165, 262);
  StoryBoss(BossKind.searchlightGargoyle, beaten: beaten).paint(c, (mood: mood, mouth: mouth, blink: blink));
}, k: k);

Future<int> _diff(ui.Image a, ui.Image b) async {
  final x = await _bytes(a), y = await _bytes(b);
  var n = 0;
  for (var i = 0; i < x.length; i += 4) {
    if (x[i] != y[i] || x[i + 1] != y[i + 1] || x[i + 2] != y[i + 2]) n++;
  }
  return n;
}

Future<void> _play(WidgetTester tester, StoryScene scene, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: skyTheme(),
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: RepaintBoundary(
          key: const ValueKey('g8-capture'),
          child: Scaffold(
            backgroundColor: SkyColors.sky,
            body: StoryScenePlayer(key: ValueKey('${scene.id}-$size'), scene: scene, bird: 0, reducedMotion: true, onDone: () {}),
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

Future<void> _save(WidgetTester tester, String name) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(const ValueKey('g8-capture')));
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    _folder.createSync(recursive: true);
    File('${_folder.path}/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    for (final family in ['Fredoka', 'Nunito']) {
      await (FontLoader(family)..addFont(rootBundle.load('assets/fonts/$family.ttf'))).load();
    }
  });

  group('review frames', skip: _review ? false : 'set GARGOYLE_STORY_REVIEW=1', () {
    testWidgets('the six moods', (tester) async {
      await tester.runAsync(() async {
        const k = 2.0;
        final cells = <(String, ui.Image)>[];
        for (final (label, mood, beaten) in [
          ('plain', StoryMood.plain, false),
          ('happy', StoryMood.happy, false),
          ('surprised', StoryMood.surprised, false),
          ('angry', StoryMood.angry, false),
          ('sad', StoryMood.sad, false),
          ('beaten', StoryMood.plain, true),
          ('beaten happy', StoryMood.happy, true),
          ('talking', StoryMood.happy, false),
        ]) {
          cells.add((label, await _cell(mood, beaten: beaten, mouth: label == 'talking' ? 2 : 0, k: k)));
        }
        const cols = 4;
        final rows = (cells.length / cols).ceil();
        final image = await _draw((c) {
          c.drawRect(Rect.fromLTWH(0, 0, 330.0 * cols, 300.0 * rows), Paint()..color = _ground);
          for (final (i, (label, cell)) in cells.indexed) {
            c.save();
            c.translate((i % cols) * 330.0, (i ~/ cols) * 300.0);
            c.scale(1 / k);
            c.drawImage(cell, Offset.zero, Paint());
            c.restore();
            final p = TextPainter(
              text: TextSpan(text: label, style: const TextStyle(fontFamily: 'Fredoka', fontSize: 12, color: Colors.white)),
              textDirection: TextDirection.ltr,
            )..layout();
            p.paint(c, Offset((i % cols) * 330.0 + 6, (i ~/ cols) * 300.0 + 4));
          }
        }, w: 330 * cols, h: 300 * rows, k: 1.4);
        _folder.createSync(recursive: true);
        File('${_folder.path}/story-moods.png').writeAsBytesSync((await image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List());
      });
    });

    for (final size in const [Size(640, 360), Size(800, 360)]) {
      testWidgets('the lair scenes at ${size.width.round()}', (tester) async {
        for (final (id, lines) in const [('before-3-4', [0, 1, 3, 4, 5]), ('last-3-4', [0, 2, 3, 4])]) {
          final scene = CampaignStory.scenes.firstWhere((s) => s.id == id);
          await _play(tester, scene, size);
          var at = 0;
          for (final line in lines) {
            await _next(tester, line - at);
            at = line;
            await _save(tester, 'story-$id-$line-${size.width.round()}');
          }
        }
      });
    }

    testWidgets('the keepsake visor', (tester) async {
      await tester.runAsync(() async {
        final image = await _draw((c) {
          c.drawRect(const Rect.fromLTWH(0, 0, 330, 300), Paint()..color = const Color(0xff6f86a8));
          CampaignHeadwear.paint(c, const Rect.fromLTWH(65, 70, 200, 160), BossKind.searchlightGargoyle);
        });
        _folder.createSync(recursive: true);
        File('${_folder.path}/story-keepsake.png').writeAsBytesSync((await image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List());
      });
    });
  });

  group('the portrait', () {
    final names = <(String, StoryMood, bool)>[
      ('plain', StoryMood.plain, false),
      ('happy', StoryMood.happy, false),
      ('surprised', StoryMood.surprised, false),
      ('angry', StoryMood.angry, false),
      ('sad', StoryMood.sad, false),
      ('beaten', StoryMood.plain, true),
      ('beaten, happy', StoryMood.happy, true),
    ];

    testWidgets('the six moods (and the beaten one smiling) are seven different, deterministic portraits', (tester) async {
      await tester.runAsync(() async {
        final cells = <String, List<int>>{};
        for (final (name, mood, beaten) in names) {
          final a = await _cell(mood, beaten: beaten);
          final b = await _cell(mood, beaten: beaten);
          cells[name] = await _bytes(a);
          expect(await _diff(a, b), 0, reason: '$name paints the same twice');
          expect(await _diff(a, await _cell(StoryMood.plain)), name == 'plain' ? 0 : greaterThan(300), reason: '$name is not the plain portrait');
        }
        for (final x in names) {
          for (final y in names) {
            if (x.$1 == y.$1) continue;
            var n = 0;
            final a = cells[x.$1]!, b = cells[y.$1]!;
            for (var i = 0; i < a.length; i += 4) {
              if (a[i] != b[i] || a[i + 1] != b[i + 1] || a[i + 2] != b[i + 2]) n++;
            }
            expect(n, greaterThan(300), reason: '${x.$1} and ${y.$1} differ');
          }
        }
      });
    });

    testWidgets('he stays inside the reach the stage fits, in every mood, talking and blinking', (tester) async {
      await tester.runAsync(() async {
        final (:unit, :origin, :reach) = StoryBossArt.portrait(BossKind.searchlightGargoyle);
        expect(StoryBossArt.portrait(BossKind.searchlightGargoyle, beaten: true).reach, reach);
        for (final (name, mood, beaten) in names) {
          for (final (mouth, blink) in const [(0, false), (2, true)]) {
            final image = await _draw((c) {
              c.translate(165, 262);
              StoryBoss(BossKind.searchlightGargoyle, beaten: beaten).paint(c, (mood: mood, mouth: mouth, blink: blink));
            }, w: 330, h: 300);
            final px = await _bytes(image);
            image.dispose();
            // The stage's box around the place he stands on.
            final box = StoryBoss(BossKind.searchlightGargoyle, beaten: beaten).box.shift(const Offset(165, 262)).inflate(2);
            // (Whatever hangs below the floor line, 262, is the cornice's corbels:
            // the stage sinks it into the dark at the foot of the scene.)
            for (var y = 0; y < 270; y++) {
              for (var x = 0; x < 330; x++) {
                if (px[(y * 330 + x) * 4 + 3] < 200) continue;
                expect(box.contains(Offset(x.toDouble(), y.toDouble())), isTrue, reason: '$name mouth $mouth: a solid pixel at ($x,$y) leaves the stage box $box');
              }
            }
          }
        }
        expect(unit, greaterThan(0));
      });
    });

    testWidgets('the beak opens with the talk and the lenses close with the blink', (tester) async {
      await tester.runAsync(() async {
        final calm = await _cell(StoryMood.plain);
        final talking = await _cell(StoryMood.plain, mouth: 2);
        final blinking = await _cell(StoryMood.plain, blink: true);
        expect(await _diff(calm, talking), greaterThan(60), reason: 'the jaw drops');
        expect(await _diff(calm, blinking), greaterThan(60), reason: 'the lenses iris shut');
        expect(await _diff(talking, blinking), greaterThan(60));
      });
    });

    testWidgets('after the fall the courier\'s weather vane turns on the mount, a pigeon sits on his crest, the visors are gone', (tester) async {
      await tester.runAsync(() async {
        final beaten = GargoyleStoryArt.poseOf(StoryMood.plain, beaten: true);
        final sad = GargoyleStoryArt.poseOf(StoryMood.sad);
        final plain = GargoyleStoryArt.poseOf(StoryMood.plain);
        expect(beaten.visor, 0, reason: 'the brow visors are the headwear he loses');
        expect(sad.visor, 1);
        expect(plain.visor, 1);
        expect(GargoyleStoryArt.poseOf(StoryMood.happy, beaten: true).visor, 0, reason: 'a cheerful, beaten Gargoyle keeps the damage');
        expect(GargoyleStoryArt.poseOf(StoryMood.happy, beaten: true).crack, 1);
        // The vane: pixels over the empty mount (rig units (-2.0, 1.2 .. 1.7)) in the beaten portrait only.
        Future<ui.Image> mount(StoryMood mood, bool beaten) => _draw((c) {
          c.translate(165, 230);
          c.scale(30);
          GargoyleStoryArt.paint(c, mood, beaten: beaten);
        }, w: 330, h: 300);
        final fallen = await _bytes(await mount(StoryMood.plain, true));
        final empty = await _bytes(await mount(StoryMood.plain, false));
        var vane = 0;
        for (var y = 230 + (1.0 * 30).round(); y < 230 + (1.7 * 30).round(); y++) {
          for (var x = 165 - (3.2 * 30).round(); x < 165 - (.8 * 30).round(); x++) {
            final i = (y * 330 + x) * 4;
            if (fallen[i] != empty[i] || fallen[i + 1] != empty[i + 1]) vane++;
          }
        }
        expect(vane, greaterThan(60), reason: 'the vane stands on the mount after the fall');
      });
    });

    testWidgets('no other boss\'s portrait, headwear or stamp is his, and the keepsake is the visor', (tester) async {
      await tester.runAsync(() async {
        final mine = <BossKind, List<int>>{};
        for (final kind in BossKind.values) {
          final image = await _draw((c) {
            c.drawRect(const Rect.fromLTWH(0, 0, 330, 300), Paint()..color = _night);
            final (:unit, :origin, :reach) = StoryBossArt.portrait(kind);
            c.translate(165 + origin.dx, 262 + origin.dy);
            c.scale(unit);
            StoryBossArt.paint(c, kind, StoryMood.plain);
          });
          mine[kind] = await _bytes(image);
        }
        final g = mine[BossKind.searchlightGargoyle]!;
        for (final kind in BossKind.values) {
          if (kind == BossKind.searchlightGargoyle) continue;
          var n = 0;
          final o = mine[kind]!;
          for (var i = 0; i < g.length; i += 4) {
            if (g[i] != o[i] || g[i + 1] != o[i + 1] || g[i + 2] != o[i + 2]) n++;
          }
          expect(n, greaterThan(2000), reason: 'the Gargoyle\'s portrait is not ${kind.name}\'s');
        }
        // The keepsake: the visor (hooded over a lens), steel and brass on the steel-blue field.
        final headwear = await _draw((c) {
          c.drawRect(const Rect.fromLTWH(0, 0, 330, 300), Paint()..color = const Color(0xff6f86a8));
          CampaignHeadwear.paint(c, const Rect.fromLTWH(65, 70, 200, 160), BossKind.searchlightGargoyle);
        });
        final px = await _bytes(headwear);
        var brass = 0, ink = 0;
        for (var i = 0; i < px.length; i += 4) {
          if (px[i] > 200 && px[i + 1] > 150 && px[i + 2] < 120) brass++;
          if (px[i] < 40 && px[i + 1] < 40 && px[i + 2] < 70) ink++;
        }
        expect(brass, greaterThan(500), reason: 'the lens stands out on the steel field');
        expect(ink, greaterThan(500));
        // ... inside its box with a margin.
        var outside = 0;
        for (var y = 0; y < 300; y++) {
          for (var x = 0; x < 330; x++) {
            if (x >= 65 && x < 265 && y >= 70 && y < 230) continue;
            final i = (y * 330 + x) * 4;
            if (px[i] != 0x6f || px[i + 1] != 0x86) outside++;
          }
        }
        expect(outside, 0, reason: 'the keepsake is fitted into its box');
        expect(CampaignHeadwear.name(BossKind.searchlightGargoyle), 'Searchlight Gargoyle');
      });
    });

    test('the pose the story paints is the rig\'s own: a story pose, still, identical under Reduced Motion', () {
      for (final (name, mood, beaten) in names) {
        final p = GargoyleStoryArt.poseOf(mood, beaten: beaten);
        expect(p.reduced, isTrue, reason: name);
        expect(p.time, 0, reason: name);
        for (final v in p.channels.values) {
          expect(v.isFinite, isTrue, reason: '$name has a finite channel');
        }
      }
      expect(GargoyleStoryArt.poseOf(StoryMood.plain).lamp, 0);
      expect(GargoyleStoryArt.poseOf(StoryMood.angry).fury, 1);
      expect(GargoyleStoryArt.poseOf(StoryMood.happy, talk: 1).gape, greaterThan(.4));
      expect(GargoyleStoryArt.poseOf(StoryMood.plain, blink: 1).iris, 0);
      expect(GargoyleLayout.ledgeY, 2.95);
      expect(GargoyleMood.values.length, 6);
      expect(const GargoyleTone().flash, 0);
    });
  });

  group('the lair scenes', () {
    for (final size in const [Size(640, 360), Size(800, 360)]) {
      testWidgets('before-3-4 and last-3-4 play with him on the stage at ${size.width.round()}', (tester) async {
        for (final id in const ['before-3-4', 'last-3-4']) {
          final scene = CampaignStory.scenes.firstWhere((s) => s.id == id);
          await _play(tester, scene, size);
          for (var i = 0; i < scene.lines.length; i++) {
            expect(tester.takeException(), isNull, reason: '$id line $i at ${size.width}');
            await _next(tester);
          }
        }
      });
    }
  });
}
