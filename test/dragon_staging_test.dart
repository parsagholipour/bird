import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/tracking.dart';
import 'package:push_up_bird/game/bird_game.dart';
import 'package:push_up_bird/game/boss_encounter_art.dart';
import 'package:push_up_bird/game/boss_motion.dart';
import 'package:push_up_bird/game/dragon_boss_rig.dart';
import 'package:push_up_bird/game/dragon_head_art.dart';
import 'package:push_up_bird/game/dragon_kit.dart';
import 'package:push_up_bird/game/dragon_layout.dart';
import 'package:push_up_bird/game/dragon_pose.dart';
import 'package:push_up_bird/game/regions/world_region.dart';

import 'boss_fight_test.dart' show arena, step;
import 'dragon_enforce.dart';

/// The Ember Dragon's staging: where `BossEncounterArt` puts it in the world
/// and how it arrives, fights and falls.
///
/// Two kinds of test share this file.
///  * Assertions that hold whatever art the parts have (they use the public
///    staging helpers, the pose and the layout numbers): the envelope stays
///    on screen and between the letterbox bars, the arrival's silhouette and
///    letterbox run on their own clock, the crown starts on the head that
///    lost it, the layers stay bounded, everything is deterministic.
///  * Pixel checks of the real art through the real renderer. Until every
///    part has landed they only REPORT; `--dart-define=DRAGON_ENFORCE=true`
///    (the switch of `dragon_enforce.dart`) makes them fail.
///
/// Set `DRAGON_STAGING_REVIEW=1` to also write the review frames (arrival
/// beats, each breath beat, fury, hit, defeat; at 640 and 800 over several
/// regions) to `build/visual-review/dragon-staging/`. `DRAGON_STAGING_VIDEO=1`
/// dumps a whole encounter, arrival to victory, as 30 fps frames to
/// `.../video/` (`ffmpeg -framerate 30 -i video/%04d.png -pix_fmt yuv420p
/// dragon.mp4`).

final _review = Platform.environment['DRAGON_STAGING_REVIEW'] == '1';
final _video = Platform.environment['DRAGON_STAGING_VIDEO'] == '1';
final _folder = Directory('build/visual-review/dragon-staging');

// ------------------------------------------------------------ the stage --

/// A real game with a dragon on stage, stepped at 50 Hz.
class _Stage {
  _Stage(this.game, this.sim, this.width, this.tour);
  final BirdGame game;
  final FlightSimulation sim;
  final double width;

  /// The tour second the frames are lit from (see [WorldRegion]).
  final double tour;

  /// Light the frames by the tour's own clock instead of holding one region.
  bool live = false;
  double birdY = .5;

  SkyBoss get boss => sim.boss!;

  /// One step of [dt] seconds with the bird hovering at [birdY].
  void tick(double dt) {
    final now = (sim.elapsed + dt) * 1000;
    sim.birdY = birdY;
    sim.velocity = 0;
    sim.hearts = 3;
    sim.apply(
      const MovementInput(valid: true),
      TrackingSample(
        mode: PlayMode.touch,
        timestampMs: now,
        receivedMs: now,
        joints: const [],
      ),
      now,
    );
    sim.tick(dt, now, viewportWidth: width / 360);
  }

  void hover(double seconds) {
    for (var i = 0; i < (seconds / .02).round(); i++) {
      tick(.02);
    }
  }

  void hoverTo(double age) => hover(age - boss.age);

  void fightTo(int cycle, double t) =>
      hoverTo(boss.arrivalDuration + cycle * DragonBreath.period + t);

  /// One frame of the whole game, lit as the tour would at [tour] + the
  /// boss's age (held inside its region's 16 s hold).
  Future<ui.Image> frame() async {
    final keep = sim.elapsed;
    if (!live) sim.elapsed = tour + math.min(boss.age, 15);
    final recorder = ui.PictureRecorder();
    game.render(ui.Canvas(recorder));
    final picture = recorder.endRecording();
    sim.elapsed = keep;
    final image = await picture.toImage(width.toInt(), 360);
    picture.dispose();
    return image;
  }
}

/// The tour second that puts [region] at its calmest, [into] s into its hold.
double _tourAt(WorldRegion region, [double into = .5]) =>
    region.index * WorldTour.leg + into;

Future<_Stage> _stage(
  WidgetTester tester,
  double width,
  WorldRegion region, {
  bool reduced = false,
  int defeated = 9,
  double? startAt,
}) async {
  final sim = arena(version: FlightSimulation.currentRulesVersion)
    ..elapsed = startAt ?? FlightSimulation.bossInterval - .001
    ..bossesDefeated = defeated;
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
  final stage = _Stage(game, sim, width, _tourAt(region))..hover(.02);
  expect(sim.boss!.kind, BossKind.dragon);
  return stage;
}

Future<Uint8List> _png(ui.Image image) async => (await image.toByteData(
  format: ui.ImageByteFormat.png,
))!.buffer.asUint8List();

Future<void> _fonts() async {
  for (final family in ['Fredoka', 'Nunito']) {
    await (FontLoader(
      family,
    )..addFont(rootBundle.load('assets/fonts/$family.ttf'))).load();
  }
}

void _label(Canvas c, String text, Offset at, double size, Color color) {
  (TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(fontFamily: 'Fredoka', fontSize: size, color: color),
    ),
    textDirection: TextDirection.ltr,
  )..layout()).paint(c, at);
}

/// Frames in a labelled contact sheet, [cols] wide, each at [scale].
Future<void> _sheet(
  String name,
  List<(String, ui.Image)> frames, {
  int cols = 3,
  double scale = 1,
}) async {
  final fw = frames.first.$2.width * scale, fh = 360 * scale;
  final rows = (frames.length / cols).ceil();
  final recorder = ui.PictureRecorder();
  final c = Canvas(recorder);
  c.drawRect(
    Rect.fromLTWH(0, 0, fw * cols, (fh + 16) * rows),
    Paint()..color = const Color(0xff101223),
  );
  for (var i = 0; i < frames.length; i++) {
    final (label, image) = frames[i];
    final at = Offset(i % cols * fw, (i ~/ cols) * (fh + 16));
    c.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(at.dx + 1, at.dy + 16, fw - 2, fh - 1),
      Paint()..filterQuality = FilterQuality.medium,
    );
    _label(c, label, at + const Offset(4, 1), 12, const Color(0xffffffff));
  }
  final picture = recorder.endRecording();
  final image = await picture.toImage(
    (fw * cols).toInt(),
    ((fh + 16) * rows).toInt(),
  );
  _folder.createSync(recursive: true);
  File('${_folder.path}/$name.png').writeAsBytesSync(await _png(image));
  image.dispose();
  picture.dispose();
}

Future<void> _disposeAll(List<(String, ui.Image)> frames) async {
  for (final (_, image) in frames) {
    image.dispose();
  }
}

// ---------------------------------------------------- what a frame drew --

/// A canvas that draws nothing and remembers what a frame asked of it: the
/// rects (with their colour and the transform they were drawn under) and the
/// layers (with the transform at the moment they opened).
class _Rec implements Canvas {
  // x' = a x + c y + e, y' = b x + d y + f.
  var _m = <double>[1, 0, 0, 1, 0, 0];
  final _stack = <List<double>>[];
  final rects = <({Rect rect, Color color})>[];
  final layers = <({Rect bounds, List<double> matrix, double alpha})>[];
  int glows = 0;
  final glowScales = <double>[];

  @override
  void save() => _stack.add([..._m]);
  @override
  void restore() => _m = _stack.removeLast();
  @override
  void saveLayer(Rect? bounds, Paint paint) {
    layers.add((bounds: bounds!, matrix: [..._m], alpha: paint.color.a));
    save();
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

  @override
  void drawRect(Rect rect, Paint paint) =>
      rects.add((rect: rect, color: paint.color));
  @override
  void drawCircle(Offset c, double radius, Paint paint) {
    if (paint.shader != null) {
      glows++;
      glowScales.add(math.sqrt(_m[0] * _m[0] + _m[1] * _m[1]));
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

SkyBoss _boss({
  double? age,
  double combat = 1.2,
  BreathLane lane = BreathLane.middle,
  int hp = 0,
}) {
  final boss = SkyBoss(number: 10, x: 2, kind: BossKind.dragon, cinematic: true)
    ..fireIn = 1.8
    ..breathLane = lane;
  if (hp > 0) boss.hp = hp;
  boss.age = age ?? boss.arrivalDuration + combat;
  return boss;
}

/// A boss [death] seconds after the killing blow.
SkyBoss _dying(double death, {double combat = 3}) {
  final boss = _boss(combat: combat);
  boss.defeatedAt = boss.age - death;
  return boss;
}

BossMotion _motion(SkyBoss boss, {bool reduced = false}) =>
    BossMotion(boss, reducedMotion: reduced);

/// [boss] placed as the rules place it in a screen [width] px wide.
SkyBoss _placed(SkyBoss boss, double width, [double? y]) {
  boss.x = width / 360 - .5;
  boss.y = y ?? boss.y;
  return boss;
}

/// One `BossEncounterArt.paint` of [boss] into a recording canvas.
_Rec _paint(
  SkyBoss boss,
  double width, {
  bool reduced = false,
  double elapsed = 40,
}) {
  final rec = _Rec();
  final sim = arena(version: FlightSimulation.currentRulesVersion)
    ..elapsed = elapsed
    ..boss = boss;
  BossEncounterArt.paint(
    rec,
    Size(width, 360),
    sim,
    _motion(boss, reduced: reduced),
  );
  return rec;
}

/// One `BossEncounterArt.foreground` of [boss] into a recording canvas.
_Rec _foreground(SkyBoss boss, double width, {bool reduced = false}) {
  final rec = _Rec();
  final sim = arena(version: FlightSimulation.currentRulesVersion)..boss = boss;
  BossEncounterArt.foreground(
    rec,
    Size(width, 360),
    sim,
    _motion(boss, reduced: reduced),
  );
  return rec;
}

/// The dragon painted alone under the staging transform of its [boss], onto a
/// canvas [width] px wide that also shows [pad] px beyond every edge but the
/// left, as raw RGBA. Returns the pixels and how the letterbox stands.
Future<({Uint8List rgba, int w, int h, double bar})> _dragonPixels(
  SkyBoss boss,
  double width, {
  bool reduced = false,
  int pad = 40,
  bool crown = true,
  bool layer = false,
  DragonPose? pose,
  BossMotion? motion,
}) async {
  final m = motion ?? _motion(boss, reduced: reduced);
  final frame = BossEncounterArt.dragonFrame(m, 360);
  final p = pose ?? DragonPose(boss, m);
  final recorder = ui.PictureRecorder();
  final c = Canvas(recorder);
  c.translate(0, pad.toDouble());
  final body = BossEncounterArt.dragonBody(p, m, 360);
  c.translate(body.dx, body.dy);
  c.rotate(frame.turn);
  c.scale(frame.sx, frame.sy);
  // Inside the layer the silhouette, the white-out and the fade are drawn in.
  if (layer) c.saveLayer(DragonBossRig.bounds, Paint());
  DragonBossRig.paintPose(c, p, crown: crown);
  if (layer) c.restore();
  final w = width.toInt() + pad, h = 360 + 2 * pad;
  final image = await recorder.endRecording().toImage(w, h);
  final data = (await image.toByteData())!.buffer.asUint8List();
  image.dispose();
  return (
    rgba: data,
    w: w,
    h: h,
    bar: 360 * .082 * BossEncounterArt.dragonFocus(m),
  );
}

/// How many of the dragon's solid pixels the layer of the silhouette, the
/// white-out and the fade ([DragonBossRig.bounds]) cuts off: the same figure
/// painted with and without it.
Future<int> _clippedByLayer(
  SkyBoss boss,
  double width, {
  bool reduced = false,
}) async {
  final free = await _dragonPixels(boss, width, reduced: reduced);
  final held = await _dragonPixels(boss, width, reduced: reduced, layer: true);
  var cut = 0;
  for (var i = 3; i < free.rgba.length; i += 4) {
    if (free.rgba[i] >= 200 && held.rgba[i] < 200) cut++;
  }
  return cut;
}

/// How far the dragon's solid pixels (fills and ink; glows stay under
/// alpha 200) reach past the screen and the letterbox bars.
Future<({double top, double bottom, double right})> _reach(
  SkyBoss boss,
  double width, {
  bool reduced = false,
  bool right = true,
}) async {
  const pad = 40;
  final px = await _dragonPixels(boss, width, reduced: reduced, pad: pad);
  var top = 0.0, bottom = 0.0, beyond = 0.0;
  bool solid(int x, int y) => px.rgba[(y * px.w + x) * 4 + 3] >= 200;
  // Rows above the top edge of the picture: the screen begins at [pad].
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

// ------------------------------------------------------ review sequences --

/// The five beats of the arrival and the moments around them.
const _arrivalBeats = <(String, double)>[
  ('1.60 silhouette', 1.6),
  ('1.86 eye wakes', 1.86),
  ('1.92 STRIKE', 1.92),
  ('1.98 cross-fade', 1.98),
  ('2.08 colour', 2.08),
  ('2.30 settles', 2.3),
  ('2.55 wind', 2.55),
  ('2.95 ROAR', 2.95),
  ('3.30 roar ends', 3.3),
  ('3.70 title', 3.7),
  ('4.10 bar leaves', 4.1),
  ('4.40 free', 4.4),
];

/// Writes [image] as `<folder>/<name>.png`.
Future<void> _write(String name, ui.Image image) async {
  _folder.createSync(recursive: true);
  File('${_folder.path}/$name.png').writeAsBytesSync(await _png(image));
}

Future<void> _arrival(_Stage s, String tag) async {
  final frames = <(String, ui.Image)>[];
  for (final (label, age) in _arrivalBeats) {
    s.hoverTo(age);
    final image = await s.frame();
    await _write('f-$tag-arrival-${age.toStringAsFixed(2)}', image);
    frames.add((label, image));
  }
  await _sheet('arrival-$tag', frames, cols: 3, scale: .75);
  await _disposeAll(frames);
}

/// The strike at 50 Hz: every frame from the eye waking to the colour in.
Future<void> _strike(_Stage s, String tag) async {
  for (var age = 1.8; age < 2.2; age += .02) {
    s.hoverTo(age);
    final image = await s.frame();
    await _write('s-$tag-${age.toStringAsFixed(2)}', image);
    image.dispose();
  }
}

/// [rect] of [image] blown up [scale] times, pixel for pixel.
Future<ui.Image> _zoom(ui.Image image, Rect rect, double scale) async {
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawImageRect(
    image,
    rect,
    Offset.zero & rect.size * scale,
    Paint()..filterQuality = FilterQuality.none,
  );
  final picture = recorder.endRecording();
  final zoomed = await picture.toImage(
    (rect.width * scale).round(),
    (rect.height * scale).round(),
  );
  picture.dispose();
  return zoomed;
}

/// The roar as a flipbook, every 0.04 s from 2.60 to 3.48: whole frames and
/// close-ups of the head (x2, on a crop that holds still), so the fire is
/// judged in motion and not only on the arrival's three fixed beats.
Future<void> _roar(_Stage s, String tag) async {
  final frames = <(String, ui.Image)>[], heads = <(String, ui.Image)>[];
  s.hoverTo(2.6);
  final heart = BossEncounterArt.dragonFrame(_motion(s.boss), 360).heart;
  final crop = Rect.fromLTWH(
    heart.dx - 250,
    math.max(0, heart.dy - 190),
    300,
    180,
  );
  for (var i = 0; i < 23; i++) {
    final age = 2.6 + i * .04;
    s.hoverTo(age);
    final image = await s.frame();
    final head = await _zoom(image, crop, 2);
    final label = age.toStringAsFixed(2);
    await _write('f-$tag-roar-$label', image);
    await _write('h-$tag-roar-$label', head);
    frames.add((label, image));
    heads.add((label, head));
  }
  await _sheet('roar-$tag', frames, cols: 4, scale: .5);
  await _sheet('roar-head-$tag', heads, cols: 4, scale: .5);
  await _disposeAll(frames);
  await _disposeAll(heads);
}

/// The swarm call and the fireball it meets at the jaws: 7.5 to 8.4 s.
Future<void> _call(_Stage s, String tag) async {
  final frames = <(String, ui.Image)>[];
  s.birdY = .8;
  for (final t in const [7.5, 7.6, 7.7, 7.8, 7.9, 8.0, 8.1, 8.2, 8.3, 8.4]) {
    s.fightTo(0, t);
    final image = await s.frame();
    await _write('f-$tag-call-${t.toStringAsFixed(2)}', image);
    frames.add(('call $t  charge ${s.boss.charge.toStringAsFixed(2)}', image));
  }
  await _sheet('call-$tag', frames, cols: 3, scale: .75);
  await _disposeAll(frames);
}

/// The fight: the fireball (charge, launch), each beat of the breath and
/// the swarm call, then fury, a hit and the heart hit, then the defeat.
Future<void> _fight(_Stage s, String tag) async {
  final boss = s.boss;
  // The fireball forming and leaving the jaws.
  final volley = <(String, ui.Image)>[];
  s.birdY = .5;
  s.fightTo(0, .4);
  for (var i = 0; i < 100 && boss.charge < .5; i++) {
    s.hover(.02);
  }
  volley.add(('charge ${boss.charge.toStringAsFixed(2)}', await s.frame()));
  for (var i = 0; i < 100 && boss.charge < .9; i++) {
    s.hover(.02);
  }
  volley.add(('charge ${boss.charge.toStringAsFixed(2)}', await s.frame()));
  final volleys = boss.volleys;
  for (var i = 0; i < 100 && boss.volleys == volleys; i++) {
    s.hover(.02);
  }
  for (final tau in [0.0, .04, .10, .20]) {
    if (tau > 0) s.hover(.04 + (tau > .05 ? .02 : 0));
    volley.add((
      'launch +${(boss.age - boss.lastVolleyAt).toStringAsFixed(2)}',
      await s.frame(),
    ));
  }
  await _sheet('fireball-$tag', volley, cols: 3, scale: .75);
  await _disposeAll(volley);

  // The breath, beat by beat (cycle 1, so the fireballs are out of the way).
  final beats = <(String, ui.Image)>[];
  for (final (label, t, y) in const [
    ('3.6 alert', 3.6, .5),
    ('4.15 sniff', 4.15, .5),
    ('4.6 rear', 4.6, .5),
    ('5.05 HOLD', 5.05, .8),
    ('5.20 snap', 5.20, .8),
    ('5.23 snap', 5.23, .8),
    ('5.27 lunge', 5.27, .8),
    ('5.28 IMPACT', 5.28, .8),
    ('5.30 impact', 5.30, .8),
    ('5.32 ignite', 5.32, .8),
    ('5.80 burn', 5.8, .8),
    ('7.20 gutter', 7.2, .8),
    ('7.45 call wind', 7.45, .8),
    ('7.80 CALL', 7.8, .8),
  ]) {
    s.birdY = y;
    s.fightTo(1, t);
    final image = await s.frame();
    await _write('f-$tag-breath-$t', image);
    beats.add((label, image));
  }
  await _sheet('breath-$tag', beats, cols: 3, scale: .75);
  await _disposeAll(beats);

  // A hit, then a hit on the open heart, then the tipping into fury.
  Future<void> rock() async {
    s.sim.rocks.add(BirdRock(x: boss.x - .12, y: boss.y));
    s.hover(.02);
  }

  final hits = <(String, ui.Image)>[];
  s.birdY = .5;
  s.fightTo(2, 1.0);
  await rock();
  for (final dt in [.04, .08, .12]) {
    s.hover(.04);
    hits.add((
      'hit +${(boss.age - boss.lastHitAt).toStringAsFixed(2)}',
      await s.frame(),
    ));
    if (dt > .1) break;
  }
  s.fightTo(2, DragonBreath.blastAt - .05);
  s.birdY = .8;
  s.hover(.02);
  await rock();
  s.hover(.06);
  hits.add((
    'HEART hit +${(boss.age - boss.lastHitAt).toStringAsFixed(2)}',
    await s.frame(),
  ));
  await _sheet('hit-$tag', hits, cols: 2, scale: .75);
  await _disposeAll(hits);

  final fury = <(String, ui.Image)>[];
  s.birdY = .5;
  s.fightTo(3, .2);
  boss.hp = boss.maxHp ~/ 2 + 5;
  await rock();
  expect(boss.enraged, isTrue);
  for (final dt in [.02, .06, .04, .04, .3, .4]) {
    s.hover(dt);
    final image = await s.frame();
    fury.add((
      'fury +${(boss.age - boss.enragedAt).toStringAsFixed(2)}',
      image,
    ));
  }
  await _sheet('fury-$tag', fury, cols: 3, scale: .75);
  await _disposeAll(fury);

  // The fury's breath: the edges it pushes the figure to.
  final furyBreath = <(String, ui.Image)>[];
  for (final (label, t, y) in const [
    ('fury 3.0', 3.0, .5),
    ('fury 4.6 rear', 4.6, .5),
    ('fury 5.05 HOLD', 5.05, .8),
    ('fury 5.28 IMPACT', 5.28, .8),
    ('fury 5.34', 5.34, .8),
    ('fury 6.0 blast', 6.0, .8),
    ('fury 7.85 CALL', 7.85, .8),
    ('fury 9.15 CALL 2', 9.15, .8),
  ]) {
    s.birdY = y;
    s.fightTo(4, t);
    final image = await s.frame();
    await _write('f-$tag-furybreath-$t', image);
    furyBreath.add((label, image));
  }
  await _sheet('furybreath-$tag', furyBreath, cols: 2, scale: .75);
  await _disposeAll(furyBreath);

  // The defeat.
  final death = <(String, ui.Image)>[];
  s.birdY = .5;
  s.sim.bossAmmo.clear();
  s.sim.rocks.addAll(
    List.generate(boss.hp, (_) => BirdRock(x: boss.x - .12, y: boss.y)),
  );
  s.hover(.02);
  expect(boss.phase, BossPhase.defeated);
  for (final at in const [
    .04,
    .16,
    .30,
    .32,
    .60,
    .86,
    1.0,
    1.2,
    1.4,
    1.56,
    1.7,
    1.9,
    2.2,
    2.6,
    3.0,
    3.4,
    3.7,
  ]) {
    s.hover(at - (boss.age - boss.defeatedAt!));
    final image = await s.frame();
    await _write('f-$tag-defeat-${at.toStringAsFixed(2)}', image);
    death.add((
      'death +${(boss.age - boss.defeatedAt!).toStringAsFixed(2)}',
      image,
    ));
  }
  await _sheet('defeat-$tag', death, cols: 3, scale: .75);
  await _disposeAll(death);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // The title card lays its lettering out once: the fonts come first.
  setUpAll(_fonts);

  group('the arrival runs on its own clock', () {
    double sil(double age, {bool reduced = false}) =>
        BossEncounterArt.dragonSilhouette(
          _motion(_boss(age: age), reduced: reduced),
        );

    test(
      'the silhouette holds to 1.9 s, then the colour floods in over 0.12 s',
      () {
        for (final age in [0.0, .9, 1.65, 1.8, 1.89, 1.9]) {
          expect(sil(age), 1.0, reason: 'still a silhouette at $age s');
        }
        // The rules' own fade would already be under way at 1.8 s.
        expect(_motion(_boss(age: 1.8)).silhouette, lessThan(.95));
        expect(sil(1.96), inExclusiveRange(.2, .8));
        expect(sil(2.02), 0.0);
        expect(sil(2.5), 0.0);
        expect(sil(1.9 + .11), greaterThan(0));
      },
    );

    test('Reduced Motion cross-fades over 0.25 s and never flashes', () {
      expect(sil(1.9, reduced: true), 1.0);
      expect(
        sil(2.0, reduced: true),
        1.0,
        reason: 'no lightning to time it to',
      );
      expect(sil(2.12, reduced: true), inExclusiveRange(.1, .9));
      expect(sil(2.26, reduced: true), 0.0);
      for (final age in [1.9, 1.95, 2.05, 2.2]) {
        final rects = _paint(
          _placed(_boss(age: age), 640),
          640,
          reduced: true,
        ).rects;
        expect(
          rects.where((r) => r.rect == const Rect.fromLTWH(0, 0, 640, 360)),
          isEmpty,
          reason: 'no lightning at $age s under Reduced Motion',
        );
      }
    });

    test('nothing is a silhouette outside the arrival', () {
      expect(
        sil(
          SkyBoss(number: 1, x: 1, kind: BossKind.dragon).arrivalDuration + 1,
        ),
        0.0,
      );
      expect(BossEncounterArt.dragonSilhouette(_motion(_dying(.5))), 0.0);
    });

    test(
      'the lightning blanches the world behind it, .45 fading over .25 s',
      () {
        const screen = Rect.fromLTWH(0, 0, 640, 360);
        double flash(double age) {
          final hits = _paint(
            _placed(_boss(age: age), 640),
            640,
          ).rects.where((r) => r.rect == screen);
          return hits.isEmpty ? 0 : hits.first.color.a;
        }

        expect(flash(1.86), 0.0, reason: 'the strike has not landed');
        expect(flash(1.9), closeTo(.45, .01));
        expect(flash(2.0), inExclusiveRange(.05, .4));
        expect(flash(2.15), 0.0);
      },
    );
  });

  group('the letterbox', () {
    double focus(double age) =>
        BossEncounterArt.dragonFocus(_motion(_boss(age: age)));

    test('opens for the roar, leaves 0.2 s earlier than the others', () {
      for (final age in [0.0, .3, .65, 1.0, 2.0, 2.4, 3.7, 3.8]) {
        expect(
          focus(age),
          closeTo(_motion(_boss(age: age)).focus, 1e-9),
          reason: '$age s',
        );
      }
      // Widescreen for the roar (2.65 to 3.45), and back for the caption.
      expect(focus(3.0), lessThan(.5 * _motion(_boss(age: 3.0)).focus));
      expect(focus(3.5), greaterThan(.5));
      // Out 0.2 s early.
      expect(focus(4.0), lessThan(_motion(_boss(age: 4.0)).focus));
      expect(focus(4.4), 0.0);
      expect(_motion(_boss(age: 4.4)).focus, greaterThan(.1));
      // A still frame under Reduced Motion.
      expect(
        BossEncounterArt.dragonFocus(_motion(_boss(age: 3.0), reduced: true)),
        closeTo(1, 1e-9),
      );
      // The plate sits as high as the bars left: seen through `foreground`.
      final bars = _foreground(_boss(age: 4.2), 640).rects.take(2).toList();
      expect(bars.first.rect.height, closeTo(360 * .082 * focus(4.2), 1e-6));
      expect(
        bars.first.rect.height,
        lessThan(360 * .082 * _motion(_boss(age: 4.2)).focus),
      );
    });

    test('is the shared one, unchanged, for every other boss', () {
      for (final kind in [
        BossKind.baronBat,
        BossKind.spitterBeetle,
        BossKind.duskMoth,
        BossKind.pirate,
      ]) {
        for (final age in [1.0, 3.0, 4.2, 4.5]) {
          final boss = SkyBoss(number: 1, x: 1.5, kind: kind, cinematic: true)
            ..age = age;
          final bars = _foreground(
            boss,
            640,
          ).rects.where((r) => r.rect.width == 640 && r.rect.height < 100);
          expect(bars, isNotEmpty, reason: '$kind at $age s');
          expect(
            bars.first.rect.height,
            closeTo(360 * .082 * _motion(boss).focus, 1e-6),
            reason: '$kind at $age s',
          );
        }
        // And the shared soft flash on the burst, not the dragon's.
        final dead = SkyBoss(number: 1, x: 1.5, kind: kind, cinematic: true);
        dead.age = dead.arrivalDuration + 3;
        dead.defeatedAt = dead.age - SkyBoss.burstAt - .05;
        final flash = _foreground(
          dead,
          640,
        ).rects.where((r) => r.rect == const Rect.fromLTWH(0, 0, 640, 360));
        expect(
          flash.first.color.a,
          closeTo(.3 * math.pow(1 - .05 / .24, 2), .01),
          reason: '$kind',
        );
      }
    });

    test('slides in behind the dying dragon instead of cutting across it', () {
      double dead(double death) =>
          BossEncounterArt.dragonFocus(_motion(_dying(death)));
      expect(dead(0), closeTo(0, 1e-9));
      expect(dead(.4), closeTo(0, 1e-9));
      expect(dead(.7), inExclusiveRange(.1, .9));
      expect(dead(1.1), closeTo(1, 1e-9));
      expect(dead(2.0), closeTo(1, 1e-9));
      expect(dead(3.8), closeTo(0, 1e-9));
    });
  });

  group('the dragon stays on screen', () {
    test(
      'its envelope fits 640 and 800 in every combat state, squash included',
      () {
        // Squash and stretch come from a charge, a shot's recoil and a hit.
        final states = <(String, void Function(SkyBoss))>[
          ('idle', (b) {}),
          ('charged', (b) => b.fireIn = .01),
          ('recoil', (b) => b.lastVolleyAt = b.age - .13),
          ('hit', (b) => b.lastHitAt = b.age - .14),
          (
            'hit + recoil',
            (b) {
              b.lastHitAt = b.age - .14;
              b.lastVolleyAt = b.age - .13;
            },
          ),
        ];
        for (final width in [640.0, 800.0]) {
          for (final y in [.43, .5, .57]) {
            for (final (name, setup) in states) {
              final boss = _placed(_boss(combat: 3.7), width, y);
              setup(boss);
              final m = _motion(boss);
              final f = BossEncounterArt.dragonFrame(m, 360);
              Offset at(double x, double y) =>
                  f.heart + DragonKit.turn(Offset(x * f.sx, y * f.sy), f.turn);
              const e = DragonLayout.envelope;
              for (final corner in [
                e.topLeft,
                e.topRight,
                e.bottomLeft,
                e.bottomRight,
              ]) {
                final p = at(corner.dx, corner.dy);
                expect(
                  p.dy,
                  greaterThanOrEqualTo(0),
                  reason: '$name at y $y: the top is cropped',
                );
                expect(
                  p.dy,
                  lessThanOrEqualTo(360),
                  reason: '$name at y $y: the bottom is cropped',
                );
                if (corner.dx > 0) {
                  expect(
                    p.dx,
                    lessThanOrEqualTo(width),
                    reason: '$name at y $y: the right is cropped',
                  );
                }
              }
              expect(
                f.turn,
                0.0,
                reason: 'the pose owns the figure\'s turn in combat',
              );
              // No squash at all: it followed the rules' charge and popped at
              // every launch.
              expect(f.sx, closeTo(360 * SkyBoss.radius, 1e-9));
              expect(f.sy, closeTo(360 * SkyBoss.radius, 1e-9));
            }
          }
        }
      },
    );

    test(
      'it stands level, at its true size, between the bars from the strike on',
      () {
        for (final width in [640.0, 800.0]) {
          for (var age = 1.9; age < 4.55; age += .1) {
            final boss = _placed(
              _boss(age: age),
              width,
              .5 + .08 * math.sin(age),
            );
            final m = _motion(boss);
            final f = BossEncounterArt.dragonFrame(m, 360);
            // Level despite the rules' swoop, centred between the bars.
            final bars = BossEncounterArt.dragonFocus(m);
            expect(
              f.heart.dy,
              closeTo(180 + .075 * 360 * SkyBoss.radius * bars, 1e-6),
              reason: 'level at $age s',
            );
            expect(
              f.sx,
              closeTo(360 * SkyBoss.radius, 1e-9),
              reason: 'true size at $age s',
            );
            expect(f.turn, 0.0);
            // The calm envelope, with the roar's lift, between the bars.
            final bar = 360 * .082 * BossEncounterArt.dragonFocus(m);
            final rest = DragonLayout.restEnvelope.expandToInclude(
              const Rect.fromLTRB(-2.9, -3.6, 4.22, 3.45),
            );
            expect(
              f.heart.dy + rest.top * f.sy,
              greaterThanOrEqualTo(bar),
              reason: 'top at $age s',
            );
            expect(
              f.heart.dy + rest.bottom * f.sy,
              lessThanOrEqualTo(360 - bar),
              reason: 'bottom at $age s',
            );
          }
        }
      },
    );

    test('the frames join: arrival to combat to defeat', () {
      for (final width in [640.0, 800.0]) {
        final arrival = BossEncounterArt.dragonFrame(
          _motion(_placed(_boss(age: 4.6 - 1e-6), width, .5)),
          360,
        );
        final combat = BossEncounterArt.dragonFrame(
          _motion(_placed(_boss(combat: 0), width, .5)),
          360,
        );
        expect((arrival.heart - combat.heart).distance, lessThan(1e-3));
        expect(arrival.sx, closeTo(combat.sx, 1e-6));
        expect(arrival.turn, closeTo(combat.turn, 1e-6));
        final swoop = BossEncounterArt.dragonFrame(
          _motion(_placed(_boss(age: 1.9 - 1e-6), width, .58)),
          360,
        );
        final level = BossEncounterArt.dragonFrame(
          _motion(_placed(_boss(age: 1.9 + 1e-6), width, .58)),
          360,
        );
        expect(
          (swoop.heart - level.heart).distance,
          lessThan(1e-2),
          reason: 'no jump at the strike',
        );
        expect((swoop.sx - level.sx).abs(), lessThan(1e-3));
        final alive = BossEncounterArt.dragonFrame(
          _motion(_placed(_boss(combat: 3), width, .5)),
          360,
        );
        final dead = BossEncounterArt.dragonFrame(
          _motion(_placed(_dying(0), width, .5)),
          360,
        );
        expect((alive.heart - dead.heart).distance, lessThan(1e-6));
        expect(dead.sx, closeTo(alive.sx, 1e-6));
      }
    });
  });

  group('the white flashes', () {
    DragonPose pose(SkyBoss b, {bool reduced = false}) =>
        DragonPose(b, _motion(b, reduced: reduced));
    double flash(SkyBoss b, {bool reduced = false}) =>
        BossEncounterArt.dragonFlash(
          pose(b, reduced: reduced),
          _motion(b, reduced: reduced),
        );

    test('the snap of the breath flashes .35 for 0.06 s', () {
      // On the pose's own impact pulse, wherever it lands in the snap.
      double at(double c) => flash(_boss(combat: c));
      expect(at(5.10), 0.0);
      var peak = 0.0, from = -1.0, to = -1.0;
      for (var c = 5.1; c < 5.6; c += .002) {
        final f = at(c);
        peak = math.max(peak, f);
        if (f > .005) {
          if (from < 0) from = c;
          to = c;
        }
      }
      expect(peak, inInclusiveRange(.32, .351));
      expect(
        from,
        inInclusiveRange(
          DragonTimeline.snapAt - .01,
          DragonTimeline.igniteAt + .01,
        ),
      );
      expect(
        to - from,
        inInclusiveRange(.04, .075),
        reason: 'it lasts about 0.06 s',
      );
      expect(at(6.5), 0.0);
    });

    test(
      'fury flashes .3 at 0.1 s (.7 of it, the camera shaking), the killing blow .55 for 0.12 s',
      () {
        SkyBoss enraged(double since) =>
            _boss(combat: 3, hp: 100)..enragedAt = _boss(combat: 3).age - since;
        expect(flash(enraged(0)), closeTo(0, .01));
        expect(flash(enraged(.1)), closeTo(.3 * .7, .01));
        expect(flash(enraged(.25)), 0.0);
        expect(
          flash(_boss(combat: 3)),
          0.0,
          reason: 'a dragon that never enraged',
        );
        expect(flash(_dying(0)), closeTo(.55, .01));
        expect(flash(_dying(.06)), closeTo(.275, .01));
        expect(flash(_dying(.12)), 0.0);
      },
    );

    test('Reduced Motion flashes nothing', () {
      expect(flash(_boss(combat: DragonTimeline.snapAt), reduced: true), 0.0);
      expect(flash(_dying(0), reduced: true), 0.0);
    });

    test(
      'the burst flashes the whole screen .55 over 0.18 s, under the letterbox',
      () {
        const screen = Rect.fromLTWH(0, 0, 640, 360);
        double flash(double death, {bool reduced = false}) {
          final hits = _foreground(
            _dying(death),
            640,
            reduced: reduced,
          ).rects.where((r) => r.rect == screen);
          return hits.isEmpty ? 0 : hits.first.color.a;
        }

        expect(
          flash(.05),
          0.0,
          reason: 'the killing blow flashes the dragon, not the screen',
        );
        expect(flash(SkyBoss.burstAt - .01), 0.0);
        expect(flash(SkyBoss.burstAt + 1e-6), closeTo(.55, .01));
        expect(flash(SkyBoss.burstAt + .09), inExclusiveRange(.05, .3));
        expect(flash(SkyBoss.burstAt + .2), 0.0);
        expect(flash(SkyBoss.burstAt + 1e-6, reduced: true), 0.0);
      },
    );
  });

  group('the falling crown', () {
    final bounds = DragonBossRig.crownBounds.inflate(.1);
    ({Offset at, double angle, double scale}) launched(bool reduced) {
      final boss = _placed(_dying(.3 + 1e-6), 640, .5);
      final rec = _paint(boss, 640, reduced: reduced);
      final layer = rec.layers.singleWhere((l) => l.bounds == bounds);
      final m = layer.matrix;
      return (
        at: Offset(m[4], m[5]),
        angle: math.atan2(m[1], m[0]),
        scale: math.sqrt(m[0] * m[0] + m[1] * m[1]),
      );
    }

    for (final reduced in [false, true]) {
      test(
        'leaves from the slumped head, same place, turn and size${reduced ? ' (Reduced Motion)' : ''}',
        () {
          final got = launched(reduced);
          final boss = _placed(_dying(.3), 640, .5);
          final f = BossEncounterArt.dragonFrame(
            _motion(boss, reduced: reduced),
            360,
          );
          final drop = DragonBossRig.crownDrop(.3, reduced: reduced);
          var want =
              f.heart +
              f.nudge +
              DragonKit.turn(
                Offset(drop.at.dx * f.sx, drop.at.dy * f.sy),
                f.turn,
              );
          var turn = drop.angle + f.turn;
          if (reduced) {
            // Held still a little way off, tilted.
            want += Offset(
              360 * .11 * .45,
              360 * (-.31 * .45 + .28 * .45 * .45),
            );
            turn += .25;
          }
          expect(
            (got.at - want).distance,
            lessThan(.5),
            reason: 'not on the head',
          );
          expect(
            math.cos(got.angle - turn),
            closeTo(1, 1e-4),
            reason: 'not the head\'s turn',
          );
          expect(
            got.scale,
            closeTo((f.sx + f.sy) / 2 * DragonHeadArt.scale, 1e-6),
          );
        },
      );
    }

    test('the old rest-pose anchor is nowhere near the slumped head', () {
      // Why the fall is anchored to `crownDrop`: the head has moved.
      final rest = DragonBossRig.crownAnchor * 360 * SkyBoss.radius;
      final drop = DragonBossRig.crownDrop(.3).at * 360 * SkyBoss.radius;
      expect((rest - drop).distance, greaterThan(15));
    });

    testWidgets('sits on the crown the rig draws (a seam between the parts)', (
      tester,
    ) async {
      await tester.runAsync(() async {
        // The rig's own circlet, isolated by painting the head with and without it.
        final boss = _placed(_dying(.3), 640, .5);
        final m = _motion(boss);
        final pose = DragonPose(boss, m);
        final withCrown = await _dragonPixels(boss, 640, pose: pose, motion: m);
        final without = await _dragonPixels(
          boss,
          640,
          pose: pose,
          motion: m,
          crown: false,
        );
        var sx = 0.0, sy = 0.0, n = 0;
        for (var y = 0; y < withCrown.h; y++) {
          for (var x = 0; x < withCrown.w; x++) {
            final i = (y * withCrown.w + x) * 4;
            var d = 0;
            for (var k = 0; k < 4; k++) {
              d += (withCrown.rgba[i + k] - without.rgba[i + k]).abs();
            }
            if (d > 200) {
              sx += x;
              sy += y - 40;
              n++;
            }
          }
        }
        expect(
          n,
          greaterThan(50),
          reason: 'the rig draws a circlet on the head',
        );
        final seen = Offset(sx / n, sy / n);
        final f = BossEncounterArt.dragonFrame(m, 360);
        final at = DragonBossRig.crownAt(pose);
        final centre =
            at.at + DragonKit.turn(DragonBossRig.crownBounds.center, at.angle);
        final want =
            f.heart +
            f.nudge +
            DragonKit.turn(Offset(centre.dx * f.sx, centre.dy * f.sy), f.turn);
        expect(
          (seen - want).distance,
          lessThan(22),
          reason:
              'crownAt says the circlet sits elsewhere than the art draws it',
        );
      });
    });
  });

  group('round 2', () {
    test(
      'the silhouette gets a lilac haze on a dark sky and none on a bright one',
      () {
        // A glow six and a half radii wide, in the screen's frame (the rig's own bloom
        // is drawn inside the figure's).
        double sx(double age) => BossEncounterArt.dragonFrame(
          _motion(_placed(_boss(age: age), 640)),
          360,
        ).sx;
        bool haze(WorldRegion r, double age) => _paint(
          _placed(_boss(age: age), 640),
          640,
          elapsed: _tourAt(r),
        ).glowScales.any((g) => (g - 6.5 * sx(age)).abs() < .5);
        for (final age in [1.3, 1.7, 1.85]) {
          expect(
            haze(WorldRegion.cyberpunk, age),
            isTrue,
            reason: 'night at $age s',
          );
          expect(
            haze(WorldRegion.egypt, age),
            isFalse,
            reason: 'day at $age s',
          );
        }
        // Paris's dusk gets a little; a bright jungle none.
        expect(haze(WorldRegion.paris, 1.7), isTrue);
        expect(haze(WorldRegion.jungle, 1.7), isFalse);
        // Once the colour is in, the haze goes.
        expect(haze(WorldRegion.cyberpunk, 2.6), isFalse);
      },
    );

    test('the crown lands, hops, settles and clears with the title', () {
      final crown = DragonBossRig.crownBounds.inflate(.1);
      ({Offset at, double alpha})? at(double death, {bool reduced = false}) {
        final rec = _paint(
          _placed(_dying(death), 640, .5),
          640,
          reduced: reduced,
        );
        final layers = rec.layers.where((l) => l.bounds == crown);
        if (layers.isEmpty) return null;
        final l = layers.single;
        return (at: Offset(l.matrix[4], l.matrix[5]), alpha: l.alpha);
      }

      final unit = 360 * SkyBoss.radius;
      final rest =
          360 * .865 -
          DragonHeadArt.crownBounds.bottom * unit * DragonHeadArt.scale;
      expect(at(1.0)!.at.dy, lessThan(rest - 20), reason: 'still falling');
      expect(at(0.3 + 1.25 + 1e-6)!.at.dy, closeTo(rest, 1.5), reason: 'lands');
      for (final death in [1.9, 2.4, 3.0]) {
        final a = at(death)!;
        expect(
          a.at.dy,
          inInclusiveRange(rest - 360 * .03, rest + .5),
          reason: 'rests at $death s',
        );
        // Above the bottom letterbox bar, whatever else.
        expect(a.at.dy, lessThan(360 * (1 - .082)));
      }
      // It stays where it landed (a skid of a few px).
      expect((at(2.4)!.at.dx - at(3.0)!.at.dx).abs(), lessThan(5));
      expect(
        at(3.0)!.alpha,
        closeTo(1, 1e-9),
        reason: 'held through the title',
      );
      expect(at(3.45)!.alpha, inExclusiveRange(0.01, .99));
      expect(at(3.75), isNull, reason: 'gone with the title');
      // Reduced Motion holds it near the head and clears it early.
      expect(at(1.0, reduced: true), isNotNull);
      expect(at(1.7, reduced: true), isNull);
    });

    test('the dragon is gone before the burst and does not hang over it', () {
      double? dragonAlpha(double death) {
        final rec = _paint(_placed(_dying(death), 640, .5), 640);
        final l = rec.layers.where((l) => l.bounds == DragonBossRig.bounds);
        return l.isEmpty ? null : l.single.alpha;
      }

      expect(dragonAlpha(.5), closeTo(1, 1e-9));
      expect(dragonAlpha(.78), inExclusiveRange(.05, .95));
      expect(
        dragonAlpha(SkyBoss.burstAt + .02),
        isNull,
        reason: 'no ghost tail',
      );
    });

    test('nothing squashes or pops at a fireball launch', () {
      BossEncounterArt.dragonFrame(_motion(_boss()), 360);
      final charged = BossEncounterArt.dragonFrame(
        _motion(_placed(_boss(combat: 1.2)..fireIn = .001, 640)),
        360,
      );
      final launched = BossEncounterArt.dragonFrame(
        _motion(
          _placed(_boss(combat: 1.2), 640)
            ..lastVolleyAt = _boss(combat: 1.2).age - .01,
        ),
        360,
      );
      expect(launched.sy, charged.sy);
      expect(launched.sx, charged.sx);
    });

    test('a boss the clock has broken draws nothing and throws nothing', () {
      // NaN and infinite time or place, in every phase, through all three
      // layers (backdrop, world, foreground), normal and Reduced Motion.
      const bad = [double.nan, double.infinity, double.negativeInfinity];
      final sim = arena(version: FlightSimulation.currentRulesVersion);
      for (final reduced in [false, true]) {
        for (final v in bad) {
          final states = <(String, SkyBoss Function())>[
            ('arrival age', () => _placed(_boss(age: 1.0)..age = v, 640)),
            ('combat age', () => _placed(_boss(combat: 5.3)..age = v, 640)),
            ('breath age', () => _placed(_boss(combat: 6.0)..age = v, 640)),
            ('defeat age', () => _placed(_dying(.5)..age = v, 640)),
            ('defeatedAt', () => _placed(_dying(.5), 640)..defeatedAt = v),
            ('x', () => _placed(_boss(combat: 2), 640)..x = v),
            ('y', () => _placed(_boss(combat: 2), 640)..y = v),
            (
              'lastVolleyAt',
              () => _placed(_boss(combat: 2), 640)..lastVolleyAt = v,
            ),
          ];
          for (final (name, make) in states) {
            final boss = make();
            final m = _motion(boss, reduced: reduced);
            final size = const Size(640, 360);
            final tag = '$name = $v${reduced ? ' (Reduced Motion)' : ''}';
            sim.boss = boss;
            // (The shared backdrop puts every boss's halo at its place: a
            // NaN place is beyond this staging's part.)
            if (name != 'x' && name != 'y') {
              expect(
                () => BossEncounterArt.backdrop(_Rec(), size, boss, m),
                returnsNormally,
                reason: 'backdrop, $tag',
              );
            }
            expect(
              () => BossEncounterArt.paint(_Rec(), size, sim, m),
              returnsNormally,
              reason: 'paint, $tag',
            );
            expect(
              () => BossEncounterArt.foreground(_Rec(), size, sim, m),
              returnsNormally,
              reason: 'foreground, $tag',
            );
          }
        }
        // A bird nowhere at all.
        final boss = _placed(_boss(combat: 8.05), 640);
        boss.lastVolleyAt = boss.age - .05;
        sim
          ..boss = boss
          ..birdY = double.nan;
        expect(
          () => BossEncounterArt.paint(
            _Rec(),
            const Size(640, 360),
            sim,
            _motion(boss, reduced: reduced),
          ),
          returnsNormally,
          reason: 'birdY NaN',
        );
      }
    });

    test('its own jolts sit beneath the shared camera pop', () {
      // The camera shakes for hits, fury, the roar and the burst, never at
      // the breath's snap, so the two do not meet there.
      final calm = _motion(_placed(_boss(combat: 5.30), 640));
      expect(
        calm.shake,
        Offset.zero,
        reason: 'the camera is at rest at the snap',
      );
      // Where it jolts hardest inside the snap's 0.06 s.
      var best = 0.0, at = 5.28;
      for (var c = 5.28; c < 5.34; c += .001) {
        final b = _placed(_boss(combat: c), 640);
        final d = BossEncounterArt.dragonRumble(
          DragonPose(b, _motion(b)),
          _motion(b),
          360,
        ).distance;
        if (d > best) {
          best = d;
          at = c;
        }
      }
      expect(
        best,
        inInclusiveRange(2.0, 3.2),
        reason: 'the jolt reads, about 3 px',
      );
      final hitBoss = _placed(_boss(combat: at), 640);
      hitBoss.lastHitAt = hitBoss.age - .1;
      final shaken = _motion(hitBoss);
      expect(shaken.shake, isNot(Offset.zero));
      final under = BossEncounterArt.dragonRumble(
        DragonPose(hitBoss, shaken),
        shaken,
        360,
      );
      expect(under.distance, closeTo(best * .4, best * .05));
      // The fury flash yields the same way.
      SkyBoss fury({bool camera = true}) {
        final boss = _boss(combat: 3, hp: 100);
        boss.enragedAt = boss.age - .1;
        return boss;
      }

      final m = _motion(fury());
      expect(
        m.shake,
        isNot(Offset.zero),
        reason: 'the roar of fury shakes the camera',
      );
      expect(
        BossEncounterArt.dragonFlash(DragonPose(fury(), m), m),
        closeTo(.3 * .7, .01),
      );
    });
  });

  group('layers and hooks', () {
    test(
      'the dragon opens at most its own layer and the crown\'s, and none in plain combat',
      () {
        final crown = DragonBossRig.crownBounds.inflate(.1);
        int own(_Rec r, Rect b) => r.layers.where((l) => l.bounds == b).length;
        final states = <(String, SkyBoss, bool)>[
          ('silhouette', _placed(_boss(age: 1.5), 640), true),
          ('cross-fade', _placed(_boss(age: 1.95), 640), true),
          ('roar', _placed(_boss(age: 3.0), 640), false),
          for (final t in [.05, .2, .3, .5, .9, 1.0, 1.4, 2.5])
            ('death $t', _placed(_dying(t), 640), true),
          ('idle', _placed(_boss(combat: 1.2), 640), false),
          ('charge', _placed(_boss(combat: 1.2)..fireIn = .1, 640), false),
          ('hold', _placed(_boss(combat: 5.05), 640), false),
          ('snap', _placed(_boss(combat: 5.22), 640), false),
          ('blast', _placed(_boss(combat: 6.0), 640), false),
          ('call', _placed(_boss(combat: 7.9), 640), false),
          ('fury', _placed(_boss(combat: 3, hp: 100), 640), false),
        ];
        for (final (name, boss, mayLayer) in states) {
          for (final reduced in [false, true]) {
            final rec = _paint(boss, 640, reduced: reduced);
            expect(
              own(rec, DragonBossRig.bounds),
              lessThanOrEqualTo(1),
              reason: '$name: the dragon\'s layer',
            );
            expect(
              own(rec, crown),
              lessThanOrEqualTo(1),
              reason: '$name: the crown\'s layer',
            );
            if (!mayLayer) {
              expect(
                own(rec, DragonBossRig.bounds),
                0,
                reason: '$name: no layer in combat',
              );
              expect(own(rec, crown), 0);
            }
          }
        }
      },
    );

    test('the sky\'s light, the hooks and the title card are wired', () {
      final source = File(
        'lib/game/boss_encounter_art.dart',
      ).readAsStringSync();
      for (final needle in const [
        'DragonSkyLight.fromSky(',
        'SkyPalette.at(sim.elapsed)',
        'DragonFireballArt.charge(',
        'DragonFireballArt.muzzle(',
        'DragonCallArt.paint(',
        'boss: boss,',
        'math.atan2(',
        'DragonEncounterUi.nameCard(',
        'DragonBossRig.crownDrop(',
        'DragonEncounterUi.victoryGem(',
        'dragonRumble(',
      ]) {
        expect(source, contains(needle), reason: '$needle is not called');
      }
      // The old inline orb and ring are gone.
      expect(source, isNot(contains('DragonFireballArt.paint(')));
    });

    testWidgets('the region\'s light reaches the dragon', (tester) async {
      await tester.runAsync(() async {
        Future<Uint8List> render(WorldRegion region) async {
          final boss = _placed(_boss(combat: 1.2), 640);
          final recorder = ui.PictureRecorder();
          final sim = arena(version: FlightSimulation.currentRulesVersion)
            ..elapsed = _tourAt(region)
            ..boss = boss;
          BossEncounterArt.paint(
            Canvas(recorder),
            const Size(640, 360),
            sim,
            _motion(boss),
          );
          final image = await recorder.endRecording().toImage(640, 360);
          final bytes = (await image.toByteData())!.buffer.asUint8List();
          image.dispose();
          return bytes;
        }

        final night = await render(WorldRegion.cyberpunk);
        final day = await render(WorldRegion.egypt);
        expect(
          night,
          isNot(equals(day)),
          reason: 'the dragon is lit the same in every region',
        );
        expect(
          await render(WorldRegion.cyberpunk),
          night,
          reason: 'and deterministically',
        );
      });
    });
  });

  testWidgets('every staging frame renders deterministically', (tester) async {
    await tester.runAsync(() async {
      Future<Uint8List> render(SkyBoss boss, {bool reduced = false}) async {
        final recorder = ui.PictureRecorder();
        final c = Canvas(recorder);
        final sim = arena(version: FlightSimulation.currentRulesVersion)
          ..elapsed = 40
          ..boss = boss;
        final m = _motion(boss, reduced: reduced);
        BossEncounterArt.paint(c, const Size(800, 360), sim, m);
        BossEncounterArt.foreground(c, const Size(800, 360), sim, m);
        final image = await recorder.endRecording().toImage(800, 360);
        final bytes = (await image.toByteData())!.buffer.asUint8List();
        image.dispose();
        return bytes;
      }

      final frames = <(String, SkyBoss Function())>[
        ('eye wakes', () => _placed(_boss(age: 1.8), 800)),
        ('strike', () => _placed(_boss(age: 1.92), 800)),
        ('cross-fade', () => _placed(_boss(age: 1.97), 800)),
        ('roar', () => _placed(_boss(age: 2.95), 800)),
        ('bar leaves', () => _placed(_boss(age: 4.1), 800)),
        ('snap', () => _placed(_boss(combat: 5.22), 800)),
        ('call', () => _placed(_boss(combat: 7.9), 800)),
        (
          'fury flash',
          () => _placed(
            _boss(combat: 3, hp: 100)..enragedAt = _boss(combat: 3).age - .1,
            800,
          ),
        ),
        ('killing blow', () => _placed(_dying(.05), 800)),
        ('crown falls', () => _placed(_dying(.6), 800)),
        ('burst', () => _placed(_dying(.9), 800)),
      ];
      for (final reduced in [false, true]) {
        for (final (name, make) in frames) {
          final a = await render(make(), reduced: reduced);
          final b = await render(make(), reduced: reduced);
          expect(
            a,
            b,
            reason:
                '$name${reduced ? ' (Reduced Motion)' : ''} is not deterministic',
          );
        }
      }
    });
  });

  for (final width in [640.0, 800.0]) {
    test(
      'through the real rules, the dragon is never cropped at ${width.toInt()}',
      () async {
        // Run the rules through the arrival, two breath cycles, fury and the
        // defeat; at every 0.1 s ask how far the dragon's solid pixels reach
        // past the screen and the letterbox bars (the real art, so this only
        // reports until every part has landed).
        final sim = arena(version: FlightSimulation.currentRulesVersion)
          ..elapsed = FlightSimulation.bossInterval - .001
          ..bossesDefeated = 9;
        final vw = width / 360;
        void advance(double to) {
          while (sim.boss!.age < to - 1e-9) {
            sim.birdY = .5;
            sim.velocity = 0;
            sim.hearts = 3;
            step(sim, .02, vw);
          }
        }

        step(sim, .02, vw);
        final boss = sim.boss!;
        expect(boss.kind, BossKind.dragon);
        var worst = (top: 0.0, bottom: 0.0, right: 0.0);
        var cut = 0;
        var cutAt = '';
        String where = '';
        Future<void> look(String tag) async {
          // Still sliding in from the right edge, it is meant to be cut there.
          final settled =
              (boss.x - math.max(FlightSimulation.birdX + .76, vw - .5)).abs() *
                  360 <
              1;
          final r = await _reach(boss, width, right: settled);
          if (r.top > worst.top ||
              r.bottom > worst.bottom ||
              r.right > worst.right) {
            where = '$tag at age ${boss.age.toStringAsFixed(2)}';
          }
          worst = (
            top: math.max(worst.top, r.top),
            bottom: math.max(worst.bottom, r.bottom),
            right: math.max(worst.right, r.right),
          );
        }

        for (var t = .5; t < boss.arrivalDuration; t += .1) {
          advance(t);
          // Under the bars a silhouette is dark on dark: only the colour counts.
          if (t >= DragonTimeline.arrivalFlashAt) await look('arrival');
          // But the silhouette's layer must not cut it, swell and all.
          if (t >= .9 && t < 2.0) {
            final n = await _clippedByLayer(boss, width);
            if (n > 0) {
              cutAt = 'silhouette at age ${boss.age.toStringAsFixed(2)}';
            }
            cut += n;
          }
        }
        for (var t = 0.0; t < 2 * DragonBreath.period; t += .15) {
          advance(boss.arrivalDuration + t);
          await look('combat');
        }
        boss.hp = boss.maxHp ~/ 3;
        for (var t = 0.0; t < DragonBreath.period; t += .1) {
          advance(boss.age + .1);
          await look('fury');
        }
        boss.defeatedAt = boss.age;
        for (var t = 0.0; t < 1.2; t += .05) {
          advance(boss.age + .05);
          await look('defeat');
          // (Only while the dragon is drawn: it is gone by the burst.)
          final n = boss.age - boss.defeatedAt! < SkyBoss.burstAt
              ? await _clippedByLayer(boss, width)
              : 0;
          if (n > 0) {
            final death = (boss.age - boss.defeatedAt!).toStringAsFixed(2);
            cutAt = 'defeat at death $death';
          }
          cut += n;
        }
        // ignore: avoid_print
        print(
          '${width.toInt()}: worst reach past the screen/bars: top ${worst.top.toStringAsFixed(1)} px, '
          'bottom ${worst.bottom.toStringAsFixed(1)} px, right ${worst.right.toStringAsFixed(1)} px'
          '${where.isEmpty ? '' : ' ($where)'}; the layer cut $cut px${cutAt.isEmpty ? '' : ' ($cutAt)'}',
        );
        if (enforceRealArt) {
          expect(
            worst.top,
            lessThanOrEqualTo(.5),
            reason: 'cropped at the top: $where',
          );
          expect(
            worst.bottom,
            lessThanOrEqualTo(.5),
            reason: 'cropped at the bottom: $where',
          );
          expect(
            worst.right,
            lessThanOrEqualTo(.5),
            reason: 'cropped at the right: $where',
          );
          expect(
            cut,
            lessThanOrEqualTo(8),
            reason:
                'the layer bounds cut the silhouette or the defeat ($cutAt)',
          );
        }
      },
      timeout: const Timeout(Duration(minutes: 4)),
    );
  }

  for (final width in [640.0, 800.0]) {
    test(
      'in fury, the roar, the hold, the snap and the blast, nothing leaves the screen at ${width.toInt()}',
      () async {
        // The moments that push the figure to its edges, at the top and the
        // bottom of the rules' bob and in every lane, with the jolt of the
        // snap on top: the breath's hold, snap and blast, the fury's roar and
        // both swarm calls.
        var worst = (top: 0.0, bottom: 0.0, right: 0.0);
        var where = '';
        Future<void> look(String tag, SkyBoss boss) async {
          final r = await _reach(boss, width);
          if (r.top > worst.top ||
              r.bottom > worst.bottom ||
              r.right > worst.right) {
            where = tag;
          }
          worst = (
            top: math.max(worst.top, r.top),
            bottom: math.max(worst.bottom, r.bottom),
            right: math.max(worst.right, r.right),
          );
        }

        for (final fury in [false, true]) {
          for (final y in [.43, .57]) {
            for (final lane in BreathLane.values) {
              for (var c = 4.9; c < 5.9; c += .02) {
                final b = _placed(_boss(combat: c, lane: lane), width, y);
                if (fury) b.hp = b.maxHp ~/ 3;
                await look(
                  '${fury ? 'fury ' : ''}breath ${c.toStringAsFixed(2)} $lane y$y',
                  b,
                );
              }
              for (var c = 7.3; c < 8.7; c += .05) {
                final b = _placed(_boss(combat: c, lane: lane), width, y);
                if (fury) b.hp = b.maxHp ~/ 3;
                await look(
                  '${fury ? 'fury ' : ''}call ${c.toStringAsFixed(2)}',
                  b,
                );
              }
            }
            for (var since = 0.0; since < 1.3; since += .05) {
              final b = _placed(_boss(combat: 3, hp: 100), width, y);
              b.enragedAt = b.age - since;
              await look('fury onset +${since.toStringAsFixed(2)} y$y', b);
            }
          }
        }
        // ignore: avoid_print
        print(
          '${width.toInt()}: fury/roar/hold/snap/blast worst reach: top ${worst.top.toStringAsFixed(1)}, '
          'bottom ${worst.bottom.toStringAsFixed(1)}, right ${worst.right.toStringAsFixed(1)} px'
          '${where.isEmpty ? '' : ' ($where)'}',
        );
        if (enforceRealArt) {
          expect(worst.top, lessThanOrEqualTo(.5), reason: 'top: $where');
          expect(worst.bottom, lessThanOrEqualTo(.5), reason: 'bottom: $where');
          expect(worst.right, lessThanOrEqualTo(.5), reason: 'right: $where');
        }
      },
      timeout: const Timeout(Duration(minutes: 6)),
    );
  }

  if (_video) {
    testWidgets('a whole encounter as frames', (tester) async {
      tester.view.physicalSize = const ui.Size(800, 360);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.runAsync(() async {
        await _fonts();
        final s = await _stage(
          tester,
          800,
          WorldRegion.cyberpunk,
          startAt: _tourAt(WorldRegion.cyberpunk, 1),
        );
        s.live = true;
        final dir = Directory('${_folder.path}/video')
          ..createSync(recursive: true);
        for (final f in dir.listSync()) {
          f.deleteSync();
        }
        final boss = s.boss;
        var n = 0, hits = 0;
        var fury = false, killed = false;
        Future<void> shoot() async {
          s.sim.rocks.add(BirdRock(x: boss.x - .12, y: boss.y));
        }

        while (true) {
          final combat = boss.age - boss.arrivalDuration;
          // The bird keeps to the middle, then the safe side of each breath.
          s.birdY = combat < 0
              ? .5
              : switch (combat % DragonBreath.period) {
                  < 4.2 => .5,
                  < 7.3 => .8,
                  _ => .5,
                };
          if (boss.phase == BossPhase.attacking) {
            if (combat > 2.0 && hits == 0 || combat > 3.2 && hits == 1) {
              hits++;
              await shoot();
            }
            if (!fury && combat > 12.6) {
              fury = true;
              boss.hp = boss.maxHp ~/ 2 + 5;
              await shoot();
            }
            if (!killed && combat > 26.4) {
              killed = true;
              for (var i = 0; i < boss.hp; i++) {
                await shoot();
              }
            }
          }
          s.tick(1 / 60);
          s.tick(1 / 60);
          final image = await s.frame();
          File(
            '${dir.path}/${(n++).toString().padLeft(4, '0')}.png',
          ).writeAsBytesSync(await _png(image));
          image.dispose();
          if (s.sim.boss == null ||
              (boss.phase == BossPhase.defeated &&
                  boss.age - boss.defeatedAt! > 4.2)) {
            break;
          }
          if (n > 30 * 60) break;
        }
      });
      await tester.pumpWidget(const SizedBox());
    }, timeout: const Timeout(Duration(minutes: 10)));
  }

  if (_review) {
    testWidgets('review reduced 640 paris', (tester) async {
      tester.view.physicalSize = const ui.Size(640, 360);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.runAsync(() async {
        await _fonts();
        final s = await _stage(tester, 640, WorldRegion.paris, reduced: true);
        await _arrival(s, '640-reduced');
        await _fight(s, '640-reduced');
      });
      await tester.pumpWidget(const SizedBox());
    });
    for (final (width, region, reduced) in const [
      (800.0, WorldRegion.cyberpunk, false),
      (640.0, WorldRegion.paris, false),
      (800.0, WorldRegion.egypt, false),
      (800.0, WorldRegion.newYork, false),
      (640.0, WorldRegion.paris, true),
    ]) {
      final tag = '${width.toInt()}-${region.name}${reduced ? '-reduced' : ''}';
      testWidgets('roar $tag', (tester) async {
        tester.view.physicalSize = ui.Size(width, 360);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.runAsync(() async {
          await _fonts();
          final s = await _stage(tester, width, region, reduced: reduced);
          await _roar(s, tag);
        });
        await tester.pumpWidget(const SizedBox());
      });
    }
    for (final width in [640.0, 800.0]) {
      testWidgets('call ${width.toInt()} cyberpunk', (tester) async {
        tester.view.physicalSize = ui.Size(width, 360);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.runAsync(() async {
          await _fonts();
          final s = await _stage(tester, width, WorldRegion.cyberpunk);
          await _call(s, '${width.toInt()}-cyberpunk');
        });
        await tester.pumpWidget(const SizedBox());
      });
    }
    for (final region in [WorldRegion.cyberpunk, WorldRegion.egypt]) {
      testWidgets('strike 800 ${region.name}', (tester) async {
        tester.view.physicalSize = const ui.Size(800, 360);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.runAsync(() async {
          await _fonts();
          final s = await _stage(tester, 800, region);
          await _strike(s, '800-${region.name}');
        });
        await tester.pumpWidget(const SizedBox());
      });
    }
    for (final width in [640.0, 800.0]) {
      for (final region in [
        WorldRegion.cyberpunk,
        WorldRegion.newYork,
        WorldRegion.paris,
        WorldRegion.egypt,
      ]) {
        testWidgets("review ${width.toInt()} ${region.name}", (tester) async {
          tester.view.physicalSize = ui.Size(width, 360);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await tester.runAsync(() async {
            await _fonts();
            final s = await _stage(tester, width, region);
            await _arrival(s, '${width.toInt()}-${region.name}');
            await _fight(s, '${width.toInt()}-${region.name}');
          });
          await tester.pumpWidget(const SizedBox());
        });
      }
    }
  }
}
