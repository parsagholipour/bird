import 'dart:convert';
import 'dart:io';

import 'package:push_up_bird/domain/jump_tracking.dart';
import 'package:push_up_bird/domain/tracking.dart';

/// Replay opt-in jump landmarks through the same calibration and interpreter
/// used on the phone. No camera images are needed.
///
/// dart run tool/replay_jump_tracking.dart app.log [expected-jumps]
/// Frame analysis goes to stdout, a summary to stderr. Supplying an expected
/// count checks interpreter events, including events during countdown/pause.
/// Use replay_jump_session_test.dart to check jumps accepted by bird physics.
void main(List<String> args) {
  if (args.isEmpty || args.length > 2) {
    stderr.writeln(
      'Usage: dart run tool/replay_jump_tracking.dart '
      '<tracking.log> [expected-jumps]',
    );
    exitCode = 64;
    return;
  }
  final expected = args.length == 2 ? int.parse(args[1]) : null;
  var calibrator = JumpCalibrator();
  JumpInterpreter? interpreter;
  var frames = 0, calibrated = 0, jumps = 0, invalid = 0;
  var recordedAcceptedJumps = 0;
  String? recordedPhase;
  final feedbackCounts = <String, int>{};
  for (final line in File(args.first).readAsLinesSync()) {
    if (line.contains('PushUpBird session:')) {
      calibrator = JumpCalibrator();
      interpreter = null;
      recordedPhase = null;
    }
    if (line.contains('PushUpBird reset:')) interpreter?.reset();
    if (line.contains('PushUpBird control:')) {
      recordedPhase = RegExp(r'phase=(\w+)').firstMatch(line)?.group(1);
    }
    const jumpMarker = 'PushUpBird jump: ';
    final jumpIndex = line.indexOf(jumpMarker);
    if (jumpIndex >= 0) {
      final event =
          jsonDecode(line.substring(jumpIndex + jumpMarker.length)) as Map;
      if (event['accepted'] == true) recordedAcceptedJumps++;
    }
    const marker = 'PushUpBird trace: ';
    final index = line.indexOf(marker);
    if (index < 0) continue;
    final data = jsonDecode(line.substring(index + marker.length)) as Map;
    if (data['mode'] != 'jump') continue;
    frames++;
    final now = (data['now'] as num).toDouble();
    final receivedJoints = data['joints'] as List;
    final ids = data['ids'] as List?;
    final joints = List.filled(33, const Joint(0, 0, 0, 0));
    for (var i = 0; i < receivedJoints.length; i++) {
      final j = receivedJoints[i] as List;
      joints[ids == null ? i : ids[i] as int] = Joint(
        (j[0] as num?)?.toDouble() ?? double.nan,
        (j[1] as num?)?.toDouble() ?? double.nan,
        (j[2] as num?)?.toDouble() ?? double.nan,
        (j[3] as num?)?.toDouble() ?? 0,
      );
    }
    final sample = TrackingSample(
      mode: PlayMode.jump,
      timestampMs: (data['t'] as num).toDouble(),
      receivedMs: now,
      aspectRatio: (data['aspect'] as num).toDouble(),
      detected: data['detected'] as bool,
      joints: joints,
    );
    final observation = observeJump(sample, now);
    calibrator.add(sample, now);
    if (calibrator.result != null && interpreter == null) {
      calibrated++;
      interpreter = JumpInterpreter(calibrator.result!);
    }
    final input = interpreter?.add(sample, now);
    if (input?.flap ?? false) jumps++;
    if (!(input?.valid ?? observation.valid)) invalid++;
    final feedback = input?.feedback ?? calibrator.feedback;
    feedbackCounts.update(feedback, (count) => count + 1, ifAbsent: () => 1);
    final baseline = calibrator.result?.standing;
    double? rise(double value, double? standing) =>
        observation.valid && baseline != null && standing != null
        ? (standing - value) / baseline.bodyHeight
        : null;
    stdout.writeln(
      jsonEncode({
        't': sample.timestampMs,
        'session': data['session'],
        'age': now - sample.timestampMs,
        'detected': sample.detected,
        'observationValid': observation.valid,
        'controlValid': input?.valid,
        'calibrated': baseline != null,
        'flap': input?.flap ?? false,
        'recordedPhase': recordedPhase,
        'hipRise': rise(observation.hipY, baseline?.hipY),
        'shoulderRise': rise(observation.shoulderY, baseline?.shoulderY),
        // These remain relative to calibration; the interpreter also tracks
        // where the feet settle after each landing.
        'leftRiseFromCalibration': rise(
          observation.leftFootY,
          baseline?.leftFootY,
        ),
        'rightRiseFromCalibration': rise(
          observation.rightFootY,
          baseline?.rightFootY,
        ),
        'shoulderScale': observation.valid && baseline != null
            ? observation.shoulderWidth / baseline.shoulderWidth
            : null,
        'torsoScale': observation.valid && baseline != null
            ? observation.torsoHeight / baseline.torsoHeight
            : null,
        'feedback': feedback,
      }),
    );
  }
  stderr.writeln(
    jsonEncode({
      'jumpFrames': frames,
      'calibrations': calibrated,
      'invalidFrames': invalid,
      'interpreterJumps': jumps,
      'recordedAcceptedJumps': recordedAcceptedJumps,
      'expectedJumps': expected,
      'feedbackCounts': feedbackCounts,
    }),
  );
  if (frames == 0 || calibrated == 0 || expected != null && jumps != expected) {
    exitCode = 1;
  }
}
