import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/game/sky_scenery.dart';
import 'package:push_up_bird/game/bird_trail.dart';
import 'package:push_up_bird/ui/flight_portrait.dart';

Future<List<int>> renderScenery({
  required double seconds,
  required double distance,
  required bool reducedMotion,
}) async {
  final recording = ui.PictureRecorder();
  SkyScenery.paint(
    Canvas(recording),
    const Size(400, 180),
    seconds: seconds,
    distance: distance,
    reducedMotion: reducedMotion,
  );
  final picture = recording.endRecording();
  final image = await picture.toImage(400, 180);
  final data = await image.toByteData();
  image.dispose();
  picture.dispose();
  return data!.buffer.asUint8List();
}

Future<List<int>> portraitPixels(WidgetTester tester) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('portrait-capture')),
  );
  return (await tester.runAsync(() async {
    final image = await boundary.toImage();
    final bytes = await image.toByteData();
    image.dispose();
    return bytes!.buffer.asUint8List();
  }))!;
}

Future<List<int>> trailPixels(int bird, double seconds, bool animate) async {
  final recording = ui.PictureRecorder();
  BirdTrail.paint(
    Canvas(recording),
    bird: bird,
    anchor: const Offset(220, 70),
    unit: 9,
    seconds: seconds,
    animate: animate,
  );
  final picture = recording.endRecording();
  final image = await picture.toImage(300, 140);
  final bytes = await image.toByteData();
  image.dispose();
  picture.dispose();
  return bytes!.buffer.asUint8List();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'all signature trails freeze in Reduced Motion and replay exactly',
    () async {
      for (var bird = 0; bird < 4; bird++) {
        final still = await trailPixels(bird, 0, false);
        expect(await trailPixels(bird, 5, false), still);
        final moving = await trailPixels(bird, 1, true);
        expect(moving, isNot(equals(still)));
        expect(await trailPixels(bird, 1, true), moving);
        expect(await trailPixels(bird, 5, true), isNot(equals(moving)));
      }
    },
  );
  test('region weights are continuous and always sum to one', () {
    for (var second = 0.0; second <= WorldTour.loop * 2; second += .25) {
      final blend = WorldTour.at(second);
      final later = WorldTour.at(second + 1e-6);
      var total = 0.0;
      for (final region in WorldRegion.values) {
        total += blend.weight(region);
        expect(
          later.weight(region),
          closeTo(blend.weight(region), 1e-4),
          reason: '\${region.name} at $second',
        );
      }
      expect(total, closeTo(1, 1e-10));
    }
  });

  for (final region in WorldRegion.values) {
    test(
      '\${region.title} scenery freezes in Reduced Motion and replays exactly',
      () async {
        final at = region.index * WorldTour.leg + 4;
        final still = await renderScenery(
          seconds: at,
          distance: 1,
          reducedMotion: true,
        );
        expect(
          await renderScenery(
            seconds: at + 7,
            distance: 4,
            reducedMotion: true,
          ),
          still,
        );
        final frame = await renderScenery(
          seconds: at,
          distance: 1,
          reducedMotion: false,
        );
        expect(
          await renderScenery(seconds: at, distance: 1, reducedMotion: false),
          frame,
        );
        expect(
          await renderScenery(
            seconds: at + 7,
            distance: 4,
            reducedMotion: false,
          ),
          isNot(equals(frame)),
        );
      },
    );
  }

  for (final reduced in [true, false]) {
    testWidgets(
      'result celebration is finite and respects reduced motion $reduced',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Center(
              child: RepaintBoundary(
                key: const ValueKey('portrait-capture'),
                child: FlightPortrait(
                  bird: 0,
                  reducedMotion: reduced,
                  celebrate: true,
                ),
              ),
            ),
          ),
        );
        await tester.runAsync(() async {
          await precacheImage(
            const AssetImage('assets/images/pip.png'),
            tester.element(find.byType(FlightPortrait)),
          );
        });
        await tester.pump();
        final first = await portraitPixels(tester);
        await tester.pump(const Duration(milliseconds: 700));
        final middle = await portraitPixels(tester);
        expect(middle, reduced ? equals(first) : isNot(equals(first)));
        await tester.pumpAndSettle();
        final settled = await portraitPixels(tester);
        await tester.pump(const Duration(seconds: 2));
        expect(await portraitPixels(tester), settled);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
}
