import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/session_replay.dart';
import 'package:push_up_bird/domain/tracking.dart';
import 'package:push_up_bird/game/bird_game.dart';
import 'package:push_up_bird/game/sky_scenery.dart';

import 'experience_ui_test.dart' show capture;

const _phone = Size(1000, 450);

/// Flies a recorded Star Trail touch flight, steering for each opening, and
/// captures real game frames as the world tour crosses from the jungle into
/// Antarctica.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    for (final family in ['Fredoka', 'Nunito']) {
      await (FontLoader(
        family,
      )..addFont(rootBundle.load('assets/fonts/$family.ttf'))).load();
    }
  });

  testWidgets('a real flight crosses regions with matching obstacles', (
    tester,
  ) async {
    tester.view.physicalSize = _phone;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var now = 0.0;
    final recorder = FlightRecorder(
      ReplayTape(
        mode: PlayMode.touch,
        course: FlightCourse.starTrail,
        practice: true,
        seed: 11,
        cycleSeconds: 3,
        bird: 0,
        reducedMotion: false,
        originMs: 0,
      ),
      () => now,
    );
    final sim = recorder.simulation;
    final game = BirdGame(
      simulation: sim,
      nowMs: () => 0,
      bird: 0,
      reducedMotion: false,
      onChanged: () {},
      playback: true,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: RepaintBoundary(
          key: const ValueKey('visual-capture'),
          child: GameWidget(game: game),
        ),
      ),
    );
    await tester.runAsync(() => game.loaded);
    final shots = [10.0, 17.5, 19.0, 20.5, 23.0, 41.0, 50.0];
    final regions = <WorldRegion>{};
    for (
      var frame = 0;
      frame < 6000 && sim.phase != RunPhase.ended && shots.isNotEmpty;
      frame++
    ) {
      now += 20;
      final upcoming = sim.obstacles.where(
        (o) =>
            o.x + o.width >
            FlightSimulation.birdX - FlightSimulation.birdRadius,
      );
      final aim = upcoming.isEmpty ? .5 : upcoming.first.target;
      recorder.apply(
        MovementInput(
          valid: true,
          height: .5,
          flap: sim.birdY > aim + .04 && sim.velocity > -.1,
        ),
        TrackingSample(
          mode: PlayMode.touch,
          timestampMs: now,
          receivedMs: now,
          joints: const [],
        ),
        now,
      );
      recorder.tick(.02, now, _phone.width / _phone.height);
      for (final o in sim.obstacles) {
        regions.add(WorldTour.of(o));
      }
      if (sim.elapsed >= shots.first) {
        shots.removeAt(0);
        await tester.pump(const Duration(milliseconds: 16));
        expect(tester.takeException(), isNull);
        await capture(tester, 'regions/flight-${sim.elapsed.round()}s');
      }
    }
    expect(regions, containsAll([WorldRegion.jungle, WorldRegion.antarctica]));
    await tester.pumpWidget(const SizedBox());
  });
}
