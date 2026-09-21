import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/replay_highlights.dart';
import 'package:push_up_bird/domain/session_replay.dart';
import 'package:push_up_bird/domain/tracking.dart';
import 'cloud_friends_test.dart' show recordCloudCruise;

ReplayTape recordRoute(
  FlightCourse course, {
  bool pause = false,
  double seconds = 90,
  bool followGates = true,
  int rulesVersion = FlightSimulation.currentRulesVersion,
}) {
  double now = 0;
  var paused = false;
  final tape = ReplayTape(
    mode: PlayMode.pushUp,
    practice: course.relaxed,
    seed: 17,
    cycleSeconds: 3,
    bird: 0,
    reducedMotion: true,
    originMs: 0,
    course: course,
    recordedVersion: rulesVersion,
  );
  final recorder = FlightRecorder(tape, () => now);
  final sim = recorder.simulation;
  while (sim.elapsed < seconds && sim.phase != RunPhase.ended) {
    now += 20;
    if (pause && !paused && sim.elapsed > 8) {
      recorder.command('break');
      now += 15000;
      recorder.command('resume');
      paused = true;
    }
    final ahead = sim.obstacles.where((o) => !o.scored);
    final target = !followGates
        ? .85
        : ahead.isEmpty
        ? .15
        : ahead.first.target;
    recorder.apply(
      MovementInput(valid: true, height: (.85 - target) / .7),
      TrackingSample(
        mode: PlayMode.pushUp,
        timestampMs: now,
        receivedMs: now,
        joints: const [],
      ),
      now,
    );
    recorder.tick(.02, now, 2.2);
  }
  if (sim.phase != RunPhase.ended) recorder.command('end', EndReason.quit);
  return tape;
}

void main() {
  for (final mode in PlayMode.values) {
    test(
      '$mode cloud highlights use exact journal times without duplicates',
      () {
        final trip = recordCloudCruise(mode);
        final before = trip.tape.toJson().toString();
        final moments = buildReplayHighlights(trip.tape);
        final clouds = moments
            .where((m) => m.kind == ReplayMomentKind.cloud)
            .toList();
        expect(clouds, hasLength(3));
        expect(clouds.map((m) => m.atMs), [
          for (var i = 1; i <= 3; i++) trip.discoveredAt[i],
        ]);
        expect(moments.first.kind, ReplayMomentKind.start);
        expect(moments.last.kind, ReplayMomentKind.finish);
        for (final moment in clouds) {
          final player = ReplayPlayer(trip.tape)..seek(moment.playFromMs);
          final prior = player.simulation.cloudFriends.length;
          player.seek(moment.atMs);
          expect(player.simulation.cloudFriends.length, prior + 1);
        }
        expect(
          trip.tape.toJson().toString(),
          before,
          reason: 'Indexing never changes the journal',
        );
      },
    );
  }

  test(
    'breaks and repeated countdowns shift highlight timestamps correctly',
    () {
      final plain = buildReplayHighlights(
        recordRoute(FlightCourse.cloudCruise),
      );
      final tape = recordRoute(FlightCourse.cloudCruise, pause: true);
      final withBreak = buildReplayHighlights(tape);
      expect(
        withBreak.where((m) => m.kind == ReplayMomentKind.start),
        hasLength(1),
      );
      final a = plain.lastWhere((m) => m.kind == ReplayMomentKind.cloud);
      final b = withBreak.lastWhere((m) => m.kind == ReplayMomentKind.cloud);
      expect(a.title, b.title);
      expect(b.atMs - a.atMs, closeTo(18000, 40));
      final player = ReplayPlayer(tape)..seek(b.atMs);
      expect(player.simulation.cloudFriends.length, 3);
    },
  );

  test('Star Trail keeps its first power-ups and voluntary ending', () {
    final tape = recordRoute(FlightCourse.starTrail);
    final moments = buildReplayHighlights(tape);
    expect(
      moments.where((m) => m.kind == ReplayMomentKind.magnet),
      hasLength(1),
    );
    expect(
      moments
          .where((m) => m.kind == ReplayMomentKind.streak)
          .map((m) => m.value),
      [2, 3],
    );
    expect(moments.last.title, 'Final moment');
    expect(moments.last.atMs, tape.durationMs);
    expect(
      moments.map((m) => m.atMs).toList()..sort(),
      moments.map((m) => m.atMs),
    );
  });

  test('Courier highlights identify actual deliveries', () {
    final tape = recordRoute(FlightCourse.skyCourier);
    final moments = buildReplayHighlights(tape);
    final deliveries = moments
        .where((m) => m.kind == ReplayMomentKind.delivery)
        .toList();
    expect(deliveries.length, greaterThan(2));
    expect(deliveries.first.title, 'First delivery');
    for (final delivery in deliveries) {
      final player = ReplayPlayer(tape)..seek(delivery.atMs);
      expect(player.simulation.score, delivery.value);
      expect(player.simulation.carryingLetter, isFalse);
    }
  });

  test('a shield highlight points to the actual close call', () {
    final tape = recordRoute(FlightCourse.starTrail, followGates: false);
    final saves = buildReplayHighlights(
      tape,
    ).where((m) => m.kind == ReplayMomentKind.shield).toList();
    expect(saves, hasLength(1));
    final player = ReplayPlayer(tape)..seek(saves.single.playFromMs);
    expect(player.simulation.shield, isTrue);
    player.seek(saves.single.atMs);
    expect(player.simulation.shield, isFalse);
    expect(player.simulation.recoveryRemaining, greaterThan(1.4));
  });

  test(
    'long flights remain bounded and retain takeoff, first perfect and finish',
    () {
      final tape = recordRoute(FlightCourse.classic, seconds: 300);
      final moments = buildReplayHighlights(tape);
      expect(moments.length, 12);
      expect(moments.first.kind, ReplayMomentKind.start);
      expect(moments.last.kind, ReplayMomentKind.finish);
      expect(
        moments.where((m) => m.kind == ReplayMomentKind.perfect),
        hasLength(1),
      );
      expect(
        moments.every((m) => m.playFromMs >= 0 && m.atMs <= tape.durationMs),
        isTrue,
      );
    },
  );

  test(
    'old Cruise journals have no new clouds and empty journals have no moments',
    () {
      final trip = recordCloudCruise(PlayMode.pushUp);
      final old = ReplayTape.fromJson(trip.tape.toJson()..['version'] = 4);
      expect(
        buildReplayHighlights(
          old,
        ).where((m) => m.kind == ReplayMomentKind.cloud),
        isEmpty,
      );
      final empty = ReplayTape.fromJson(trip.tape.toJson()..['events'] = []);
      expect(buildReplayHighlights(empty), isEmpty);
      empty.events.add([0, 'end', 'quit']);
      final stopped = buildReplayHighlights(empty);
      expect(stopped, hasLength(1));
      expect(stopped.single.kind, ReplayMomentKind.finish);
      expect(stopped.single.playFromMs, 0);
    },
  );
}
