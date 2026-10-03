// Test support for the staged campaign bosses and their vanguards (rules
// version 44): a REAL game (BirdGame over a real FlightSimulation of a
// campaign boss level) flown by the shared bot to the vanguard or the boss,
// then stepped and rendered through the real renderer. Used by
// boss_stages_art_test.dart and boss_stages_review_test.dart.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/campaign.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/game/bird_game.dart';

import 'campaign_flight.dart';
import 'gargoyle_pilot.dart' show frame;

/// The campaign's boss levels, one per boss.
const bossLevels = {
  BossKind.baronBat: '1-8',
  BossKind.neferhoo: '2-6',
  BossKind.spitterBeetle: '2-9',
  BossKind.kingCoo: '3-2',
  BossKind.searchlightGargoyle: '3-4',
  BossKind.duskMoth: '3-8',
  BossKind.pirate: '4-8',
  BossKind.dragon: '5-8',
};

String kindName(BossKind kind) => switch (kind) {
  BossKind.baronBat => 'baron-bat',
  BossKind.spitterBeetle => 'spitter-king',
  BossKind.duskMoth => 'dusk-empress',
  BossKind.pirate => 'pirate-captain',
  BossKind.dragon => 'ember-dragon',
  BossKind.kingCoo => 'king-coo',
  BossKind.searchlightGargoyle => 'searchlight-gargoyle',
  BossKind.neferhoo => 'neferhoo',
};

/// A flight of [kind]'s level, flown by the bot until its vanguard begins
/// (or, for a boss with none, its boss arrives).
FlightSimulation runUp(BossKind kind, {double width = 2.2}) {
  final sim = levelFlight(Campaign.level(bossLevels[kind]!)!);
  flyLevel(
    sim,
    viewportWidth: width,
    sprintWhen: (sim, frame) => false,
    until: (sim) => sim.vanguard != null || sim.boss != null,
  );
  if (sim.vanguard == null && sim.boss == null) {
    throw StateError('the flight did not reach $kind');
  }
  return sim;
}

/// A real game on a campaign boss level, the bird held at [birdY] while the
/// rules run (it cannot be hurt), stepped at 60 Hz.
class StagesGame {
  StagesGame(this.game, this.sim, this.width, {required this.reduced});
  final BirdGame game;
  final FlightSimulation sim;

  /// The screen's width in px (its height is always 360).
  final double width;
  final bool reduced;
  double birdY = .62;

  /// Whether the bot shoots while the frames step.
  bool shooting = false;
  int _frames = 0;

  SkyBoss? get boss => sim.boss;
  double get aspect => width / 360;

  void tick({double dt = 1 / 60}) {
    sim
      ..birdY = birdY
      ..velocity = 0
      ..hearts = 3
      ..invulnerableUntil = sim.elapsed + 1;
    if (shooting && ++_frames % 12 == 0 && sim.canShoot) sim.shoot();
    frame(sim, dt: dt, width: aspect);
    sim
      ..birdY = birdY
      ..velocity = 0;
  }

  /// Steps [seconds] of flight.
  void run(double seconds) {
    final end = sim.elapsed + seconds;
    var guard = 0;
    while (sim.elapsed < end - 1e-6 && guard++ < 60 * 120) {
      tick();
    }
  }

  /// Steps until [until] holds (at most [seconds]).
  void runUntil(bool Function(FlightSimulation) until, {double seconds = 90}) {
    var guard = 0;
    while (!until(sim) && guard++ < seconds * 60) {
      tick();
    }
    if (!until(sim)) throw StateError('never got there');
  }

  /// Steps until the boss's age is [age].
  void bossTo(double age) {
    var guard = 0;
    while (sim.boss != null && sim.boss!.age < age - 1e-6 && guard++ < 7200) {
      tick();
    }
  }

  /// Shoots the vanguard's enemies on screen: every member left alive is
  /// downed by the rules' own path (a rock where it is).
  void downOne() {
    final guard = sim.vanguard;
    if (guard == null) return;
    for (final enemy in guard.members) {
      if (!sim.enemies.contains(enemy) || enemy.x > aspect - .05) continue;
      sim.rocks.add(BirdRock(x: enemy.x, y: enemy.y, damage: 999));
      return;
    }
  }

  /// Takes the boss to [share] of its health with one blow and steps a few
  /// frames, so the rules raise its stage.
  void hurtTo(double share, {double after = 0}) {
    final b = sim.boss!;
    final target = (b.maxHp * share).floor();
    if (b.hp > target) b.takeDamage(b.hp - target);
    tick();
    run(after);
  }

  Future<ui.Image> render() async {
    final recorder = ui.PictureRecorder();
    game.render(ui.Canvas(recorder));
    final picture = recorder.endRecording();
    final image = await picture.toImage(width.toInt(), 360);
    picture.dispose();
    return image;
  }
}

Future<StagesGame> stagesGame(
  WidgetTester tester,
  BossKind kind,
  double width, {
  bool reduced = false,
}) async {
  tester.view.physicalSize = ui.Size(width, 360);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final sim = runUp(kind, width: width / 360);
  final game = BirdGame(
    simulation: sim,
    nowMs: () => 0,
    bird: 0,
    reducedMotion: reduced,
    playback: true,
    onChanged: () {},
  );
  await tester.pumpWidget(GameWidget<BirdGame>(game: game));
  await game.loaded;
  game.pauseEngine();
  return StagesGame(game, sim, width, reduced: reduced)..tick();
}

Future<void> loadFonts() async {
  for (final family in ['Fredoka', 'Nunito']) {
    await (FontLoader(
      family,
    )..addFont(rootBundle.load('assets/fonts/$family.ttf'))).load();
  }
}

Future<Uint8List> png(ui.Image image) async => (await image.toByteData(
  format: ui.ImageByteFormat.png,
))!.buffer.asUint8List();

Future<Uint8List> rgba(ui.Image image) async =>
    (await image.toByteData())!.buffer.asUint8List();

Future<void> save(Directory folder, String name, ui.Image image) async {
  final file = File('${folder.path}/$name.png')
    ..parent.createSync(recursive: true);
  file.writeAsBytesSync(await png(image));
}

/// Labelled frames in a contact sheet, [cols] wide, each at [scale].
Future<void> sheet(
  Directory folder,
  String name,
  List<(String, ui.Image)> frames, {
  int cols = 3,
  double scale = 1,
  double height = 360,
}) async {
  final fw = frames.first.$2.width * scale, fh = height * scale;
  final rows = (frames.length / cols).ceil();
  final recorder = ui.PictureRecorder();
  final c = ui.Canvas(recorder);
  c.drawRect(
    ui.Rect.fromLTWH(0, 0, fw * cols, (fh + 16) * rows),
    ui.Paint()..color = const ui.Color(0xff101223),
  );
  for (var i = 0; i < frames.length; i++) {
    final (label, image) = frames[i];
    final at = ui.Offset(i % cols * fw, (i ~/ cols) * (fh + 16));
    c.drawImageRect(
      image,
      ui.Rect.fromLTWH(0, 0, image.width.toDouble(), height),
      ui.Rect.fromLTWH(at.dx + 1, at.dy + 16, fw - 2, fh - 1),
      ui.Paint()..filterQuality = ui.FilterQuality.medium,
    );
    final p = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          fontFamily: 'Fredoka',
          fontSize: 12,
          color: ui.Color(0xffffffff),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    p.paint(c, at + const ui.Offset(4, 1));
  }
  final picture = recorder.endRecording();
  final image = await picture.toImage(
    (fw * cols).toInt(),
    ((fh + 16) * rows).toInt(),
  );
  folder.createSync(recursive: true);
  File('${folder.path}/$name.png').writeAsBytesSync(await png(image));
  image.dispose();
  picture.dispose();
}

/// [rect] of [image], [scale] times bigger.
Future<ui.Image> zoom(ui.Image image, ui.Rect rect, double scale) {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawImageRect(
    image,
    rect,
    ui.Rect.fromLTWH(0, 0, rect.width * scale, rect.height * scale),
    ui.Paint()..filterQuality = ui.FilterQuality.none,
  );
  return recorder.endRecording().toImage(
    (rect.width * scale).round(),
    (rect.height * scale).round(),
  );
}
