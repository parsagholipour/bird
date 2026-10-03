import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/game/bird_game.dart';
import 'package:push_up_bird/ui/level_result.dart';

/// Review frames of the finish-line celebration, staged by hand so the
/// crossing can happen in any region, at any height, with any bird: the
/// gate on its way in, then the celebration seeked through its beats. Each
/// scenario also gets a contact sheet.
///
/// Run with `--dart-define=CAPTURE_FINISH=true` to write PNGs to
/// build/visual-review/campaign/finish-celebration/.
const _capture = bool.fromEnvironment('CAPTURE_FINISH');
const _folder = 'build/visual-review/campaign/finish-celebration';
const _size = Size(792, 360);

FlightSimulation _stage(
  WorldRegion region, {
  required double lineX,
  bool crossed = false,
  double birdY = .5,
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
        ..distance = 30
        ..elapsed = 12.3
        ..birdY = birdY;
  sim.finishLine = FinishLine(worldX: 30 + lineX, x: lineX);
  if (crossed) {
    sim.finishLine!.crossedAt = sim.elapsed;
    sim.end(EndReason.completed);
  }
  return sim;
}

class _Rig {
  _Rig(this.game, this.time);
  final BirdGame game;
  final List<double?> time;
}

Future<_Rig> _rig(
  WidgetTester tester,
  FlightSimulation sim, {
  required int bird,
  bool reduced = false,
  bool seat = true,
}) async {
  tester.view.physicalSize = _size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final time = <double?>[null];
  final game = BirdGame(
    simulation: sim,
    nowMs: () => 0,
    bird: bird,
    reducedMotion: reduced,
    playback: true,
    onChanged: () {},
    finish: () => time[0],
    seat: seat
        ? (size) => LevelResultStage.courierSeat(size, EdgeInsets.zero)
        : null,
  );
  await tester.pumpWidget(GameWidget<BirdGame>(game: game));
  await tester.runAsync(() => game.loaded.timeout(const Duration(seconds: 5)));
  game.pauseEngine();
  return _Rig(game, time);
}

Future<ui.Image> _frame(_Rig rig) async {
  final recorder = ui.PictureRecorder();
  rig.game.render(ui.Canvas(recorder));
  final picture = recorder.endRecording();
  final image = await picture.toImage(
    _size.width.toInt(),
    _size.height.toInt(),
  );
  picture.dispose();
  return image;
}

Future<void> _save(ui.Image image, String name) async {
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  File('$_folder/$name.png')
    ..parent.createSync(recursive: true)
    ..writeAsBytesSync(bytes!.buffer.asUint8List());
}

/// Lays [frames] out three to a row at half size, each with its label.
Future<void> _sheet(List<(String, ui.Image)> frames, String name) async {
  const cols = 3, w = 396.0, h = 180.0, gap = 6.0, label = 18.0;
  final rows = (frames.length / cols).ceil();
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  final width = cols * w + (cols + 1) * gap;
  final height = rows * (h + label) + (rows + 1) * gap;
  canvas.drawRect(
    Rect.fromLTWH(0, 0, width, height),
    Paint()..color = const Color(0xff18313b),
  );
  for (final (i, (text, image)) in frames.indexed) {
    final x = gap + (i % cols) * (w + gap);
    final y = gap + (i ~/ cols) * (h + label + gap);
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(x, y + label, w, h),
      Paint()..filterQuality = FilterQuality.medium,
    );
    TextPainter(
        text: TextSpan(
          text: text,
          style: const TextStyle(
            fontFamily: 'Fredoka',
            fontSize: 13,
            color: Color(0xfffff9ed),
          ),
        ),
        textDirection: TextDirection.ltr,
      )
      ..layout()
      ..paint(canvas, Offset(x + 2, y + 1));
  }
  final picture = recorder.endRecording();
  final image = await picture.toImage(width.toInt(), height.toInt());
  await _save(image, name);
  image.dispose();
  picture.dispose();
}

/// Renders the approach at [toGo] seconds and the celebration at [times],
/// writing each frame and a contact sheet named [name].
Future<void> _scenario(
  WidgetTester tester,
  String name, {
  required WorldRegion region,
  required int bird,
  double birdY = .5,
  bool reduced = false,
  bool seat = true,
  List<double> toGo = const [3.4, 2.4, 1.2, .3],
  List<double> times = const [
    0,
    .05,
    .09,
    .12,
    .15,
    .18,
    .22,
    .3,
    .45,
    .6,
    .75,
    .9,
    1.1,
    1.3,
    1.5,
    1.65,
    1.75,
    2.2,
    3.0,
  ],
}) async {
  if (!_capture) return;
  final frames = <(String, ui.Image)>[];
  for (final s in toGo) {
    final sim = _stage(
      region,
      lineX: FlightSimulation.birdX + s * 0.3 * .9,
      birdY: birdY,
    );
    final rig = await _rig(tester, sim, bird: bird, reduced: reduced);
    await tester.runAsync(() async {
      final image = await _frame(rig);
      frames.add(('-${s.toStringAsFixed(1)} s', image));
    });
  }
  final sim = _stage(
    region,
    lineX: FlightSimulation.birdX,
    crossed: true,
    birdY: birdY,
  );
  final rig = await _rig(tester, sim, bird: bird, reduced: reduced, seat: seat);
  await tester.runAsync(() async {
    for (final t in times) {
      rig.time[0] = t;
      final image = await _frame(rig);
      frames.add(('+${t.toStringAsFixed(2)} s', image));
    }
    for (final (text, image) in frames) {
      await _save(image, '$name/${text.replaceAll(' ', '')}');
    }
    await _sheet(frames, '$name-sheet');
    for (final (_, image) in frames) {
      image.dispose();
    }
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

  for (final (name, region, bird, y) in [
    ('jungle-chick-mid', WorldRegion.jungle, 0, .5),
    ('newyork-owl-high', WorldRegion.newYork, 3, .12),
    ('cyberpunk-pink-low', WorldRegion.cyberpunk, 1, .88),
    ('brazil-leaf-high', WorldRegion.brazil, 2, .26),
    ('sea-owl-mid', WorldRegion.sea, 3, .42),
    ('antarctica-chick-low', WorldRegion.antarctica, 0, .75),
  ]) {
    testWidgets(name, (tester) async {
      await _scenario(tester, name, region: region, bird: bird, birdY: y);
    });
  }
  testWidgets('reduced motion', (tester) async {
    await _scenario(
      tester,
      'brazil-pink-reduced',
      region: WorldRegion.brazil,
      bird: 1,
      birdY: .6,
      reduced: true,
      times: const [0, .2, .4, .6, .8, 1.0, 1.2, 1.4],
    );
  });
  testWidgets('a replay, with no seat to land in', (tester) async {
    await _scenario(
      tester,
      'replay-jungle-chick',
      region: WorldRegion.jungle,
      bird: 0,
      seat: false,
      toGo: const [],
      times: const [1.2, 1.5, 1.7, 2.0, 2.6, 4.2],
    );
  });
}
