import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/tracking.dart';
import 'package:push_up_bird/game/bird_game.dart';
import 'package:push_up_bird/game/knockout_art.dart';
import 'package:push_up_bird/ui/theme.dart';

import 'boss_fight_test.dart' show arena, step;
import 'recorded_flight.dart' show rideTheSky;

/// Review renders are written with --dart-define=CAPTURE_VISUALS=true.
const _capture = bool.fromEnvironment('CAPTURE_VISUALS');
final _folder = Directory('build/visual-review/death');

const _daylight = [Color(0xffbde9f6), Color(0xfff9efd8)];
const _dusk = [Color(0xff8f86bf), Color(0xffd2a9af)];
const _names = ['pip', 'peaches', 'minty', 'orbit'];

/// A touch flight that has just ended on its last heart at [y].
FlightSimulation _fallen({double y = .5, double velocity = .4}) =>
    FlightSimulation(rules: TapFlyMode(), practice: true)
      ..phase = RunPhase.playing
      ..started = true
      ..elapsed = 6
      ..birdY = y
      ..velocity = velocity
      ..end(EndReason.collision);

/// A Pirate Captain fight with the sea at its resting level.
FlightSimulation _atSea({double y = .86}) {
  final sim = _fallen(y: y);
  sim.boss = SkyBoss(number: 4, x: 1.6, kind: BossKind.pirate, cinematic: true)
    ..age = 8;
  return sim;
}

Future<List<int>> _raster(
  void Function(Canvas) draw,
  String? name, {
  int width = 400,
  int height = 360,
}) async {
  final recorder = ui.PictureRecorder();
  draw(Canvas(recorder));
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  final pixels = (await image.toByteData())!.buffer.asUint8List();
  if (name != null) {
    _folder.createSync(recursive: true);
    final png = (await image.toByteData(
      format: ui.ImageByteFormat.png,
    ))!.buffer.asUint8List();
    File('${_folder.path}/$name.png').writeAsBytesSync(png);
  }
  image.dispose();
  picture.dispose();
  return pixels;
}

void _knockout(
  Canvas c,
  FlightSimulation sim,
  double t, {
  int bird = 0,
  bool reduced = false,
  double h = 360,
}) => KnockoutArt.paint(
  c,
  Size(h * 400 / 360, h),
  sim,
  bird: bird,
  seconds: t,
  reducedMotion: reduced,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    for (final family in ['Fredoka', 'Nunito']) {
      await (FontLoader(
        family,
      )..addFont(rootBundle.load('assets/fonts/$family.ttf'))).load();
    }
  });

  test('the knockout lasts long enough to read and short enough to stay '
      'snappy', () {
    expect(KnockoutArt.seconds, inInclusiveRange(1.5, 2.5));
    expect(KnockoutArt.calmSeconds, lessThanOrEqualTo(KnockoutArt.seconds));
    expect(KnockoutArt.skipAfter, inInclusiveRange(.4, .9));
    expect(KnockoutArt.skipAfter, lessThan(KnockoutArt.calmSeconds));
    expect(KnockoutArt.duration(reducedMotion: true), KnockoutArt.calmSeconds);
    expect(KnockoutArt.duration(reducedMotion: false), KnockoutArt.seconds);
  });

  test('the world winds down into a held, dimmed still', () {
    for (final reduced in [false, true]) {
      expect(KnockoutArt.worldLayer(0, reducedMotion: reduced), isNull);
      final end = KnockoutArt.duration(reducedMotion: reduced);
      expect(KnockoutArt.settle(end, reducedMotion: reduced), 1);
      expect(KnockoutArt.settle(end + 5, reducedMotion: reduced), 1);
      var last = 0.0;
      for (var t = 0.0; t <= end; t += 1 / 30) {
        final k = KnockoutArt.settle(t, reducedMotion: reduced);
        expect(k, greaterThanOrEqualTo(last));
        last = k;
      }
    }
    // Reduced Motion keeps the camera still.
    for (var t = 0.0; t < 2; t += .01) {
      expect(KnockoutArt.cameraOffset(t, reducedMotion: true), Offset.zero);
      expect(KnockoutArt.zoom(t, reducedMotion: true), 1);
    }
    expect(
      KnockoutArt.cameraOffset(.02, reducedMotion: false),
      isNot(Offset.zero),
    );
    expect(KnockoutArt.cameraOffset(.5, reducedMotion: false), Offset.zero);
  });

  test('every frame is a pure function of its time, for every bird', () async {
    final blank = await _raster((_) {}, null);
    for (var bird = 0; bird < 4; bird++) {
      for (final reduced in [false, true]) {
        for (final sim in [_fallen(), _atSea()]) {
          final label =
              '${_names[bird]} reduced: $reduced sea: ${sim.boss != null}';
          Future<List<int>> at(double t) => _raster(
            (c) => _knockout(c, sim, t, bird: bird, reduced: reduced),
            null,
          );
          final early = await at(.3);
          expect(early, isNot(equals(blank)), reason: 'visible $label');
          final later = await at(.8);
          expect(later, isNot(equals(early)), reason: 'animates $label');
          expect(await at(.3), early, reason: 'seek restores $label');
          expect(
            await at(KnockoutArt.duration(reducedMotion: reduced)),
            blank,
            reason: 'the bird and every piece are gone by the stage $label',
          );
        }
      }
    }
  });

  test('Reduced Motion fades in place without growing or flinging', () async {
    for (var bird = 0; bird < 4; bird++) {
      final sim = _fallen(y: .4);
      final first = _bounds(
        await _raster(
          (c) => _knockout(c, sim, 0, bird: bird, reduced: true),
          null,
        ),
        400,
      );
      expect(first, isNot(Rect.zero));
      for (final t in [.2, .4, .6, .8, 1.0, 1.15]) {
        final frame = _bounds(
          await _raster(
            (c) => _knockout(c, sim, t, bird: bird, reduced: true),
            null,
          ),
          400,
        );
        if (frame == Rect.zero) continue;
        expect(
          first.expandToInclude(frame),
          first,
          reason: 'no expansion at $t for ${_names[bird]}',
        );
      }
    }
  });

  test('the tumble drops the bird off the bottom, or into the sea', () async {
    final sky = _fallen(y: .5);
    final wide = await _raster((c) => _knockout(c, sky, .3), null);
    final gone = await _raster((c) => _knockout(c, sky, 1.45), null);
    // Early on the bird is well inside the screen; by 1.45 s only fading
    // feathers remain, so far fewer pixels are drawn.
    expect(_coverage(gone), lessThan(_coverage(wide) * .5));
    final sea = _atSea();
    final entry = KnockoutArt.splashAt(sea, reducedMotion: false)!;
    expect(entry, inInclusiveRange(.3, 1.2));
    expect(KnockoutArt.splashAt(sea, reducedMotion: true), isNull);
    expect(KnockoutArt.splashAt(sky, reducedMotion: false), isNull);
  });

  for (final (name, seconds, bird) in [
    ('day', 9.0, 0),
    ('dusk', 29.0, 1),
    ('twilight', 47.0, 3),
  ]) {
    testWidgets('in-game knockout at $name', skip: !_capture, (tester) async {
      await _inGame(tester, name, _crashInto(seconds), bird);
    });
  }
  testWidgets('in-game knockout into the pirate sea', skip: !_capture, (
    tester,
  ) async {
    await _inGame(tester, 'pirate', _sink(), 2);
  });
  testWidgets('in-game Reduced Motion knockout', skip: !_capture, (
    tester,
  ) async {
    await _inGame(tester, 'day-reduced', _crashInto(9), 0, reduced: true);
  });

  group('visual review', skip: !_capture, () {
    test('filmstrips for every bird, close-up and at gameplay scale', () async {
      final seconds = [for (var f = 0; f <= 57; f++) f / 30];
      for (var bird = 0; bird < 4; bird++) {
        await _raster(
          (c) => _closeups(c, bird, seconds.where((t) => t <= .72).toList()),
          'closeup-${_names[bird]}',
          width: 60 + 11 * 190,
          height: 70 + 2 * 230,
        );
      }
      for (final (name, sky) in [('day', _daylight), ('dusk', _dusk)]) {
        for (final reduced in [false, true]) {
          await _raster(
            (c) => _onion(c, sky, seconds, reduced: reduced),
            'onion-$name${reduced ? '-reduced' : ''}',
            width: 2 * 640,
            height: 2 * 360,
          );
        }
      }
    });
  });
}

/// Bird-following close-ups: two rows of the first ~0.7 s at 30 fps.
void _closeups(Canvas c, int bird, List<double> seconds) {
  const cell = Size(190, 230);
  final width = 60 + 11 * cell.width, height = 70 + 2 * cell.height;
  c.drawRect(
    Rect.fromLTWH(0, 0, width, height),
    Paint()..color = const Color(0xfff2eedf),
  );
  _text(
    c,
    '${_names[bird].toUpperCase()} · close-up · 30 fps',
    const Offset(16, 10),
    18,
  );
  const h = 900.0;
  for (var i = 0; i < seconds.length && i < 22; i++) {
    final t = seconds[i];
    final col = i % 11, row = i ~/ 11;
    final cellRect = Rect.fromLTWH(
      60 + col * cell.width,
      70 + row * cell.height,
      cell.width - 4,
      cell.height - 4,
    );
    c.save();
    c.clipRect(cellRect);
    final sky = row.isEven ? _daylight : _dusk;
    c.drawRect(
      cellRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: sky,
        ).createShader(cellRect),
    );
    // Follow the bird, as a camera would.
    final sim = _fallen(y: .5);
    final bird0 = KnockoutArt.birdCenter(sim, t, reducedMotion: false) * h;
    c.translate(
      cellRect.center.dx - bird0.dx,
      cellRect.center.dy - bird0.dy + 20,
    );
    KnockoutArt.paint(
      c,
      const Size(h * 2, h),
      sim,
      bird: bird,
      seconds: t,
      reducedMotion: false,
    );
    c.restore();
    _text(
      c,
      '${(t * 1000).round()}ms',
      cellRect.topLeft + const Offset(6, 4),
      12,
    );
  }
}

/// Four birds dying at once on one gameplay-size screen per quadrant, with
/// every 30 fps frame overlaid to show spacing.
void _onion(
  Canvas c,
  List<Color> sky,
  List<double> seconds, {
  required bool reduced,
}) {
  for (var bird = 0; bird < 4; bird++) {
    final origin = Offset((bird % 2) * 640.0, (bird ~/ 2) * 360.0);
    final rect = origin & const Size(640, 360);
    c.save();
    c.clipRect(rect);
    c.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: sky,
        ).createShader(rect),
    );
    c.translate(origin.dx, origin.dy);
    final sim = _fallen(y: [.5, .2, .8, .5][bird]);
    for (final t in seconds.reversed) {
      if (t > (reduced ? KnockoutArt.calmSeconds : 1.6)) continue;
      // Every third frame (10 fps) keeps the spacing readable.
      if ((t * 30).round() % 3 != 0) continue;
      c.saveLayer(
        Offset.zero & const Size(640, 360),
        Paint()..color = Color.fromRGBO(0, 0, 0, t == 0 ? 1 : .35),
      );
      KnockoutArt.paint(
        c,
        const Size(640, 360),
        sim,
        bird: bird,
        seconds: t,
        reducedMotion: reduced,
      );
      c.restore();
    }
    c.restore();
    _text(
      c,
      '${_names[bird]} · y ${sim.birdY}',
      origin + const Offset(8, 6),
      13,
    );
  }
}

double _coverage(List<int> rgba) {
  var n = 0;
  for (var i = 3; i < rgba.length; i += 4) {
    if (rgba[i] > 0) n++;
  }
  return n.toDouble();
}

/// The bounding box of pixels that differ from transparent.
Rect _bounds(List<int> rgba, int width) {
  var left = width, top = 1 << 30, right = -1, bottom = -1;
  for (var i = 0; i < rgba.length; i += 4) {
    if (rgba[i + 3] == 0) continue;
    final p = i ~/ 4, x = p % width, y = p ~/ width;
    if (x < left) left = x;
    if (x > right) right = x;
    if (y < top) top = y;
    if (y > bottom) bottom = y;
  }
  if (right < 0) return Rect.zero;
  return Rect.fromLTRB(
    left.toDouble(),
    top.toDouble(),
    right + 1.0,
    bottom + 1.0,
  );
}

void _text(Canvas c, String text, Offset at, double size) {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        fontFamily: 'Nunito',
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: SkyColors.ink,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  painter.paint(c, at);
}

/// Rides a real Star Trail touch flight for [seconds], then steers into the
/// upper half of the next wall on the last heart.
FlightSimulation _crashInto(double seconds, {int seed = 5}) {
  final sim =
      FlightSimulation(
          rules: TapFlyMode(),
          practice: true,
          course: FlightCourse.starTrail,
          random: Random(seed),
        )
        ..phase = RunPhase.playing
        ..started = true;
  var now = 0.0;
  void tick(bool flap) {
    now += 20;
    sim.apply(
      MovementInput(valid: true, flap: flap),
      TrackingSample(
        mode: PlayMode.touch,
        timestampMs: now,
        receivedMs: now,
        joints: const [],
      ),
      now,
    );
    sim.tick(.02, now, viewportWidth: 800 / 360);
  }

  while (sim.elapsed < seconds) {
    sim.hearts = 3;
    tick(rideTheSky(sim));
  }
  sim
    ..hearts = 1
    ..shield = false
    ..invulnerableUntil = 0;
  for (var i = 0; i < 2000 && sim.phase != RunPhase.ended; i++) {
    final next = sim.obstacles
        .where((o) => o.x + o.width > FlightSimulation.birdX - .05)
        .firstOrNull;
    // Just into the upper pillar, so the beak meets the wall face-on.
    final aim = next == null
        ? .45
        : next.top > .2
        ? next.top - .05
        : next.bottom + .05;
    tick(sim.birdY > aim + .02 && sim.velocity >= 0);
  }
  expect(sim.endReason, EndReason.collision);
  return sim;
}

/// The Pirate Captain's fight: hover until he attacks, then drop into the sea
/// on the last heart.
FlightSimulation _sink() {
  final sim = arena(version: FlightSimulation.currentRulesVersion)
    ..elapsed = FlightSimulation.bossInterval - .001
    ..bossesDefeated = 3;
  for (var i = 0; i < 400; i++) {
    sim
      ..birdY = .5
      ..velocity = 0
      ..hearts = 3;
    step(sim, .02, 800 / 360);
  }
  expect(sim.boss?.kind, BossKind.pirate);
  sim
    ..hearts = 1
    ..shield = false
    ..invulnerableUntil = 0;
  for (var i = 0; i < 400 && sim.phase != RunPhase.ended; i++) {
    step(sim, .02, 800 / 360);
  }
  expect(sim.endReason, EndReason.collision);
  return sim;
}

const _moments = [0.0, .033, .1, .2, .33, .5, .7, .9, 1.1, 1.4, 1.9];

Future<void> _inGame(
  WidgetTester tester,
  String name,
  FlightSimulation sim,
  int bird, {
  bool reduced = false,
}) async {
  tester.view.physicalSize = const Size(800, 360);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  var ko = 0.0;
  final game = BirdGame(
    simulation: sim,
    nowMs: () => 0,
    bird: bird,
    reducedMotion: reduced,
    playback: true,
    onChanged: () {},
    knockout: () => ko,
  );
  await tester.pumpWidget(GameWidget(game: game));
  await tester.runAsync(() async {
    await game.loaded;
    game.pauseEngine();
    _folder.createSync(recursive: true);
    final frames = <(String, ui.Image)>[];
    final moments = reduced
        ? [0.0, .2, .4, .6, .8, 1.0, KnockoutArt.calmSeconds]
        : _moments;
    for (final t in moments) {
      ko = t;
      final recorder = ui.PictureRecorder();
      game.render(Canvas(recorder));
      final picture = recorder.endRecording();
      final image = await picture.toImage(800, 360);
      picture.dispose();
      final label = '${(t * 1000).round().toString().padLeft(4, '0')}ms';
      final png = (await image.toByteData(
        format: ui.ImageByteFormat.png,
      ))!.buffer.asUint8List();
      File('${_folder.path}/in-game-$name-$label.png').writeAsBytesSync(png);
      frames.add((label, image));
    }
    // A half-size contact sheet of the whole sequence.
    const cols = 4, scale = .5;
    final rows = (frames.length / cols).ceil();
    final recorder = ui.PictureRecorder();
    final c = Canvas(recorder);
    c.drawRect(
      Rect.fromLTWH(0, 0, 400.0 * cols, (180 + 20.0) * rows),
      Paint()..color = const Color(0xfff2eedf),
    );
    for (final (i, (label, image)) in frames.indexed) {
      final at = Offset((i % cols) * 400.0, (i ~/ cols) * 200.0 + 20);
      c.save();
      c.translate(at.dx, at.dy);
      c.scale(scale);
      c.drawImage(image, Offset.zero, Paint());
      c.restore();
      _text(c, label, at - const Offset(-6, 18), 12);
    }
    final sheet = await recorder.endRecording().toImage(400 * cols, 200 * rows);
    File('${_folder.path}/sheet-$name.png').writeAsBytesSync(
      (await sheet.toByteData(
        format: ui.ImageByteFormat.png,
      ))!.buffer.asUint8List(),
    );
    sheet.dispose();
    for (final (_, image) in frames) {
      image.dispose();
    }
  });
  expect(tester.takeException(), isNull);
  await tester.pumpWidget(const SizedBox());
}
