import 'dart:io';
import 'dart:ui' as ui;
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/game/arrival_art.dart';
import 'package:push_up_bird/game/bird_game.dart';
import 'package:push_up_bird/game/finish_gate_art.dart';
import 'campaign_play_test.dart' show launchLevel, level, redraw;

/// Review frames of the finish gate over every region, staged by hand so the
/// gate can stand anywhere on screen: on its way in, at the bird, and after
/// the crossing, at 800×360 and 640×360 and with Reduced Motion.
///
/// Run with `--dart-define=CAPTURE_POLISH=true` to write PNGs to
/// build/visual-review/campaign/polish/finish-line/.
const _capture = bool.fromEnvironment('CAPTURE_POLISH');
const _folder = 'build/visual-review/campaign/polish/finish-line';

FlightSimulation _stage(
  WorldRegion region, {
  required double lineX,
  bool crossed = false,
  double birdY = .5,
  double distance = 30,
  bool obstacles = false,
}) {
  final sim =
      FlightSimulation(
          rules: TapFlyMode(),
          practice: false,
          course: FlightCourse.starTrail,
          plan: LevelPlan(
            id: '1-1',
            region: region,
            length: 60,
            start: 0,
            seed: 1,
            families: const [ObstacleKind.garden],
            marks: const StarMarks(35, 60),
          ),
        )
        ..started = true
        ..phase = RunPhase.playing
        ..distance = distance
        ..elapsed = 12.3
        ..birdY = birdY;
  sim.finishLine = FinishLine(worldX: distance + lineX, x: lineX);
  if (obstacles) {
    sim.obstacles.add(Obstacle(x: lineX + 1.0, center: .6, gap: .48));
  }
  if (crossed) {
    sim.finishLine!.crossedAt = sim.elapsed;
    sim.end(EndReason.completed);
  }
  return sim;
}

Future<void> _shot(
  WidgetTester tester,
  FlightSimulation sim,
  Size size,
  String name, {
  bool reduced = false,
  bool hideBird = false,
  int bird = 0,
}) async {
  tester.view.physicalSize = size;
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
  )..hideBird = hideBird;
  await tester.pumpWidget(GameWidget<BirdGame>(game: game));
  await tester.runAsync(() => game.loaded.timeout(const Duration(seconds: 5)));
  game.pauseEngine();
  await tester.runAsync(() async {
    final recorder = ui.PictureRecorder();
    game.render(ui.Canvas(recorder));
    final picture = recorder.endRecording();
    final image = await picture.toImage(
      size.width.toInt(),
      size.height.toInt(),
    );
    if (_capture) {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('$_folder/$name.png')
        ..parent.createSync(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
    }
    image.dispose();
    picture.dispose();
  });
}

void main() {
  setUpAll(() async {
    for (final family in ['Fredoka', 'Nunito']) {
      await (FontLoader(
        family,
      )..addFont(rootBundle.load('assets/fonts/$family.ttf'))).load();
    }
  });

  const wide = Size(800, 360), narrow = Size(640, 360);

  Future<List<int>> gate(FlightSimulation sim, {bool reduced = false}) async {
    final recorder = ui.PictureRecorder();
    ArrivalArt.gate(ui.Canvas(recorder), 360, sim, reducedMotion: reduced);
    final picture = recorder.endRecording();
    final image = await picture.toImage(1200, 360);
    final bytes = (await image.toByteData())!.buffer.asUint8List();
    image.dispose();
    picture.dispose();
    return bytes;
  }

  test('the gate stays within its reach of the line', () async {
    // A line at 3.0 screen heights, so its pixels sit clear of the edges.
    final sim = _stage(WorldRegion.brazil, lineX: 3, crossed: true);
    final pixels = await gate(sim);
    final lit = <int>[];
    for (var i = 3; i < pixels.length; i += 4) {
      if (pixels[i] != 0) lit.add((i ~/ 4) % 1200);
    }
    expect(lit, isNotEmpty);
    final left = 3 * 360 - FinishGateArt.reach * 360;
    final right = 3 * 360 + FinishGateArt.reach * 360;
    expect(lit.reduce((a, b) => a < b ? a : b), greaterThanOrEqualTo(left));
    expect(lit.reduce((a, b) => a > b ? a : b), lessThanOrEqualTo(right));
  });

  test(
    'the crossing adds a still burst and Reduced Motion stills the rest',
    () async {
      final before = _stage(WorldRegion.sea, lineX: .47);
      final after = _stage(WorldRegion.sea, lineX: .47, crossed: true);
      expect(ArrivalPose.forFlight(after)!.arrived, isTrue);
      expect(await gate(after), isNot(equals(await gate(before))));
      // The burst is laid by a fixed hash: the same crossing paints the same.
      expect(await gate(after), await gate(after));
      final seen = await gate(before, reduced: true);
      before.elapsed += .7;
      expect(await gate(before, reduced: true), seen);
      expect(await gate(before), isNot(equals(seen)));
    },
  );

  test('a level finish is drawn as the gate, a timed route as before', () {
    final level = _stage(WorldRegion.egypt, lineX: 1);
    expect(ArrivalPose.forFlight(level)!.finish, isTrue);
    final route =
        FlightSimulation(
            rules: PushUpFlightMode(cycleSeconds: 3),
            practice: true,
            course: FlightCourse.starTrail,
            rulesVersion: 11,
          )
          ..started = true
          ..phase = RunPhase.playing
          ..elapsed = FlightCourse.starTrail.duration - 3;
    expect(ArrivalPose.forFlight(route)!.finish, isFalse);
  });

  testWidgets('the gate approaches over every region', (tester) async {
    for (final region in WorldRegion.values) {
      await _shot(
        tester,
        _stage(region, lineX: 1.35, obstacles: true),
        wide,
        'approach-${region.name}-800',
        bird: region.index % 4,
      );
    }
  });

  testWidgets('the gate meets the bird over every region', (tester) async {
    for (final region in WorldRegion.values) {
      await _shot(
        tester,
        _stage(
          region,
          lineX: FlightSimulation.birdX,
          crossed: true,
          birdY: .56,
        ),
        wide,
        'crossed-${region.name}-800',
        bird: region.index % 4,
      );
    }
  });

  testWidgets('the gate at 640 and with Reduced Motion', (tester) async {
    for (final region in [
      WorldRegion.brazil,
      WorldRegion.cyberpunk,
      WorldRegion.antarctica,
    ]) {
      await _shot(
        tester,
        _stage(region, lineX: 1.05),
        narrow,
        'mid-${region.name}-640',
      );
      await _shot(
        tester,
        _stage(region, lineX: 1.05),
        narrow,
        'mid-reduced-${region.name}-640',
        reduced: true,
      );
      await _shot(
        tester,
        _stage(region, lineX: FlightSimulation.birdX, crossed: true),
        narrow,
        'crossed-hidden-${region.name}-640',
        hideBird: true,
      );
    }
  });

  for (final size in [wide, narrow]) {
    testWidgets('the gate under the level HUD at ${size.width.toInt()}', (
      tester,
    ) async {
      for (final (id, tag) in [('1-4', 'brazil'), ('2-4', 'egypt')]) {
        final f = await launchLevel(
          tester,
          level(id),
          size: size,
          reduced: false,
        );
        final sim = f.controller.simulation!
          ..phase = RunPhase.playing
          ..countdown = 0
          ..started = true;
        for (final (x, name) in [
          (1.3, 'far'),
          (.75, 'over-score'),
          (FlightSimulation.birdX, 'at-bird'),
        ]) {
          sim.finishLine = FinishLine(worldX: sim.distance + x, x: x);
          if (name == 'at-bird') {
            sim.finishLine!.crossedAt = sim.elapsed;
            sim.end(EndReason.completed);
          }
          await redraw(tester, f.controller);
          if (!_capture) continue;
          final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(const ValueKey('visual-capture')),
          );
          await tester.runAsync(() async {
            final image = await boundary.toImage();
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            File('$_folder/hud-$tag-$name-${size.width.toInt()}.png')
              ..parent.createSync(recursive: true)
              ..writeAsBytesSync(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
        await tester.runAsync(f.controller.exit);
      }
    });
  }
}
