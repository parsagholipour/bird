import 'dart:io';
import 'dart:ui' as ui;
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/game/bird_game.dart';
import 'package:push_up_bird/game/door_art.dart';

Future<Uint8List> pixels(Obstacle o, {bool reduced = true}) async {
  final recorder = ui.PictureRecorder();
  DoorArt.paint(Canvas(recorder), 360, o, reducedMotion: reduced);
  final picture = recorder.endRecording();
  final image = await picture.toImage(800, 360);
  final data = (await image.toByteData())!.buffer.asUint8List();
  image.dispose();
  picture.dispose();
  return data;
}

void main() {
  testWidgets(
    'damage changes the panel silhouette and leaves the surrounding wall alone',
    (tester) async {
      await tester.runAsync(() async {
        final o = Obstacle(x: 1.2, center: .5, gap: .34, door: SkyDoor());
        var previous = await pixels(o);
        for (var hit = 1; hit <= 4; hit++) {
          o.door!.takeDamage(10, hitY: .5);
          o.advance(hit.toDouble());
          final current = await pixels(o);
          expect(current, isNot(equals(previous)));
          for (var y = 0; y < 360; y++) {
            if (y >= (o.top * 360).floor() && y <= (o.bottom * 360).ceil()) {
              continue;
            }
            for (var x = 0; x < 800; x++) {
              expect(current[(y * 800 + x) * 4 + 3], 0);
            }
          }
          previous = current;
        }
        expect(
          previous.every((byte) => byte == 0),
          isTrue,
          reason: 'Reduced Motion removes the destroyed insert immediately',
        );
        final d = o.door!;
        d.age = d.destroyedAt! + .12;
        final burst = await pixels(o, reduced: false);
        d.age += .1;
        expect(await pixels(o, reduced: false), isNot(equals(burst)));
        d.age -= .1;
        expect(await pixels(o, reduced: false), burst);
      });
    },
  );

  testWidgets('captures intact, cracked and open wall gaps at phone size', (
    tester,
  ) async {
    if (!const bool.fromEnvironment('CAPTURE_DOOR_ART')) return;
    tester.view.physicalSize = const Size(800, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final family in ['Fredoka', 'Nunito']) {
      await (FontLoader(
        family,
      )..addFont(rootBundle.load('assets/fonts/$family.ttf'))).load();
    }
    final sim =
        FlightSimulation(
            rules: TapFlyMode(),
            practice: true,
            course: FlightCourse.starTrail,
          )
          ..phase = RunPhase.playing
          ..elapsed = 130
          ..bossesDefeated = 2;
    final o = Obstacle(
      x: 1.25,
      center: .5,
      gap: .34,
      appearance: 0,
      door: SkyDoor(),
    );
    sim.obstacles.addAll([
      o,
      Obstacle(x: 2.05, center: .3, gap: .34, appearance: 1),
    ]);
    final game = BirdGame(
      simulation: sim,
      nowMs: () => 0,
      bird: 0,
      reducedMotion: true,
      onChanged: () {},
      playback: true,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: RepaintBoundary(
          key: const ValueKey('door-capture'),
          child: GameWidget(game: game),
        ),
      ),
    );
    await tester.runAsync(() => game.loaded);
    await tester.pump();
    for (var hit = 0; hit <= 4; hit++) {
      if (hit > 0) o.door!.takeDamage(10, hitY: .5);
      o.advance(130 + hit.toDouble());
      await tester.pump(const Duration(milliseconds: 16));
      await tester.runAsync(() async {
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(const ValueKey('door-capture')),
        );
        final image = await boundary.toImage();
        final folder = Directory('build/visual-review/breakable-walls')
          ..createSync(recursive: true);
        File('${folder.path}/${o.door!.hp}hp.png').writeAsBytesSync(
          (await image.toByteData(
            format: ui.ImageByteFormat.png,
          ))!.buffer.asUint8List(),
        );
        image.dispose();
      });
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(const SizedBox());
  });
}
