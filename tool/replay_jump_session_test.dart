import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/tracking.dart';
import 'package:push_up_bird/game/play_controller.dart';

import '../test/play_session_test.dart' show SessionSource, SilentAudio;

/// Replay private, opt-in camera landmarks through calibration, countdown,
/// controller and bird physics. Captures stay outside the repository.
///
/// flutter test tool/replay_jump_session_test.dart
///   --dart-define=TRACKING_LOG=/tmp/tracking.log
/// Optional assertions (milliseconds relative to the first captured frame):
/// CALIBRATE_BY_MS, STOP_AT_MS, NO_JUMPS_BEFORE_MS, MIN_JUMPS.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('captured jump session calibrates and controls the bird', () async {
    const path = String.fromEnvironment('TRACKING_LOG');
    expect(path, isNotEmpty, reason: 'Pass --dart-define=TRACKING_LOG=<path>');
    final source = SessionSource();
    final controller = PlayController(
      mode: PlayMode.jump,
      practice: true,
      // Keep obstacles from ending the diagnostic replay before later inputs.
      course: FlightCourse.cloudCruise,
      source: source,
      audio: SilentAudio(),
      saveRun: (_) async {},
      saveSession: (_) async {},
    );
    addTearDown(controller.dispose);
    await controller.startCamera();
    double? origin, clock, calibratedAt;
    final jumpsAt = <double>[];
    var maxJumps = 0;
    var frames = 0;
    for (final line in File(path).readAsLinesSync()) {
      const marker = 'PushUpBird trace: ';
      final index = line.indexOf(marker);
      if (index < 0) continue;
      final data = jsonDecode(line.substring(index + marker.length)) as Map;
      if (data['mode'] != 'jump') continue;
      final timestamp = (data['t'] as num).toDouble();
      final now = (data['now'] as num).toDouble();
      origin ??= timestamp;
      const stopAt = int.fromEnvironment('STOP_AT_MS', defaultValue: 1 << 30);
      if (timestamp - origin > stopAt) break;
      clock ??= now;
      while (clock! < now) {
        final dt = math.min(1000 / 60, now - clock);
        clock += dt;
        source.time = clock;
        controller.advance(dt / 1000, clock, 2.2);
      }
      final ids = data['ids'] as List;
      final received = data['joints'] as List;
      final joints = List.filled(33, const Joint(0, 0, 0, 0));
      for (var i = 0; i < received.length; i++) {
        final j = received[i] as List;
        joints[ids[i] as int] = Joint(
          (j[0] as num?)?.toDouble() ?? double.nan,
          (j[1] as num?)?.toDouble() ?? double.nan,
          (j[2] as num?)?.toDouble() ?? double.nan,
          (j[3] as num?)?.toDouble() ?? 0,
        );
      }
      source.time = now;
      source.sampleStream.add(
        TrackingSample(
          mode: PlayMode.jump,
          timestampMs: timestamp,
          receivedMs: now,
          detected: data['detected'] as bool,
          aspectRatio: (data['aspect'] as num).toDouble(),
          joints: joints,
        ),
      );
      await Future<void>.delayed(Duration.zero);
      frames++;
      if (controller.stage == PlayStage.flying) {
        calibratedAt ??= timestamp - origin;
      }
      final count = controller.simulation?.flaps ?? 0;
      if (count > maxJumps) {
        jumpsAt.add(timestamp - origin);
        maxJumps = count;
      }
    }
    // ignore: avoid_print
    print(
      jsonEncode({
        'frames': frames,
        'calibratedAtMs': calibratedAt,
        'gameJumps': maxJumps,
        'jumpsAtMs': jumpsAt,
        'finalPhase': controller.simulation?.phase.name,
      }),
    );
    expect(calibratedAt, isNotNull);
    expect(
      calibratedAt,
      lessThanOrEqualTo(
        const int.fromEnvironment('CALIBRATE_BY_MS', defaultValue: 1 << 30),
      ),
    );
    expect(
      maxJumps,
      greaterThanOrEqualTo(
        const int.fromEnvironment('MIN_JUMPS', defaultValue: 1),
      ),
    );
    expect(
      jumpsAt,
      everyElement(
        greaterThanOrEqualTo(const int.fromEnvironment('NO_JUMPS_BEFORE_MS')),
      ),
    );
  });
}
