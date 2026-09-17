import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/game/gate_art.dart';
import 'package:push_up_bird/game/sky_scenery.dart';

Future<List<int>> pixels(
  double time, {
  bool top = true,
  bool reduced = false,
  bool cleared = false,
  bool perfect = false,
  Rect rect = const Rect.fromLTWH(40, 20, 54, 200),
}) async {
  final recorder = ui.PictureRecorder();
  GateArt.paint(
    Canvas(recorder),
    rect,
    top: top,
    seconds: time,
    reducedMotion: reduced,
    cleared: cleared,
    perfect: perfect,
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(140, 240);
  final bytes = await image.toByteData();
  image.dispose();
  picture.dispose();
  return bytes!.buffer.asUint8List();
}

double difference(List<int> a, List<int> b) {
  var total = 0;
  for (var i = 0; i < a.length; i++) {
    total += (a[i] - b[i]).abs();
  }
  return total / a.length;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'regional gates keep artwork out of openings, including short towers',
    () async {
      for (final time in [5.0, 25.0, 45.0]) {
        for (final top in [true, false]) {
          for (final height in [1.0, 7.0, 30.0, 200.0]) {
            final rect = Rect.fromLTWH(40, 20, 54, height);
            final art = await pixels(
              time,
              top: top,
              rect: rect,
              cleared: true,
              perfect: true,
            );
            var painted = 0;
            for (var y = 0; y < 240; y++) {
              for (var x = 0; x < 140; x++) {
                final alpha = art[(y * 140 + x) * 4 + 3];
                if (alpha > 0) painted++;
                if (y < rect.top ||
                    y >= rect.bottom ||
                    x < rect.left - 5 ||
                    x >= rect.right + 5) {
                  expect(
                    alpha,
                    0,
                    reason: '$time, top=$top, h=$height at $x,$y',
                  );
                }
              }
            }
            expect(painted, greaterThan(0));
          }
        }
      }
    },
  );

  test(
    'regional artwork crossfades continuously and distinguishes each sky',
    () async {
      final day = await pixels(5);
      final warm = await pixels(25);
      final night = await pixels(45);
      expect(difference(day, warm), greaterThan(2));
      expect(difference(warm, night), greaterThan(2));
      expect(difference(night, day), greaterThan(2));
      for (final boundary in [20.0, 40.0, 60.0]) {
        expect(
          difference(await pixels(boundary - .001), await pixels(boundary)),
          lessThan(.1),
          reason: 'No sudden colour or decoration jump at $boundary seconds',
        );
      }
    },
  );

  test(
    'lantern glow follows simulation time and honors Reduced Motion',
    () async {
      final first = await pixels(45);
      expect(await pixels(49), isNot(equals(first)));
      expect(await pixels(45), first, reason: 'Pause and backwards seek agree');
      expect(await pixels(45, reduced: true), await pixels(49, reduced: true));
      expect(await pixels(5), await pixels(9));
      expect(await pixels(25), await pixels(29));
    },
  );

  test('clear and perfect flowers remain distinct in every region', () async {
    for (final time in [5.0, 25.0, 45.0]) {
      final waiting = await pixels(time);
      final cleared = await pixels(time, cleared: true);
      final perfect = await pixels(time, cleared: true, perfect: true);
      expect(cleared, isNot(equals(waiting)));
      expect(perfect, isNot(equals(cleared)));
    }
    if (!const bool.fromEnvironment('CAPTURE_VISUALS')) return;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    for (var i = 0; i < 3; i++) {
      canvas.save();
      canvas.translate(i * 300.0, 0);
      canvas.clipRect(const Rect.fromLTWH(0, 0, 300, 360));
      SkyScenery.paint(
        canvas,
        const Size(300, 360),
        seconds: 5 + i * 20.0,
        reducedMotion: true,
      );
      for (var column = 0; column < 3; column++) {
        for (final top in [true, false]) {
          GateArt.paint(
            canvas,
            Rect.fromLTWH(28 + column * 88.0, top ? 0 : 242, 44, 118),
            top: top,
            seconds: 5 + i * 20.0,
            reducedMotion: true,
            cleared: column > 0,
            perfect: column == 2,
          );
        }
      }
      canvas.restore();
    }
    final picture = recorder.endRecording();
    final image = await picture.toImage(900, 360);
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    Directory('build/visual-review').createSync(recursive: true);
    File(
      'build/visual-review/regional-gates.png',
    ).writeAsBytesSync(png!.buffer.asUint8List());
    image.dispose();
    picture.dispose();
  });
}
