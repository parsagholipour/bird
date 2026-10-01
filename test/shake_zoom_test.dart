// The camera's zoom while it shakes (the OPTIONAL shared "zoom-pop" patch).
//
// `BirdGame.render` used to scale the whole world by a constant 1.018 on every
// frame whose shake offset was not exactly zero: the picture grew 1.8% on the
// first frame of any hit and shrank back on the last, a pop on every boss's
// hit, however small the shake was. The zoom is now `1 + 2.2 * max(|dx| / w,
// |dy| / h)` (exactly 1 at rest): just enough that the shaken world still
// covers the screen's edges, and continuous with the rest state.
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flame/game.dart' show GameWidget;
import 'package:flutter/painting.dart' show Size;
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/game/bird_game.dart';
import 'package:push_up_bird/game/rush_art.dart';

/// A real game on a [size] screen, loaded and paused.
Future<BirdGame> mountGame(WidgetTester tester, FlightSimulation sim, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final game = BirdGame(
    simulation: sim,
    nowMs: () => 0,
    bird: 0,
    reducedMotion: false,
    playback: true,
    onChanged: () {},
  );
  await tester.pumpWidget(GameWidget<BirdGame>(game: game));
  await tester.runAsync(() => game.loaded.timeout(const Duration(seconds: 5)));
  game.pauseEngine();
  return game;
}

/// A canvas that draws nothing and remembers the transform calls, in order.
class _Spy implements ui.Canvas {
  _Spy(this.size);
  final Size size;
  final ops = <String>[];

  @override
  void translate(double dx, double dy) => ops.add('translate $dx $dy');

  @override
  void scale(double sx, [double? sy]) => ops.add('scale $sx ${sy ?? sx}');

  @override
  ui.Rect getLocalClipBounds() => ui.Offset.zero & size;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;

  /// The world zoom of the frame: the scale that directly follows the move to
  /// the screen's centre; null when the frame has none.
  double? worldZoom() {
    final c = 'translate ${size.width / 2} ${size.height / 2}';
    for (var i = 0; i + 1 < ops.length; i++) {
      if (ops[i] == c && ops[i + 1].startsWith('scale ')) {
        return double.parse(ops[i + 1].split(' ')[1]);
      }
    }
    return null;
  }
}

FlightSimulation _sim({double knockAgo = -1}) {
  final sim = FlightSimulation(rules: TapFlyMode(), practice: true)
    ..phase = RunPhase.playing
    ..elapsed = 5;
  if (knockAgo >= 0) {
    // A scorching knocks the camera for .34 s.
    sim.events.add(FlightEvent(FlightEventKind.scorched, sim.elapsed - knockAgo, .5));
  }
  return sim;
}

void main() {
  group('BirdGame.shakeZoom', () {
    test('is exactly 1 at rest, whatever the screen', () {
      for (final s in const [Size(640, 360), Size(800, 360), Size(0, 360)]) {
        expect(BirdGame.shakeZoom(ui.Offset.zero, s.width, s.height), 1.0);
      }
    });

    test('1 + 2.2 * max(|dx| / w, |dy| / h), in either direction', () {
      const w = 640.0, h = 360.0;
      expect(BirdGame.shakeZoom(const ui.Offset(6.4, 0), w, h), closeTo(1.022, 1e-12));
      expect(BirdGame.shakeZoom(const ui.Offset(-6.4, 0), w, h), closeTo(1.022, 1e-12));
      expect(BirdGame.shakeZoom(const ui.Offset(0, 3.6), w, h), closeTo(1.022, 1e-12));
      expect(BirdGame.shakeZoom(const ui.Offset(0, -3.6), w, h), closeTo(1.022, 1e-12));
      // The larger of the two decides.
      expect(BirdGame.shakeZoom(const ui.Offset(3.2, 7.2), w, h), closeTo(1.044, 1e-12));
      expect(BirdGame.shakeZoom(const ui.Offset(12.8, 3.6), w, h), closeTo(1.044, 1e-12));
    });

    test('has no pop: a hair of shake is a hair of zoom (it was 1.018 for any)', () {
      for (final d in [1e-9, 1e-6, 1e-3, .01, .1]) {
        final z = BirdGame.shakeZoom(ui.Offset(d, d), 640, 360);
        expect(z, greaterThan(1));
        expect(z - 1, closeTo(2.2 * d / 360, 1e-12), reason: '$d');
        expect(z - 1, lessThan(.0007), reason: 'under 0.07% for a tenth of a pixel');
      }
      // Continuous: the zoom grows with the shake and never jumps.
      var last = 1.0;
      for (var i = 0; i <= 400; i++) {
        final z = BirdGame.shakeZoom(ui.Offset(i * .05, 0), 640, 360);
        expect(z, greaterThanOrEqualTo(last));
        expect(z - last, lessThan(.0002), reason: 'step $i');
        last = z;
      }
    });

    test('still covers the screen: the shaken, zoomed world reaches every edge', () {
      // The canvas does translate(w/2, h/2); scale(z); translate(-w/2 + dx,
      // -h/2 + dy): the screen's edges, mapped back into the world, must lie
      // inside the world's [0, w] x [0, h].
      for (final s in const [Size(640, 360), Size(800, 360), Size(932, 430)]) {
        final w = s.width, h = s.height;
        // Every shake the game makes is under 3% of the screen height; the
        // formula holds up to 4.5% of the width.
        for (final f in [0.0, .002, .005, .01, .02, .03]) {
          for (final (sx, sy) in const [(1, 0), (0, 1), (1, 1), (-1, 1), (1, -1), (-1, -1)]) {
            final dx = sx * f * h, dy = sy * f * h;
            final z = BirdGame.shakeZoom(ui.Offset(dx, dy), w, h);
            // Screen edges mapped back into the world.
            final left = (0 - w / 2) / z + w / 2 - dx, right = (w - w / 2) / z + w / 2 - dx;
            final top = (0 - h / 2) / z + h / 2 - dy, bottom = (h - h / 2) / z + h / 2 - dy;
            expect(left, greaterThanOrEqualTo(-1e-9), reason: 'left $dx,$dy at $w');
            expect(right, lessThanOrEqualTo(w + 1e-9), reason: 'right $dx,$dy at $w');
            expect(top, greaterThanOrEqualTo(-1e-9), reason: 'top $dx,$dy at $w');
            expect(bottom, lessThanOrEqualTo(h + 1e-9), reason: 'bottom $dx,$dy at $w');
          }
        }
      }
    });

    test('the biggest camera knock the game makes is under the 4.5% the formula covers', () {
      // Rush knocks (the largest sources) at their start, every kind.
      var worst = 0.0;
      for (final kind in [
        FlightEventKind.smashed,
        FlightEventKind.meteorSmashed,
        FlightEventKind.swarmSmashed,
        FlightEventKind.enemyRammed,
        FlightEventKind.scorched,
        FlightEventKind.sprintRing,
      ]) {
        for (var i = 0; i < 400; i++) {
          final sim = _sim();
          sim.events.add(FlightEvent(kind, sim.elapsed - i * .001, .5, value: 5));
          final o = RushArt.cameraOffset(sim, false);
          worst = math.max(worst, math.max(o.dx.abs(), o.dy.abs()));
        }
      }
      expect(worst, greaterThan(0), reason: 'the probe sees the knocks');
      // Offsets are in screen heights; at the narrowest phone width (1.6 h) the
      // fraction of the width is worst / 1.6.
      expect(worst / 1.6, lessThan(.045));
    });
  });

  group('BirdGame.render', () {
    testWidgets('a frame at rest has no world zoom; a knocked one zooms by the formula, not by 1.018', (tester) async {
      const size = Size(640, 360);
      // At rest: no zoom call at all.
      var game = await mountGame(tester, _sim(), size);
      final rest = _Spy(size);
      game.render(rest);
      expect(rest.worldZoom(), isNull, reason: 'no shake, no zoom: ${rest.ops.take(6)}');

      // Knocked: the zoom follows the offset the camera was given.
      for (final ago in [.01, .1, .2, .3]) {
        final sim = _sim(knockAgo: ago);
        game = await mountGame(tester, sim, size);
        final spy = _Spy(size);
        game.render(spy);
        final shake = RushArt.cameraOffset(sim, false) * size.height;
        final want = BirdGame.shakeZoom(shake, size.width, size.height);
        expect(want, greaterThan(1), reason: 'the probe shakes at $ago s');
        expect(spy.worldZoom(), isNotNull, reason: 'knocked at $ago s: ${spy.ops.take(6)}');
        expect(spy.worldZoom()!, closeTo(want, 1e-12), reason: '$ago s');
        expect(spy.worldZoom()!, isNot(closeTo(1.018, 1e-3)), reason: '$ago s: the old constant zoom');
        expect(spy.worldZoom()!, lessThan(1.018), reason: '$ago s: a knock of this size zooms less than the old pop');
      }
    });

    testWidgets('a knock on its last frames leaves the picture where it was (it popped 1.8% before)', (tester) async {
      const size = Size(640, 360);
      Future<Uint8List> frame(FlightSimulation sim) async {
        final game = await mountGame(tester, sim, size);
        return (await tester.runAsync(() async {
          final rec = ui.PictureRecorder();
          game.render(ui.Canvas(rec));
          final pic = rec.endRecording();
          final img = await pic.toImage(640, 360);
          final data = await img.toByteData();
          img.dispose();
          pic.dispose();
          return data!.buffer.asUint8List();
        }))!;
      }

      // A scorching knock is .34 s long: .3399 s in, the offset is a hair.
      final tail = _sim(knockAgo: .3399);
      final shake = RushArt.cameraOffset(tail, false);
      expect(shake, isNot(ui.Offset.zero), reason: 'the probe frame is still shaking');
      expect(shake.distance * 360, lessThan(.01), reason: 'by a hundredth of a pixel');
      final shaken = await frame(tail);
      // The same flight and clock with the knock already over: the shake is
      // exactly zero, the zoom exactly 1.
      final over = _sim(knockAgo: .3401);
      expect(RushArt.cameraOffset(over, false), ui.Offset.zero);
      final calm = await frame(over);
      var differing = 0;
      for (var i = 0; i < calm.length; i += 4) {
        final d = (calm[i] - shaken[i]).abs() + (calm[i + 1] - shaken[i + 1]).abs() + (calm[i + 2] - shaken[i + 2]).abs();
        if (d > 24) differing++;
      }
      // With the old 1.018 zoom the whole skyline shifted by up to 6 px: tens
      // of thousands of pixels differ. A hundredth of a pixel moves none that
      // far (the burst/ring art of the event itself is the same in both).
      expect(differing, lessThan(300), reason: '$differing pixels differ');
    });
  });
}
