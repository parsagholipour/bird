import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/game/bird_game.dart';
import 'package:push_up_bird/game/combat_art.dart';
import 'package:push_up_bird/game/enemy_art.dart';
import 'package:push_up_bird/game/enemy_hit_art.dart';
import 'package:push_up_bird/ui/theme.dart';

/// Visual review for a small enemy surviving a rock hit.
///
/// Frame strips step through the reaction every 1/60 s at close-up and at
/// actual gameplay size, over daylight and dusk skies, and real 800x360 game
/// frames show several enemies mid-reaction. PNGs are written to
/// `build/visual-review/enemy-polish-hit/`.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final folder = Directory('build/visual-review/enemy-polish-hit');

  Future<ui.Image> image(void Function(Canvas) draw, int width, int height) {
    final recorder = ui.PictureRecorder();
    draw(Canvas(recorder));
    final picture = recorder.endRecording();
    final result = picture.toImage(width, height);
    picture.dispose();
    return result;
  }

  Future<List<int>> pixels(
    void Function(Canvas) draw, {
    int width = 240,
    int height = 200,
  }) async {
    final raster = await image(draw, width, height);
    final bytes = (await raster.toByteData())!.buffer.asUint8List();
    raster.dispose();
    return bytes;
  }

  Future<void> save(
    String name,
    void Function(Canvas) draw,
    int width,
    int height,
  ) async {
    folder.createSync(recursive: true);
    final raster = await image(draw, width, height);
    final png = (await raster.toByteData(
      format: ui.ImageByteFormat.png,
    ))!.buffer.asUint8List();
    File('${folder.path}/$name.png').writeAsBytesSync(png);
    raster.dispose();
  }

  Future<void> fonts() async {
    for (final family in ['Fredoka', 'Nunito']) {
      await (FontLoader(
        family,
      )..addFont(rootBundle.load('assets/fonts/$family.ttf'))).load();
    }
  }

  // A hit enemy centred at (120, 110) in a 240x200 raster, radius 18 px. The
  // wing pose is the same for every hit age, so only the reaction differs.
  SkyEnemy hitEnemy(int appearance, double hitAge) {
    final enemy = SkyEnemy(x: 1, y: .5, appearance: appearance)..age = 1;
    if (hitAge >= 0) enemy.lastHitAt = enemy.age - hitAge;
    return enemy;
  }

  void body(Canvas c, SkyEnemy enemy, {required bool reduced}) {
    const height = 400.0;
    c.translate(120 - enemy.x * height, 110 - .5 * height);
    EnemyArt.paint(c, height, enemy, birdY: .5, reducedMotion: reduced);
  }

  testWidgets('a surviving enemy gets a short, exact hit reaction', (
    tester,
  ) async {
    await tester.runAsync(() async {
      for (var appearance = 0; appearance < 4; appearance++) {
        for (final reduced in [false, true]) {
          final rest = await pixels(
            (c) => body(c, hitEnemy(appearance, -1), reduced: reduced),
          );
          for (final age in [0.0, .016, .05, .12, .2]) {
            final frame = await pixels(
              (c) => body(c, hitEnemy(appearance, age), reduced: reduced),
            );
            expect(
              frame,
              isNot(equals(rest)),
              reason: 'hit is visible at $age ($appearance, $reduced)',
            );
            expect(
              await pixels(
                (c) => body(c, hitEnemy(appearance, age), reduced: reduced),
              ),
              frame,
              reason: 'paused hit frame is exact',
            );
          }
          expect(
            await pixels(
              (c) => body(
                c,
                hitEnemy(appearance, EnemyHitArt.hitSeconds),
                reduced: reduced,
              ),
            ),
            rest,
            reason: 'nothing remains after hitSeconds',
          );
        }
        // Reduced Motion: a stationary acknowledgement, no motion or flash.
        expect(
          await pixels(
            (c) => body(c, hitEnemy(appearance, .01), reduced: true),
          ),
          await pixels(
            (c) => body(c, hitEnemy(appearance, .12), reduced: true),
          ),
          reason: 'Reduced Motion hit mark holds still',
        );
        // The flash frame keeps a solid body with its dark outline. Measured
        // at close-up, right of the impact accents, against the rest pose.
        Future<List<int>> closeUp(double hitAge) => pixels(
          (c) {
            const height = 800.0;
            c.translate(240 - height, 220 - .5 * height);
            EnemyArt.paint(
              c,
              height,
              hitEnemy(appearance, hitAge),
              birdY: .5,
              reducedMotion: false,
            );
          },
          width: 480,
          height: 400,
        );
        final rest = await closeUp(-1);
        final flash = await closeUp(0);
        int count(List<int> p, bool Function(int i) test) {
          var n = 0;
          for (var i = 0; i < p.length; i += 4) {
            if ((i ~/ 4) % 480 > 240 && test(i)) n++;
          }
          return n;
        }

        double lum(List<int> p, int i) =>
            p[i] * .2126 + p[i + 1] * .7152 + p[i + 2] * .0722;
        expect(
          count(flash, (i) => flash[i + 3] > 250),
          greaterThan(count(rest, (i) => rest[i + 3] > 250) * .85),
          reason: 'flash keeps the silhouette opaque ($appearance)',
        );
        expect(
          count(flash, (i) => flash[i + 3] > 200 && lum(flash, i) < 80),
          greaterThan(
            count(rest, (i) => rest[i + 3] > 200 && lum(rest, i) < 60) * .4,
          ),
          reason: 'flash keeps an ink outline ($appearance)',
        );
      }
    });
  });

  testWidgets('hit reaction review strips', (tester) async {
    await tester.runAsync(() async {
      await fonts();
      for (final reduced in [false, true]) {
        final suffix = reduced ? '-reduced' : '';
        await save(
          'strip-gameplay$suffix',
          (c) => _strip(c, 360, _gameplayAges, 92, 78, reduced: reduced),
          130 + 92 * _gameplayAges.length,
          60 + 78 * 12,
        );
        await save(
          'strip-closeup$suffix',
          (c) => _strip(c, 800, _closeAges, 200, 170, reduced: reduced),
          130 + 200 * _closeAges.length,
          60 + 170 * 8,
        );
      }
    });
  });

  testWidgets('hit reaction in the actual game', (tester) async {
    tester.view.physicalSize = const Size(800, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final (name, elapsed) in [('day', 5.0), ('dusk', 21.0)]) {
      final sim = FlightSimulation(rules: TapFlyMode(), practice: true)
        ..phase = RunPhase.playing
        ..elapsed = elapsed;
      const spots = [(1.02, .25), (1.40, .52), (1.78, .30), (1.95, .72)];
      for (var kind = 0; kind < 4; kind++) {
        sim.enemies.add(
          SkyEnemy(
            x: spots[kind].$1,
            y: spots[kind].$2,
            appearance: (kind + 3) % 4,
            flightPhase: kind * 2.399963,
          )..age = 1.8,
        );
      }
      final game = BirdGame(
        simulation: sim,
        nowMs: () => 0,
        bird: 0,
        reducedMotion: false,
        playback: true,
        onChanged: () {},
      );
      await tester.pumpWidget(GameWidget(game: game));
      await tester.runAsync(() async {
        await game.loaded;
        game.pauseEngine();
        folder.createSync(recursive: true);
        Future<void> capture(String file) async {
          final recorder = ui.PictureRecorder();
          game.render(Canvas(recorder));
          final picture = recorder.endRecording();
          final raster = await picture.toImage(800, 360);
          final bytes = (await raster.toByteData(
            format: ui.ImageByteFormat.png,
          ))!.buffer.asUint8List();
          File('${folder.path}/$file.png').writeAsBytesSync(bytes);
          raster.dispose();
          picture.dispose();
        }

        await capture('in-game-$name-rest');
        for (final enemy in sim.enemies) {
          enemy.takeDamage(1);
        }
        // Every 1/60 s through the reaction, all four enemies in step.
        for (var frame = 0; frame <= 18; frame++) {
          for (final enemy in sim.enemies) {
            enemy.age = enemy.lastHitAt + frame / 60;
          }
          await capture('in-game-$name-f${frame.toString().padLeft(2, '0')}');
        }
        // One staggered frame, as seen during real play.
        for (var i = 0; i < sim.enemies.length; i++) {
          final enemy = sim.enemies[i];
          enemy.age = enemy.lastHitAt + const [.0, .033, .083, .15][i];
        }
        await capture('in-game-$name');
      });
      await tester.pumpWidget(const SizedBox());
    }
    expect(tester.takeException(), isNull);
  });
}

const _gameplayAges = [
  -1.0, 0.0, 1 / 60, 2 / 60, 3 / 60, 4 / 60, 5 / 60, 6 / 60, 7 / 60, 8 / 60, //
  9 / 60, 10 / 60, 11 / 60, 12 / 60, 13 / 60, 14 / 60, 15 / 60, 16 / 60,
  17 / 60, .30,
];
const _closeAges = [
  -1.0, 0.0, 1 / 60, 2 / 60, 3 / 60, 4 / 60, 5 / 60, 6 / 60, 8 / 60, //
  10 / 60, 12 / 60, 14 / 60, 16 / 60,
];

const _skies = [
  ('day', Color(0xffbde9f6)),
  ('horizon', Color(0xfff6efd9)),
  ('dusk', Color(0xffaaa9e0)),
];

void _strip(
  Canvas c,
  double height,
  List<double> ages,
  double cellW,
  double cellH, {
  required bool reduced,
}) {
  final kinds = height > 400 ? 4 : 4;
  final skies = height > 400 ? _skies.sublist(0, 2) : _skies;
  final rows = kinds * skies.length;
  c.drawPaint(Paint()..color = const Color(0xfff2eedf));
  _text(
    c,
    'HIT REACTION${reduced ? ' · REDUCED MOTION' : ''} · '
    '${height > 400 ? 'CLOSE-UP' : 'GAMEPLAY SIZE (360 px viewport)'}',
    const Offset(14, 14),
    18,
  );
  for (var col = 0; col < ages.length; col++) {
    final age = ages[col];
    _text(
      c,
      age < 0
          ? 'before'
          : age >= EnemyHitArt.hitSeconds
          ? 'settled'
          : '${(age * 1000).round()}ms',
      Offset(130 + col * cellW + 6, 42),
      12,
    );
  }
  for (var row = 0; row < rows; row++) {
    final appearance = const [3, 0, 1, 2][row ~/ skies.length];
    final (sky, color) = skies[row % skies.length];
    final top = 60 + row * cellH;
    c.drawRect(
      Rect.fromLTWH(0, top, 130 + ages.length * cellW, cellH),
      Paint()..color = color,
    );
    _text(
      c,
      '${EnemyKind.values[appearance].name}\n$sky',
      Offset(8, top + 6),
      11,
    );
    for (var col = 0; col < ages.length; col++) {
      final left = 130 + col * cellW;
      c.drawLine(
        Offset(left, top),
        Offset(left, top + cellH),
        Paint()..color = const Color(0x22000000),
      );
      final sim = FlightSimulation(rules: TapFlyMode(), practice: true)
        ..elapsed = 2;
      final enemy = SkyEnemy(x: 1, y: .5, appearance: appearance, maxHp: 30)
        ..age = 1;
      if (ages[col] >= 0) {
        enemy.takeDamage(10);
        enemy.age += ages[col];
      }
      sim.enemies.add(enemy);
      c.save();
      c.clipRect(Rect.fromLTWH(left, top, cellW, cellH));
      c.translate(
        left + cellW * .56 - height,
        top + cellH * (height > 400 ? .6 : .62) - .5 * height,
      );
      CombatArt.paint(c, height, sim, reducedMotion: reduced);
      c.restore();
    }
  }
}

void _text(
  Canvas c,
  String text,
  Offset at,
  double size, {
  Color color = SkyColors.ink,
}) {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        fontFamily: 'Nunito',
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: color,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  painter.paint(c, at);
}
