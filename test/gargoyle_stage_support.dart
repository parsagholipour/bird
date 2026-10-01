// Test support for the Searchlight Gargoyle's staging: a REAL game (BirdGame
// over a real FlightSimulation of level 3-4, New York's night held) stepped
// at 60 Hz through the arrival, the fight and the defeat, rendered through
// the real renderer (backdrop, boss layer, bird, letterbox and cards, health
// bar). Used by gargoyle_staging_test.dart and the visual-review generators.
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/game/bird_game.dart';
import 'package:push_up_bird/game/boss_encounter_art.dart';
import 'package:push_up_bird/game/boss_motion.dart';
import 'package:push_up_bird/game/gargoyle_boss_rig.dart';
import 'package:push_up_bird/game/gargoyle_encounter_art.dart';
import 'package:push_up_bird/game/gargoyle_layout.dart';

import 'campaign_flight.dart';
import 'gargoyle_pilot.dart';
import 'ny_plans.dart';
import 'proof/gargoyle_stage.dart' show gBoss;

/// A level-3-4 flight stopped at the first frame of the Gargoyle's arrival
/// (boss age 0), the run-up flown by the shared bot with no sprint.
FlightSimulation arrivalSim({double width = 2.2, int weaponDamage = BirdRock.baseDamage}) {
  final sim = nyFlight(gargoylePlan(), weaponDamage: weaponDamage);
  flyLevel(sim, viewportWidth: width, sprintWhen: (sim, frame) => false, until: (sim) => sim.boss != null);
  final boss = sim.boss;
  if (boss == null || !boss.isGargoyle) throw StateError('the flight did not reach the Gargoyle');
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

/// A real game with the Gargoyle on stage.
class Stage {
  Stage(this.game, this.sim, this.width, {required this.reduced});
  final BirdGame game;
  final FlightSimulation sim;

  /// The screen's width in px (its height is always 360).
  final double width;
  final bool reduced;

  /// Where the bird is held while [hold] is on (the arrival coasts, and a
  /// review wants the bird exactly where the shot says).
  double birdY = .5;
  bool hold = true;

  /// While the bird is held, whether the rules may hurt it (a review of the
  /// SPOTTED! moment turns it on).
  bool vulnerable = false;
  final pilot = Pilot();

  SkyBoss get boss => sim.boss!;
  double get aspect => width / 360;

  /// One 1/60 s step: the bird held at [birdY], or flown by the pilot.
  void tick({double dt = 1 / 60}) {
    if (hold) {
      sim
        ..birdY = birdY
        ..velocity = 0
        ..hearts = 3;
      sim.invulnerableUntil = vulnerable ? 0 : sim.elapsed + 1;
      frame(sim, dt: dt, width: aspect);
      sim
        ..birdY = birdY
        ..velocity = 0;
    } else {
      final tap = pilot.flap(sim);
      if (boss.phase == BossPhase.attacking && pilot.shoot(sim)) sim.shoot();
      frame(sim, flap: tap, dt: dt, width: aspect);
    }
  }

  /// Steps until the boss's age is [age] (to a 1/60 s).
  void runTo(double age) {
    var guard = 0;
    while (sim.boss != null && boss.age < age - 1e-6 && guard++ < 60 * 60) {
      tick();
    }
  }

  /// Steps to [t] seconds into combat.
  void fightTo(double t) => runTo(boss.arrivalDuration + t);

  /// Steps to cycle [k]'s second [x].
  void cycleTo(int k, double x) => fightTo(k * 9.0 + x);

  /// A rock that hits the lamp now.
  void rock() => sim.rocks.add(BirdRock(x: boss.x - .12, y: boss.y));

  /// One frame of the whole game.
  Future<ui.Image> render() async {
    final recorder = ui.PictureRecorder();
    game.render(ui.Canvas(recorder));
    final picture = recorder.endRecording();
    final image = await picture.toImage(width.toInt(), 360);
    picture.dispose();
    return image;
  }

  Future<ui.Image> at(double age) async {
    runTo(age);
    return render();
  }
}

Future<Stage> stage(WidgetTester tester, double width, {bool reduced = false, bool arrival = true}) async {
  tester.view.physicalSize = ui.Size(width, 360);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final sim = arrivalSim(width: width / 360);
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
  return Stage(game, sim, width, reduced: reduced)..tick();
}

Future<void> loadFonts() async {
  for (final family in ['Fredoka', 'Nunito']) {
    await (FontLoader(family)..addFont(rootBundle.load('assets/fonts/$family.ttf'))).load();
  }
}

Future<Uint8List> png(ui.Image image) async => (await image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();

Future<Uint8List> rgba(ui.Image image) async => (await image.toByteData())!.buffer.asUint8List();

/// Labelled frames in a contact sheet, [cols] wide, each at [scale].
Future<void> sheet(Directory folder, String name, List<(String, ui.Image)> frames, {int cols = 3, double scale = 1}) async {
  final fw = frames.first.$2.width * scale, fh = 360 * scale;
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

Future<void> disposeAll(List<(String, ui.Image)> frames) async {
  for (final (_, image) in frames) {
    image.dispose();
  }
}


// ----------------------------------------------- pure states and pixels --

/// A canvas that draws nothing and remembers the layers a frame opened (with
/// the transform at that moment), the blurs it asked for, the rects it filled
/// and how many things it drew.
class Rec implements ui.Canvas {
  var _m = <double>[1, 0, 0, 1, 0, 0];
  final _stack = <List<double>>[];
  final layers = <({ui.Rect bounds, List<double> matrix, double alpha})>[];
  final rects = <({ui.Rect rect, ui.Color color})>[];
  int blurs = 0;
  int draws = 0;
  int maxLayerDepth = 0;
  int _depth = 0;
  final _open = <bool>[];

  @override
  void save() {
    _stack.add([..._m]);
    _open.add(false);
  }

  @override
  void restore() {
    _m = _stack.removeLast();
    if (_open.removeLast()) _depth--;
  }

  @override
  void saveLayer(ui.Rect? bounds, ui.Paint paint) {
    layers.add((bounds: bounds!, matrix: [..._m], alpha: paint.color.a));
    save();
    _open[_open.length - 1] = true;
    _depth++;
    maxLayerDepth = math.max(maxLayerDepth, _depth);
  }

  @override
  void translate(double dx, double dy) {
    _m[4] += _m[0] * dx + _m[2] * dy;
    _m[5] += _m[1] * dx + _m[3] * dy;
  }

  @override
  void scale(double sx, [double? sy]) {
    sy ??= sx;
    _m[0] *= sx;
    _m[1] *= sx;
    _m[2] *= sy;
    _m[3] *= sy;
  }

  @override
  void rotate(double r) {
    final co = math.cos(r), si = math.sin(r);
    final a = _m[0], b = _m[1], c = _m[2], d = _m[3];
    _m[0] = a * co + c * si;
    _m[1] = b * co + d * si;
    _m[2] = -a * si + c * co;
    _m[3] = -b * si + d * co;
  }

  void _p(ui.Paint paint) {
    draws++;
    if (paint.maskFilter != null) blurs++;
  }

  @override
  void drawRect(ui.Rect rect, ui.Paint paint) {
    _p(paint);
    rects.add((rect: rect, color: paint.color));
  }

  @override
  void drawPath(ui.Path p, ui.Paint paint) => _p(paint);
  @override
  void drawCircle(ui.Offset c, double r, ui.Paint paint) => _p(paint);
  @override
  void drawLine(ui.Offset a, ui.Offset b, ui.Paint paint) => _p(paint);
  @override
  void drawOval(ui.Rect r, ui.Paint paint) => _p(paint);
  @override
  void drawRRect(ui.RRect r, ui.Paint paint) => _p(paint);
  @override
  void drawArc(ui.Rect r, double a, double b, bool c, ui.Paint paint) => _p(paint);
  @override
  void drawParagraph(ui.Paragraph p, ui.Offset o) => draws++;
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

FlightSimulation? _base;

/// The one flight (level 3-4's run-up) the pure tests dress with a boss.
FlightSimulation simOf(SkyBoss boss, {double birdY = .5, List<BossAmmo> ammo = const [], double elapsed = 40}) {
  final sim = _base ??= arrivalSim();
  sim
    ..boss = boss
    ..birdY = birdY
    ..elapsed = elapsed;
  sim.bossAmmo
    ..clear()
    ..addAll(ammo);
  sim.rocks.clear();
  return sim;
}

/// A boss as the rules hold him [combat] seconds into the fight (negative: in
/// the arrival, -4.6 its first frame) on a screen [width] px wide.
SkyBoss bossAt(
  double combat, {
  double width = 640,
  bool fury = false,
  bool slit = false,
  BeamSide side = BeamSide.high,
  double? hitAgo,
  double? glanceAgo,
  double? deadFor,
  double? enragedAgo,
}) {
  final b = gBoss(combat, fury: fury, slit: slit, side: side, hitAgo: hitAgo, glanceAgo: glanceAgo, deadFor: deadFor, aspect: width / 360, enragedAgo: enragedAgo);
  if (hitAgo != null) b.lastDamage = 10;
  if (combat < 0) {
    // In the arrival the rules slide him in from just off the edge: parked at
    // width + .3 until .95 s, then easing out (cubic) to his anchor by 2.65 s.
    final entrance = ((b.age - .95) / 1.7).clamp(0.0, 1.0);
    final ease = 1 - math.pow(1 - entrance, 3);
    b.x = (width / 360 + .3) * (1 - ease) + b.x * ease;
  }
  return b;
}

BossMotion motion(SkyBoss b, {bool reduced = false}) => BossMotion(b, reducedMotion: reduced);

/// One whole encounter frame of [boss] (backdrop, boss layer, foreground) into
/// [canvas] on a screen [width] px wide.
void encounter(ui.Canvas canvas, SkyBoss boss, double width, {bool reduced = false, double birdY = .5, List<BossAmmo> ammo = const []}) {
  final size = ui.Size(width, 360);
  final sim = simOf(boss, birdY: birdY, ammo: ammo);
  final m = motion(boss, reduced: reduced);
  BossEncounterArt.backdrop(canvas, size, boss, m);
  BossEncounterArt.paint(canvas, size, sim, m);
  BossEncounterArt.foreground(canvas, size, sim, m);
}

Future<Uint8List> raster(void Function(ui.Canvas c) draw, double width, {double height = 360}) async {
  final rec = ui.PictureRecorder();
  final c = ui.Canvas(rec);
  c.drawRect(ui.Rect.fromLTWH(0, 0, width, height), ui.Paint()..color = const ui.Color(0xff1b1f3a));
  draw(c);
  final pic = rec.endRecording();
  final image = await pic.toImage(width.toInt(), height.toInt());
  final data = await rgba(image);
  image.dispose();
  pic.dispose();
  return data;
}

/// How many pixels differ (in colour) between two rasters of the same size.
int changed(Uint8List a, Uint8List b) {
  var n = 0;
  for (var i = 0; i < a.length; i += 4) {
    if (a[i] != b[i] || a[i + 1] != b[i + 1] || a[i + 2] != b[i + 2]) n++;
  }
  return n;
}

/// The creature alone (no ledge, no loosened blade: both leave the screen by
/// design) under the staging transform of [boss], on a canvas [width] wide with
/// [pad] px of margin on every side but the left, as RGBA; [layer] wraps him in
/// the white-out's layer, bounded to [GargoyleBossRig.bounds].
Future<({Uint8List rgba, int w, int h, double bar})> creaturePixels(SkyBoss boss, double width, {bool reduced = false, int pad = 40, bool layer = false}) async {
  final sim = simOf(boss);
  final m = motion(boss, reduced: reduced);
  final f = GargoyleEncounterArt.frame(m, 360);
  final pose = GargoyleEncounterArt.pose(sim, m);
  final body = f.heart + GargoyleEncounterArt.jolt(m, 360);
  final rec = ui.PictureRecorder();
  final c = ui.Canvas(rec);
  c.translate(0, pad.toDouble());
  c.translate(body.dx, body.dy);
  c.scale(f.unit);
  if (layer) c.saveLayer(GargoyleBossRig.bounds, ui.Paint());
  GargoyleBossRig.paintPose(c, pose, plinth: false, only: GargoyleLayout.zOrder.where((p) => p != 'shed' && p != 'ledge').toSet());
  if (layer) c.restore();
  final w = width.toInt() + pad, h = 360 + 2 * pad;
  final pic = rec.endRecording();
  final image = await pic.toImage(w, h);
  final data = await rgba(image);
  image.dispose();
  pic.dispose();
  return (rgba: data, w: w, h: h, bar: 360 * .082 * GargoyleEncounterArt.focus(m));
}

/// How many solid (alpha >= 200) pixels of him the layer's bounds cut off.
Future<int> clippedByLayer(SkyBoss boss, double width, {bool reduced = false}) async {
  final free = await creaturePixels(boss, width, reduced: reduced);
  final held = await creaturePixels(boss, width, reduced: reduced, layer: true);
  var cut = 0;
  for (var i = 3; i < free.rgba.length; i += 4) {
    if (free.rgba[i] >= 200 && held.rgba[i] < 200) cut++;
  }
  return cut;
}

/// How far his solid pixels reach past the screen's top (or the letterbox's
/// lower edge), its bottom (or the letterbox's upper edge) and, [right] true,
/// its right edge, in px.
Future<({double top, double bottom, double right})> reach(SkyBoss boss, double width, {bool reduced = false, bool right = true}) async {
  const pad = 40;
  final px = await creaturePixels(boss, width, reduced: reduced, pad: pad);
  var top = 0.0, bottom = 0.0, beyond = 0.0;
  bool solid(int x, int y) => px.rgba[(y * px.w + x) * 4 + 3] >= 200;
  for (var y = 0; y < pad + px.bar.ceil(); y++) {
    for (var x = 0; x < width.toInt(); x++) {
      if (solid(x, y)) {
        top = math.max(top, px.bar + pad - y);
        break;
      }
    }
  }
  for (var y = pad + 360 - px.bar.floor(); y < px.h; y++) {
    for (var x = 0; x < width.toInt(); x++) {
      if (solid(x, y)) {
        bottom = math.max(bottom, y + 1 - (pad + 360 - px.bar));
        break;
      }
    }
  }
  for (var x = width.toInt(); right && x < px.w; x++) {
    for (var y = 0; y < px.h; y += 2) {
      if (solid(x, y)) beyond = math.max(beyond, x + 1 - width);
    }
  }
  return (top: top, bottom: bottom, right: beyond);
}

/// Every state of the fight and the arrival the budgets and scans walk: its
/// name and the boss as the rules hold him on a screen of a given width.
List<(String, SkyBoss Function(double width))> encounterStates() => [
  for (final t in const [.4, 1.0, 1.4, 1.62, 1.68, 1.8, 2.0, 2.3, 2.5, 2.75, 2.95, 3.3, 3.6, 3.95, 4.3, 4.55])
    ('arrival $t', (w) => bossAt(t - 4.6, width: w)),
  ('perch', (w) => bossAt(1.0, width: w)),
  ('shrug flick', (w) => bossAt(4.6 - .02, width: w)),
  ('warning HIGH', (w) => bossAt(3.3, width: w)),
  ('warning LOW', (w) => bossAt(3.3, width: w, side: BeamSide.low)),
  ('sweep HIGH', (w) => bossAt(4.5, width: w)),
  ('sweep LOW', (w) => bossAt(4.5, width: w, side: BeamSide.low)),
  ('vent', (w) => bossAt(7.0, width: w)),
  ('glance', (w) => bossAt(1.0, width: w, glanceAgo: .07)),
  ('hit', (w) => bossAt(7.0, width: w, hitAgo: .06)),
  ('fury onset', (w) => bossAt(1.0, width: w, fury: true, enragedAgo: .4)),
  ('fury slit warning', (w) => bossAt(2.8, width: w, fury: true, slit: true)),
  ('fury slit', (w) => bossAt(4.5, width: w, fury: true, slit: true)),
  ('fury hit sweep', (w) => bossAt(4.5, width: w, fury: true, hitAgo: .06)),
  for (final d in const [.04, .1, .2, .3, .5, .7, .86, .95, 1.1, 1.4, 1.8, 2.4, 3.0, 3.6]) ('defeat $d', (w) => bossAt(1.0, width: w, deadFor: d)),
];

