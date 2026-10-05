import 'dart:io';
import 'dart:ui' as ui;
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/game/bird_game.dart';
import 'package:push_up_bird/game/gale_football_art.dart';
import 'boss_fight_test.dart' show step;
import 'gale_test.dart' show cruise, dodge;

/// A Brazil level whose gale starts five seconds in.
FlightSimulation brazilGale() => FlightSimulation(
  rules: TapFlyMode(),
  practice: false,
  course: FlightCourse.starTrail,
  weaponDamage: 30,
  plan: const LevelPlan(
    id: 'review',
    region: WorldRegion.brazil,
    length: 60,
    start: 20,
    seed: 1104,
    families: [
      ObstacleKind.garden,
      ObstacleKind.windLift,
      ObstacleKind.petalGate,
    ],
    sprint: false,
    pieces: [SetPiece(SetPieceKind.gale, at: 5)],
    marks: StarMarks(30, 50),
  ),
);

FlightSimulation blowingOverBrazil() {
  final sim = brazilGale();
  cruise(sim, 40, until: () => sim.gale?.phase == GalePhase.blowing);
  expect(sim.gale!.phase, GalePhase.blowing);
  sim.invulnerableUntil = 0;
  return sim;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('footballs over Brazil, for visual review', (tester) async {
    const size = Size(792, 360);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.runAsync(
      () => (FontLoader(
        'Fredoka',
      )..addFont(rootBundle.load('assets/fonts/Fredoka.ttf'))).load(),
    );
    Future<List<int>> png(ui.Picture picture, [Size frame = size]) async {
      late List<int> bytes;
      await tester.runAsync(() async {
        final image = await picture.toImage(
          frame.width.round(),
          frame.height.round(),
        );
        bytes = (await image.toByteData(
          format: ui.ImageByteFormat.png,
        ))!.buffer.asUint8List();
        image.dispose();
        picture.dispose();
      });
      return bytes;
    }

    Future<List<int>> render(FlightSimulation sim, bool reducedMotion) async {
      final game = BirdGame(
        simulation: sim,
        nowMs: () => 0,
        bird: 0,
        reducedMotion: reducedMotion,
        playback: true,
        onChanged: () {},
      );
      await tester.pumpWidget(GameWidget(game: game));
      late ui.Picture picture;
      await tester.runAsync(() async {
        await game.loaded;
        game.pauseEngine();
        final recorder = ui.PictureRecorder();
        game.render(Canvas(recorder));
        picture = recorder.endRecording();
      });
      return png(picture);
    }

    final shots = <String, List<int>>{};
    final storm = blowingOverBrazil();
    dodge(
      storm,
      10,
      until: () =>
          storm.gale!.gusts >= 5 &&
          storm.galeDebris.where((d) => d.x < 2.1 && d.x > .5).length >= 3,
    );
    shots['blowing'] = await render(storm, false);
    shots['blowing-reduced'] = await render(storm, true);

    final struck = blowingOverBrazil();
    cruise(struck, 5, until: () => struck.galeDebris.isNotEmpty);
    struck.invulnerableUntil = 0;
    for (var i = 0; i < 200 && struck.gale!.hits == 0; i++) {
      struck.birdY = struck.galeDebris.first.y;
      struck.velocity = 0;
      step(struck);
    }
    expect(struck.gale!.hits, 1);
    cruise(struck, .08);
    shots['struck'] = await render(struck, false);
    shots['struck-reduced'] = await render(struck, true);
    // Turf still flying off the strike.
    cruise(struck, .14);
    shots['struck-late'] = await render(struck, false);

    // The four kits at four times their size over a sky, then at play size
    // in four poses each.
    const sheet = Size(792, 360);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)
      ..drawRect(Offset.zero & sheet, Paint()..color = const Color(0xff90d5ee));
    const r = GaleDebris.radius * 360;
    for (var kit = 0; kit < GaleFootballArt.kits; kit++) {
      final x = 99.0 + kit * 198;
      GaleFootballArt.paint(canvas, Offset(x, 110), r * 4, kit, 0, 1);
      for (var pose = 0; pose < 4; pose++) {
        GaleFootballArt.paint(
          canvas,
          Offset(x - 66 + pose * 44, 260),
          r,
          kit,
          pose * .9,
          1,
        );
      }
      GaleFootballArt.paint(canvas, Offset(x - 22, 320), r, kit, 2.4, .5);
      GaleFootballArt.paint(canvas, Offset(x + 22, 320), r, kit, 4, .25);
    }
    shots['sheet'] = await png(recorder.endRecording(), sheet);

    expect(tester.takeException(), isNull);
    if (const bool.fromEnvironment('CAPTURE_VISUALS')) {
      Directory('build/visual-review').createSync(recursive: true);
      for (final MapEntry(key: name, value: bytes) in shots.entries) {
        File(
          'build/visual-review/gale-football-$name.png',
        ).writeAsBytesSync(bytes);
      }
    }
  });
}
