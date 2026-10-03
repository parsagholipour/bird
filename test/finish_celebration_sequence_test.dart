import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/game/finish_gate_art.dart';
import 'package:push_up_bird/game/play_controller.dart';

import 'campaign_play_test.dart'
    show flyController, launchLevel, level, loadFonts;
import 'recorded_flight.dart' show rideTheSky;

/// Full-screen review sequences of a real level's finish: the bot flies the
/// level to the last few seconds before the line, then the play screen is
/// captured frame by frame at 30 fps through the approach, the crossing,
/// the celebration and the result's entrance, for MP4s and stills.
///
/// Run with `--dart-define=CAPTURE_FINISH_SEQUENCE=true` to write frames to
/// build/visual-review/campaign/finish-celebration/sequence/`name`/.
const _capture = bool.fromEnvironment('CAPTURE_FINISH_SEQUENCE');
const _folder = 'build/visual-review/campaign/finish-celebration/sequence';

Future<void> _sequence(
  WidgetTester tester,
  String name, {
  required String id,
  required int bird,
  bool reduced = false,
  double? holdY,
  double lead = 3.4,
  double after = 4.4,
  bool staged = false,
}) async {
  if (!_capture) return;
  final f = await launchLevel(
    tester,
    level(id),
    size: const Size(792, 360),
    reduced: reduced,
    bird: bird,
  );
  final c = f.controller;
  final sim = c.simulation!;
  if (staged) {
    // Lay the line just ahead instead of fighting the level's boss.
    flyController(c, seconds: 8);
    final ahead = FlightSimulation.birdX + lead * sim.speed;
    sim.finishLine = FinishLine(worldX: sim.distance + ahead, x: ahead);
    // A real approach is clear sky: passages stop short of the line.
    sim.obstacles.clear();
  } else {
    flyController(
      c,
      seconds: 600,
      until: (sim) {
        final toGo = FinishGateArt.toGo(sim);
        return toGo != null && toGo <= lead;
      },
    );
  }
  expect(FinishGateArt.toGo(sim), isNotNull, reason: '$id reached its line');
  const dt = 1 / 30;
  final out = Directory('$_folder/$name')..createSync(recursive: true);
  for (final file in out.listSync()) {
    file.deleteSync();
  }
  var frame = 0;
  int? crossed;
  var saved = false;
  while (frame < 400) {
    if (sim.phase == RunPhase.playing) {
      if (holdY != null && !sim.victoryGlide) {
        // Ease the bird to the height under review and hold it there.
        sim.birdY += (holdY - sim.birdY) * .12;
        sim.velocity = 0;
      } else if (!sim.victoryGlide && rideTheSky(sim)) {
        c.flap();
      }
      if (sim.hearts < 2) sim.hearts = 3;
    }
    c.advance(dt, 0, 2.2);
    c.tick();
    if (crossed == null && c.stage != PlayStage.flying) crossed = frame;
    if (!saved && c.stage != PlayStage.flying) {
      // Let the save land so the result's news reads as it will.
      saved = true;
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 80)),
      );
    }
    await tester.pump(const Duration(microseconds: 33333));
    for (final box in tester.allRenderObjects) {
      if (box.runtimeType.toString() == 'GameRenderBox') box.markNeedsPaint();
    }
    await tester.pump();
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('visual-capture')),
    );
    await tester.runAsync(() async {
      final image = await boundary.toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File(
        '${out.path}/f${(frame++).toString().padLeft(4, '0')}.png',
      ).writeAsBytesSync(bytes!.buffer.asUint8List());
      image.dispose();
    });
    if (crossed != null && (frame - crossed) * dt >= after) break;
  }
  File('${out.path}/crossed.txt').writeAsStringSync(
    'frames=$frame crossedFrame=$crossed '
    'crossedAtY=${sim.birdY.toStringAsFixed(3)} '
    'stage=${c.stage.name} handedOff=${c.handedOff}\n',
  );
  await tester.runAsync(c.exit);
}

void main() {
  setUpAll(loadFonts);

  testWidgets('jungle, yellow chick', (tester) async {
    await _sequence(tester, 'jungle-chick', id: '1-1', bird: 0);
  });
  testWidgets('New York, owl, high', (tester) async {
    await _sequence(tester, 'newyork-owl', id: '3-3', bird: 3, holdY: .2);
  });
  testWidgets('boss level after its glide', (tester) async {
    await _sequence(tester, 'boss-1-8-leaf', id: '1-8', bird: 2);
  });
  testWidgets('guardian, low', (tester) async {
    await _sequence(
      tester,
      'guardian-3-2-pink',
      id: '3-2',
      bird: 1,
      holdY: .8,
      staged: true,
    );
  });
  testWidgets('reduced motion', (tester) async {
    await _sequence(
      tester,
      'reduced-brazil-pink',
      id: '1-4',
      bird: 1,
      reduced: true,
      holdY: .7,
      after: 2.6,
    );
  });
}
