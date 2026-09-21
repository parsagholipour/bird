import 'dart:math' as math;
import 'tracking.dart';

/// A front-facing standing body. The torso supplies the motion signal; lower
/// landmarks establish framing and scale without needing sharply tracked toes.
class JumpObservation {
  const JumpObservation({
    required this.valid,
    required this.feedback,
    this.shoulderY = 0,
    this.hipY = 0,
    this.leftFootY = 0,
    this.rightFootY = 0,
    this.shoulderWidth = 0,
  });
  final bool valid;
  final String feedback;
  final double shoulderY, hipY, leftFootY, rightFootY, shoulderWidth;
  double get bodyHeight => (leftFootY + rightFootY) / 2 - shoulderY;
  double get torsoHeight => hipY - shoulderY;
}

JumpObservation observeJump(TrackingSample sample, double now) {
  if (!sample.freshAt(now)) {
    return const JumpObservation(
      valid: false,
      feedback: 'Camera is catching up',
    );
  }
  const missing = JumpObservation(
    valid: false,
    feedback: 'Step back so your shoulders, hips and both feet are in view',
  );
  if (sample.mode != PlayMode.jump ||
      !sample.detected ||
      sample.joints.length < 33) {
    return missing;
  }
  final p = sample.joints;
  bool visible(Joint joint, double confidence) =>
      joint.confidence.isFinite &&
      joint.confidence >= confidence &&
      joint.x.isFinite &&
      joint.y.isFinite &&
      joint.x >= .02 &&
      joint.x <= .98 &&
      joint.y >= .02 &&
      joint.y <= .98;
  if ([11, 12, 23, 24].any((id) => !visible(p[id], .5)) ||
      [25, 26].any((id) => !visible(p[id], .3))) {
    return missing;
  }
  double? footY(int ankle, int toe) {
    final candidates = [p[ankle], p[toe]].where((joint) => visible(joint, .3));
    if (candidates.isEmpty) return null;
    return candidates.map((joint) => joint.y).reduce(math.max);
  }

  final leftFoot = footY(27, 31);
  final rightFoot = footY(28, 32);
  if (leftFoot == null || rightFoot == null) return missing;
  final shoulder = (p[11].y + p[12].y) / 2;
  final hip = (p[23].y + p[24].y) / 2;
  final knee = (p[25].y + p[26].y) / 2;
  if (hip - shoulder < .08 ||
      knee <= hip ||
      math.min(leftFoot, rightFoot) <= knee ||
      math.min(leftFoot, rightFoot) - shoulder < .25 ||
      (p[11].x - p[12].x).abs() < .06) {
    return const JumpObservation(
      valid: false,
      feedback: 'Stand facing the camera with room above you to jump',
    );
  }
  return JumpObservation(
    valid: true,
    feedback: 'Small jumps are enough · land before jumping again',
    shoulderY: shoulder,
    hipY: hip,
    leftFootY: leftFoot,
    rightFootY: rightFoot,
    shoulderWidth: (p[11].x - p[12].x).abs(),
  );
}

class JumpCalibration {
  const JumpCalibration(this.standing, {this.riseThreshold = .025});
  final JumpObservation standing;
  final double riseThreshold;
}

class JumpCalibrator {
  final List<({double time, JumpObservation observation})> _standing = [];
  double? _last;
  JumpCalibration? result;
  String feedback = 'Stand still with your whole body and both feet in view';
  double get progress => _standing.isEmpty || _last == null
      ? 0
      : ((_last! - _standing.first.time) / 1000).clamp(0.0, 1.0);

  void add(TrackingSample sample, double now) {
    if (result != null) return;
    if (_last != null && sample.timestampMs <= _last!) return;
    if (_last != null && sample.timestampMs - _last! > 350) _clear();
    final observation = observeJump(sample, now);
    if (!observation.valid) {
      feedback = observation.feedback;
      return;
    }
    _last = sample.timestampMs;
    _standing.add((time: sample.timestampMs, observation: observation));
    while (_standing.length > 1 &&
        _standing[1].time <= sample.timestampMs - 1000) {
      _standing.removeAt(0);
    }
    feedback = 'Stand tall and still for a moment';
    if (progress < 1 || _standing.length < 12) return;
    List<double> sorted(double Function(JumpObservation) value) =>
        _standing.map((frame) => value(frame.observation)).toList()..sort();
    double median(double Function(JumpObservation) value) {
      final values = sorted(value);
      return values[values.length ~/ 2];
    }

    // Feet jitter and briefly occlude even while the torso is still. Estimate
    // their standing position robustly, but use torso stability to calibrate.
    // The central 80% also tolerates isolated pose spikes without restarting.
    final tolerance = median((p) => p.bodyHeight) * .035;
    bool stable(double Function(JumpObservation) value) {
      final values = sorted(value);
      return values[((values.length - 1) * .9).floor()] -
              values[((values.length - 1) * .1).ceil()] <=
          tolerance;
    }

    if (!stable((p) => p.shoulderY) || !stable((p) => p.hipY)) return;

    double spread(double Function(JumpObservation) value) {
      final values = sorted(value);
      return values[((values.length - 1) * .9).floor()] -
          values[((values.length - 1) * .1).ceil()];
    }

    final bodyHeight = median((p) => p.bodyHeight);
    final motionNoise =
        math.min(spread((p) => p.shoulderY), spread((p) => p.hipY)) /
        bodyHeight;

    result = JumpCalibration(
      JumpObservation(
        valid: true,
        feedback: '',
        shoulderY: median((p) => p.shoulderY),
        hipY: median((p) => p.hipY),
        leftFootY: median((p) => p.leftFootY),
        rightFootY: median((p) => p.rightFootY),
        shoulderWidth: median((p) => p.shoulderWidth),
      ),
      riseThreshold: math.max(.025, motionNoise * 2),
    );
    feedback = 'Ready! One small jump gives one big boost.';
  }

  void _clear() {
    _standing.clear();
    _last = null;
  }
}

class JumpInterpreter implements MovementInterpreter {
  JumpInterpreter(this.calibration);
  final JumpCalibration calibration;
  double? _last, _groundedSince, _risingSince, _previousRise;
  double _lastJump = double.negativeInfinity;
  bool _armed = false;

  @override
  MovementInput add(TrackingSample sample, double now) {
    final observation = observeJump(sample, now);
    if (!observation.valid || (_last != null && sample.timestampMs <= _last!)) {
      _interrupt(sample.timestampMs);
      return MovementInput(
        valid: false,
        feedback: observation.valid
            ? 'Waiting for a fresh frame'
            : observation.feedback,
      );
    }
    final time = sample.timestampMs;
    if (_last != null && time - _last! > 250) _disarm();
    final baseline = calibration.standing;
    final scale = observation.shoulderWidth / baseline.shoulderWidth;
    final torsoScale = observation.torsoHeight / baseline.torsoHeight;
    if (scale < .6 || scale > 1.45 || torsoScale < .7 || torsoScale > 1.4) {
      _interrupt(time);
      return const MovementInput(
        valid: false,
        feedback:
            'Face the camera at your starting distance · recalibrate if you moved',
      );
    }
    final height = baseline.bodyHeight;
    final hipRise = (baseline.hipY - observation.hipY) / height;
    final shoulderRise = (baseline.shoulderY - observation.shoulderY) / height;
    final rise = math.min(hipRise, shoulderRise);
    final speed = _last == null || _previousRise == null
        ? 0.0
        : (rise - _previousRise!) * 1000 / (time - _last!);
    // With a low phone, pose estimation can move toes downward during a real
    // hop. A prompt boost follows coherent torso rise, not proof of foot lift.
    // This deliberately accepts small body bounces as well as airborne jumps.
    final airborne = rise >= calibration.riseThreshold;
    final grounded =
        !airborne &&
        hipRise > -.15 &&
        hipRise < calibration.riseThreshold &&
        shoulderRise > -.15 &&
        shoulderRise < .075;
    if (grounded) {
      _groundedSince ??= time;
      if (time - _groundedSince! >= 60) {
        _armed = true;
      }
      _risingSince = null;
    } else {
      _groundedSince = null;
    }
    var flap = false;
    if (_armed && airborne && time - _lastJump >= 450) {
      if (_risingSince == null && speed >= .15) _risingSince = time;
      // Two frames, separated in time, reject single-frame landmark spikes.
      if (_risingSince != null && time - _risingSince! >= 25) {
        flap = true;
        _lastJump = time;
        _armed = false;
        _risingSince = null;
      }
    } else {
      _risingSince = null;
    }
    _last = time;
    _previousRise = rise;
    return MovementInput(
      valid: true,
      flap: flap,
      feedback: _armed
          ? 'Jump for a big boost'
          : 'Land to prepare your next jump',
    );
  }

  void _interrupt(double time) {
    // One late or distorted pose must not forget a confirmed landing. Never
    // emit a flap on that pose, and require two fresh airborne frames afterward.
    if (_last == null || time - _last! > 200) {
      _disarm();
    } else {
      _groundedSince = _risingSince = null;
    }
  }

  void _disarm() {
    _armed = false;
    _last = _groundedSince = _risingSince = _previousRise = null;
  }

  @override
  void reset() {
    _disarm();
    _lastJump = double.negativeInfinity;
  }
}
