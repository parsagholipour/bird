import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/session_replay.dart';
import 'package:push_up_bird/domain/tracking.dart';
import 'package:push_up_bird/game/bird_puppet.dart';
import 'package:push_up_bird/ui/theme.dart';
import 'recorded_flight.dart';

Future<ui.Image> renderBird(int bird, double wing) async {
  final recorder = ui.PictureRecorder();
  BirdPuppet.paint(
    Canvas(recorder),
    const Rect.fromLTWH(0, 0, 512, 448),
    bird: bird,
    wing: wing,
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(512, 448);
  picture.dispose();
  return image;
}

List<double> poseValues(BirdPose pose) => [
  pose.wing,
  pose.tilt,
  pose.spring,
  pose.flapWake,
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('neutral vector puppets retain all four original bird designs', () async {
    for (final (bird, name) in ['pip', 'peaches', 'minty', 'orbit'].indexed) {
      final data = await rootBundle.load('assets/images/$name.png');
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final original = (await codec.getNextFrame()).image;
      final painted = await renderBird(bird, 0);
      final before = (await original.toByteData())!.buffer.asUint8List();
      final after = (await painted.toByteData())!.buffer.asUint8List();
      expect(after.length, before.length);
      var difference = 0;
      for (var i = 0; i < before.length; i++) {
        difference += (after[i] - before[i]).abs();
      }
      // Raster export and runtime curves have slightly different edge sampling.
      expect(difference / before.length, lessThan(1.2), reason: name);
      original.dispose();
      painted.dispose();
      codec.dispose();
    }
  });

  test(
    'push-up wing pose follows the calibrated range and holds each endpoint',
    () {
      final sim = FlightSimulation(
        rules: PushUpFlightMode(cycleSeconds: 3),
        practice: true,
      )..started = true;
      sim.birdY = .15;
      final high = BirdPose.forFlight(sim, reducedMotion: false);
      sim.elapsed += 10;
      expect(
        poseValues(BirdPose.forFlight(sim, reducedMotion: false)),
        poseValues(high),
      );
      sim.birdY = .85;
      final low = BirdPose.forFlight(sim, reducedMotion: false);
      expect(low.wing - high.wing, greaterThan(.9));
      expect(high.tilt, 0);
      expect(low.tilt, 0);
      expect(high.spring, 0);
      expect(low.spring, 0);
      expect(poseValues(BirdPose.forFlight(sim, reducedMotion: true)), [
        0,
        0,
        0,
        0,
      ]);
    },
  );

  test('jump stroke is finite, pause-stable and quiet in Reduced Motion', () {
    final sim = FlightSimulation(rules: JumpFlyMode(), practice: true)
      ..started = true
      ..phase = RunPhase.playing
      ..lastFlapAt = 2
      ..elapsed = 2.07
      ..velocity = -.3;
    final stroke = BirdPose.forFlight(sim, reducedMotion: false);
    expect(stroke.wing, closeTo(-.43, .01));
    expect(stroke.spring, lessThan(0));
    expect(stroke.flapWake, greaterThan(0));
    sim.takeBreak();
    sim.tick(.2, 5000);
    expect(
      poseValues(BirdPose.forFlight(sim, reducedMotion: false)),
      poseValues(stroke),
    );
    expect(poseValues(BirdPose.forFlight(sim, reducedMotion: true)), [
      0,
      0,
      0,
      0,
    ]);
    sim.elapsed = 2.285;
    final recovery = BirdPose.forFlight(sim, reducedMotion: false);
    expect(recovery.wing, closeTo(.275, .001));
    expect(recovery.wing - .10, lessThan((stroke.wing - .10).abs()));
    sim.elapsed = 2.38;
    expect(
      BirdPose.forFlight(sim, reducedMotion: false).wing,
      closeTo(.10, 1e-9),
    );
    sim.elapsed = 2.5;
    final glide = BirdPose.forFlight(sim, reducedMotion: false);
    expect(glide.wing, .10);
    expect(glide.spring, 0);
    expect(glide.flapWake, 0);
  });

  for (final rules in [TapFlyMode(), JumpFlyMode()]) {
    test('${rules.mode} spring extends, softly compresses, then settles', () {
      final sim = FlightSimulation(rules: rules, practice: true)
        ..started = true
        ..lastFlapAt = 0;
      double springAt(double age) {
        sim.elapsed = age;
        return BirdPose.forFlight(sim, reducedMotion: false).spring;
      }

      final extension = springAt(.04);
      final compression = springAt(.15);
      expect(springAt(.001), lessThan(0));
      expect(extension, lessThan(0));
      expect(compression, greaterThan(0));
      expect(compression, lessThan(extension.abs()));
      for (final age in [-.1, 0.0, .08, .22, 1.0]) {
        expect(springAt(age), 0);
      }
      for (final boundary in [0.0, .08, .22]) {
        for (final offset in [-.000001, .000001]) {
          expect(springAt(boundary + offset), closeTo(0, 1e-8));
        }
      }
      for (var ms = 0; ms <= 220; ms++) {
        expect(springAt(ms / 1000).abs(), lessThanOrEqualTo(.06));
      }
      expect(springAt(.15), compression);
      expect(springAt(.04), extension);
      expect(BirdPose.forFlight(sim, reducedMotion: true).spring, 0);
    });
  }

  for (final mode in PlayMode.values) {
    test('$mode wing poses replay identically across backward seeks', () {
      final tape = recordFlight(mode);
      final player = ReplayPlayer(tape);
      for (final at in [16000.0, 29000.0, 7000.0, 29100.0]) {
        player.seek(at);
        final other = ReplayPlayer(tape)..seek(at);
        expect(
          poseValues(
            BirdPose.forFlight(player.simulation, reducedMotion: false),
          ),
          poseValues(
            BirdPose.forFlight(other.simulation, reducedMotion: false),
          ),
        );
      }
    });
  }

  test(
    'wings move independently while faces keep their exact appearance',
    () async {
      for (var bird = 0; bird < 4; bird++) {
        final down = await renderBird(bird, -.42);
        final up = await renderBird(bird, .60);
        final before = (await down.toByteData())!.buffer.asUint8List();
        final after = (await up.toByteData())!.buffer.asUint8List();
        expect(after, isNot(equals(before)));
        for (var y = 0; y < 448; y++) {
          expect(
            after.sublist((y * 512 + 240) * 4, (y + 1) * 512 * 4),
            before.sublist((y * 512 + 240) * 4, (y + 1) * 512 * 4),
          );
        }
        down.dispose();
        up.dispose();
      }
      if (!const bool.fromEnvironment('CAPTURE_VISUALS')) return;
      await (FontLoader(
        'Nunito',
      )..addFont(rootBundle.load('assets/fonts/Nunito.ttf'))).load();
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawColor(SkyColors.cream, BlendMode.src);
      for (final (row, (title, wing)) in [
        ('Neutral', 0.0),
        ('Power stroke', -.42),
        ('Open wing', .60),
      ].indexed) {
        for (var bird = 0; bird < 4; bird++) {
          BirdPuppet.paint(
            canvas,
            Rect.fromLTWH(bird * 256, row * 244, 256, 224),
            bird: bird,
            wing: wing,
          );
          final painter = TextPainter(
            text: TextSpan(text: title, style: bodyText(14)),
            textDirection: TextDirection.ltr,
          )..layout();
          painter.paint(
            canvas,
            Offset(bird * 256 + (256 - painter.width) / 2, row * 244 + 213),
          );
        }
      }
      final picture = recorder.endRecording();
      final image = await picture.toImage(1024, 732);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await Directory('build/visual-review').create(recursive: true);
      await File(
        'build/visual-review/bird-wing-poses.png',
      ).writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
      picture.dispose();
    },
  );
}
