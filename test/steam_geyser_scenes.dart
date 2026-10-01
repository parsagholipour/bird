import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/campaign.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/game/bird_game.dart';

import 'campaign_flight.dart' show flyLevel, levelFlight;

/// Scenes for the steam geysers' art tests and review renders: real
/// `BirdGame` frames over a campaign level's own backdrop, with vents laid by
/// hand (the simulation lays none until the rules land).

const wide = Size(800, 360), narrow = Size(640, 360);

typedef VentSpec = ({
  double x,
  double top,
  SteamKind kind,
  double tau,
  int slot,
});

/// A vent [x] viewport heights from the left edge, whose plume stands [top]
/// high, caught [tau] route seconds after its burst began.
VentSpec spec(
  double x,
  double top,
  double tau, {
  SteamKind kind = SteamKind.hop,
  int slot = 4,
}) => (x: x, top: top, kind: kind, tau: tau, slot: slot);

SteamVent makeVent(VentSpec v, double route) => SteamVent(
  geyser: SteamGeyser(
    slot: v.slot,
    x: v.x,
    kind: v.kind,
    burstAt: route - v.tau,
  ),
  x: v.x,
  top: v.top,
);

/// A flight of [level] [seconds] in, with the bird at [y] and [vents] laid
/// in place of whatever the level had on screen.
FlightSimulation scene(
  String level,
  List<VentSpec> vents, {
  double seconds = 13,
  double y = .32,
  bool clear = true,
}) {
  final sim = levelFlight(Campaign.level(level)!, practice: true);
  flyLevel(sim, seconds: seconds, sprintWhen: (_, _) => false);
  sim
    ..hearts = 3
    ..birdY = y
    ..velocity = 0;
  if (clear) {
    sim.obstacles.clear();
    sim.enemies.clear();
    sim.stars.clear();
    sim.starTrios.clear();
  }
  sim.steamVents
    ..clear()
    ..addAll([for (final v in vents) makeVent(v, sim.routeSeconds)]);
  return sim;
}

/// Puts the vents at new cycle times, keeping everything else.
void retime(FlightSimulation sim, List<VentSpec> vents) {
  sim.steamVents
    ..clear()
    ..addAll([for (final v in vents) makeVent(v, sim.routeSeconds)]);
}

/// The three stars a hop slot lays on an arc over a vent.
void arcStars(FlightSimulation sim, double x, double top) {
  for (final (dx, dy) in const [(-.20, .05), (-.03, 0.0), (.14, .05)]) {
    sim.stars.add(SkyStar(x: x + dx, y: top - .14 + dy));
  }
}

/// A gate: [center] is the gap's middle height.
void gate(FlightSimulation sim, double x, double center, {int look = 0}) {
  sim.obstacles.add(Obstacle(x: x, center: center, gap: .36, appearance: look));
  for (var i = 0; i < 3; i++) {
    sim.stars.add(SkyStar(x: x - .42 + i * .17, y: center));
  }
}

Future<BirdGame> mountGame(
  WidgetTester tester,
  FlightSimulation sim,
  Size size, {
  bool reduced = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final game = BirdGame(
    simulation: sim,
    nowMs: () => 0,
    bird: 0,
    reducedMotion: reduced,
    playback: true,
    onChanged: () {},
  );
  await tester.pumpWidget(GameWidget<BirdGame>(game: game));
  await tester.runAsync(() => game.loaded.timeout(const Duration(seconds: 5)));
  game.pauseEngine();
  return game;
}

/// The frame as an image: [crop] in layout px, magnified by [scale].
Future<ui.Image> shoot(
  BirdGame game,
  Size size, {
  double scale = 1,
  Rect? crop,
}) async {
  final area = crop ?? Offset.zero & size;
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.scale(scale);
  canvas.translate(-area.left, -area.top);
  game.render(canvas);
  final picture = recorder.endRecording();
  final image = await picture.toImage(
    (area.width * scale).round(),
    (area.height * scale).round(),
  );
  picture.dispose();
  return image;
}

Future<void> savePng(ui.Image image, String path) async {
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  final file = File(path)..parent.createSync(recursive: true);
  await file.writeAsBytes(bytes!.buffer.asUint8List());
}

/// Lays [tiles] side by side (or in a grid of [columns]) into one image.
Future<ui.Image> sheetOf(List<ui.Image> tiles, {int? columns}) async {
  final cols = columns ?? tiles.length;
  final rows = (tiles.length / cols).ceil();
  final tw = tiles.first.width, th = tiles.first.height;
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  for (final (i, t) in tiles.indexed) {
    canvas.drawImage(
      t,
      Offset((i % cols) * tw.toDouble(), (i ~/ cols) * th.toDouble()),
      Paint(),
    );
  }
  return recorder.endRecording().toImage(tw * cols, th * rows);
}
