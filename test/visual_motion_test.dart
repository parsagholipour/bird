import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/game/sky_landmarks.dart';
import 'package:push_up_bird/game/sky_scenery.dart';
import 'package:push_up_bird/game/bird_trail.dart';
import 'package:push_up_bird/ui/flight_portrait.dart';
import 'package:push_up_bird/ui/flight_goals.dart';
import 'package:push_up_bird/domain/flight_goals.dart';
import 'package:push_up_bird/domain/flight_course.dart';
import 'package:push_up_bird/domain/cloud_friends.dart';
import 'package:push_up_bird/game/cloud_friend_art.dart';

Future<List<int>> renderLandmarks({
  required double seconds,
  required double distance,
  required bool reducedMotion,
  required int region,
}) async {
  final recording = ui.PictureRecorder();
  final canvas = Canvas(recording);
  SkyLandmarks.paint(
    canvas,
    const Size(800, 360),
    seconds: seconds,
    distance: distance,
    reducedMotion: reducedMotion,
    sunrise: region == 0 ? 1 : 0,
    peach: region == 1 ? 1 : 0,
    twilight: region == 2 ? 1 : 0,
  );
  final picture = recording.endRecording();
  final image = await picture.toImage(800, 360);
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
    'cloud friends are distinct and their gentle motion can be disabled',
    () async {
      Future<List<int>> pixels(
        CloudFriend friend,
        double seconds,
        bool reduced,
      ) async {
        final recorder = ui.PictureRecorder();
        CloudFriendArt.inSky(
          Canvas(recorder),
          center: const Offset(120, 80),
          height: 400,
          friend: friend,
          known: false,
          seconds: seconds,
          reducedMotion: reduced,
        );
        final picture = recorder.endRecording();
        final image = await picture.toImage(240, 160);
        final data = await image.toByteData();
        image.dispose();
        picture.dispose();
        return data!.buffer.asUint8List();
      }

      List<int>? previous;
      for (final friend in CloudFriend.values) {
        final still = await pixels(friend, 0, true);
        expect(await pixels(friend, 10, true), still);
        expect(await pixels(friend, 1, false), isNot(equals(still)));
        expect(await pixels(friend, 1, false), await pixels(friend, 1, false));
        if (previous != null) expect(still, isNot(equals(previous)));
        previous = still;
      }
    },
  );
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
  test('landmark crossfades are continuous at all three region boundaries', () {
    for (final boundary in [20.0, 40.0, 60.0]) {
      for (var region = 0; region < 3; region++) {
        expect(
          SkyPalette.regionWeight(boundary - .00001, region),
          closeTo(SkyPalette.regionWeight(boundary, region), .00001),
        );
      }
    }
    for (final second in [0.0, 17.5, 25.0, 38.0, 45.0, 58.5, 60.0]) {
      expect(
        List.generate(
          3,
          (i) => SkyPalette.regionWeight(second, i),
        ).reduce((a, b) => a + b),
        closeTo(1, 1e-10),
      );
    }
  });

  for (var region = 0; region < 3; region++) {
    test(
      'region $region landmarks freeze in Reduced Motion and replay exactly',
      () async {
        final still = await renderLandmarks(
          seconds: 5,
          distance: 1,
          reducedMotion: true,
          region: region,
        );
        expect(
          await renderLandmarks(
            seconds: 12,
            distance: 4,
            reducedMotion: true,
            region: region,
          ),
          still,
        );
        final frame = await renderLandmarks(
          seconds: 5,
          distance: 1,
          reducedMotion: false,
          region: region,
        );
        expect(
          await renderLandmarks(
            seconds: 5,
            distance: 1,
            reducedMotion: false,
            region: region,
          ),
          frame,
        );
        expect(
          await renderLandmarks(
            seconds: 12,
            distance: 4,
            reducedMotion: false,
            region: region,
          ),
          isNot(equals(frame)),
        );
      },
    );
  }

  for (final reduced in [true, false]) {
    testWidgets(
      'wing celebration settles and respects Reduced Motion $reduced',
      (tester) async {
        Widget hud(int gates) => MaterialApp(
          home: Center(
            child: RepaintBoundary(
              key: const ValueKey('portrait-capture'),
              child: SizedBox(
                width: 120,
                child: FlightGoalHud(
                  goals: [
                    for (final goal in FlightGoals.forCourse(
                      FlightCourse.classic,
                    ))
                      FlightGoalProgress(goal, gates),
                  ],
                  celebrating: gates > 0,
                  reducedMotion: reduced,
                ),
              ),
            ),
          ),
        );
        await tester.pumpWidget(hud(0));
        await tester.pumpWidget(hud(5));
        final first = await portraitPixels(tester);
        await tester.pump(const Duration(milliseconds: 300));
        final middle = await portraitPixels(tester);
        expect(middle, reduced ? equals(first) : isNot(equals(first)));
        await tester.pumpAndSettle();
        final settled = await portraitPixels(tester);
        await tester.pumpWidget(hud(5));
        await tester.pump(const Duration(seconds: 2));
        expect(await portraitPixels(tester), settled);
        expect(tester.takeException(), isNull);
      },
    );
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
