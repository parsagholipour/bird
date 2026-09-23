import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/game/bird_game.dart';
import 'package:push_up_bird/game/obstacle_art.dart';
import 'package:push_up_bird/game/sky_scenery.dart';
import 'package:push_up_bird/ui/theme.dart';
import 'experience_ui_test.dart' show capture;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    for (final family in ['Fredoka', 'Nunito']) {
      await (FontLoader(
        family,
      )..addFont(rootBundle.load('assets/fonts/$family.ttf'))).load();
    }
  });

  test(
    'every new silhouette leaves its actual moving lane visibly clear',
    () async {
      for (final kind in ObstacleKind.values) {
        for (final center in [.25, .5, .75]) {
          final obstacle = Obstacle(
            x: .3,
            center: center,
            gap: .36,
            kind: kind,
            amplitude: .065,
            width: kind.width,
          );
          for (final time in [0.0, 1.75, 5.25]) {
            obstacle.advance(time);
            final recorder = ui.PictureRecorder();
            ObstacleArt.paint(
              Canvas(recorder),
              obstacle,
              200,
              seconds: 25 + time,
              reducedMotion: false,
              cleared: false,
              perfect: false,
            );
            final picture = recorder.endRecording();
            final image = await picture.toImage(200, 200);
            final bytes = (await image.toByteData())!.buffer.asUint8List();
            final passages = obstacle.passages.toList();
            final upper = kind.floating
                ? obstacle.top
                : passages.map((p) => p.top).reduce(math.max);
            final lower = kind.floating
                ? obstacle.bottom
                : passages.map((p) => p.bottom).reduce(math.min);
            for (
              var y = (upper * 200).ceil() + 2;
              y < (lower * 200).floor() - 2;
              y++
            ) {
              for (
                var x = (obstacle.x * 200).ceil();
                x < ((obstacle.x + obstacle.width) * 200).floor();
                x++
              ) {
                expect(
                  bytes[(y * 200 + x) * 4 + 3],
                  0,
                  reason:
                      '$kind at $time must not draw in the safe flight lane',
                );
              }
            }
            for (final orb in obstacle.orbs) {
              final y = (orb.y * 200).floor(), x = (orb.x * 200).floor();
              if (y >= 0 && y < 200) expect(bytes[(y * 200 + x) * 4 + 3], 255);
            }
            image.dispose();
            picture.dispose();
          }
        }
      }
    },
  );

  test('obstacle design sheet renders every silhouette and its name', () async {
    final recorder = ui.PictureRecorder();
    final c = Canvas(recorder);
    c.drawRect(
      const Rect.fromLTWH(0, 0, 1120, 800),
      Paint()..color = SkyColors.cream,
    );
    for (var i = 0; i < ObstacleKind.values.length; i++) {
      final kind = ObstacleKind.values[i];
      c.save();
      c.translate((i % 4) * 280.0, (i ~/ 4) * 400.0);
      c.clipRect(const Rect.fromLTWH(10, 10, 260, 380));
      final seconds = [5.0, 25.0, 45.0][i % 3];
      SkyScenery.paint(
        c,
        const Size(280, 340),
        seconds: seconds,
        reducedMotion: true,
      );
      final o = Obstacle(
        x: 140 / 340 - kind.width / 2,
        center: .5,
        gap: .36,
        width: kind.width,
        kind: kind,
        amplitude: .065,
        appearance: i % 3,
      )..advance(1.75);
      ObstacleArt.paint(
        c,
        o,
        340,
        seconds: seconds,
        reducedMotion: true,
        cleared: false,
        perfect: false,
      );
      c.drawRect(
        const Rect.fromLTWH(10, 340, 260, 50),
        Paint()..color = SkyColors.cream,
      );
      final title = TextPainter(
        text: TextSpan(text: kind.title, style: heading(20)),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 246);
      title.paint(c, Offset(140 - title.width / 2, 356));
      c.restore();
    }
    final picture = recorder.endRecording();
    final image = await picture.toImage(1120, 800);
    if (const bool.fromEnvironment('CAPTURE_VISUALS')) {
      Directory('build/visual-review').createSync(recursive: true);
      File('build/visual-review/obstacle-variety.png').writeAsBytesSync(
        (await image.toByteData(
          format: ui.ImageByteFormat.png,
        ))!.buffer.asUint8List(),
      );
    }
    image.dispose();
    picture.dispose();
  });

  testWidgets(
    'old and new obstacle families render at phone size in every region',
    (tester) async {
      tester.view.physicalSize = const Size(1000, 450);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final sim =
          FlightSimulation(
              rules: TapFlyMode(),
              practice: true,
              course: FlightCourse.starTrail,
            )
            ..started = true
            ..phase = RunPhase.playing
            ..birdY = .5;
      final game = BirdGame(
        simulation: sim,
        nowMs: () => 0,
        bird: 0,
        reducedMotion: false,
        onChanged: () {},
        playback: true,
      );
      await tester.runAsync(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: RepaintBoundary(
              key: const ValueKey('visual-capture'),
              child: GameWidget(game: game),
            ),
          ),
        );
        await game.loaded;
      });
      for (final family in [
        ObstacleKind.values.take(4),
        ObstacleKind.values.skip(4),
      ]) {
        sim.obstacles.clear();
        for (final (i, kind) in family.indexed) {
          sim.obstacles.add(
            Obstacle(
              x: .7 + i * .44,
              center: i.isEven ? .42 : .62,
              gap: .4,
              width: kind.width,
              kind: kind,
              amplitude: kind == ObstacleKind.garden ? 0 : .065,
              appearance: i,
            ),
          );
        }
        for (final time in [5.0, 25.0, 45.0]) {
          sim.elapsed = time;
          for (final o in sim.obstacles) {
            o.advance(time);
          }
          await tester.pump(const Duration(milliseconds: 16));
          expect(tester.takeException(), isNull);
          await capture(tester, 'variety-${family.first.name}-${time.toInt()}');
        }
      }
      await tester.pumpWidget(const SizedBox());
    },
  );
}
