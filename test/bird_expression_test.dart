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

FlightSimulation flight() =>
    FlightSimulation(rules: JumpFlyMode(), practice: true)
      ..started = true
      ..phase = RunPhase.playing
      ..elapsed = 3;

BirdExpression expression(
  FlightSimulation sim, {
  bool reduced = false,
  int bird = 0,
}) => BirdPose.forFlight(sim, reducedMotion: reduced, bird: bird).expression;

/// The eyes, lashes and brows of each bird in its 256 × 224 design box: the
/// only pixels an expression may change.
const faces = [
  Rect.fromLTRB(110, 52, 194, 124), // Pip
  Rect.fromLTRB(104, 48, 200, 124), // Peaches: lashes and raised brows
  Rect.fromLTRB(110, 52, 194, 124), // Minty
  Rect.fromLTRB(110, 48, 194, 124), // Orbit: brows above its facial disc
];

Future<List<int>> pixels(int bird, BirdExpression expression) async {
  final recorder = ui.PictureRecorder();
  BirdPuppet.paint(
    Canvas(recorder),
    const Rect.fromLTWH(0, 0, 256, 224),
    bird: bird,
    wing: 0,
    expression: expression,
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(256, 224);
  final data = await image.toByteData();
  image.dispose();
  picture.dispose();
  return data!.buffer.asUint8List();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'rewards get a brief pleased reaction while ordinary pickups stay readable',
    () {
      final sim = flight();
      for (final kind in [
        FlightEventKind.starTrio,
        FlightEventKind.magnet,
        FlightEventKind.milestone,
        FlightEventKind.streak,
        FlightEventKind.perfect,
      ]) {
        sim.events.clear();
        sim.events.add(FlightEvent(kind, sim.elapsed - .1, .5));
        expect(expression(sim), BirdExpression.pleased, reason: kind.name);
        sim.elapsed += .71;
        expect(expression(sim), isNot(BirdExpression.pleased));
      }
      sim.elapsed = 3;
      sim.events.clear();
      sim.events.add(const FlightEvent(FlightEventKind.star, 3, .5));
      expect(expression(sim), BirdExpression.neutral);
      sim.events.add(const FlightEvent(FlightEventKind.magnet, 4, .5));
      expect(
        expression(sim),
        BirdExpression.neutral,
        reason: 'Future events cannot animate a face',
      );
    },
  );

  test('bumps briefly take priority over simultaneous rewards', () {
    for (final kind in [
      FlightEventKind.hit,
      FlightEventKind.shieldUsed,
    ]) {
      final sim = flight();
      sim.events.addAll([
        FlightEvent(kind, 3, .5),
        const FlightEvent(FlightEventKind.starTrio, 3, .5),
      ]);
      expect(expression(sim), BirdExpression.startled);
      expect(expression(sim, reduced: true), BirdExpression.neutral);
      sim.elapsed = 3.8;
      expect(expression(sim), BirdExpression.neutral);
    }
  });

  test(
    'blinks are short, staggered, pause-stable and absent before flight',
    () {
      final sim = flight()..elapsed = 4.84;
      expect(expression(sim), BirdExpression.blink);
      expect(expression(sim, bird: 1), BirdExpression.neutral);
      sim.takeBreak();
      sim.tick(.4, 1000);
      expect(expression(sim), BirdExpression.blink);
      sim.elapsed = 5;
      expect(expression(sim), BirdExpression.neutral);
      sim.elapsed = 4.84;
      expect(expression(sim, reduced: true), BirdExpression.neutral);
      sim.started = false;
      expect(expression(sim), BirdExpression.neutral);
    },
  );

  test('completed and collision replays keep their final expression', () {
    for (final reason in EndReason.values) {
      final sim = flight()..end(reason);
      expect(expression(sim), switch (reason) {
        EndReason.completed => BirdExpression.pleased,
        EndReason.collision => BirdExpression.startled,
        _ => BirdExpression.neutral,
      });
      expect(expression(sim, reduced: true), BirdExpression.neutral);
    }
  });

  for (final mode in PlayMode.values) {
    test('$mode expressions restore exactly when replaying backwards', () {
      final tape = recordFlight(mode);
      final player = ReplayPlayer(tape);
      for (final at in [18000.0, 35000.0, 7000.0, 12000.0, 7840.0]) {
        player.seek(at);
        final independent = ReplayPlayer(tape)..seek(at);
        for (var bird = 0; bird < 4; bird++) {
          expect(
            expression(player.simulation, bird: bird),
            expression(independent.simulation, bird: bird),
          );
          expect(
            expression(player.simulation, reduced: true, bird: bird),
            BirdExpression.neutral,
          );
        }
      }
    });
  }

  test('every bird keeps its body and beak while its eyes react', () async {
    for (var bird = 0; bird < 4; bird++) {
      final neutral = await pixels(bird, BirdExpression.neutral);
      final variants = <List<int>>[];
      for (final expression in BirdExpression.values.skip(1)) {
        final rendered = await pixels(bird, expression);
        expect(
          rendered,
          isNot(equals(neutral)),
          reason: '$bird ${expression.name}',
        );
        for (final other in variants) {
          expect(rendered, isNot(equals(other)));
        }
        expect(
          await pixels(bird, expression),
          rendered,
          reason: 'Cached expressions must be deterministic',
        );
        final face = faces[bird];
        for (var y = 0; y < 224; y++) {
          for (var x = 0; x < 256; x++) {
            if (x >= face.left &&
                x <= face.right &&
                y >= face.top &&
                y <= face.bottom) {
              continue;
            }
            final i = (y * 256 + x) * 4;
            expect(
              rendered.sublist(i, i + 4),
              neutral.sublist(i, i + 4),
              reason: 'Only eyes/brows may change at $x,$y',
            );
          }
        }
        variants.add(rendered);
      }
    }
    if (!const bool.fromEnvironment('CAPTURE_VISUALS')) return;
    await (FontLoader(
      'Nunito',
    )..addFont(rootBundle.load('assets/fonts/Nunito.ttf'))).load();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..drawColor(SkyColors.cream, BlendMode.src);
    for (final (row, expression) in BirdExpression.values.indexed) {
      for (var bird = 0; bird < 4; bird++) {
        BirdPuppet.paint(
          canvas,
          Rect.fromLTWH(bird * 256, row * 244, 256, 224),
          bird: bird,
          wing: 0,
          expression: expression,
        );
        final text = TextPainter(
          text: TextSpan(text: expression.name, style: bodyText(14)),
          textDirection: TextDirection.ltr,
        )..layout();
        text.paint(
          canvas,
          Offset(bird * 256 + (256 - text.width) / 2, row * 244 + 214),
        );
      }
    }
    final picture = recorder.endRecording();
    final image = await picture.toImage(1024, 976);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await Directory('build/visual-review').create(recursive: true);
    await File(
      'build/visual-review/bird-expressions.png',
    ).writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
    picture.dispose();
  });
}
