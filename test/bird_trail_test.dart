import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/session_replay.dart';
import 'package:push_up_bird/domain/tracking.dart';
import 'package:push_up_bird/game/bird_trail.dart';
import 'recorded_flight.dart';

double gap(({double distance, double y}) a, ({double distance, double y}) b) =>
    sqrt(pow(a.distance - b.distance, 2) + pow(a.y - b.y, 2));

Future<Uint8List> trailPixels(List<Offset>? path) async {
  final recording = ui.PictureRecorder();
  BirdTrail.paint(
    Canvas(recording),
    bird: 0,
    anchor: const Offset(200, 40),
    unit: 9,
    animate: false,
    path: path,
  );
  final picture = recording.endRecording();
  final image = await picture.toImage(300, 240);
  final bytes = await image.toByteData();
  image.dispose();
  picture.dispose();
  return bytes!.buffer.asUint8List();
}

bool painted(Uint8List pixels, int x, int y) =>
    pixels[(y * 300 + x) * 4 + 3] > 0;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('the flight path keeps where the bird flew, newest point first', () {
    final sim =
        FlightSimulation(
            rules: TapFlyMode(),
            practice: true,
            course: FlightCourse.starTrail,
            random: Random(4),
          )
          ..phase = RunPhase.playing
          ..started = true;
    final flown = <({double distance, double y})>[];
    var now = 0.0;
    for (var i = 0; i < 360; i++) {
      now += 1000 / 120;
      sim.apply(
        MovementInput(valid: true, flap: sim.birdY > .6 && sim.velocity >= 0),
        TrackingSample(
          mode: sim.rules.mode,
          timestampMs: now,
          receivedMs: now,
          joints: const [],
        ),
        now,
      );
      sim.tick(1 / 120, now);
      flown.add((distance: sim.distance, y: sim.birdY));
    }
    final path = sim.flightPath.recent.toList();
    expect(path, everyElement(isIn(flown)));
    expect(gap(path.first, flown.last), lessThan(.01));
    for (var i = 1; i < path.length; i++) {
      expect(path[i].distance, lessThan(path[i - 1].distance));
    }
    final heights = path.map((p) => p.y);
    expect(heights.reduce(max) - heights.reduce(min), greaterThan(.05));
    var beforeOldest = 0.0;
    for (var i = 1; i < path.length - 1; i++) {
      beforeOldest += gap(path[i - 1], path[i]);
    }
    expect(beforeOldest, lessThan(FlightPath.reach));
    expect(
      beforeOldest + gap(path[path.length - 2], path.last),
      greaterThanOrEqualTo(FlightPath.reach),
    );
  });

  for (final mode in PlayMode.values) {
    test('$mode flight path replays identically across backward seeks', () {
      final tape = recordFlight(mode);
      final player = ReplayPlayer(tape);
      for (final at in [16000.0, 29000.0, 7000.0, 29100.0]) {
        player.seek(at);
        final other = ReplayPlayer(tape)..seek(at);
        final path = player.simulation.flightPath.recent.toList();
        expect(path, isNotEmpty);
        expect(path, other.simulation.flightPath.recent.toList());
      }
    });
  }

  test('marks follow the flown line and continue level past it', () async {
    final climb = await trailPixels([
      for (var d = 5.0; d <= 200; d += 5) Offset(200, 40 + d),
    ]);
    expect(painted(climb, 200, 103), isTrue);
    expect(painted(climb, 200, 193), isTrue);
    expect(painted(climb, 137, 40), isFalse);
    expect(painted(climb, 47, 40), isFalse);

    final short = await trailPixels([const Offset(200, 70)]);
    expect(painted(short, 167, 70), isTrue);
    expect(painted(short, 77, 70), isTrue);
    expect(painted(short, 200, 103), isFalse);
  });
}
