import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flame/game.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/tracking.dart';
import 'package:push_up_bird/game/bird_game.dart';
import 'package:push_up_bird/game/boss_audio_cues.dart';
import 'boss_fight_test.dart' show arena;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final bossNumber in [1, 2]) {
    testWidgets(
      'boss $bossNumber storyboard renders entrance, combat, burst and aftermath',
      (tester) async {
        tester.view.physicalSize = const ui.Size(800, 360);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.runAsync(() async {
          for (final family in ['Fredoka', 'Nunito']) {
            await (FontLoader(
              family,
            )..addFont(rootBundle.load('assets/fonts/$family.ttf'))).load();
          }
          final capture = bossNumber == 1
              ? const bool.fromEnvironment('CAPTURE_BOSS_MOVIE')
              : const bool.fromEnvironment('CAPTURE_SPITTER_BOSS_MOVIE');
          final folder = Directory(
            'build/visual-review/${bossNumber == 1 ? 'boss' : 'spitter-boss'}-movie',
          );
          if (capture) folder.createSync(recursive: true);
          final sim = arena(version: FlightSimulation.currentRulesVersion)
            ..elapsed = FlightSimulation.bossInterval - .001
            ..bossesDefeated = bossNumber - 1;
          final game = BirdGame(
            simulation: sim,
            nowMs: () => 0,
            bird: 0,
            reducedMotion: false,
            playback: true,
            onChanged: () {},
          );
          await tester.pumpWidget(GameWidget<BirdGame>(game: game));
          await game.loaded;
          game.pauseEngine();
          final cueClock = BossAudioCues();
          final cues = <Map<String, Object>>[];
          final renderTimes = <int>[];
          final keyframes = {20, 42, 65, 88, 145, 205, 265, 291, 331};
          var rendered = 0;
          double now = sim.elapsed * 1000;
          // A director's preview: normal inputs during combat, with staged final
          // hits at 8.8s to demonstrate the full death sequence in a short movie.
          for (var frame = 0; frame < 410; frame++) {
            now += 1000 / 30;
            sim.apply(
              MovementInput(
                valid: true,
                flap: sim.birdY > .56 && sim.velocity > 0,
              ),
              TrackingSample(
                mode: PlayMode.touch,
                timestampMs: now,
                receivedMs: now,
                joints: const [],
              ),
              now,
            );
            if (sim.canShoot && frame % 11 == 0) sim.shoot();
            if (sim.boss case final boss?) {
              if (frame == 220 || frame == 264) {
                sim.rocks.addAll(
                  List.generate(
                    frame == 220 ? (bossNumber == 1 ? 4 : 9) : boss.hp,
                    (_) => BirdRock(x: boss.x - .07, y: boss.y),
                  ),
                );
              }
            }
            sim.tick(1 / 30, now, viewportWidth: 800 / 360);
            for (final cue in cueClock.advance(sim.boss)) {
              cues.add({'time': frame / 30, 'cue': cue});
            }
            if (!capture && !keyframes.contains(frame)) continue;
            final timer = Stopwatch()..start();
            final recorder = ui.PictureRecorder();
            game.render(ui.Canvas(recorder));
            final picture = recorder.endRecording();
            final image = await picture.toImage(800, 360);
            renderTimes.add(timer.elapsedMicroseconds);
            final bytes = (await image.toByteData(
              format: ui.ImageByteFormat.png,
            ))!.buffer.asUint8List();
            expect(bytes.length, greaterThan(2000));
            if (capture) {
              File(
                '${folder.path}/frame-${frame.toString().padLeft(4, '0')}.png',
              ).writeAsBytesSync(bytes);
            }
            image.dispose();
            picture.dispose();
            rendered++;
          }
          expect(rendered, capture ? 410 : keyframes.length);
          expect(sim.bossesDefeated, bossNumber);
          expect(sim.boss, isNull);
          expect(sim.phase, RunPhase.playing);
          if (capture) {
            File(
              '${folder.path}/cues.json',
            ).writeAsStringSync(jsonEncode(cues));
            renderTimes.sort();
            File('${folder.path}/render-timing.txt').writeAsStringSync(
              'Host Flutter test rasterization, not device FPS. 800x360, ${renderTimes.length} frames. '
              'Median ${renderTimes[renderTimes.length ~/ 2]}us; p95 ${renderTimes[(renderTimes.length * .95).floor()]}us.\n',
            );
          }
        });
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
}
