// Test support for Neferhoo's presentation (A2): a REAL game (BirdGame over a
// real FlightSimulation of level 2-6, Egypt held) stepped at 60 Hz through the
// arrival, the fight and the defeat and rendered through the real renderer
// (backdrop, boss layer, bird, letterbox and cards, health strip), plus the
// design's dusk check (Egypt pushed to a violet dusk under the boss layer).
// Used by the neferhoo_* presentation tests and the review generator.
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/campaign.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/tracking.dart';
import 'package:push_up_bird/game/bird_game.dart';
import 'package:push_up_bird/game/boss_motion.dart';
import 'package:push_up_bird/game/sky_scenery.dart';

import 'campaign_flight.dart';

/// The 2-6 flight (the catalog's own plan) flown by the shared bot, no
/// sprint, until Neferhoo arrives (boss age 0), the bird parked mid-screen.
/// [version]: the rules flown (the current ones by default).
FlightSimulation neferhooArrival({double width = 2.2, int version = FlightSimulation.currentRulesVersion}) {
  final sim = levelFlight(Campaign.level('2-6')!, version: version);
  flyLevel(sim, viewportWidth: width, sprintWhen: (sim, frame) => false, until: (sim) => sim.boss != null);
  final boss = sim.boss;
  if (boss == null || !boss.isNeferhoo) throw StateError('the flight did not reach Neferhoo');
  sim
    ..rocks.clear()
    ..bossAmmo.clear()
    ..birdY = .5
    ..velocity = 0
    ..hearts = 3
    ..shield = true
    ..invulnerableUntil = 0;
  return sim;
}

final _clocks = Expando<double>();

/// One 1/60 s step of [sim] with the bird held (no tap).
void frame(FlightSimulation sim, {double dt = 1 / 60, double width = 2.2}) {
  final now = (_clocks[sim] ?? (sim.lastValidMs.isFinite ? sim.lastValidMs : 0.0)) + dt * 1000;
  _clocks[sim] = now;
  sim.apply(MovementInput(valid: true, flap: false), touchAt(now), now);
  sim.tick(dt, now, viewportWidth: width);
}

/// A real game with Neferhoo on stage.
class NStage {
  NStage(this.game, this.sim, this.width, {required this.reduced});
  final BirdGame game;
  final FlightSimulation sim;

  /// The screen's width in px (its height is always 360).
  final double width;
  final bool reduced;

  /// Where the bird is held.
  double birdY = .5;

  SkyBoss get boss => sim.boss!;
  double get aspect => width / 360;

  /// One 1/60 s step, the bird held at [birdY] and kept safe.
  void tick({double dt = 1 / 60}) {
    sim
      ..birdY = birdY
      ..velocity = 0
      ..hearts = 3
      ..invulnerableUntil = sim.elapsed + 1;
    frame(sim, dt: dt, width: aspect);
    sim
      ..birdY = birdY
      ..velocity = 0;
  }

  /// Steps until the boss's age is [age] (to a 1/60 s).
  void runTo(double age) {
    var guard = 0;
    while (sim.boss != null && boss.age < age - 1e-6 && guard++ < 60 * 90) {
      tick();
    }
  }

  /// Steps to [t] seconds into the fight.
  void fightTo(double t) => runTo(boss.arrivalDuration + t);

  /// Brings him to [hp] and lands one rock on him (the killing blow when
  /// [hp] is the rock's damage or less).
  void strike({int hp = 1}) {
    boss.hp = hp;
    sim.rocks.add(BirdRock(x: boss.x - .12, y: boss.y));
    var guard = 0;
    while (boss.phase == BossPhase.attacking && guard++ < 120) {
      tick();
    }
  }

  /// Steps to [d] seconds after the killing blow.
  void deathTo(double d) {
    var guard = 0;
    while (sim.boss != null && boss.defeatedAt != null && boss.age - boss.defeatedAt! < d - 1e-6 && guard++ < 60 * 10) {
      tick();
    }
  }

  BossMotion get motion => BossMotion(boss, reducedMotion: reduced);

  /// One frame of the whole game; [dusk] pushes Egypt to the design's violet
  /// dusk under everything the game draws over the sky.
  Future<ui.Image> render({bool dusk = false}) async {
    final recorder = ui.PictureRecorder();
    final c = ui.Canvas(recorder);
    if (dusk) {
      final size = ui.Size(width, 360);
      SkyScenery.paint(c, size, seconds: sim.elapsed, distance: sim.distance, reducedMotion: reduced, held: sim.region);
      duskOver(c, size);
      game.transparent = true;
    }
    game.render(c);
    game.transparent = false;
    final picture = recorder.endRecording();
    final image = await picture.toImage(width.toInt(), 360);
    picture.dispose();
    return image;
  }
}

/// The design's dark-backdrop check (`eg_util.egyptDusk`): Egypt pushed to a
/// violet dusk.
void duskOver(ui.Canvas c, ui.Size size) {
  c.drawRect(ui.Offset.zero & size, ui.Paint()..color = const ui.Color(0xff1c1850).withValues(alpha: .62));
  c.drawRect(
    ui.Offset.zero & size,
    ui.Paint()
      ..shader = ui.Gradient.linear(ui.Offset.zero, ui.Offset(0, size.height), const [ui.Color(0x00ff9a6a), ui.Color(0x55ff7a5a)], const [.5, 1]),
  );
}

/// A real game at the first frame of his arrival.
Future<NStage> neferhooStage(WidgetTester tester, double width, {bool reduced = false, int version = FlightSimulation.currentRulesVersion}) async {
  tester.view.physicalSize = ui.Size(width, 360);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final sim = neferhooArrival(width: width / 360, version: version);
  final game = BirdGame(simulation: sim, nowMs: () => 0, bird: 0, reducedMotion: reduced, playback: true, onChanged: () {});
  await tester.pumpWidget(GameWidget<BirdGame>(game: game));
  await game.loaded;
  game.pauseEngine();
  return NStage(game, sim, width, reduced: reduced);
}

Future<void> loadFonts() async {
  for (final family in ['Fredoka', 'Nunito']) {
    await (FontLoader(family)..addFont(rootBundle.load('assets/fonts/$family.ttf'))).load();
  }
}

Future<Uint8List> png(ui.Image image) async => (await image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();

Future<Uint8List> rgba(ui.Image image) async => (await image.toByteData())!.buffer.asUint8List();

/// Rasters [paint] on a [w] x [h] canvas into RGBA bytes.
Future<Uint8List> raster(void Function(ui.Canvas c) paint, double w, [double h = 360]) async {
  final recorder = ui.PictureRecorder();
  paint(ui.Canvas(recorder));
  final picture = recorder.endRecording();
  final image = await picture.toImage(w.toInt(), h.toInt());
  final bytes = await rgba(image);
  image.dispose();
  picture.dispose();
  return bytes;
}

/// How many pixels differ between two rasters of the same size.
int changed(Uint8List a, Uint8List b, {int tolerance = 6}) {
  var n = 0;
  for (var i = 0; i < a.length; i += 4) {
    if ((a[i] - b[i]).abs() > tolerance || (a[i + 1] - b[i + 1]).abs() > tolerance || (a[i + 2] - b[i + 2]).abs() > tolerance || (a[i + 3] - b[i + 3]).abs() > tolerance) {
      n++;
    }
  }
  return n;
}

/// The bounds of the pixels with any alpha in an RGBA raster [w] wide, or
/// null when nothing was drawn.
ui.Rect? inked(Uint8List a, int w, {int alpha = 8}) {
  var l = 1 << 30, t = 1 << 30, r = -1, b = -1;
  final h = a.length ~/ (4 * w);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      if (a[(y * w + x) * 4 + 3] > alpha) {
        l = math.min(l, x);
        r = math.max(r, x);
        t = math.min(t, y);
        b = math.max(b, y);
      }
    }
  }
  return r < 0 ? null : ui.Rect.fromLTRB(l.toDouble(), t.toDouble(), r + 1.0, b + 1.0);
}

/// Labelled frames in a contact sheet, [cols] wide, each at [scale].
Future<void> sheet(Directory folder, String name, List<(String, ui.Image)> frames, {int cols = 3, double scale = 1}) async {
  final fw = frames.first.$2.width * scale, fh = frames.first.$2.height * scale;
  final rows = (frames.length / cols).ceil();
  final recorder = ui.PictureRecorder();
  final c = ui.Canvas(recorder);
  c.drawRect(ui.Rect.fromLTWH(0, 0, fw * cols, (fh + 16) * rows), ui.Paint()..color = const ui.Color(0xff101223));
  for (var i = 0; i < frames.length; i++) {
    final (label, image) = frames[i];
    final at = ui.Offset(i % cols * fw, (i ~/ cols) * (fh + 16));
    c.drawImageRect(
      image,
      ui.Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      ui.Rect.fromLTWH(at.dx + 1, at.dy + 16, fw - 2, fh - 1),
      ui.Paint()..filterQuality = ui.FilterQuality.medium,
    );
    final p = TextPainter(
      text: TextSpan(text: label, style: const TextStyle(fontFamily: 'Fredoka', fontSize: 12, color: ui.Color(0xffffffff))),
      textDirection: TextDirection.ltr,
    )..layout();
    p.paint(c, at + const ui.Offset(4, 1));
  }
  final picture = recorder.endRecording();
  final image = await picture.toImage((fw * cols).toInt(), ((fh + 16) * rows).toInt());
  folder.createSync(recursive: true);
  File('${folder.path}/$name.png').writeAsBytesSync(await png(image));
  image.dispose();
  picture.dispose();
}

void disposeAll(List<(String, ui.Image)> frames) {
  for (final (_, image) in frames) {
    image.dispose();
  }
}
