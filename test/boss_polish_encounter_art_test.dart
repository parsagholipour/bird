import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/tracking.dart';
import 'package:push_up_bird/game/bird_game.dart';
import 'package:push_up_bird/game/boss_encounter_art.dart';
import 'package:push_up_bird/game/boss_motion.dart';

import 'boss_fight_test.dart' show arena;

/// Director's review of the cinematic staging: every beat of every boss,
/// rendered through the real game at phone sizes. Set CAPTURE_BOSS_POLISH to
/// write PNGs (and contact sheets) to build/visual-review/boss-polish/encounter.
const _capture = bool.fromEnvironment('CAPTURE_BOSS_POLISH');
const _folder = 'build/visual-review/boss-polish/encounter';

const _names = {1: 'baron-bat', 2: 'spitter-king', 3: 'dusk-empress'};

/// Beats before defeat are staged on the boss clock; the rest on death time.
const _arrival = <(String, double)>[
  ('warning', .9),
  ('arriving', 1.42),
  ('reveal', 2.05),
  ('roar', 2.85),
  ('title', 3.7),
  ('ready', 4.3),
];
const _death = <(String, double)>[
  ('defeat-hit', .12),
  ('defeat-gather', .6),
  ('burst', .9),
  ('burst-late', 1.2),
  ('crown-fall', 1.6),
  ('victory', 2.3),
  ('victory-late', 3.1),
];

class _Stage {
  _Stage(this.game, this.sim, this.width);
  final BirdGame game;
  final FlightSimulation sim;
  final double width;

  void hover(double seconds) {
    for (var i = 0; i < (seconds / .02).round(); i++) {
      final now = (sim.elapsed + .02) * 1000;
      sim.birdY = .5;
      sim.velocity = 0;
      sim.hearts = 3;
      sim.apply(
        const MovementInput(valid: true),
        TrackingSample(
          mode: PlayMode.touch,
          timestampMs: now,
          receivedMs: now,
          joints: const [],
        ),
        now,
      );
      sim.tick(.02, now, viewportWidth: width / 360);
    }
  }

  void hoverTo(double age) => hover(age - sim.boss!.age);

  Future<ui.Image> frame() async {
    final recorder = ui.PictureRecorder();
    game.render(ui.Canvas(recorder));
    final picture = recorder.endRecording();
    final image = await picture.toImage(width.toInt(), 360);
    picture.dispose();
    return image;
  }
}

Future<void> _fonts() async {
  for (final family in ['Fredoka', 'Nunito']) {
    await (FontLoader(
      family,
    )..addFont(rootBundle.load('assets/fonts/$family.ttf'))).load();
  }
}

Future<_Stage> _stage(
  WidgetTester tester,
  int bossNumber,
  double width, {
  required bool reduced,
}) async {
  final sim = arena(version: FlightSimulation.currentRulesVersion)
    ..elapsed = FlightSimulation.bossInterval - .001
    ..bossesDefeated = bossNumber - 1;
  final game = BirdGame(
    simulation: sim,
    nowMs: () => 0,
    bird: 0,
    reducedMotion: reduced,
    playback: true,
    onChanged: () {},
  );
  await tester.pumpWidget(GameWidget<BirdGame>(game: game));
  await game.loaded;
  game.pauseEngine();
  final stage = _Stage(game, sim, width)..hover(.02);
  expect(sim.boss, isNotNull);
  expect(sim.boss!.cinematic, isTrue);
  return stage;
}

/// Walks one boss through the whole encounter, handing each beat to [shot].
Future<void> _timeline(
  _Stage s,
  Future<void> Function(String beat) shot,
) async {
  for (final (beat, age) in _arrival) {
    s.hoverTo(age);
    await shot(beat);
  }
  final boss = s.sim.boss!;
  s.hoverTo(boss.arrivalDuration + 1.2);
  expect(boss.phase, BossPhase.attacking);
  // The moth's veil cycle: fight in the opening, not behind the shield.
  if (boss.isMoth) s.hoverTo(boss.arrivalDuration + 2.2);
  await shot('fighting');
  boss.fireIn = .12;
  await shot('charging');
  boss.fireIn = 2;
  s.hover(.3);
  boss.hp = boss.maxHp ~/ 2 + 3;
  s.sim.rocks.add(BirdRock(x: boss.x - .07, y: boss.y));
  s.hover(.02);
  expect(boss.enraged, isTrue);
  s.hover(.5);
  await shot('enraged');
  s.sim.enemies.clear();
  s.sim.bossAmmo.clear();
  s.sim.rocks.addAll(
    List.generate(boss.hp, (_) => BirdRock(x: boss.x - .07, y: boss.y)),
  );
  s.hover(.02);
  expect(boss.phase, BossPhase.defeated);
  for (final (beat, death) in _death) {
    s.hover(death - (boss.age - boss.defeatedAt!));
    await shot(beat);
  }
}

Future<Uint8List> _png(ui.Image image) async =>
    (await image.toByteData(format: ui.ImageByteFormat.png))!.buffer
        .asUint8List();

Future<Uint8List> _raw(ui.Image image) async =>
    (await image.toByteData())!.buffer.asUint8List();

Future<void> _sheet(String name, List<(String, ui.Image)> frames) async {
  const cols = 4, scale = .5;
  final fw = frames.first.$2.width * scale, fh = 360 * scale;
  final rows = (frames.length / cols).ceil();
  final recorder = ui.PictureRecorder();
  final c = ui.Canvas(recorder);
  c.drawRect(
    Rect.fromLTWH(0, 0, fw * cols, (fh + 18) * rows),
    Paint()..color = const Color(0xff101223),
  );
  for (var i = 0; i < frames.length; i++) {
    final (label, image) = frames[i];
    final at = Offset(i % cols * fw, (i ~/ cols) * (fh + 18));
    c.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(at.dx, at.dy + 18, fw - 2, fh - 2),
      Paint()..filterQuality = FilterQuality.medium,
    );
    (TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          fontFamily: 'Nunito',
          fontSize: 12,
          color: Color(0xffffffff),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout()).paint(c, at + const Offset(4, 2));
  }
  final picture = recorder.endRecording();
  final image = await picture.toImage(
    (fw * cols).toInt(),
    ((fh + 18) * rows).toInt(),
  );
  File('$_folder/$name.png').writeAsBytesSync(await _png(image));
  image.dispose();
  picture.dispose();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final bossNumber in [1, 2, 3]) {
    for (final width in [640.0, 800.0]) {
      for (final reduced in [false, true]) {
        if (reduced && width == 800) continue;
        final label =
            '${_names[bossNumber]}-${width.toInt()}${reduced ? '-reduced' : ''}';
        testWidgets('$label renders every cinematic beat', (tester) async {
          tester.view.physicalSize = ui.Size(width, 360);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await tester.runAsync(() async {
            await _fonts();
            if (_capture) Directory(_folder).createSync(recursive: true);
            final s = await _stage(tester, bossNumber, width, reduced: reduced);
            final frames = <(String, ui.Image)>[];
            await _timeline(s, (beat) async {
              final image = await s.frame();
              final png = await _png(image);
              expect(png.length, greaterThan(2000));
              if (_capture) {
                File('$_folder/$label-$beat.png').writeAsBytesSync(png);
                frames.add((beat, image));
              } else {
                image.dispose();
              }
            });
            if (_capture) {
              await _sheet('sheet-$label', frames);
              for (final (_, image) in frames) {
                image.dispose();
              }
            }
          });
          await tester.pumpWidget(const SizedBox());
        });
      }
    }
  }

  testWidgets('staging is deterministic across independent replays', (
    tester,
  ) async {
    tester.view.physicalSize = const ui.Size(640, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.runAsync(() async {
      await _fonts();
      for (final bossNumber in [1, 2, 3]) {
        final runs = <Map<String, Uint8List>>[];
        for (var run = 0; run < 2; run++) {
          final s = await _stage(tester, bossNumber, 640, reduced: false);
          final frames = <String, Uint8List>{};
          await _timeline(s, (beat) async {
            final image = await s.frame();
            frames[beat] = await _raw(image);
            // Rendering twice from the same state must not advance anything.
            final again = await s.frame();
            expect(await _raw(again), frames[beat], reason: beat);
            again.dispose();
            image.dispose();
          });
          runs.add(frames);
        }
        for (final beat in runs.first.keys) {
          expect(
            runs[1][beat],
            runs[0][beat],
            reason: '${_names[bossNumber]} $beat',
          );
        }
      }
    });
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Reduced Motion keeps the staging still', (tester) async {
    await tester.runAsync(() async {
      await _fonts();
      Future<Uint8List> draw(
        SkyBoss boss,
        void Function(Canvas, Size, FlightSimulation, BossMotion) layer,
      ) async {
        final sim = arena()..boss = boss;
        final recorder = ui.PictureRecorder();
        layer(
          Canvas(recorder),
          const Size(640, 360),
          sim,
          BossMotion(boss, reducedMotion: true),
        );
        final picture = recorder.endRecording();
        final image = await picture.toImage(640, 360);
        final bytes = await _raw(image);
        image.dispose();
        picture.dispose();
        return bytes;
      }

      void backdrop(Canvas c, Size s, FlightSimulation sim, BossMotion m) =>
          BossEncounterArt.backdrop(c, s, m.boss, m);
      for (final kind in BossKind.values) {
        SkyBoss boss(double age) =>
            SkyBoss(number: 1, x: 1.4, kind: kind, cinematic: true)
              ..age = age
              ..fireIn = 5;
        // The storm frame does not drift or flash while motion is reduced.
        // (The Gargoyle's warning is a STATE and shows under Reduced Motion:
        // judged in his perch, 1.4 s and 1.9 s into the fight.)
        final (stormA, stormB) = kind == BossKind.searchlightGargoyle ? (6.0, 6.5) : (6.0, 7.3);
        expect(await draw(boss(stormA), backdrop), await draw(boss(stormB), backdrop));
        expect(
          await draw(boss(1.3), backdrop),
          await draw(boss(1.5), backdrop),
          reason: 'no lightning strike',
        );
        // The name card fades in place rather than sliding.
        Offset leftmost(Uint8List p) {
          for (var x = 0; x < 640; x++) {
            for (var y = 40; y < 160; y++) {
              if (p[(y * 640 + x) * 4 + 3] > 12) return Offset(x * 1, y * 1);
            }
          }
          return const Offset(-1, -1);
        }

        // The dragon's, King Coo's, the Gargoyle's and Neferhoo's own cards
        // slam in on their roars (2.85 s), so they are judged once they are
        // there.
        final (cardA, cardB) = kind == BossKind.kingCoo
            ? (3.4, 3.9)
            : kind == BossKind.dragon ||
                  kind == BossKind.searchlightGargoyle ||
                  kind == BossKind.neferhoo
            ? (3.0, 3.5)
            : (2.0, 3.0);
        expect(
          leftmost(await draw(boss(cardA), BossEncounterArt.foreground)).dx,
          leftmost(await draw(boss(cardB), BossEncounterArt.foreground)).dx,
        );
        // The defeat burst holds its shape; it only fades.
        Future<Offset> centroid(double death) async {
          final b = boss(10)
            ..x = 1
            ..defeatedAt = 10 - death;
          final p = await draw(b, BossEncounterArt.paint);
          var sx = 0.0, sy = 0.0, n = 0.0;
          for (var i = 0; i < p.length; i += 4) {
            final a = p[i + 3] / 255;
            if (a < .1) continue;
            final px = (i ~/ 4) % 640, py = (i ~/ 4) ~/ 640;
            // The pirate's sea drains by the rules across the whole width;
            // judge only his burst.
            if (kind == BossKind.pirate &&
                (Offset(px * 1.0, py * 1.0) - const Offset(360, 180)).distance >
                    150) {
              continue;
            }
            sx += px * a;
            sy += py * a;
            n += a;
          }
          return n == 0 ? Offset.zero : Offset(sx / n, sy / n);
        }

        final early = await centroid(1.0), late = await centroid(1.45);
        expect((early - late).distance, lessThan(6), reason: '$kind');
      }
    });
  });
}
