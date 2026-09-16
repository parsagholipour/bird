import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/data/session_repository.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/session_replay.dart';
import 'package:push_up_bird/domain/tracking.dart';

List<Object?> state(FlightSimulation s) => [
  s.phase,
  s.endReason,
  s.birdY,
  s.velocity,
  s.score,
  s.repetitions,
  s.flaps,
  s.elapsed,
  s.distance,
  s.countdown,
  for (final o in s.obstacles) [o.x, o.center, o.gap, o.scored],
];

FlightRecorder makeRecorder(PlayMode mode, double Function() now) =>
    FlightRecorder(
      ReplayTape(
        mode: mode,
        practice: true,
        seed: 761,
        cycleSeconds: 3,
        bird: 2,
        reducedMotion: false,
        originMs: 1000,
      ),
      now,
    );

void main() {
  for (final mode in PlayMode.values) {
    test(
      '${mode.name}: serialized inputs reproduce flight and backward seeking exactly',
      () {
        double now = 1000;
        final recorder = makeRecorder(mode, () => now);
        final checkpoints = <double, List<Object?>>{};
        for (var i = 0; i < 1200; i++) {
          now += i % 7 == 0 ? 25 : 16;
          final sim = recorder.simulation;
          // Follow each passage so this tests RNG, spawning, passing and scoring.
          final nearby = sim.obstacles.where(
            (o) => o.x + o.width > FlightSimulation.birdX - .04,
          );
          final target = nearby.isEmpty ? .5 : nearby.first.center;
          final flap =
              mode == PlayMode.smile && sim.birdY > target && sim.velocity >= 0;
          recorder.apply(
            MovementInput(
              valid: true,
              height: (.85 - target) / .7,
              flap: flap,
              repetitions: i ~/ 80,
            ),
            TrackingSample(
              mode: mode,
              timestampMs: now - 30,
              receivedMs: now,
              joints: const [],
            ),
            now,
          );
          recorder.tick(i % 7 == 0 ? .025 : .016, now, 2.2);
          if (i == 220) recorder.command('break');
          if (i == 240) recorder.command('resume');
          checkpoints[now - 1000] = state(sim);
          if (sim.phase == RunPhase.ended) break;
        }
        recorder.command('end', EndReason.quit);
        final tape = ReplayTape.fromJson(
          jsonDecode(jsonEncode(recorder.tape.toJson()))
              as Map<String, dynamic>,
        );
        final player = ReplayPlayer(tape)..seek(tape.durationMs);
        expect(state(player.simulation), state(recorder.simulation));
        expect(player.simulation.started, isTrue);
        expect(
          tape.events.where((e) => e[1] == 'input').length,
          greaterThan(200),
        );
        final positions = checkpoints.keys.toList();
        for (final index in [
          positions.length ~/ 2,
          100,
          positions.length - 2,
          0,
        ]) {
          player.seek(positions[index]);
          expect(state(player.simulation), checkpoints[positions[index]]);
        }
      },
    );
  }
  test('tracking failure, background and long frame are journaled', () {
    for (final end in ['background', 'stalled', 'trackingLost']) {
      double now = 1000;
      final recorder = FlightRecorder(
        ReplayTape(
          mode: PlayMode.pushUp,
          practice: false,
          seed: 1,
          cycleSeconds: 3,
          bird: 0,
          reducedMotion: true,
          originMs: now,
        ),
        () => now,
      );
      for (var i = 0; i < 200; i++) {
        now += 20;
        recorder.apply(
          const MovementInput(valid: true, height: 1),
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
      if (end == 'background') {
        recorder.command('background');
      } else {
        now += 600;
        recorder.tick(end == 'stalled' ? .6 : .016, now, 2.2);
      }
      final replay = ReplayPlayer(recorder.tape)
        ..seek(recorder.tape.durationMs);
      expect(state(replay.simulation), state(recorder.simulation));
      expect(replay.simulation.phase, RunPhase.ended);
    }
  });
  test(
    'session commit copies raw video, survives reopening, retries, and deletes',
    () async {
      final temp = await Directory.systemTemp.createTemp('session-test');
      addTearDown(() => temp.delete(recursive: true));
      final camera = await File(
        '${temp.path}/raw.mp4',
      ).writeAsBytes([0, 1, 2, 3]);
      final recorder = makeRecorder(PlayMode.pushUp, () => 2000)
        ..command('end', EndReason.quit);
      final result = RunResult(
        id: '123-pushUp',
        mode: PlayMode.pushUp,
        practice: true,
        score: 2,
        repetitions: 4,
        flaps: 0,
        durationSeconds: 12,
        reason: EndReason.quit,
        finishedAt: DateTime(2026, 9, 11),
      );
      final session = SavedSession(
        result: result,
        tape: recorder.tape,
        clips: [
          SessionClip(
            path: camera.path,
            startMs: -40,
            durationMs: 13000,
            hasAudio: true,
          ),
        ],
      );
      final root = Directory('${temp.path}/saved');
      final repo = SessionRepository(root);
      expect(await repo.list(), isEmpty);
      await repo.save(session);
      await repo.save(session);
      await camera.delete();
      final reopened = SessionRepository(root);
      final loaded = await reopened.load(result.id);
      expect(await File(loaded.clips.single.path).readAsBytes(), [0, 1, 2, 3]);
      expect(loaded.clips.single.startMs, -40);
      expect(loaded.clips.single.hasAudio, isTrue);
      final manifest = File('${root.path}/${result.id}/session.json');
      final legacy =
          jsonDecode(await manifest.readAsString()) as Map<String, dynamic>;
      (legacy['clips'] as List).single.remove('hasAudio');
      await manifest.writeAsString(jsonEncode(legacy));
      expect((await reopened.load(result.id)).clips.single.hasAudio, isFalse);
      expect(loaded.tape.toJson(), recorder.tape.toJson());
      expect((await reopened.list()).single.id, result.id);
      await reopened.delete(result.id);
      expect(await reopened.list(), isEmpty);
    },
  );
  test(
    'failed copy does not publish a partial session and can be retried',
    () async {
      final temp = await Directory.systemTemp.createTemp('session-fail-test');
      addTearDown(() => temp.delete(recursive: true));
      final repo = SessionRepository(Directory('${temp.path}/saved'));
      final source = File('${temp.path}/missing.mp4');
      final session = SavedSession(
        result: RunResult(
          id: 'retry',
          mode: PlayMode.smile,
          practice: false,
          score: 0,
          repetitions: 0,
          flaps: 1,
          durationSeconds: 1,
          reason: EndReason.quit,
          finishedAt: DateTime.now(),
        ),
        tape: makeRecorder(PlayMode.smile, () => 1000).tape,
        clips: [SessionClip(path: source.path, startMs: 0, durationMs: 1000)],
      );
      await expectLater(
        repo.save(session),
        throwsA(isA<FileSystemException>()),
      );
      expect(await repo.list(), isEmpty);
      await source.writeAsBytes([1]);
      await repo.save(session);
      expect(await repo.list(), hasLength(1));
      await repo.reset();
      expect(await repo.list(), isEmpty);
    },
  );
  test('unknown simulation versions fail explicitly', () {
    final data = makeRecorder(PlayMode.pushUp, () => 1000).tape.toJson();
    data['version'] = 2;
    expect(() => ReplayTape.fromJson(data), throwsFormatException);
  });
}
