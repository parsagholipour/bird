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

/// Alpha of a level flight at height 100 in a 300 × 200 frame, with the
/// bird [ahead] pixels further along than at x = 250.
Future<Uint8List> flownPixels(
  int bird,
  double ahead, {
  required bool drop,
}) async {
  final recording = ui.PictureRecorder();
  final anchor = Offset(250 + ahead, 100);
  BirdTrail.paint(
    Canvas(recording),
    bird: bird,
    anchor: anchor,
    unit: 9,
    seconds: 2,
    path: [for (var x = anchor.dx - 4; x > -60; x -= 4) Offset(x, 100)],
    flown: 1000 + (drop ? ahead : 0) - 4,
  );
  final picture = recording.endRecording();
  final image = await picture.toImage(300, 200);
  final bytes = await image.toByteData();
  image.dispose();
  picture.dispose();
  final rgba = bytes!.buffer.asUint8List();
  return Uint8List.fromList([for (var i = 3; i < rgba.length; i += 4) rgba[i]]);
}

/// The sideways shift that best lines [later] up with [earlier] over the
/// middle of the trail, clear of where marks are born and fade.
int drift(Uint8List earlier, Uint8List later) {
  var best = 0, bestScore = -1;
  for (var shift = -14; shift <= 14; shift++) {
    var score = 0;
    for (var y = 40; y < 160; y++) {
      for (var x = 90; x < 200; x++) {
        score += min(earlier[y * 300 + x], later[y * 300 + x + shift]);
      }
    }
    if (score > bestScore) (best, bestScore) = (shift, score);
  }
  return best;
}

/// The bounding box of everything painted inside [window], or null.
Rect? paintedBounds(Uint8List pixels, Rect window) {
  Rect? box;
  for (var y = window.top.toInt(); y < window.bottom; y++) {
    for (var x = window.left.toInt(); x < window.right; x++) {
      if (pixels[(y * 300 + x) * 4 + 3] == 0) continue;
      final dot = Rect.fromLTWH(x.toDouble(), y.toDouble(), 1, 1);
      box = box?.expandToInclude(dot) ?? dot;
    }
  }
  return box;
}

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
    // The odometer counts the whole flight, not just the part still kept.
    expect(sim.flightPath.flown, greaterThan(FlightPath.reach * 2));
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
        expect(
          player.simulation.flightPath.flown,
          other.simulation.flightPath.flown,
        );
      }
    });
  }

  test('marks stay where they were dropped as the bird flies on', () async {
    for (var bird = 0; bird < 4; bird++) {
      final before = await flownPixels(bird, 0, drop: true);
      // One unit on, dropped marks hold their place in the sky; marks that
      // ignored the flown distance would ride along with the bird.
      expect(
        drift(before, await flownPixels(bird, 9, drop: true)).abs(),
        lessThanOrEqualTo(2),
        reason: 'bird $bird',
      );
      expect(
        drift(before, await flownPixels(bird, 9, drop: false)),
        inInclusiveRange(7, 11),
        reason: 'bird $bird',
      );
    }
  });

  test('marks follow the flown line and continue level past it', () async {
    // Unit 9: marks may drift a unit or two off the line as they age, never
    // further.
    final climb = await trailPixels([
      for (var d = 5.0; d <= 200; d += 5) Offset(200, 40 + d),
    ]);
    final down = paintedBounds(climb, const Rect.fromLTRB(0, 90, 300, 240))!;
    expect(down.left, greaterThan(200 - 18));
    expect(down.right, lessThan(200 + 18));
    expect(down.bottom, greaterThan(170));
    expect(paintedBounds(climb, const Rect.fromLTRB(0, 0, 180, 240)), isNull);

    final short = await trailPixels([const Offset(200, 70)]);
    final level = paintedBounds(short, const Rect.fromLTRB(0, 0, 190, 240))!;
    expect(level.left, lessThan(80));
    expect(level.top, greaterThan(70 - 27));
    expect(level.bottom, lessThan(70 + 14));
    expect(paintedBounds(short, const Rect.fromLTRB(0, 85, 300, 240)), isNull);
  });
}
