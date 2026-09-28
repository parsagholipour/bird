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

/// Mid-hold seconds of regions that borrow each legacy look: warm Aztec,
/// night Antarctica and day Jungle.
const warm = 52.0, night = 30.0, day = 8.0;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'regional gates keep artwork out of openings, including short towers',
    () async {
      for (final time in [warm, night, day]) {
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
      final dayArt = await pixels(day);
      final warmArt = await pixels(warm);
      final nightArt = await pixels(night);
      expect(difference(dayArt, warmArt), greaterThan(2));
      expect(difference(warmArt, nightArt), greaterThan(2));
      expect(difference(nightArt, dayArt), greaterThan(2));
      for (var leg = 0; leg < 6; leg++) {
        final start = leg * WorldTour.leg + WorldTour.hold;
        for (final at in [start, start + 3, start + WorldTour.crossing]) {
          // Mid-crossing, a millisecond may still tip 8-bit rounding across
          // whole colour areas; a real pop differs by whole units.
          expect(
            difference(await pixels(at - .001), await pixels(at)),
            lessThan(.3),
            reason: 'No sudden colour or decoration jump at $at seconds',
          );
        }
      }
    },
  );

  test(
    'lantern glow follows simulation time and honors Reduced Motion',
    () async {
      final first = await pixels(night);
      expect(await pixels(night + 4), isNot(equals(first)));
      expect(
        await pixels(night),
        first,
        reason: 'Pause and backwards seek agree',
      );
      expect(
        await pixels(night, reduced: true),
        await pixels(night + 4, reduced: true),
      );
      expect(await pixels(day), await pixels(day + 4));
      expect(await pixels(warm), await pixels(warm + 4));
    },
  );

  test('clear and perfect flowers remain distinct in every region', () async {
    for (final time in [warm, night, day]) {
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
      final seconds = [warm, night, day][i];
      SkyScenery.paint(
        canvas,
        const Size(300, 360),
        seconds: seconds,
        reducedMotion: true,
      );
      for (var column = 0; column < 3; column++) {
        for (final top in [true, false]) {
          GateArt.paint(
            canvas,
            Rect.fromLTWH(28 + column * 88.0, top ? 0 : 242, 44, 118),
            top: top,
            seconds: seconds,
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
