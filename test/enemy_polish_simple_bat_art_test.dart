import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/game/bird_game.dart';
import 'package:push_up_bird/game/enemy_art.dart';
import 'package:push_up_bird/game/enemy_designs/simple_bat.dart';
import 'package:push_up_bird/game/sky_scenery.dart';

/// Visual review for the simple purple bat (EnemyKind.simpleBat).
///
/// Writes PNGs to build/visual-review/enemy-polish/simple-bat/ and checks the
/// silhouette budget, determinism and Reduced Motion.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final folder = Directory('build/visual-review/enemy-polish/simple-bat');

  Future<Uint8List> raster(
    void Function(Canvas) draw, {
    required int width,
    required int height,
    String? name,
  }) async {
    final recorder = ui.PictureRecorder();
    draw(Canvas(recorder));
    final picture = recorder.endRecording();
    final image = await picture.toImage(width, height);
    final pixels = (await image.toByteData())!.buffer.asUint8List();
    if (name != null) {
      folder.createSync(recursive: true);
      final png = (await image.toByteData(
        format: ui.ImageByteFormat.png,
      ))!.buffer.asUint8List();
      File('${folder.path}/$name.png').writeAsBytesSync(png);
    }
    image.dispose();
    picture.dispose();
    return pixels;
  }

  // Painted bounds in hit-radius units of one pose, from non-transparent pixels.
  const r = 100.0, boxW = 600, boxH = 400;
  Future<Rect> bounds(
    double seconds, {
    bool reduced = false,
    double lookY = 0,
    double charge = 0,
    double recoil = 0,
  }) async {
    final pixels = await raster(
      (c) {
        c.translate(boxW / 2, boxH / 2);
        SimpleBatArt.paint(
          c,
          r,
          seconds: seconds,
          reducedMotion: reduced,
          lookY: lookY,
          charge: charge,
          recoil: recoil,
        );
      },
      width: boxW,
      height: boxH,
    );
    var left = boxW, top = boxH, right = -1, bottom = -1;
    for (var y = 0; y < boxH; y++) {
      for (var x = 0; x < boxW; x++) {
        if (pixels[(y * boxW + x) * 4 + 3] > 8) {
          left = math.min(left, x);
          right = math.max(right, x + 1);
          top = math.min(top, y);
          bottom = math.max(bottom, y + 1);
        }
      }
    }
    return Rect.fromLTRB(
      (left - boxW / 2) / r,
      (top - boxH / 2) / r,
      (right - boxW / 2) / r,
      (bottom - boxH / 2) / r,
    );
  }

  test(
    'simple bat stays inside the small-enemy art box in every pose',
    () async {
      final report = StringBuffer();
      var union = Rect.zero;
      var minWidth = double.infinity, maxWidth = 0.0;
      for (var frame = 0; frame < 150; frame++) {
        final seconds = frame / 60;
        for (final (lookY, charge, recoil) in [
          (0.0, 0.0, 0.0),
          if (frame % 10 == 0) ...[(-1.0, 1.0, 0.0), (1.0, 0.0, 1.0)],
        ]) {
          final box = await bounds(
            seconds,
            lookY: lookY,
            charge: charge,
            recoil: recoil,
          );
          union = union == Rect.zero ? box : union.expandToInclude(box);
          if (charge == 0 && recoil == 0) {
            minWidth = math.min(minWidth, box.width);
            maxWidth = math.max(maxWidth, box.width);
          }
        }
      }
      final still = await bounds(0, reduced: true);
      String fmt(Rect b) =>
          'L ${b.left.toStringAsFixed(3)} T ${b.top.toStringAsFixed(3)} '
          'R ${b.right.toStringAsFixed(3)} B ${b.bottom.toStringAsFixed(3)}';
      report
        ..writeln('union bounds (r): ${fmt(union)}')
        ..writeln('width range (r): $minWidth .. $maxWidth')
        ..writeln(
          'reduced motion pose (r): ${fmt(still)} width ${still.width}',
        );
      folder.createSync(recursive: true);
      File('${folder.path}/bounds.txt').writeAsStringSync(report.toString());
      expect(union.left, greaterThanOrEqualTo(-1.9), reason: '$report');
      expect(union.right, lessThanOrEqualTo(1.9), reason: '$report');
      expect(union.top, greaterThanOrEqualTo(-1.2), reason: '$report');
      expect(union.bottom, lessThanOrEqualTo(1.2), reason: '$report');
      // Same size class as the other small enemies: ~3.3-3.6 r wide.
      expect(maxWidth, inInclusiveRange(3.3, 3.62), reason: '$report');
      expect(still.width, inInclusiveRange(3.3, 3.62), reason: '$report');
    },
  );

  test('simple bat is deterministic, tracks the bird and freezes', () async {
    Future<Uint8List> pose(
      double seconds, {
      bool reduced = false,
      double lookY = 0,
    }) => raster(
      (c) {
        c.translate(100, 70);
        SimpleBatArt.paint(
          c,
          40,
          seconds: seconds,
          reducedMotion: reduced,
          lookY: lookY,
        );
      },
      width: 200,
      height: 140,
    );
    expect(await pose(1.37), await pose(1.37), reason: 'paused frame exact');
    expect(await pose(.2), isNot(equals(await pose(.45))), reason: 'flaps');
    expect(
      await pose(.2, reduced: true),
      await pose(3.9, reduced: true),
      reason: 'Reduced Motion freezes wings, bob and blinks',
    );
    expect(
      await pose(0, reduced: true, lookY: -1),
      isNot(equals(await pose(0, reduced: true, lookY: 1))),
      reason: 'eyes follow the bird',
    );
  });

  test('simple bat review sheets', () async {
    // Close-up + gameplay-size strips: one flapping cycle (a full cycle plus
    // one frame, while climbing) and the flap -> glide -> flap transition.
    Future<void> strip(String name, List<double> times) => raster(
      (c) {
        c.drawPaint(Paint()..color = const Color(0xfff2eedf));
        for (var i = 0; i < times.length; i++) {
          c.save();
          c.translate(110 + i * 220.0, 120);
          c.drawRect(
            const Rect.fromLTRB(-1.9 * 50, -1.2 * 50, 1.9 * 50, 1.2 * 50),
            Paint()
              ..style = PaintingStyle.stroke
              ..color = const Color(0x40203b45),
          );
          SimpleBatArt.paint(c, 50, seconds: times[i], reducedMotion: false);
          c.restore();
          c.save();
          c.translate(110 + i * 220.0, 250);
          SimpleBatArt.paint(c, 16, seconds: times[i], reducedMotion: false);
          c.restore();
        }
      },
      width: times.length * 220,
      height: 300,
      name: name,
    );
    await strip('wing-cycle-strip', [
      for (var i = 0; i < 13; i++) .8 + i / 12 * SimpleBatArt.cycleSeconds,
    ]);
    await strip('glide-strip', [for (var i = 0; i < 14; i++) 1.6 + i * .1]);

    // Close-up hero, look up / level / down, charge, recoil, reduced motion.
    await raster(
      (c) {
        c.drawPaint(Paint()..color = const Color(0xfff2eedf));
        final poses = <(double, double, double, double, bool)>[
          (.1, 0, 0, 0, false),
          (.1, -1, 0, 0, false),
          (.1, 1, 0, 0, false),
          (.1, 0, 1, 0, false),
          (.1, 0, 0, 1, false),
          (.1, 0, 0, 0, true),
        ];
        for (var i = 0; i < poses.length; i++) {
          final (s, look, charge, recoil, reduced) = poses[i];
          c.save();
          c.translate(220 + (i % 3) * 420.0, 150 + (i ~/ 3) * 290.0);
          c.drawRect(
            const Rect.fromLTRB(-190, -120, 190, 120),
            Paint()
              ..style = PaintingStyle.stroke
              ..color = const Color(0x40203b45),
          );
          SimpleBatArt.paint(
            c,
            100,
            seconds: s,
            reducedMotion: reduced,
            lookY: look,
            charge: charge,
            recoil: recoil,
          );
          c.restore();
        }
      },
      width: 1260,
      height: 590,
      name: 'close-up-poses',
    );

    // Gameplay-size lineup of all four kinds over real skies.
    for (final (label, elapsed) in [
      ('daylight', 5.0),
      ('dusk', 21.0),
      ('twilight', 45.0),
    ]) {
      await raster(
        (c) {
          SkyScenery.paint(c, const Size(400, 120), seconds: elapsed);
          for (var kind = 0; kind < 4; kind++) {
            final appearance = [3, 0, 1, 2][kind];
            EnemyArt.paint(
              c,
              360,
              SkyEnemy(
                x: (60 + kind * 90) / 360,
                y: 60 / 360,
                appearance: appearance,
              )..age = 1.8,
              birdY: 60 / 360,
              reducedMotion: false,
            );
          }
        },
        width: 400,
        height: 120,
        name: 'gameplay-lineup-$label',
      );
    }
  });

  for (final (label, elapsed, withBat) in [
    ('daylight', 5.0, true),
    ('dusk', 21.0, true),
    ('twilight', 45.0, true),
    ('dusk-without-simple-bat', 21.0, false),
  ]) {
    testWidgets('simple bat in the actual game: $label', (tester) async {
      tester.view.physicalSize = const Size(800, 360);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final sim = _scene(elapsed, withBat: withBat);
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
        Future<void> capture(String name) async {
          final recorder = ui.PictureRecorder();
          game.render(Canvas(recorder));
          final picture = recorder.endRecording();
          final image = await picture.toImage(800, 360);
          final bytes = (await image.toByteData(
            format: ui.ImageByteFormat.png,
          ))!.buffer.asUint8List();
          File('${folder.path}/$name.png').writeAsBytesSync(bytes);
          expect(bytes.length, greaterThan(2000));
          image.dispose();
          picture.dispose();
        }

        await capture('in-game-$label');
        if (withBat && label == 'dusk') {
          // A short in-game flap sequence around the simple bat.
          final bat = sim.enemies.last;
          for (var i = 0; i < 8; i++) {
            bat.age += 1 / 30;
            await capture('in-game-dusk-frame-$i');
          }
        }
      });
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}

// Mirrors the baseline scene of small_enemies_art_test.dart.
FlightSimulation _scene(double elapsed, {required bool withBat}) {
  final sim = FlightSimulation(rules: TapFlyMode(), practice: true)
    ..phase = RunPhase.playing
    ..elapsed = elapsed;
  for (var kind = 0; kind < 3; kind++) {
    sim.enemies.add(
      SkyEnemy(
          x: 1.35 + kind * .30,
          y: .28 + kind * .22,
          appearance: kind,
          flightPhase: kind * 2.399963,
        )
        ..age = 1.8
        ..preparing = kind > 0
        ..fireIn = .15,
    );
  }
  if (withBat) {
    sim.enemies.add(
      SkyEnemy(x: 1.03, y: .27, appearance: 3, flightPhase: 2.1)..age = 1.8,
    );
  }
  return sim;
}
