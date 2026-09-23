import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/replay_highlights.dart';
import 'package:push_up_bird/domain/session_replay.dart';
import 'package:push_up_bird/domain/tracking.dart';
import 'recorded_flight.dart';

ReplayTape recordRoute(
  FlightCourse course, {
  bool pause = false,
  double seconds = 90,
  bool followGates = true,
  bool practice = false,
  int rulesVersion = FlightSimulation.currentRulesVersion,
}) {
  double now = 0;
  var paused = false;
  final tape = ReplayTape(
    mode: PlayMode.pushUp,
    practice: practice,
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
    if (pause && !paused && sim.elapsed > 2) {
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
  test(
    'breaks and repeated countdowns shift highlight timestamps correctly',
    () {
      final plain = buildReplayHighlights(
        recordRoute(FlightCourse.starTrail, practice: true),
      );
      final tape = recordRoute(
        FlightCourse.starTrail,
        pause: true,
        practice: true,
      );
      final withBreak = buildReplayHighlights(tape);
      expect(
        withBreak.where((m) => m.kind == ReplayMomentKind.start),
        hasLength(1),
      );
      final a = plain.lastWhere((m) => m.kind == ReplayMomentKind.magnet);
      final b = withBreak.lastWhere((m) => m.kind == ReplayMomentKind.magnet);
      expect(a.title, b.title);
      expect(b.atMs - a.atMs, closeTo(18000, 40));
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
    'empty journals have no moments',
    () {
      final tape = recordFlight(PlayMode.pushUp);
      final empty = ReplayTape.fromJson(tape.toJson()..['events'] = []);
      expect(buildReplayHighlights(empty), isEmpty);
      empty.events.add([0, 'end', 'quit']);
      final stopped = buildReplayHighlights(empty);
      expect(stopped, hasLength(1));
      expect(stopped.single.kind, ReplayMomentKind.finish);
      expect(stopped.single.playFromMs, 0);
    },
  );
}
