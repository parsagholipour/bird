import 'dart:io';
import 'dart:ui' as ui;
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/game/bird_game.dart';
import 'boss_polish_health_bar_art_test.dart' show bossAfter, drawHudZones;

const _folder = 'build/visual-review/boss-polish/health-bar';

/// The boss plate over real game frames, with the flight HUD's reserved
/// corners outlined.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    for (final family in ['Fredoka', 'Nunito']) {
      await (FontLoader(
        family,
      )..addFont(rootBundle.load('assets/fonts/$family.ttf'))).load();
    }
  });

  Future<void> save(void Function(Canvas) draw, String name, Size size) async {
    final recorder = ui.PictureRecorder();
    draw(Canvas(recorder));
    final shot = await recorder.endRecording().toImage(
      size.width.round(),
      size.height.round(),
    );
    final png = (await shot.toByteData(
      format: ui.ImageByteFormat.png,
    ))!.buffer.asUint8List();
    final file = File('$_folder/$name.png')..parent.createSync(recursive: true);
    file.writeAsBytesSync(png);
    shot.dispose();
  }

  testWidgets('boss plate in the actual game', (tester) async {
    for (final size in [const Size(640, 360), const Size(800, 360)]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final sim = FlightSimulation(rules: TapFlyMode(), practice: true)
        ..phase = RunPhase.playing
        ..started = true
        ..elapsed = FlightSimulation.bossInterval;
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
        for (final (name, boss) in [
          (
            'baron-bat-chip',
            bossAfter(BossKind.baronBat, 1, hits: [.2], since: .22),
          ),
          (
            'spitter-king-fury',
            bossAfter(BossKind.spitterBeetle, 2, fight: 2, hits: [.3, .32]),
          ),
          (
            'dusk-empress-warning',
            bossAfter(BossKind.duskMoth, 3, fight: 4.7, hits: [.1]),
          ),
          (
            'dusk-empress-shielded',
            bossAfter(BossKind.duskMoth, 3, fight: 5.6, hits: [.1]),
          ),
        ]) {
          boss.y = .55;
          boss.x = 1.45 * size.width / 800;
          sim.boss = boss;
          sim.elapsed = FlightSimulation.bossInterval + boss.age;
          await save(
            (c) {
              game.render(c);
              drawHudZones(c, size);
            },
            'in-game/$name-${size.width.toInt()}',
            size,
          );
        }
      });
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    }
  });
}
