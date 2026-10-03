import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/campaign_story.dart' show StoryMood;
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/game/bird_game.dart';
import 'package:push_up_bird/game/bird_puppet.dart';
import 'package:push_up_bird/game/boss_art.dart';
import 'package:push_up_bird/game/boss_motion.dart';
import 'package:push_up_bird/game/dragon_pose.dart';
import 'package:push_up_bird/game/flight_voice_faces.dart';
import 'package:push_up_bird/game/flight_voices.dart';
import 'package:push_up_bird/ui/theme.dart';

/// Talking faces in flight: while a line plays, the speaker's face shows the
/// line's mood and its mouth follows the words (docs/flight-voices.md).
///
/// The tests pin the behaviour; with
/// `--dart-define=CAPTURE_TALKING_FACES=true` they also write the review
/// sheets to build/visual-review/talking-faces/.
const capture = bool.fromEnvironment('CAPTURE_TALKING_FACES');
final folder = Directory('build/visual-review/talking-faces');

Future<Uint8List> raster(
  int w,
  int h,
  void Function(Canvas) draw, {
  String? name,
}) async {
  final recorder = ui.PictureRecorder();
  draw(Canvas(recorder));
  final picture = recorder.endRecording();
  final image = await picture.toImage(w, h);
  final pixels = (await image.toByteData())!.buffer.asUint8List();
  if (name != null) {
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    folder.createSync(recursive: true);
    File(
      '${folder.path}/$name.png',
    ).writeAsBytesSync(png!.buffer.asUint8List());
  }
  image.dispose();
  picture.dispose();
  return pixels;
}

/// Draws at true pixel size, then writes it [zoom] times bigger with hard
/// pixel edges, so a review sees exactly what a phone shows.
Future<void> savePixels(
  String name,
  int w,
  int h,
  void Function(Canvas) draw, {
  int zoom = 3,
}) async {
  final recorder = ui.PictureRecorder();
  draw(Canvas(recorder));
  final picture = recorder.endRecording();
  final small = await picture.toImage(w, h);
  await raster(w * zoom, h * zoom, (c) {
    c.drawImageRect(
      small,
      Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
      Rect.fromLTWH(0, 0, w * zoom.toDouble(), h * zoom.toDouble()),
      Paint()..filterQuality = FilterQuality.none,
    );
  }, name: name);
  small.dispose();
  picture.dispose();
}

void label(Canvas c, String text, Offset at, {double size = 14}) {
  final p = TextPainter(
    text: TextSpan(text: text, style: bodyText(size)),
    textDirection: TextDirection.ltr,
  )..layout();
  p.paint(c, at - Offset(p.width / 2, 0));
}

/// [kind] mid-fight and calm: arrived a second ago, nothing charging.
SkyBoss calm(BossKind kind) {
  final boss = SkyBoss(
    number: kind.index + 1,
    x: 1.6,
    kind: kind,
    cinematic: true,
    debut: true,
  );
  return boss
    ..y = .5
    ..age = boss.arrivalDuration + 1
    ..fireIn = 2;
}

/// Where each boss's face is from its hit circle's centre, in its rig units
/// (the hit radius): what a close-up centres on.
Offset faceOf(BossKind kind) => switch (kind) {
  BossKind.baronBat => const Offset(0, -.2),
  BossKind.spitterBeetle => const Offset(-.6, -.2),
  BossKind.duskMoth => const Offset(-1, -.25),
  BossKind.pirate => const Offset(-.5, -.4),
  BossKind.dragon => const Offset(-1.3, -1.9),
  // The guardians do not talk in flight (no recorded lines yet).
  BossKind.kingCoo ||
  BossKind.searchlightGargoyle ||
  BossKind.neferhoo => Offset.zero,
};

/// Paints [boss] as the flight does, with [focus] (rig units from its
/// centre) at the middle of [cell], on a screen [h] high.
void paintBoss(
  Canvas c,
  SkyBoss boss,
  Rect cell,
  double h, {
  FlightSpeech? speech,
  Offset focus = Offset.zero,
  bool reduced = false,
}) {
  final sim = FlightSimulation(rules: TapFlyMode(), practice: true)
    ..phase = RunPhase.playing
    ..elapsed = 30
    ..birdY = boss.y;
  sim.boss = boss;
  final unit = h * SkyBoss.radius;
  c.save();
  c.clipRect(cell);
  c.drawRect(cell, Paint()..color = const Color(0xff8fa3cf));
  c.translate(
    cell.center.dx - boss.x * h - focus.dx * unit,
    cell.center.dy - boss.y * h - focus.dy * unit,
  );
  BossArt.paint(
    c,
    Size(h * 16 / 9, h),
    sim,
    reducedMotion: reduced,
    speech: speech,
  );
  c.restore();
}

FlightSpeech say(BossKind? boss, StoryMood mood, int mouth) =>
    FlightSpeech(boss: boss, mood: mood, mouth: mouth, age: .4, length: 2);

/// The speech of [clip] [frame] steps (50 ms each) into it, as
/// FlightVoices.speech builds it.
FlightSpeech spoken(String clip, int frame, {BossKind? boss}) {
  final curve = flightVoiceMouths[clip]!;
  return FlightSpeech(
    boss: boss,
    mood:
        StoryMood.values.asNameMap()[flightVoiceMoods[clip]] ?? StoryMood.plain,
    mouth: frame < curve.length ? curve.codeUnitAt(frame) - 48 : 0,
    age: frame * .05,
    length: curve.length * .05,
  );
}

Future<Uint8List> bird(
  int bird, {
  BirdExpression expression = BirdExpression.neutral,
  StoryMood? mood,
  int beak = 0,
}) => raster(
  256,
  224,
  (c) => BirdPuppet.paint(
    c,
    const Rect.fromLTWH(0, 0, 256, 224),
    bird: bird,
    wing: 0,
    expression: expression,
    mood: mood,
    beak: beak,
  ),
);

Future<Uint8List> boss(
  BossKind kind, {
  FlightSpeech? speech,
  bool reduced = false,
  SkyBoss? at,
}) => raster(
  360,
  300,
  (c) => paintBoss(
    c,
    at ?? calm(kind),
    const Rect.fromLTWH(0, 0, 360, 300),
    360,
    speech: speech,
    focus: faceOf(kind) * .6,
    reduced: reduced,
  ),
);

/// One whole game frame, 800 × 360, of [sim] with [speech] said in it.
Future<Uint8List> gameFrame(
  WidgetTester tester,
  FlightSimulation sim, {
  FlightSpeech? Function()? speech,
  bool reduced = false,
  int bird = 0,
  String? name,
}) async {
  tester.view.physicalSize = const Size(800, 360);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final game = BirdGame(
    simulation: sim,
    nowMs: () => 0,
    bird: bird,
    reducedMotion: reduced,
    playback: true,
    onChanged: () {},
    speech: speech,
  );
  await tester.pumpWidget(GameWidget(game: game));
  late Uint8List pixels;
  await tester.runAsync(() async {
    await game.loaded;
    game.pauseEngine();
    pixels = await raster(800, 360, game.render, name: name);
  });
  await tester.pumpWidget(const SizedBox());
  return pixels;
}

FlightSimulation flying({SkyBoss? boss}) {
  final sim = FlightSimulation(rules: TapFlyMode(), practice: true)
    ..started = true
    ..phase = RunPhase.playing
    ..elapsed = 21
    ..birdY = .42;
  if (boss != null) {
    sim.boss = boss
      ..x = 1.72
      ..y = .47;
  }
  return sim;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('the bird talks', () {
    test(
      'a line sets the mood on the face and the words open the beak',
      () async {
        for (var b = 0; b < 4; b++) {
          final silent = await bird(b);
          // A plain line with the beak shut between words is the plain face.
          expect(await bird(b, mood: StoryMood.plain), silent, reason: '$b');
          final frames = [
            for (var beak = 0; beak <= BirdPuppet.beaks; beak++)
              await bird(b, mood: StoryMood.plain, beak: beak),
          ];
          for (var i = 1; i < frames.length; i++) {
            expect(frames[i], isNot(frames[i - 1]), reason: '$b beak $i');
          }
          final faces = <Uint8List>[silent];
          for (final mood in StoryMood.values.skip(1)) {
            final face = await bird(b, mood: mood);
            for (final other in faces) {
              expect(face, isNot(other), reason: '$b ${mood.name}');
            }
            faces.add(face);
          }
          // Seeing stars outlasts any mood; the beak still talks.
          final dazed = await bird(b, expression: BirdExpression.dazed);
          expect(
            await bird(
              b,
              expression: BirdExpression.dazed,
              mood: StoryMood.sad,
            ),
            dazed,
          );
          expect(
            await bird(
              b,
              expression: BirdExpression.dazed,
              mood: StoryMood.sad,
              beak: 2,
            ),
            isNot(dazed),
          );
        }
      },
    );

    test('the picture cache stays bounded', () {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      for (var round = 0; round < 2; round++) {
        for (var b = 0; b < 4; b++) {
          for (final expression in BirdExpression.values) {
            for (final mood in [null, ...StoryMood.values]) {
              for (var beak = -1; beak <= BirdPuppet.beaks + 2; beak++) {
                BirdPuppet.paint(
                  canvas,
                  const Rect.fromLTWH(0, 0, 64, 56),
                  bird: b,
                  wing: 0,
                  expression: expression,
                  mood: mood,
                  beak: beak,
                );
              }
            }
          }
        }
      }
      recorder.endRecording().dispose();
      expect(
        BirdPuppet.debugCachedBodies,
        lessThanOrEqualTo(BirdPuppet.debugMaxBodies),
      );
      expect(BirdPuppet.debugMaxBodies, 144);
    });

    testWidgets('in flight, only the bird\'s own lines move its face', (
      tester,
    ) async {
      final silent = await gameFrame(tester, flying());
      expect(await gameFrame(tester, flying(), speech: () => null), silent);
      final talking = await gameFrame(
        tester,
        flying(),
        speech: () => say(null, StoryMood.plain, 3),
      );
      expect(talking, isNot(silent));
      // A boss's line with no boss on screen leaves the bird alone.
      expect(
        await gameFrame(
          tester,
          flying(),
          speech: () => say(BossKind.baronBat, StoryMood.angry, 3),
        ),
        silent,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('Reduced Motion keeps the beak shut but shows the mood', (
      tester,
    ) async {
      final silent = await gameFrame(tester, flying(), reduced: true);
      final shut = await gameFrame(
        tester,
        flying(),
        reduced: true,
        speech: () => say(null, StoryMood.angry, 0),
      );
      expect(shut, isNot(silent));
      expect(
        await gameFrame(
          tester,
          flying(),
          reduced: true,
          speech: () => say(null, StoryMood.angry, 3),
        ),
        shut,
      );
    });
  });

  group('the guardians stay unaffected', () {
    // King Coo and the Searchlight Gargoyle have no in-flight voice: a line
    // said by anyone, even one keyed to them, leaves their pictures as they
    // are (their rigs do not read speech).
    for (final kind in BossKind.values.where(
      (kind) => !FlightVoices.voicedBosses.contains(kind),
    )) {
      test('${kind.name} paints the same whoever speaks', () async {
        final silent = await boss(kind);
        for (final speaker in [null, kind, BossKind.dragon]) {
          for (final mood in StoryMood.values) {
            for (var mouth = 0; mouth <= FlightSpeech.mouths; mouth++) {
              expect(
                await boss(kind, speech: say(speaker, mood, mouth)),
                silent,
                reason: '${speaker?.name} $mood $mouth',
              );
            }
          }
        }
      });
    }
  });

  group('the bosses talk', () {
    for (final kind in FlightVoices.voicedBosses) {
      test(
        '${kind.name} opens its mouth to the words and shows the mood',
        () async {
          final silent = await boss(kind);
          expect(
            await boss(kind, speech: say(null, StoryMood.angry, 3)),
            silent,
            reason: 'The bird is talking, not the boss',
          );
          final other = BossKind.values[(kind.index + 1) % 5];
          expect(
            await boss(kind, speech: say(other, StoryMood.angry, 3)),
            silent,
            reason: 'Another boss is talking',
          );
          final frames = [
            for (var mouth = 0; mouth <= FlightSpeech.mouths; mouth++)
              await boss(kind, speech: say(kind, StoryMood.plain, mouth)),
          ];
          expect(frames.first, silent, reason: 'A plain face between words');
          for (var i = 1; i < frames.length; i++) {
            expect(frames[i], isNot(frames[i - 1]), reason: 'mouth $i');
          }
          for (final mood in StoryMood.values.skip(1)) {
            expect(
              await boss(kind, speech: say(kind, mood, 0)),
              isNot(silent),
              reason: mood.name,
            );
            // Reduced Motion: the mood shows, the mouth keeps still.
            final still = await boss(
              kind,
              speech: say(kind, mood, 0),
              reduced: true,
            );
            expect(still, isNot(await boss(kind, reduced: true)));
            expect(
              await boss(kind, speech: say(kind, mood, 3), reduced: true),
              still,
              reason: mood.name,
            );
          }
          // The beaten boss's own death plays out, whatever is said.
          SkyBoss beaten() => calm(kind)..defeatedAt = calm(kind).age - .5;
          expect(
            await boss(kind, at: beaten(), speech: say(kind, StoryMood.sad, 3)),
            await boss(kind, at: beaten()),
          );
        },
      );
    }

    test('an attack holds its own mouth over the words', () {
      final m = BossMotion(
        calm(BossKind.baronBat),
        reducedMotion: false,
        speech: say(BossKind.baronBat, StoryMood.angry, 3),
      );
      expect(m.voiced(0), greaterThan(.9));
      expect(m.voiced(1), 1);
      expect(m.voiced(.3, busy: 1), .3);
      // The dragon mid-breath: the words leave its jaws alone.
      for (final t in [4.5, 5.0, 5.6, 7.7]) {
        final dragon = calm(BossKind.dragon)
          ..age = calm(BossKind.dragon).arrivalDuration + t;
        double gape(FlightSpeech? speech) => DragonPose(
          dragon,
          BossMotion(dragon, reducedMotion: false, speech: speech),
        ).gape;
        expect(
          gape(say(BossKind.dragon, StoryMood.angry, 3)),
          closeTo(gape(null), 1e-9),
          reason: 'at $t',
        );
      }
    });
  });

  group('review sheets', () {
    setUpAll(() async {
      if (!capture) return;
      for (final family in ['Fredoka', 'Nunito']) {
        await (FontLoader(
          family,
        )..addFont(rootBundle.load('assets/fonts/$family.ttf'))).load();
      }
    });

    test('birds: moods by beak frames, large and at gameplay size', () async {
      if (!capture) return;
      for (var b = 0; b < 4; b++) {
        const cell = 256.0, rowH = 250.0;
        await raster((cell * 4).toInt(), (rowH * 5).toInt(), (c) {
          c.drawColor(SkyColors.cream, BlendMode.src);
          for (final (row, mood) in StoryMood.values.indexed) {
            for (var beak = 0; beak <= BirdPuppet.beaks; beak++) {
              BirdPuppet.paint(
                c,
                Rect.fromLTWH(beak * cell, row * rowH, 256, 224),
                bird: b,
                wing: 0,
                mood: mood,
                beak: beak,
              );
              label(
                c,
                '${mood.name} $beak',
                Offset(beak * cell + 128, row * rowH + 222),
              );
            }
          }
        }, name: 'bird-$b-large');
        // The face three times the art, every mood and frame.
        const zoom = 3.0, face = Rect.fromLTRB(96, 36, 240, 156);
        await raster(
          (face.width * zoom * 4).toInt(),
          (face.height * zoom * 5).toInt(),
          (c) {
            c.drawColor(SkyColors.cream, BlendMode.src);
            for (final (row, mood) in StoryMood.values.indexed) {
              for (var beak = 0; beak <= BirdPuppet.beaks; beak++) {
                c.save();
                c.translate(beak * face.width * zoom, row * face.height * zoom);
                c.clipRect(
                  Rect.fromLTWH(0, 0, face.width * zoom, face.height * zoom),
                );
                c.scale(zoom);
                c.translate(-face.left, -face.top);
                BirdPuppet.paint(
                  c,
                  const Rect.fromLTWH(0, 0, 256, 224),
                  bird: b,
                  wing: 0,
                  mood: mood,
                  beak: beak,
                );
                c.restore();
              }
            }
          },
          name: 'bird-$b-closeup',
        );
      }
      // The bird is BirdFlightMotion.size (.145) of the screen's height: a
      // 360, 440 and 620 px high phone.
      for (final h in [360, 440, 620]) {
        final bw = h * .145;
        final cell = (bw * 1.3).ceilToDouble();
        await savePixels(
          'birds-gameplay-$h',
          (cell * 16).toInt(),
          (cell * 5).toInt(),
          (c) {
            c.drawColor(SkyColors.sky, BlendMode.src);
            for (final (row, mood) in StoryMood.values.indexed) {
              for (var b = 0; b < 4; b++) {
                for (var beak = 0; beak <= BirdPuppet.beaks; beak++) {
                  final x = (b * 4 + beak) * cell, y = row * cell;
                  BirdPuppet.paint(
                    c,
                    Rect.fromLTWH(
                      x + cell * .12,
                      y + cell * .1,
                      bw,
                      bw * 224 / 256,
                    ),
                    bird: b,
                    wing: 0,
                    mood: mood,
                    beak: beak,
                  );
                }
              }
            }
          },
          zoom: h == 620 ? 2 : 3,
        );
      }
    });

    test('bosses: silence, then moods by mouth frames', () async {
      if (!capture) return;
      for (final kind in FlightVoices.voicedBosses) {
        // Close-up: moods (rows) by mouth frames (columns), silence first.
        const cw = 300.0, ch = 260.0;
        // The Empress and the Captain have small faces: closer.
        final h = switch (kind) {
          BossKind.duskMoth || BossKind.pirate => 1300.0,
          _ => 900.0,
        };
        await raster((cw * 5).toInt(), (ch * 5).toInt(), (c) {
          for (final (row, mood) in StoryMood.values.indexed) {
            for (var col = 0; col < 5; col++) {
              paintBoss(
                c,
                calm(kind),
                Rect.fromLTWH(col * cw, row * ch, cw, ch),
                h,
                speech: col == 0 ? null : say(kind, mood, col - 1),
                focus: faceOf(kind),
              );
            }
          }
        }, name: 'boss-${kind.name}-closeup');
        // At gameplay size (a 360 px high phone), the whole boss.
        const gw = 200.0, gh = 200.0;
        await savePixels(
          'boss-${kind.name}-gameplay',
          (gw * 5).toInt(),
          (gh * 5).toInt(),
          (c) {
            for (final (row, mood) in StoryMood.values.indexed) {
              for (var col = 0; col < 5; col++) {
                paintBoss(
                  c,
                  calm(kind),
                  Rect.fromLTWH(col * gw, row * gh, gw, gh),
                  360,
                  speech: col == 0 ? null : say(kind, mood, col - 1),
                  focus: faceOf(kind) * .6,
                );
              }
            }
          },
          zoom: 2,
        );
      }
    });

    test('talking through real lines, 50 ms a frame', () async {
      if (!capture) return;
      // Pip cheering a boss down, at gameplay size on a 360 px phone.
      const clip = 'pip-boss-down-01', frames = 40;
      const bw = 360 * .145, cell = 68.0;
      await savePixels(
        'strip-pip-$clip',
        (cell * 10).toInt(),
        (cell * frames / 10).toInt(),
        (c) {
          c.drawColor(SkyColors.sky, BlendMode.src);
          for (var i = 0; i < frames; i++) {
            final s = spoken(clip, i);
            BirdPuppet.paint(
              c,
              Rect.fromLTWH(
                i % 10 * cell + 8,
                i ~/ 10 * cell + 8,
                bw,
                bw * 224 / 256,
              ),
              bird: 0,
              wing: 0,
              mood: s.mood,
              beak: s.mouth,
            );
          }
        },
      );
      for (final (kind, line) in [
        (BossKind.baronBat, 'baron-gloat-01'),
        (BossKind.duskMoth, 'empress-taunt-01'),
        (BossKind.dragon, 'dragon-hurt-01'),
      ]) {
        const cw = 120.0, ch = 110.0, count = 30;
        await savePixels(
          'strip-${kind.name}-$line',
          (cw * 10).toInt(),
          (ch * count / 10).toInt(),
          (c) {
            for (var i = 0; i < count; i++) {
              // The boss's own clock runs with the line.
              final b = calm(kind)..age += i * .05;
              paintBoss(
                c,
                b,
                Rect.fromLTWH(i % 10 * cw, i ~/ 10 * ch, cw, ch),
                360,
                speech: spoken(line, i, boss: kind),
                focus: faceOf(kind),
              );
            }
          },
        );
      }
    });

    testWidgets('whole game frames with a line being said', (tester) async {
      if (!capture) return;
      await gameFrame(
        tester,
        flying(),
        speech: () => spoken('pip-boss-down-01', 13),
        name: 'game-bird-talking',
      );
      await gameFrame(
        tester,
        flying(),
        bird: 2,
        speech: () => say(null, StoryMood.angry, 3),
        name: 'game-minty-angry',
      );
      for (final (kind, line, frame) in [
        (BossKind.baronBat, 'baron-gloat-01', 26),
        (BossKind.pirate, 'captain-taunt-01', 12),
        (BossKind.dragon, 'dragon-hurt-01', 5),
      ]) {
        final s = spoken(line, frame, boss: kind);
        await gameFrame(
          tester,
          flying(boss: calm(kind)),
          speech: () => s,
          name: 'game-${kind.name}-talking',
        );
      }
      expect(tester.takeException(), isNull);
    });
  });
}
