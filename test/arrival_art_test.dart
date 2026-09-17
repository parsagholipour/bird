import 'dart:ui' as ui;
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/session_replay.dart';
import 'package:push_up_bird/game/arrival_art.dart';
import 'package:push_up_bird/game/bird_game.dart';
import 'package:push_up_bird/ui/flight_portrait.dart';
import 'package:push_up_bird/ui/theme.dart';
import 'experience_ui_test.dart' show capture;
import 'replay_highlights_test.dart' show recordRoute;
import 'visual_motion_test.dart' show portraitPixels;

FlightSimulation flight(FlightCourse course) =>
    FlightSimulation(
        rules: PushUpFlightMode(cycleSeconds: 3),
        practice: true,
        course: course,
      )
      ..started = true
      ..phase = RunPhase.playing;

Future<List<int>> gatePixels(
  FlightSimulation sim, {
  bool reduced = false,
  bool align = false,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  if (align) canvas.translate(400 - ArrivalPose.forFlight(sim)!.x * 360, 0);
  ArrivalArt.gate(canvas, 360, sim, reducedMotion: reduced);
  final picture = recorder.endRecording();
  final image = await picture.toImage(800, 360);
  final bytes = await image.toByteData();
  image.dispose();
  picture.dispose();
  return bytes!.buffer.asUint8List();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    for (final family in ['Fredoka', 'Nunito']) {
      await (FontLoader(
        family,
      )..addFont(rootBundle.load('assets/fonts/$family.ttf'))).load();
    }
  });

  test(
    'only timed routes show a destination during their last six seconds',
    () {
      for (final course in FlightCourse.values) {
        final sim = flight(course)..elapsed = course.duration - 6.01;
        expect(ArrivalPose.forFlight(sim), isNull);
        sim.elapsed = course.duration - 6;
        if (!course.timed) {
          expect(ArrivalPose.forFlight(sim), isNull);
          continue;
        }
        expect(ArrivalPose.forFlight(sim)!.reveal, 0);
        final far = ArrivalPose.forFlight(sim)!.x;
        sim.elapsed = course.duration - 3;
        expect(ArrivalPose.forFlight(sim)!.x, lessThan(far));
        expect(ArrivalPose.forFlight(sim)!.reveal, 1);
        sim.started = false;
        expect(ArrivalPose.forFlight(sim), isNull);
        sim.started = true;
        sim.end(EndReason.quit);
        expect(ArrivalPose.forFlight(sim), isNull);
      }
    },
  );

  for (final course in [FlightCourse.starTrail, FlightCourse.skyCourier]) {
    test(
      '$course Reduced Motion removes flag flutter while the destination approaches',
      () async {
        final sim = flight(course)..elapsed = course.duration - 3;
        final still = await gatePixels(sim, reduced: true, align: true);
        final moving = await gatePixels(sim, align: true);
        sim.elapsed += .5;
        expect(await gatePixels(sim, reduced: true, align: true), still);
        expect(await gatePixels(sim, align: true), isNot(equals(moving)));
      },
    );
    test(
      '$course pause freezes the approach and ending arrives at the bird',
      () async {
        final sim = flight(course)..elapsed = course.duration - 2;
        final before = await gatePixels(sim);
        sim.takeBreak();
        sim.tick(.4, 1000);
        expect(await gatePixels(sim), before);
        sim.resume();
        expect(await gatePixels(sim), before);
        sim.elapsed = course.duration;
        sim.end(EndReason.completed);
        final pose = ArrivalPose.forFlight(sim)!;
        expect(pose.arrived, isTrue);
        expect(pose.x, FlightSimulation.birdX);
        expect(await gatePixels(sim), isNot(equals(before)));
      },
    );

    test(
      '$course replay seeks reproduce the approach and final frame',
      () async {
        final tape = recordRoute(course);
        final player = ReplayPlayer(tape);
        for (final offset in [4000.0, 1000.0, 7000.0, 0.0]) {
          final at = tape.durationMs - offset;
          player.seek(at);
          final other = ReplayPlayer(tape)..seek(at);
          expect(
            await gatePixels(player.simulation),
            await gatePixels(other.simulation),
          );
        }
        expect(ArrivalPose.forFlight(player.simulation)!.arrived, isTrue);
        expect(player.simulation.endReason, EndReason.completed);
      },
    );

    testWidgets('$course approach and completed portrait fit a small phone', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 360);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final sim = flight(course)
        ..elapsed = course.duration - 2
        ..birdY = .5;
      sim.obstacles.add(Obstacle(x: 1.7, center: .7, gap: .48));
      final game = BirdGame(
        simulation: sim,
        nowMs: () => 0,
        bird: course == FlightCourse.starTrail ? 3 : 1,
        reducedMotion: false,
        onChanged: () {},
        playback: true,
      );
      await tester.runAsync(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: RepaintBoundary(
              key: const ValueKey('visual-capture'),
              child: GameWidget(game: game),
            ),
          ),
        );
        await game.loaded;
      });
      await tester.pump(const Duration(milliseconds: 16));
      await capture(tester, 'arrival-approach-${course.name}');
      sim.elapsed = course.duration;
      sim.end(EndReason.completed);
      await tester.pump(const Duration(milliseconds: 16));
      await capture(tester, 'arrival-finish-${course.name}');
      await tester.pumpWidget(
        MaterialApp(
          home: RepaintBoundary(
            key: const ValueKey('visual-capture'),
            child: ColoredBox(
              color: SkyColors.sky,
              child: Center(
                child: FlightPortrait(
                  bird: course == FlightCourse.starTrail ? 3 : 1,
                  reducedMotion: true,
                  celebrate: true,
                  arrivedCourse: course,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.runAsync(() async {
        await precacheImage(
          AssetImage(
            'assets/images/${course == FlightCourse.starTrail ? 'orbit' : 'peaches'}.png',
          ),
          tester.element(find.byType(FlightPortrait)),
        );
      });
      await tester.pumpAndSettle();
      await capture(tester, 'arrival-portrait-${course.name}');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }

  for (final reduced in [true, false]) {
    testWidgets(
      'arrival portrait remains finite with Reduced Motion $reduced',
      (tester) async {
        Widget portrait(FlightCourse? course) => MaterialApp(
          home: Center(
            child: RepaintBoundary(
              key: const ValueKey('portrait-capture'),
              child: FlightPortrait(
                bird: 0,
                reducedMotion: reduced,
                celebrate: true,
                arrivedCourse: course,
              ),
            ),
          ),
        );
        await tester.pumpWidget(portrait(null));
        await tester.pumpAndSettle();
        final plain = await portraitPixels(tester);
        await tester.pumpWidget(portrait(FlightCourse.starTrail));
        await tester.pumpAndSettle();
        final medal = await portraitPixels(tester);
        expect(medal, isNot(equals(plain)));
        await tester.pump(const Duration(seconds: 3));
        expect(await portraitPixels(tester), medal);
        await tester.pumpWidget(portrait(FlightCourse.skyCourier));
        await tester.pumpAndSettle();
        expect(await portraitPixels(tester), isNot(equals(medal)));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
}
