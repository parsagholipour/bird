import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/game/bird_game.dart';
import 'package:push_up_bird/game/enemy_designs/patrol_bat.dart';
import 'package:push_up_bird/game/enemy_designs/simple_bat.dart';

/// Visual review for the cave bat: art-box fill over a full wingbeat,
/// determinism, Reduced Motion, close-up / gameplay-size sheets and real
/// 800x360 frames at daylight, dusk and twilight.
const _wingPeriod = PatrolBatArt.wingPeriod;
const _folder = 'build/visual-review/cave-bat';

typedef _Painter =
    void Function(
      Canvas c,
      double radius, {
      required double seconds,
      required bool reducedMotion,
      double lookY,
      double charge,
      double recoil,
    });

Future<ui.Image> _image(void Function(Canvas) draw, int w, int h) async {
  final recorder = ui.PictureRecorder();
  draw(Canvas(recorder));
  final picture = recorder.endRecording();
  final image = await picture.toImage(w, h);
  picture.dispose();
  return image;
}

Future<void> _png(String name, void Function(Canvas) draw, int w, int h) async {
  final image = await _image(draw, w, h);
  final png = (await image.toByteData(format: ui.ImageByteFormat.png))!;
  Directory(_folder).createSync(recursive: true);
  File('$_folder/$name.png').writeAsBytesSync(png.buffer.asUint8List());
  image.dispose();
}

Future<List<int>> _pixels(void Function(Canvas) draw, int w, int h) async {
  final image = await _image(draw, w, h);
  final bytes = (await image.toByteData())!.buffer.asUint8List();
  image.dispose();
  return bytes;
}

/// Painted bounds in hit-radius units for one pose, drawn at [r] px.
Future<Rect> _bounds(
  _Painter painter, {
  required double seconds,
  bool reducedMotion = false,
  double lookY = 0,
  double charge = 0,
  double recoil = 0,
}) async {
  const r = 100.0, w = 600, h = 400;
  final bytes = await _pixels(
    (c) {
      c.translate(w / 2, h / 2);
      painter(
        c,
        r,
        seconds: seconds,
        reducedMotion: reducedMotion,
        lookY: lookY,
        charge: charge,
        recoil: recoil,
      );
    },
    w,
    h,
  );
  var left = w, right = -1, top = h, bottom = -1;
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      if (bytes[(y * w + x) * 4 + 3] > 24) {
        left = math.min(left, x);
        right = math.max(right, x);
        top = math.min(top, y);
        bottom = math.max(bottom, y);
      }
    }
  }
  return Rect.fromLTRB(
    (left - w / 2) / r,
    (top - h / 2) / r,
    (right + 1 - w / 2) / r,
    (bottom + 1 - h / 2) / r,
  );
}

String _r(Rect r) => [
  r.left,
  r.top,
  r.right,
  r.bottom,
].map((v) => v.toStringAsFixed(2)).join(', ');

const _day = [Color(0xff8dd8eb), Color(0xffe9f5df)];
const _dusk = [Color(0xffaaa9e0), Color(0xffffdfc3)];
const _twilight = [Color(0xff485584), Color(0xffadb6da)];
const _duskHills = Color(0xff9e82b4);

void _sky(Canvas c, Rect rect, List<Color> colors) {
  c.drawRect(
    rect,
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: colors,
      ).createShader(rect),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('cave bat fills its art box, stays deterministic, and renders', (
    tester,
  ) async {
    await tester.runAsync(() async {
      // Bounds over a full wingbeat, including every passed pose.
      var union = Rect.zero;
      var minWidth = double.infinity, maxWidth = 0.0;
      var minHeight = double.infinity;
      final widths = <String>[];
      for (var i = 0; i < 24; i++) {
        final t = i / 24 * _wingPeriod;
        for (final (look, charge, recoil) in [
          (0.0, 0.0, 0.0),
          if (i % 6 == 0) ...[(-1.0, 1.0, 0.0), (1.0, 0.0, 1.0)],
        ]) {
          final b = await _bounds(
            PatrolBatArt.paint,
            seconds: t,
            lookY: look,
            charge: charge,
            recoil: recoil,
          );
          union = union == Rect.zero ? b : union.expandToInclude(b);
          if (look == 0) {
            minWidth = math.min(minWidth, b.width);
            maxWidth = math.max(maxWidth, b.width);
            minHeight = math.min(minHeight, b.height);
            widths.add(
              '${b.width.toStringAsFixed(2)}x${b.height.toStringAsFixed(2)}',
            );
          }
        }
      }
      final still = await _bounds(
        PatrolBatArt.paint,
        seconds: 0,
        reducedMotion: true,
      );
      union = union.expandToInclude(still);
      final simple = await _bounds(SimpleBatArt.paint, seconds: .3);
      // ignore: avoid_print
      print(
        'cave bat union ${_r(union)}  width ${minWidth.toStringAsFixed(2)}-'
        '${maxWidth.toStringAsFixed(2)}r  min height '
        '${minHeight.toStringAsFixed(2)}r  still ${_r(still)}\n'
        'frames: ${widths.join(' ')}\nsimple bat ${_r(simple)}',
      );

      // Pure function of time; Reduced Motion freezes decorative motion.
      Future<List<int>> at(double t, {bool reduced = false, double look = 0}) =>
          _pixels(
            (c) {
              c.translate(100, 70);
              PatrolBatArt.paint(
                c,
                40,
                seconds: t,
                reducedMotion: reduced,
                lookY: look,
              );
            },
            200,
            140,
          );
      final a = await at(1.37);
      expect(await at(1.37), a, reason: 'paused frame stays exact');
      expect(await at(1.37 + _wingPeriod * .4), isNot(equals(a)));
      expect(await at(.2, reduced: true), await at(3.9, reduced: true));
      expect(
        await at(.2, reduced: true, look: 1),
        isNot(equals(await at(.2, reduced: true, look: -1))),
        reason: 'the eye still tracks the bird under Reduced Motion',
      );

      // Close-up sheet: daylight, dusk and twilight at a large scale.
      await _png(
        'close-up',
        (c) {
          const panels = [_day, _dusk, _twilight];
          for (var i = 0; i < 3; i++) {
            final rect = Rect.fromLTWH(i * 420.0, 0, 420, 300);
            _sky(c, rect, panels[i]);
            c.save();
            c.translate(rect.center.dx, rect.center.dy);
            PatrolBatArt.paint(
              c,
              100,
              seconds: .3 + i * _wingPeriod / 3,
              reducedMotion: false,
              lookY: i - 1.0,
            );
            c.restore();
          }
          c.drawRect(
            const Rect.fromLTWH(0, 300, 1260, 300),
            Paint()..color = const Color(0xfff2eedf),
          );
          c.save();
          c.translate(300, 450);
          SimpleBatArt.paint(c, 100, seconds: .3, reducedMotion: false);
          c.restore();
          c.save();
          c.translate(900, 450);
          PatrolBatArt.paint(c, 100, seconds: 0, reducedMotion: true);
          // The art box, for reference.
          c.drawRect(
            const Rect.fromLTRB(-190, -120, 190, 120),
            Paint()
              ..style = PaintingStyle.stroke
              ..color = const Color(0x66d75e4f),
          );
          c.restore();
        },
        1260,
        600,
      );

      // Key poses through one beat, large enough to judge shapes.
      await _png(
        'poses',
        (c) {
          c.drawPaint(Paint()..color = const Color(0xfff2eedf));
          const phases = [0.0, .1, .2, .3, .42, .55, .7, .85];
          for (var i = 0; i < phases.length; i++) {
            final x = (i % 4) * 420.0 + 210, y = (i ~/ 4) * 260.0 + 130;
            c.save();
            c.translate(x, y);
            c.drawRect(
              const Rect.fromLTRB(-171, -108, 171, 108),
              Paint()
                ..style = PaintingStyle.stroke
                ..color = const Color(0x44d75e4f),
            );
            PatrolBatArt.paint(
              c,
              90,
              seconds: (7 + phases[i]) * _wingPeriod,
              reducedMotion: false,
            );
            c.restore();
          }
        },
        1680,
        520,
      );

      // Frame strip over one wingbeat, large and at gameplay size.
      await _png(
        'wing-strip',
        (c) {
          c.drawPaint(Paint()..color = const Color(0xfff2eedf));
          for (var i = 0; i < 12; i++) {
            final t = (5 + i / 12) * _wingPeriod;
            final x = (i % 6) * 210.0 + 105, y = (i ~/ 6) * 170.0 + 85;
            c.save();
            c.translate(x, y);
            PatrolBatArt.paint(c, 52, seconds: t, reducedMotion: false);
            c.restore();
          }
          _sky(c, const Rect.fromLTWH(0, 340, 1260, 70), _dusk);
          for (var i = 0; i < 24; i++) {
            final t = (5 + i / 24) * _wingPeriod;
            c.save();
            c.translate(i * 52.0 + 30, 375);
            PatrolBatArt.paint(c, 16.2, seconds: t, reducedMotion: false);
            c.restore();
          }
        },
        1260,
        410,
      );

      // Gameplay size (radius 16.2 px in a 360 px viewport) on every sky.
      await _png(
        'gameplay-size',
        (c) {
          const bands = [_day, _dusk, _twilight];
          for (var i = 0; i < 4; i++) {
            final rect = Rect.fromLTWH(0, i * 70.0, 420, 70);
            if (i < 3) {
              _sky(c, rect, bands[i]);
            } else {
              c.drawRect(rect, Paint()..color = _duskHills);
            }
            for (var j = 0; j < 4; j++) {
              c.save();
              c.translate(50 + j * 75.0, rect.center.dy);
              PatrolBatArt.paint(
                c,
                16.2,
                seconds: 1 + j * _wingPeriod / 4,
                reducedMotion: false,
                lookY: j / 1.5 - 1,
              );
              c.restore();
            }
            c.save();
            c.translate(370, rect.center.dy);
            SimpleBatArt.paint(c, 16.2, seconds: 1, reducedMotion: false);
            c.restore();
          }
        },
        420,
        280,
      );

      if (const bool.fromEnvironment('CAPTURE_CAVE_BAT_MOVIE')) {
        // 60 fps frames over two beats, close-up and at gameplay size.
        final frames = (2 * _wingPeriod * 60).ceil();
        for (var f = 0; f < frames; f++) {
          await _png(
            'movie-${f.toString().padLeft(3, '0')}',
            (c) {
              _sky(c, const Rect.fromLTWH(0, 0, 480, 300), _dusk);
              c.save();
              c.translate(210, 140);
              PatrolBatArt.paint(
                c,
                100,
                seconds: 3 + f / 60,
                reducedMotion: false,
              );
              c.restore();
              c.save();
              c.translate(430, 260);
              PatrolBatArt.paint(
                c,
                16.2,
                seconds: 3 + f / 60,
                reducedMotion: false,
              );
              c.restore();
            },
            480,
            300,
          );
        }
      }

      // Painted bounds (1 px = .01 r of antialiasing) stay inside the art
      // box through a full wingbeat, every look direction and attack input,
      // while filling it: ~3.3-3.6 r wide in every pose.
      expect(union.left, greaterThanOrEqualTo(-1.91));
      expect(union.right, lessThanOrEqualTo(1.91));
      expect(union.top, greaterThanOrEqualTo(-1.21));
      expect(union.bottom, lessThanOrEqualTo(1.21));
      expect(minWidth, greaterThan(3.3), reason: 'fills the box sideways');
      expect(maxWidth, lessThan(3.65), reason: 'same size class as others');
      expect(minHeight, greaterThan(1.8));
      expect(still.width, greaterThan(3.3));
    });
  });

  for (final (name, elapsed) in [
    ('in-game-day', 5.0),
    ('in-game-dusk', 21.0),
    ('in-game-twilight', 45.0),
  ]) {
    testWidgets('cave bat in the actual game: $name', (tester) async {
      tester.view.physicalSize = const Size(800, 360);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final sim = FlightSimulation(rules: TapFlyMode(), practice: true)
        ..phase = RunPhase.playing
        ..elapsed = elapsed;
      for (var kind = 0; kind < 3; kind++) {
        sim.enemies.add(
          SkyEnemy(
              x: 1.35 + kind * .30,
              y: .28 + kind * .22,
              appearance: kind,
              flightPhase: kind * 2.399963,
            )
            ..age = 1.8
            ..preparing = kind > 0
            ..fireIn = .15,
        );
      }
      sim.enemies
        ..add(
          SkyEnemy(x: 1.03, y: .27, appearance: 3, flightPhase: 2.1)..age = 1.8,
        )
        ..add(
          SkyEnemy(x: 2.06, y: .72, appearance: 0, flightPhase: .9)..age = 2.05,
        )
        ..add(
          SkyEnemy(x: 1.2, y: .62, appearance: 0, flightPhase: 1.7)..age = 1.1,
        );
      final game = BirdGame(
        simulation: sim,
        nowMs: () => 0,
        bird: 0,
        reducedMotion: false,
        playback: true,
        onChanged: () {},
      );
      await tester.pumpWidget(GameWidget(game: game));
      await tester.runAsync(() async {
        await game.loaded;
        game.pauseEngine();
        await _png(name, game.render, 800, 360);
      });
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
