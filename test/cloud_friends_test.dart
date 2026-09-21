import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/cloud_friends.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/session_replay.dart';
import 'package:push_up_bird/domain/tracking.dart';
import 'star_magnet_test.dart' show FlightHarness;

({ReplayTape tape, Map<int, double> discoveredAt}) recordCloudCruise(
  PlayMode mode, {
  double cycle = 3,
  int version = FlightSimulation.currentRulesVersion,
}) {
  double now = 0, height = 1;
  final tape = ReplayTape(
    mode: mode,
    practice: false,
    seed: 18,
    cycleSeconds: cycle,
    bird: 2,
    reducedMotion: true,
    originMs: 0,
    course: FlightCourse.cloudCruise,
    recordedVersion: version,
  );
  final recorder = FlightRecorder(tape, () => now);
  final discoveredAt = <int, double>{};
  for (var i = 0; i < 6000; i++) {
    now += 20;
    final sim = recorder.simulation;
    final ahead = sim.obstacles.where((o) => !o.scored);
    final target = ahead.isEmpty ? .15 : ahead.first.target;
    // Center the larger jump arc around the target instead of boosting at its
    // center and spending the whole arc above the collectibles.
    final flapAt = (target + (mode == PlayMode.jump && version >= 8 ? .13 : 0))
        .clamp(.15, .88);
    height += ((.85 - target) / .7 - height).clamp(
      -.02 * 2 / cycle,
      .02 * 2 / cycle,
    );
    recorder.apply(
      MovementInput(
        valid: true,
        height: height,
        flap: !mode.controlsHeight && sim.birdY > flapAt && sim.velocity >= 0,
      ),
      TrackingSample(
        mode: mode,
        timestampMs: now,
        receivedMs: now,
        joints: const [],
      ),
      now,
    );
    recorder.tick(.02, now, 2.2);
    discoveredAt.putIfAbsent(sim.cloudFriends.length, () => now);
  }
  recorder.command('end', EndReason.quit);
  return (tape: tape, discoveredAt: discoveredAt);
}

void main() {
  test('clouds are optional and a new friend is greeted only once', () {
    final h = FlightHarness(course: FlightCourse.cloudCruise);
    h.sim.clouds.add(DriftingCloud(friend: CloudFriend.whale, x: .47, y: .5));
    h.step();
    expect(h.sim.cloudFriends, {CloudFriend.whale});
    expect(h.sim.score, 0);
    expect(h.sim.combo, 0);
    expect(
      h.sim.events.where((e) => e.kind == FlightEventKind.cloudFriend),
      hasLength(1),
    );
    h.sim.clouds.addAll([
      DriftingCloud(friend: CloudFriend.whale, x: .47, y: .5),
      DriftingCloud(friend: CloudFriend.bunny, x: .24, y: .1),
    ]);
    h.step();
    expect(h.sim.cloudFriends, {CloudFriend.whale});
    expect(h.sim.clouds.last.passed, isTrue);
    expect(h.sim.phase, RunPhase.playing);
    expect(
      h.sim.events.where((e) => e.kind == FlightEventKind.cloudFriend),
      hasLength(1),
    );
    h.sim.clouds.add(DriftingCloud(friend: CloudFriend.bunny, x: .47, y: .5));
    h.step();
    expect(h.sim.cloudFriends, {CloudFriend.whale, CloudFriend.bunny});
  });

  test('pause freezes discoveries and the drifting sky', () {
    final h = FlightHarness(course: FlightCourse.cloudCruise);
    final cloud = DriftingCloud(friend: CloudFriend.turtle, x: .47, y: .5);
    h.sim.clouds.add(cloud);
    h.sim.takeBreak();
    h.step(.4);
    expect(cloud.x, .47);
    expect(h.sim.cloudFriends, isEmpty);
    h.sim.resume();
    h.step(.2);
    expect(cloud.x, .47);
    expect(h.sim.cloudFriends, isEmpty);
    for (var i = 0; i < 160; i++) {
      h.step();
    }
    expect(h.sim.cloudFriends, {CloudFriend.turtle});
  });

  for (final cycle in [1.0, 4.0, 9.0]) {
    test('cloud friends fit a $cycle-second calibrated movement', () {
      final trip = recordCloudCruise(PlayMode.pushUp, cycle: cycle);
      expect(trip.discoveredAt.keys, containsAll([1, 2, 3]));
      final player = ReplayPlayer(trip.tape)..seek(trip.tape.durationMs);
      expect(player.simulation.practice, isTrue);
      expect(player.simulation.cloudFriends, CloudFriend.values.toSet());
      expect(player.simulation.clouds.length, lessThan(5));
    });
  }

  for (final mode in PlayMode.values) {
    test('$mode cloud discoveries replay and disappear on backward seeks', () {
      final trip = recordCloudCruise(mode);
      final player = ReplayPlayer(ReplayTape.fromJson(trip.tape.toJson()));
      expect(trip.discoveredAt.keys, containsAll([0, 1, 2, 3]));
      for (final count in [3, 1, 0, 2, 3]) {
        player.seek(trip.discoveredAt[count]!);
        expect(player.simulation.cloudFriends.length, count);
        final independent = ReplayPlayer(trip.tape)..seek(player.positionMs);
        expect(
          player.simulation.clouds.length,
          independent.simulation.clouds.length,
        );
        for (var i = 0; i < player.simulation.clouds.length; i++) {
          final a = player.simulation.clouds[i];
          final b = independent.simulation.clouds[i];
          expect(
            [a.x, a.y, a.friend, a.discovered, a.passed],
            [b.x, b.y, b.friend, b.discovered, b.passed],
          );
        }
      }
    });
  }

  test(
    'older cruise journals retain their stars, physics and random route',
    () {
      final trip = recordCloudCruise(PlayMode.jump, version: 7);
      final old = ReplayTape.fromJson(trip.tape.toJson()..['version'] = 4);
      expect(old.toJson()['version'], 4);
      final modern = ReplayPlayer(trip.tape)..seek(trip.tape.durationMs);
      final legacy = ReplayPlayer(old)..seek(old.durationMs);
      expect(legacy.simulation.cloudFriends, isEmpty);
      expect(legacy.simulation.clouds, isEmpty);
      List<Object> stats(FlightSimulation s) => [
        s.score - s.completedTrios * StarTrio.bonus,
        s.birdY,
        s.velocity,
        s.elapsed,
        s.collectedStars,
        s.gates,
        s.magnetActivations,
        s.bestCombo,
        for (final o in s.obstacles) [o.x, o.target, o.scored, o.maxDeviation],
      ];
      expect(stats(legacy.simulation), stats(modern.simulation));
      expect(legacy.simulation.score, 151);
      expect(legacy.simulation.completedTrios, 0);
      for (final course in FlightCourse.values.where((c) => !c.relaxed)) {
        final sim = FlightSimulation(
          rules: JumpFlyMode(),
          practice: true,
          course: course,
          random: Random(1),
        );
        expect(sim.discoversClouds, isFalse);
      }
    },
  );
}
