import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/session_replay.dart';
import 'package:push_up_bird/domain/replay_highlights.dart';
import 'package:push_up_bird/domain/tracking.dart';
import 'star_magnet_test.dart' show FlightHarness;
import 'cloud_friends_test.dart' show recordCloudCruise;
import 'replay_highlights_test.dart' show recordRoute;

StarTrio addTrio(FlightHarness h) {
  final trio = StarTrio(x: 1, y: .5);
  h.sim.starTrios.add(trio);
  return trio;
}

void collectSlot(FlightHarness h, StarTrio trio, int slot) {
  h.sim.stars.add(SkyStar(x: .47, y: .5, trio: trio, trioSlot: slot));
  h.step();
}

List<Object?> trioState(FlightSimulation sim) => [
  sim.score,
  sim.collectedStars,
  sim.completedTrios,
  sim.combo,
  for (final t in sim.starTrios)
    [t.x, t.y, t.collectedMask, t.missed, t.completedAt],
  for (final s in sim.stars)
    [s.x, s.y, s.collected, s.missed, s.trioSlot, s.trio?.collectedMask],
];

void main() {
  test('one complete approach gives exactly five bonus points, once', () {
    final h = FlightHarness();
    final trio = addTrio(h);
    collectSlot(h, trio, 0);
    collectSlot(h, trio, 1);
    expect(h.sim.score, 2);
    expect(trio.completedAt, isNull);
    collectSlot(h, trio, 2);
    expect(h.sim.score, 8);
    expect(h.sim.collectedStars, 3);
    expect(h.sim.combo, 3);
    expect(h.sim.shieldCharge, 3);
    expect(h.sim.completedTrios, 1);
    expect(trio.completedAt, isNotNull);
    final at = trio.completedAt;
    for (var i = 0; i < 10; i++) {
      h.step();
    }
    expect(h.sim.score, 8);
    expect(trio.completedAt, at);
    expect(
      h.sim.events
          .where((e) => e.kind == FlightEventKind.starTrio)
          .map((e) => e.value),
      [5],
    );
  });

  test(
    'missing one star forfeits only that set; the next trio still works',
    () {
      final h = FlightHarness();
      final failed = addTrio(h);
      h.sim.stars.add(SkyStar(x: .3, y: .15, trio: failed, trioSlot: 0));
      h.step();
      collectSlot(h, failed, 1);
      collectSlot(h, failed, 2);
      expect(failed.missed, isTrue);
      expect(failed.completedAt, isNull);
      expect(h.sim.score, 2);
      expect(h.sim.completedTrios, 0);
      final next = addTrio(h);
      for (var i = 0; i < 3; i++) {
        collectSlot(h, next, i);
      }
      expect(h.sim.completedTrios, 1);
      expect(h.sim.score, 10);
    },
  );

  test('stars from different approaches cannot complete each other', () {
    final h = FlightHarness();
    final a = addTrio(h), b = addTrio(h);
    collectSlot(h, a, 0);
    collectSlot(h, a, 1);
    collectSlot(h, b, 2);
    expect(h.sim.completedTrios, 0);
    collectSlot(h, a, 2);
    expect(h.sim.completedTrios, 1);
    expect(a.completedAt, isNotNull);
    expect(b.completedAt, isNull);
  });

  test(
    'a magnet can finish a trio in one step without multiplying its bonus',
    () {
      final h = FlightHarness();
      h.sim.combo = 11;
      h.sim.collectedStars = 6;
      h.sim.shield = false;
      h.sim.magnetUntil = 10;
      final trio = addTrio(h);
      h.sim.stars.addAll([
        for (var i = 0; i < 3; i++)
          SkyStar(x: .47 + (i - 1) * .17, y: .5, trio: trio, trioSlot: i),
      ]);
      h.step();
      expect(h.sim.completedTrios, 1);
      expect(
        h.sim.score,
        14,
        reason: 'Three 3× pickups plus one flat +5 bonus',
      );
      expect(h.sim.collectedStars, 9);
      expect(h.sim.shieldCharge, 0);
      expect(h.sim.shield, isTrue);
      expect(h.sim.hearts, 3);
      expect(h.sim.gates, 0);
    },
  );

  test('pause and resume countdown freeze pending trios', () {
    final h = FlightHarness(practice: true);
    final trio = addTrio(h);
    collectSlot(h, trio, 0);
    collectSlot(h, trio, 1);
    h.sim.stars.add(SkyStar(x: .47, y: .5, trio: trio, trioSlot: 2));
    h.sim.takeBreak();
    final state = trioState(h.sim);
    h.step(.4);
    expect(trioState(h.sim), state);
    h.sim.resume();
    h.step(.4);
    expect(trioState(h.sim), state);
    for (var i = 0; i < 160; i++) {
      h.step();
    }
    expect(h.sim.completedTrios, 1);
  });

  test('old journals keep their score and identical seeded movement', () {
    final tape = recordRoute(FlightCourse.starTrail, rulesVersion: 11);
    final old = ReplayTape.fromJson(tape.toJson()..['version'] = 5);
    final current = ReplayPlayer(tape)..seek(tape.durationMs);
    final legacy = ReplayPlayer(old)..seek(old.durationMs);
    final a = current.simulation, b = legacy.simulation;
    expect(a.completedTrios, greaterThan(0));
    expect(a.score, b.score + a.completedTrios * 5);
    expect(
      [
        a.gates,
        a.collectedStars,
        a.bestCombo,
        a.hearts,
        a.magnetActivations,
        a.distance,
        a.birdY,
      ],
      [
        b.gates,
        b.collectedStars,
        b.bestCombo,
        b.hearts,
        b.magnetActivations,
        b.distance,
        b.birdY,
      ],
    );
    expect(b.starTrios, isEmpty);
    expect(b.completedTrios, 0);
    expect(b.stars.every((s) => s.trio == null), isTrue);
    expect(
      buildReplayHighlights(
        old,
      ).where((m) => m.kind == ReplayMomentKind.starTrio),
      isEmpty,
    );
    expect(ReplayTape.fromJson(old.toJson()).recordedVersion, 5);
    for (final course in [FlightCourse.classic, FlightCourse.skyCourier]) {
      expect(FlightHarness(course: course).sim.supportsStarTrios, isFalse);
    }
  });

  for (final mode in PlayMode.values) {
    test('$mode trios replay, seek backwards and leave bounded state', () {
      final tape = recordCloudCruise(mode).tape;
      final player = ReplayPlayer(ReplayTape.fromJson(tape.toJson()));
      for (final at in [120000.0, 13000.0, 3100.0, 60000.0, 120000.0]) {
        player.seek(at);
        final independent = ReplayPlayer(tape)..seek(at);
        expect(trioState(player.simulation), trioState(independent.simulation));
        expect(player.simulation.starTrios.length, lessThan(6));
      }
      expect(player.simulation.completedTrios, greaterThan(0));
      expect(player.simulation.practice, isTrue);
      final highlights = buildReplayHighlights(
        tape,
      ).where((m) => m.kind == ReplayMomentKind.starTrio).toList();
      expect(highlights, hasLength(1));
      player.seek(highlights.single.atMs - 20);
      expect(player.simulation.completedTrios, 0);
      player.seek(highlights.single.atMs);
      expect(player.simulation.completedTrios, 1);
    });
  }
}
