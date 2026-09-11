import 'dart:convert';
import 'dart:io';
import 'package:push_up_bird/domain/tracking.dart';

/// Replay an opt-in `PushUpBird trace:` log without a camera or Flutter engine.
/// Usage: dart run tool/replay_tracking.dart /path/to/app.log > analysis.jsonl
void main(List<String> args) {
  var calibrator = BodyCalibrator();
  PushUpInterpreter? interpreter;
  for (final line in File(args.single).readAsLinesSync()) {
    if (line.contains('PushUpBird session:')) {
      calibrator = BodyCalibrator();
      interpreter = null;
    }
    if (line.contains('PushUpBird reset:')) interpreter?.reset();
    const marker = 'PushUpBird trace: ';
    final index = line.indexOf(marker);
    if (index < 0) continue;
    final data = jsonDecode(line.substring(index + marker.length)) as Map;
    if (data['mode'] != 'pushUp') continue;
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
      mode: PlayMode.pushUp,
      timestampMs: (data['t'] as num).toDouble(),
      receivedMs: now,
      aspectRatio: (data['aspect'] as num).toDouble(),
      detected: data['detected'] as bool,
      joints: joints,
    );
    final observation = observeBody(
      sample,
      now,
      preferredSide: calibrator.side,
      preferredPerspective: calibrator.perspective,
    );
    calibrator.add(sample, now);
    if (calibrator.result != null) {
      interpreter ??= PushUpInterpreter(calibrator.result!);
    }
    final input = interpreter?.add(sample, now);
    stdout.writeln(
      jsonEncode({
        't': sample.timestampMs,
        'nativeT': data['nativeT'],
        'session': data['session'],
        'age': now - sample.timestampMs,
        'valid': observation.valid,
        'elbow': observation.elbow,
        'cues': {for (final e in observation.cues.entries) e.key.name: e.value},
        'torso': observation.bodyLength,
        'arm': observation.armLength,
        'side': observation.side,
        'perspective': observation.perspective.name,
        'controlValid': input?.valid,
        'step': calibrator.step.name,
        'cycles': calibrator.cycles,
        'height': input?.height ?? calibrator.previewHeight,
        'feedback': input?.feedback ?? calibrator.feedback,
        'models': [
          for (final m in calibrator.result?.cues ?? const <CueModel>[])
            {
              'cue': m.cue.name,
              'top': m.top,
              'bottom': m.bottom,
              'weight': m.weight,
            },
        ],
        'topElbow': calibrator.result?.topElbow,
        'bottomElbow': calibrator.result?.bottomElbow,
      }),
    );
  }
}
