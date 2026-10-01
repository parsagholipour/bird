import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/game/bird_game.dart';
import 'package:push_up_bird/game/tether_art.dart';

import 'coop_flight_test.dart' show pair, settle, step;

/// Review renders are written with --dart-define=CAPTURE_VISUALS=true.
const _capture = bool.fromEnvironment('CAPTURE_VISUALS');
final _folder = Directory('build/visual-review/coop');

/// Moments of a co-op flight, each a simulation ready to draw.
Map<String, FlightSimulation> _moments() {
  FlightSimulation fresh() => pair()..invulnerableUntil = double.infinity;
  final level = fresh();
  settle(level);
  step(level, .2);

  // Player 1 flaps alone from a taut hang: the rope has just snapped.
  final snap = fresh();
  settle(snap, y: .42);
  final dx = snap.partner!.homeX - snap.lead.homeX;
  snap.partner!.y = .42 + sqrt(Tether.length * Tether.length - dx * dx);
  snap.flap(0);
  step(snap, .06);

  final drag = fresh();
  settle(drag);
  drag.sprint(player: 1);
  for (var i = 0; i < 25; i++) {
    for (final bird in drag.flock) {
      bird
        ..y = .5
        ..velocity = 0;
    }
    step(drag, .02);
  }

  final push = fresh();
  settle(push);
  push.sprint(player: 0);
  for (var i = 0; i < 25; i++) {
    for (final bird in push.flock) {
      bird
        ..y = .5
        ..velocity = 0;
    }
    step(push, .02);
  }

  final apart = fresh();
  settle(apart, y: .3);
  apart.partner!.y = .62;
  step(apart, .1);

  return {
    'level': level,
    'snap': snap,
    'drag': drag,
    'push': push,
    'apart': apart,
  };
}

Future<ui.Image> _render(BirdGame game, int width, int height) async {
  final recorder = ui.PictureRecorder();
  game.render(Canvas(recorder));
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  picture.dispose();
  return image;
}

Future<void> _save(ui.Image image, String name) async {
  if (!_capture) return;
  _folder.createSync(recursive: true);
  final png = await image.toByteData(format: ui.ImageByteFormat.png);
  File('${_folder.path}/$name.png').writeAsBytesSync(png!.buffer.asUint8List());
}

Color _pixel(ByteData pixels, int width, Offset at) {
  final i = (at.dy.round() * width + at.dx.round()) * 4;
  return Color.fromARGB(
    pixels.getUint8(i + 3),
    pixels.getUint8(i),
    pixels.getUint8(i + 1),
    pixels.getUint8(i + 2),
  );
}

/// Draws the flight at the review size: 800 × 360.
void _sized(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 360);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader(
      'Fredoka',
    )..addFont(rootBundle.load('assets/fonts/Fredoka.ttf'))).load();
  });

  for (final reducedMotion in [false, true]) {
    testWidgets('the pair and their rope draw in every moment'
        '${reducedMotion ? ' with Reduced Motion' : ''}', (tester) async {
      _sized(tester);
      for (final MapEntry(key: name, value: sim) in _moments().entries) {
        final game = BirdGame(
          simulation: sim,
          nowMs: () => 0,
          bird: 2,
          partnerBird: 3,
          reducedMotion: reducedMotion,
          playback: true,
          onChanged: () {},
        );
        await tester.pumpWidget(GameWidget(game: game));
        await tester.runAsync(() async {
          await game.loaded;
          game.pauseEngine();
          const width = 800, height = 360;
          final image = await _render(game, width, height);
          await _save(image, '$name${reducedMotion ? '-calm' : ''}');
          image.dispose();
        });
        expect(tester.takeException(), isNull);
      }
    });
  }

  test(
    'a slack rope hangs below the birds and a taut one runs straight',
    () async {
      Future<ByteData> draw(Offset a, Offset b) async {
        final recorder = ui.PictureRecorder();
        TetherArt.between(
          Canvas(recorder),
          400,
          a,
          b,
          seconds: 0,
          reducedMotion: true,
        );
        final picture = recorder.endRecording();
        final image = await picture.toImage(400, 400);
        final pixels = (await image.toByteData())!;
        image.dispose();
        picture.dispose();
        return pixels;
      }

      // A span of .2 leaves .1 of slack: the rope sags a parabola's depth.
      final slack = await draw(const Offset(.2, .4), const Offset(.4, .4));
      final sag = sqrt(3 * .2 * (Tether.length - .2) / 8);
      expect(_pixel(slack, 400, Offset(.3 * 400, (.4 + sag) * 400)).a, 1);
      expect(_pixel(slack, 400, const Offset(.3 * 400, .4 * 400)).a, 0);
      expect(_pixel(slack, 400, Offset(.3 * 400, (.4 + sag + .03) * 400)).a, 0);
      // At the rope's full length it runs straight from bird to bird.
      final taut = await draw(
        const Offset(.2, .4),
        const Offset(.2 + Tether.length, .4),
      );
      expect(
        _pixel(taut, 400, Offset((.2 + Tether.length / 2) * 400, 160)).a,
        1,
      );
      final warm = _pixel(
        taut,
        400,
        Offset((.2 + Tether.length / 2) * 400, 160),
      );
      expect(warm.r, greaterThan(warm.b));
    },
  );

  test('a pair without the rope draws no rope', () async {
    final sim = pair(coop: CoopMode.free);
    settle(sim);
    final recorder = ui.PictureRecorder();
    TetherArt.rope(Canvas(recorder), 360, sim, reducedMotion: false);
    final picture = recorder.endRecording();
    final image = await picture.toImage(400, 360);
    final pixels = (await image.toByteData())!.buffer.asUint8List();
    expect(
      [
        for (var i = 3; i < pixels.length; i += 4) pixels[i],
      ].every((a) => a == 0),
      isTrue,
    );
    image.dispose();
    picture.dispose();
  });

  testWidgets('a knocked-out pair tumbles together', (tester) async {
    _sized(tester);
    final sim = pair();
    settle(sim);
    sim.end(EndReason.collision);
    var ko = 0.0;
    final game = BirdGame(
      simulation: sim,
      nowMs: () => 0,
      bird: 0,
      partnerBird: 1,
      reducedMotion: false,
      playback: true,
      onChanged: () {},
      knockout: () => ko,
    );
    await tester.pumpWidget(GameWidget(game: game));
    await tester.runAsync(() async {
      await game.loaded;
      game.pauseEngine();
      for (final t in [.05, .4, .9]) {
        ko = t;
        final image = await _render(game, 800, 360);
        await _save(image, 'knockout-${(t * 1000).round()}ms');
        image.dispose();
      }
    });
    expect(tester.takeException(), isNull);
  });
}
