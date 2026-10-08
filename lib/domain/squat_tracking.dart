import 'dart:math' as math;
import 'tracking.dart';

// l10n-english-twin: the coaching lines here are English twins; screens show
// them through `l.trackingFeedback(...)` (lib/l10n/text/tracking_text.dart).

/// Standing and squatting share a grounded stance. Hip height, measured from
/// the ankles, ignores hand gestures and a forward bend at the waist.
class SquatObservation {
  const SquatObservation({
    required this.valid,
    required this.feedback,
    this.hipY = 0,
    this.shoulderY = 0,
    this.shoulderWidth = 0,
    this.leftAnkleY = 0,
    this.rightAnkleY = 0,
  });
  final bool valid;
  final String feedback;
  final double hipY, shoulderY, shoulderWidth, leftAnkleY, rightAnkleY;
  double get ankleY => (leftAnkleY + rightAnkleY) / 2;
  double get hipHeight => ankleY - hipY;
  double get bodyHeight => ankleY - shoulderY;
}

SquatObservation observeSquat(TrackingSample sample, double now) {
  const missing = SquatObservation(
    valid: false,
    feedback: 'Step back so your shoulders, hips, knees and feet are in view',
  );
  if (sample.mode != PlayMode.squat ||
      !sample.detected ||
      !sample.freshAt(now) ||
      sample.joints.length < 33) {
    return missing;
  }
  final p = sample.joints;
  for (final id in [11, 12, 23, 24, 25, 26, 27, 28]) {
    final joint = p[id];
    if (!joint.confidence.isFinite ||
        joint.confidence < .5 ||
        !joint.x.isFinite ||
        !joint.y.isFinite ||
        joint.x < .02 ||
        joint.x > .98 ||
        joint.y < .02 ||
        joint.y > .98) {
      return missing;
    }
  }
  final shoulderY = (p[11].y + p[12].y) / 2;
  final hipY = (p[23].y + p[24].y) / 2;
  final kneeY = (p[25].y + p[26].y) / 2;
  final ankleY = (p[27].y + p[28].y) / 2;
  final width = (p[11].x - p[12].x).abs();
  if (width < .06 ||
      hipY - shoulderY < .06 ||
      ankleY - hipY < .08 ||
      ankleY - kneeY < .04 ||
      kneeY < hipY - .08) {
    return const SquatObservation(
      valid: false,
      feedback: 'Face the camera with both feet on the floor',
    );
  }
  return SquatObservation(
    valid: true,
    feedback: 'Squat to descend · stand to rise',
    hipY: hipY,
    shoulderY: shoulderY,
    shoulderWidth: width,
    leftAnkleY: p[27].y,
    rightAnkleY: p[28].y,
  );
}

String? _stanceIssue(SquatObservation o, SquatObservation standing) {
  final scale = o.shoulderWidth / standing.shoulderWidth;
  if (scale < .75 || scale > 1.25) {
    return 'Face the camera at your starting distance · recalibrate if you moved';
  }
  final tolerance = standing.bodyHeight * .08;
  if ((o.leftAnkleY - standing.leftAnkleY).abs() > tolerance ||
      (o.rightAnkleY - standing.rightAnkleY).abs() > tolerance) {
    return 'Keep both feet planted in your starting spot';
  }
  return null;
}

enum SquatCalibrationStep { standing, lower, rise, complete }

class SquatCalibration {
  const SquatCalibration({
    required this.standing,
    required this.bottomHipHeight,
    required this.cycleSeconds,
  });
  final SquatObservation standing;
  final double bottomHipHeight, cycleSeconds;
  double height(SquatObservation o) =>
      ((o.hipHeight - bottomHipHeight) / (standing.hipHeight - bottomHipHeight))
          .clamp(0.0, 1.0);
}

class SquatCalibrator {
  SquatCalibrationStep step = SquatCalibrationStep.standing;
  SquatCalibration? result;
  String feedback = 'Stand tall and still with both feet in view';
  double previewHeight = 1;
  final List<({double time, SquatObservation pose})> _hold = [];
  SquatObservation? _standing;
  double? _last, _lowerAt, _bottom;

  double get progress => switch (step) {
    SquatCalibrationStep.standing => 0,
    SquatCalibrationStep.lower => .33,
    SquatCalibrationStep.rise => .67,
    SquatCalibrationStep.complete => 1,
  };

  void add(TrackingSample sample, double now) {
    if (result != null) return;
    final o = observeSquat(sample, now);
    final time = sample.timestampMs;
    if (!o.valid || (_last != null && time <= _last!)) {
      _restart();
      feedback = o.valid ? 'Waiting for a fresh frame' : o.feedback;
      return;
    }
    if (_last != null && time - _last! > 250) _restart();
    _last = time;
    if (_standing != null) {
      final issue = _stanceIssue(o, _standing!);
      if (issue != null) {
        _restart();
        feedback = issue;
        return;
      }
      final range =
          _standing!.hipHeight -
          (_bottom ?? (_standing!.hipHeight - _standing!.bodyHeight * .18));
      previewHeight = (1 - (_standing!.hipHeight - o.hipHeight) / range).clamp(
        0.0,
        1.0,
      );
    }
    switch (step) {
      case SquatCalibrationStep.standing:
        feedback = 'Stand tall and still for a moment';
        if (_steady(o, time, 800)) {
          _standing = _medianPose();
          _hold.clear();
          step = SquatCalibrationStep.lower;
          feedback = 'Squat to a comfortable depth and hold briefly';
        }
      case SquatCalibrationStep.lower:
        final drop = _standing!.hipHeight - o.hipHeight;
        // A small, deliberate squat is enough; no prescribed knee angle/depth.
        if (drop < _standing!.bodyHeight * .10) {
          _hold.clear();
          _lowerAt = null;
          feedback = 'Squat comfortably, then hold for a moment';
          break;
        }
        _lowerAt ??= time;
        feedback = 'Hold this comfortable squat briefly';
        if (_steady(o, time, 400)) {
          _bottom = _medianPose().hipHeight;
          _hold.clear();
          step = SquatCalibrationStep.rise;
          feedback = 'Stand back up to finish calibration';
        }
      case SquatCalibrationStep.rise:
        feedback = 'Stand back up to finish calibration';
        final range = _standing!.hipHeight - _bottom!;
        if (o.hipHeight < _standing!.hipHeight - range * .12) {
          _hold.clear();
          break;
        }
        if (_steady(o, time, 300)) {
          result = SquatCalibration(
            standing: _standing!,
            bottomHipHeight: _bottom!,
            cycleSeconds: ((time - _lowerAt!) / 1000 + .8).clamp(3.0, 12.0),
          );
          step = SquatCalibrationStep.complete;
          feedback = 'Ready! Squat to descend · stand to rise';
          previewHeight = 1;
        }
      case SquatCalibrationStep.complete:
        break;
    }
  }

  bool _steady(SquatObservation o, double time, double duration) {
    if (_hold.isNotEmpty) {
      final first = _hold.first.pose;
      final tolerance = (_standing ?? first).bodyHeight * .025;
      if ((o.hipHeight - first.hipHeight).abs() > tolerance ||
          (o.shoulderY - first.shoulderY).abs() > tolerance ||
          (o.leftAnkleY - first.leftAnkleY).abs() > tolerance ||
          (o.rightAnkleY - first.rightAnkleY).abs() > tolerance ||
          (o.shoulderWidth - first.shoulderWidth).abs() > tolerance) {
        _hold.clear();
      }
    }
    _hold.add((time: time, pose: o));
    return _hold.length >= 5 && time - _hold.first.time >= duration;
  }

  SquatObservation _medianPose() {
    double median(double Function(SquatObservation) value) {
      final values = _hold.map((f) => value(f.pose)).toList()..sort();
      return values[values.length ~/ 2];
    }

    return SquatObservation(
      valid: true,
      feedback: '',
      hipY: median((p) => p.hipY),
      shoulderY: median((p) => p.shoulderY),
      shoulderWidth: median((p) => p.shoulderWidth),
      leftAnkleY: median((p) => p.leftAnkleY),
      rightAnkleY: median((p) => p.rightAnkleY),
    );
  }

  void _restart() {
    step = SquatCalibrationStep.standing;
    _standing = null;
    _last = _lowerAt = _bottom = null;
    _hold.clear();
    previewHeight = 1;
  }
}

class SquatInterpreter implements MovementInterpreter {
  SquatInterpreter(this.calibration);
  final SquatCalibration calibration;
  final List<double> _recent = [];
  double? _last, _filtered, _downAt;
  bool _wasStanding = false;
  int _reps = 0;

  @override
  MovementInput add(TrackingSample sample, double now) {
    final o = observeSquat(sample, now);
    final issue = !o.valid
        ? o.feedback
        : _last != null && sample.timestampMs <= _last!
        ? 'Waiting for a fresh frame'
        : _stanceIssue(o, calibration.standing);
    if (issue != null) {
      _clearMovement();
      return MovementInput(valid: false, repetitions: _reps, feedback: issue);
    }
    final time = sample.timestampMs;
    if (_last != null && time - _last! > 250) _clearMovement();
    _recent.add(calibration.height(o));
    if (_recent.length > 3) _recent.removeAt(0);
    final sorted = [..._recent]..sort();
    final raw = sorted[sorted.length ~/ 2];
    final alpha = _last == null ? 1.0 : 1 - math.exp(-(time - _last!) / 65);
    _filtered = (_filtered ?? raw) + alpha * (raw - (_filtered ?? raw));
    _last = time;
    final height = ((_filtered! - .06) / .88).clamp(0.0, 1.0);
    if (height >= .85) {
      if (_downAt != null && time - _downAt! >= 350) _reps++;
      _downAt = null;
      _wasStanding = true;
    } else if (height <= .15 && _wasStanding) {
      _downAt = time;
      _wasStanding = false;
    }
    return MovementInput(
      valid: true,
      height: height,
      repetitions: _reps,
      feedback: o.feedback,
    );
  }

  void _clearMovement() {
    _last = _filtered = _downAt = null;
    _recent.clear();
    _wasStanding = false;
  }

  @override
  void reset() {
    _clearMovement();
    _reps = 0;
  }
}
