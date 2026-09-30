import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/tracking.dart';
import 'package:push_up_bird/game/knockout_art.dart';
import 'package:push_up_bird/game/play_controller.dart';

import 'play_session_test.dart'
    show RecordingAudio, SessionSource, SilentAudio, startFlight;

/// A touch flight through its countdown, flying level.
Future<PlayController> _touchFlight({
  bool practice = false,
  bool reducedMotion = false,
  List<RunResult>? saves,
  Future<void> Function(RunResult)? saveRun,
  RecordingAudio? audio,
}) async {
  final controller = PlayController(
    mode: PlayMode.touch,
    practice: practice,
    source: null,
    audio: audio ?? SilentAudio(),
    reducedMotion: reducedMotion,
    saveRun: saveRun ?? (run) async => saves?.add(run),
    saveSession: (_) async {},
  );
  await controller.fly();
  for (var i = 0; i < 160; i++) {
    controller.simulation!
      ..birdY = .5
      ..velocity = 0;
    controller.advance(.02, 0, 2.2);
  }
  expect(controller.simulation!.phase, RunPhase.playing);
  return controller;
}

/// Loses the last heart against the top of the sky, the way the game loop
/// would: the rules end the flight and the loop reports it.
Future<void> _crash(PlayController controller) async {
  controller.simulation!
    ..hearts = 1
    ..shield = false
    ..invulnerableUntil = 0
    ..birdY = .02
    ..velocity = -1;
  controller.advance(.02, 0, 2.2);
  expect(controller.simulation!.endReason, EndReason.collision);
  controller.tick();
  await Future<void>.delayed(Duration.zero);
}

/// Feeds the game loop's frame time to the knockout.
void _frames(PlayController controller, double seconds, [double dt = 1 / 60]) {
  for (var t = 0.0; t < seconds - 1e-9; t += dt) {
    controller.advance(dt, 0, 2.2);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a fatal bump plays the knockout, then the stage after its time; '
      'saving starts at the bump', () async {
    final saves = <RunResult>[];
    final controller = await _touchFlight(saves: saves);
    final journal = controller.recorder!.tape.events.length;
    await _crash(controller);
    expect(controller.stage, PlayStage.fallen);
    expect(controller.knockout, 0);
    expect(controller.result!.reason, EndReason.collision);
    // The run is persisted immediately, not after the animation.
    expect(saves, hasLength(1));
    expect(controller.saved, isTrue);
    final ended = controller.recorder!.tape.events.length;
    expect(ended, greaterThan(journal));
    _frames(controller, KnockoutArt.seconds - .1);
    expect(controller.stage, PlayStage.fallen);
    expect(controller.knockout, closeTo(KnockoutArt.seconds - .1, 1e-6));
    _frames(controller, .12);
    expect(controller.stage, PlayStage.results);
    expect(controller.knockout, KnockoutArt.seconds);
    // The stage holds the final still; nothing more is journaled or saved.
    _frames(controller, 1);
    expect(controller.knockout, KnockoutArt.seconds);
    expect(controller.recorder!.tape.events.length, ended);
    expect(saves, hasLength(1));
    controller.dispose();
  });

  test('taps skip the knockout only after the guard', () async {
    final controller = await _touchFlight();
    await _crash(controller);
    var notified = 0;
    controller.addListener(() => notified++);
    // Frantic tapping right after the bump neither flaps nor skips.
    for (var i = 0; i < 20; i++) {
      controller.flap();
      controller.skipKnockout();
      _frames(controller, .025, .025);
    }
    expect(controller.knockout, lessThan(KnockoutArt.skipAfter));
    expect(controller.canSkipKnockout, isFalse);
    expect(controller.stage, PlayStage.fallen);
    expect(controller.simulation!.flaps, 0);
    expect(notified, 0, reason: 'The knockout does not rebuild every frame');
    _frames(controller, KnockoutArt.skipAfter - controller.knockout! + .01);
    expect(controller.canSkipKnockout, isTrue);
    controller.skipKnockout();
    expect(controller.stage, PlayStage.results);
    expect(controller.knockout, KnockoutArt.seconds);
    expect(notified, 1);
    controller.dispose();
  });

  test('Reduced Motion uses the calm knockout length', () async {
    final controller = await _touchFlight(reducedMotion: true);
    await _crash(controller);
    expect(controller.stage, PlayStage.fallen);
    _frames(controller, KnockoutArt.calmSeconds + .02);
    expect(controller.stage, PlayStage.results);
    expect(controller.knockout, KnockoutArt.calmSeconds);
    controller.dispose();
  });

  test('practice flights get the same knockout', () async {
    final saves = <RunResult>[];
    final controller = await _touchFlight(practice: true, saves: saves);
    await _crash(controller);
    expect(controller.stage, PlayStage.fallen);
    expect(saves.single.practice, isTrue);
    _frames(controller, KnockoutArt.seconds + .05);
    expect(controller.stage, PlayStage.results);
    controller.dispose();
  });

  test('backgrounding during the knockout lands on the stage', () async {
    final controller = await _touchFlight();
    await _crash(controller);
    _frames(controller, .3);
    final events = controller.recorder!.tape.events.length;
    controller.background();
    expect(controller.stage, PlayStage.results);
    expect(controller.knockout, KnockoutArt.seconds);
    expect(
      controller.recorder!.tape.events.length,
      events,
      reason: 'An ended flight journals no background command',
    );
    controller.dispose();
  });

  test('leaving during the knockout saves once and never crashes after '
      'dispose', () async {
    final saving = Completer<void>();
    var saves = 0;
    final controller = await _touchFlight(
      saveRun: (_) async {
        saves++;
        await saving.future;
      },
    );
    await _crash(controller);
    expect(controller.stage, PlayStage.fallen);
    final exit = controller.exit();
    saving.complete();
    await exit;
    expect(saves, 1);
    controller.dispose();
    // A late frame and the stalled-frame fallback are harmless now.
    controller.advance(.5, 0, 2.2);
    controller.skipKnockout();
    controller.background();
    await Future<void>.delayed(
      Duration(milliseconds: ((KnockoutArt.seconds + 1.2) * 1000).round()),
    );
    expect(saves, 1);
  });

  testWidgets('the stage still arrives if frames stop mid-knockout', (
    tester,
  ) async {
    // Built inside the test's fake clock so its fallback timer is too.
    final controller = PlayController(
      mode: PlayMode.touch,
      practice: true,
      source: null,
      audio: SilentAudio(),
      saveRun: (_) async {},
      saveSession: (_) async {},
    );
    unawaited(controller.fly());
    await tester.pump();
    for (var i = 0; i < 160; i++) {
      controller.simulation!
        ..birdY = .5
        ..velocity = 0;
      controller.advance(.02, 0, 2.2);
    }
    controller.simulation!
      ..hearts = 1
      ..shield = false
      ..invulnerableUntil = 0
      ..birdY = .02;
    controller.advance(.02, 0, 2.2);
    controller.tick();
    _frames(controller, .2);
    expect(controller.stage, PlayStage.fallen);
    await tester.pump(
      Duration(milliseconds: ((KnockoutArt.seconds + 1.05) * 1000).round()),
    );
    expect(controller.stage, PlayStage.results);
    controller.dispose();
    await tester.pump();
  });

  test('Fly again after a knockout starts a fresh flight', () async {
    final controller = await _touchFlight();
    final first = controller.simulation;
    await _crash(controller);
    _frames(controller, KnockoutArt.seconds + .05);
    await controller.retry();
    expect(controller.stage, PlayStage.flying);
    expect(controller.knockout, isNull);
    expect(controller.simulation, isNot(same(first)));
    controller.dispose();
  });

  test('other endings keep going straight to results', () async {
    for (final reason in [
      EndReason.quit,
      EndReason.breakTaken,
      EndReason.backgrounded,
      EndReason.completed,
      EndReason.trackingLost,
      EndReason.postureLost,
      EndReason.stalled,
    ]) {
      final controller = await _touchFlight();
      controller.recorder!.command('end', reason);
      await controller.finish();
      expect(controller.stage, PlayStage.results, reason: reason.name);
      expect(controller.knockout, isNull, reason: reason.name);
      controller.dispose();
    }
  });

  test('the game-over cue plays at the bump and the stage keeps it', () async {
    final audio = RecordingAudio();
    final controller = await _touchFlight(audio: audio);
    await _crash(controller);
    expect(audio.effects.where((e) => e == 'game_over'), hasLength(1));
    _frames(controller, KnockoutArt.seconds + .05);
    expect(audio.effects.where((e) => e == 'game_over'), hasLength(1));
    controller.dispose();
  });

  test(
    'camera flights: the knockout ignores the camera shutting down',
    () async {
      final source = SessionSource();
      final saves = <RunResult>[];
      final controller = PlayController(
        mode: PlayMode.pushUp,
        practice: false,
        source: source,
        audio: SilentAudio(),
        saveRun: (run) async => saves.add(run),
        saveSession: (_) async {},
      );
      await startFlight(controller, source);
      controller.simulation!
        ..hearts = 1
        ..shield = false
        ..invulnerableUntil = 0
        ..birdY = .02;
      controller.simulation!.end(EndReason.collision);
      controller.tick();
      expect(controller.stage, PlayStage.fallen);
      source.issueStream.add(
        const TrackingIssue('camera', 'The camera stopped.'),
      );
      expect(controller.stage, PlayStage.fallen);
      final events = controller.recorder!.tape.events.length;
      // Late tracking samples after the bump are not journaled.
      source.sampleStream.add(
        TrackingSample(
          mode: PlayMode.pushUp,
          timestampMs: source.time + 20,
          receivedMs: source.time + 20,
          joints: const [],
        ),
      );
      _frames(controller, KnockoutArt.seconds + .05);
      expect(controller.stage, PlayStage.results);
      expect(controller.recorder!.tape.events.length, events);
      await Future<void>.delayed(Duration.zero);
      expect(saves, hasLength(1));
      controller.dispose();
      await Future<void>.delayed(Duration.zero);
    },
  );
}
