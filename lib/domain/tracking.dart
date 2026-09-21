import 'dart:math' as math;

/// Camera-independent tracking data. All times use one monotonic millisecond clock.
// Persisted by index: jump replaces smile at index 1; keep existing records.
enum PlayMode {
  pushUp,
  jump,
  touch,
  squat;

  bool get controlsHeight => this == pushUp || this == squat;

  /// Accept old session journals and links after replacing smile mode.
  static PlayMode fromName(String name) =>
      name == 'smile' ? jump : values.byName(name);

  String get title => switch (this) {
    pushUp => 'Push-Up Flight',
    jump => 'Jump & Fly',
    touch => 'Tap & Fly',
    squat => 'Squat & Fly',
  };
}

enum TrackingState { idle, starting, tracking, missing, denied, error }

enum BodyPerspective { side, front }

class Joint {
  const Joint(this.x, this.y, this.z, this.confidence);
  final double x, y, z, confidence;
}

class TrackingSample {
  const TrackingSample({
    required this.mode,
    required this.timestampMs,
    required this.receivedMs,
    required this.joints,
    this.aspectRatio = 4 / 3,
    this.detected = true,
    this.inferenceMs = 0,
    this.sensorTimestamp = true,
  });
  final PlayMode mode;
  final double timestampMs, receivedMs, aspectRatio, inferenceMs;
  final List<Joint> joints;
  final bool detected, sensorTimestamp;
  bool freshAt(double now) =>
      timestampMs <= now + 10 && now - timestampMs <= 200;
}

abstract interface class TrackingSource {
  Stream<TrackingSample> get samples;
  Stream<TrackingIssue> get issues;
  double get nowMs;
  Future<bool> requestPermission();
  Future<void> start(PlayMode mode, {bool frontCamera = true});
  Future<void> stop();
}

class TrackingIssue {
  const TrackingIssue(this.code, this.message);
  final String code, message;
}

/// Scalar depth cues measured from one frame. Each should move monotonically
/// between a player's top and bottom. Calibration measures how well each one
/// actually separates the two for this camera placement and weights it
/// accordingly, so the same code serves side and front views.
enum DepthCue {
  /// Projected shoulder–elbow–wrist angle of the left arm, in degrees.
  leftElbow,

  /// Projected shoulder–elbow–wrist angle of the right arm, in degrees.
  rightElbow,

  /// Front view only: shoulder height above the hands, in shoulder widths.
  shoulderDrop,
}

class BodyObservation {
  const BodyObservation({
    required this.valid,
    required this.feedback,
    this.elbow = 0,
    this.cues = const {},
    this.bodyLength = 0,
    this.armLength = 0,
    this.side = 0,
    this.perspective = BodyPerspective.side,
  });
  final bool valid;
  final String feedback;

  /// Arm angle used to segment movement: the mean of both tracked arms, or the
  /// straighter one when they disagree by more than 25°, because a single
  /// misplaced elbow landmark folds one arm while the real one stays put.
  final double elbow;
  final Map<DepthCue, double> cues;
  final double bodyLength, armLength;
  final int side;
  final BodyPerspective perspective;
}

double _distance(Joint a, Joint b, double aspect) =>
    math.sqrt(math.pow((a.x - b.x) * aspect, 2) + math.pow(a.y - b.y, 2));

double _angle(Joint a, Joint b, Joint c, double aspect) {
  final ax = (a.x - b.x) * aspect, ay = a.y - b.y;
  final cx = (c.x - b.x) * aspect, cy = c.y - b.y;
  final d = math.sqrt((ax * ax + ay * ay) * (cx * cx + cy * cy));
  if (d < 0.00001) return 0;
  return math.acos(((ax * cx + ay * cy) / d).clamp(-1, 1)) * 180 / math.pi;
}

/// Arm/torso control is sufficient; leg checks apply only when reliable.
/// Face landmarks 0–10 are deliberately ignored (including while looking down).
BodyObservation observeBody(
  TrackingSample sample,
  double now, {
  int? preferredSide,
  BodyPerspective? preferredPerspective,
}) {
  if (!sample.freshAt(now)) {
    return const BodyObservation(
      valid: false,
      feedback: 'Camera is catching up',
    );
  }
  if (sample.mode != PlayMode.pushUp ||
      !sample.detected ||
      sample.joints.length < 33 ||
      !sample.aspectRatio.isFinite ||
      sample.aspectRatio <= 0) {
    return const BodyObservation(
      valid: false,
      feedback: 'Step into the body outline',
    );
  }
  final shoulderSpan = _distance(
    sample.joints[11],
    sample.joints[12],
    sample.aspectRatio,
  );
  final shouldersVisible =
      _jointVisible(sample.joints[11]) &&
      _jointVisible(sample.joints[12]) &&
      shoulderSpan >= .12;
  final torsoLength =
      (_distance(sample.joints[11], sample.joints[23], sample.aspectRatio) +
          _distance(sample.joints[12], sample.joints[24], sample.aspectRatio)) /
      2;
  final perspective =
      preferredPerspective ??
      (shouldersVisible && shoulderSpan > torsoLength * .8
          ? BodyPerspective.front
          : BodyPerspective.side);
  if (perspective == BodyPerspective.front && !shouldersVisible) {
    return const BodyObservation(
      valid: false,
      feedback: 'Keep both shoulders in view',
    );
  }
  // Keep a usable side stable, but recover when it is occluded or misread.
  final sides = [0, 1]
    ..sort(
      (a, b) =>
          _sideConfidence(sample, b).compareTo(_sideConfidence(sample, a)),
    );
  if (preferredSide == 0 || preferredSide == 1) {
    sides.remove(preferredSide);
    sides.insert(0, preferredSide!);
  }
  BodyObservation? rejection;
  for (final side in sides) {
    if (_sideConfidence(sample, side) < .3) continue;
    final observation = _observeBodySide(sample, side, perspective);
    if (observation.valid) return observation;
    rejection ??= observation;
  }
  return rejection ??
      const BodyObservation(
        valid: false,
        feedback: 'Show one shoulder, elbow, wrist and hip from the side',
      );
}

bool _jointVisible(Joint p) =>
    p.x.isFinite &&
    p.y.isFinite &&
    p.confidence.isFinite &&
    p.confidence >= .3 &&
    p.x >= -.05 &&
    p.x <= 1.05 &&
    p.y >= -.05 &&
    p.y <= 1.05;

double _sideConfidence(TrackingSample sample, int side) => [11, 13, 15, 23]
    .map((i) {
      final p = sample.joints[i + side];
      return p.x.isFinite &&
              p.y.isFinite &&
              p.confidence.isFinite &&
              p.x >= -.05 &&
              p.x <= 1.05 &&
              p.y >= -.05 &&
              p.y <= 1.05
          ? p.confidence
          : 0.0;
    })
    .reduce(math.min);

// Below this the forearm would fold onto the upper arm. Nobody holds a
// push-up like that; it is a misplaced landmark and must not read as depth.
const _minimumElbowDegrees = 55.0;

double? _armAngle(List<Joint> joints, int side, double aspect) {
  final s = joints[11 + side], e = joints[13 + side], w = joints[15 + side];
  if (!_jointVisible(s) || !_jointVisible(e) || !_jointVisible(w)) return null;
  final angle = _angle(s, e, w, aspect);
  return angle >= _minimumElbowDegrees ? angle : null;
}

double _robustElbow(Map<DepthCue, double> cues, double fallback) {
  final left = cues[DepthCue.leftElbow], right = cues[DepthCue.rightElbow];
  if (left == null) return right ?? fallback;
  if (right == null) return left;
  if ((left - right).abs() > 25) return math.max(left, right);
  return (left + right) / 2;
}

BodyObservation _observeBodySide(
  TrackingSample sample,
  int side,
  BodyPerspective perspective,
) {
  final joints = sample.joints;
  final s = joints[11 + side], e = joints[13 + side], w = joints[15 + side];
  final h = joints[23 + side], k = joints[25 + side], a = joints[27 + side];
  final aspect = sample.aspectRatio;
  final length = _distance(s, h, aspect);
  bool reliable(Joint p) =>
      p.confidence >= .65 && p.x >= 0 && p.x <= 1 && p.y >= 0 && p.y <= 1;
  final legsVisible = reliable(k) && reliable(a);
  final arm = _distance(s, e, aspect) + _distance(e, w, aspect);
  final hip = _angle(s, h, k, aspect), knee = _angle(h, k, a, aspect);
  final elbow = _angle(s, e, w, aspect);
  if (length < 0.08 || arm < 0.07) {
    return const BodyObservation(
      valid: false,
      feedback: 'Move a little closer',
    );
  }
  // Compare the arm with the torso, not with the image horizon. A propped
  // phone and an oblique view can make a valid plank look almost vertical.
  final armToTorso = _angle(w, s, h, aspect);
  if (perspective == BodyPerspective.side &&
      (armToTorso < 20 || armToTorso > 165)) {
    return const BodyObservation(
      valid: false,
      feedback: 'Put your hands on the floor and extend your body behind you',
    );
  }
  // Only a pronounced fold is a blocker. Perspective and clothing make small
  // deviations unreliable, so this is not a straight-leg form assessment.
  if (perspective == BodyPerspective.side &&
      legsVisible &&
      (hip < 110 || knee < 95)) {
    return const BodyObservation(
      valid: false,
      feedback: 'Extend your body a little farther behind your hands',
    );
  }
  if (elbow < _minimumElbowDegrees) {
    return const BodyObservation(
      valid: false,
      feedback: 'Stay within a comfortable push-up range',
    );
  }
  final cues = <DepthCue, double>{};
  final leftElbow = _armAngle(joints, 0, aspect);
  final rightElbow = _armAngle(joints, 1, aspect);
  if (leftElbow != null) cues[DepthCue.leftElbow] = leftElbow;
  if (rightElbow != null) cues[DepthCue.rightElbow] = rightElbow;
  if (perspective == BodyPerspective.front) {
    final left = joints[11], right = joints[12];
    final dx = (right.x - left.x) * aspect, dy = right.y - left.y;
    final span = _distance(left, right, aspect);
    // The shoulder line supplies the horizontal axis even with camera roll.
    // Measure above the hands, not away from the foreshortened torso line.
    double depth(Joint p) =>
        ((p.x - left.x) * aspect * dy - (p.y - left.y) * dx) / span;
    final wrists = [joints[15], joints[16]].where(_jointVisible).toList();
    final wristDepth =
        wrists.map(depth).reduce((a, b) => a + b) / wrists.length;
    if (wristDepth.abs() < .07 ||
        depth(h) / wristDepth < -.2 ||
        depth(h) / wristDepth > 1.3 ||
        (legsVisible && depth(a) / wristDepth > 1.3)) {
      return const BodyObservation(
        valid: false,
        feedback: 'Place your hands on the floor with your body behind them',
      );
    }
    cues[DepthCue.shoulderDrop] = wristDepth.abs() / span;
  }
  return BodyObservation(
    valid: true,
    feedback: perspective == BodyPerspective.front
        ? 'Front view tracked · keep your hands in view'
        : legsVisible
        ? 'Body in view · face can look down'
        : 'Arms tracked · leg check limited',
    elbow: _robustElbow(cues, elbow),
    cues: cues,
    bodyLength: length,
    armLength: arm,
    side: side,
    perspective: perspective,
  );
}

/// Compact, non-image diagnostics for the opt-in camera lab.
String bodyDiagnostics(
  TrackingSample sample,
  double now, {
  int? preferredSide,
  BodyPerspective? preferredPerspective,
}) {
  if (!sample.detected || sample.joints.length < 33) return 'No pose detected';
  final j = sample.joints;
  final observation = observeBody(
    sample,
    now,
    preferredSide: preferredSide,
    preferredPerspective: preferredPerspective,
  );
  final side = observation.valid
      ? observation.side
      : _sideConfidence(sample, 0) >= _sideConfidence(sample, 1)
      ? 0
      : 1;
  final s = j[11 + side], e = j[13 + side], w = j[15 + side], h = j[23 + side];
  final aspect = sample.aspectRatio;
  String degrees(double value) => value.isFinite ? '${value.round()}°' : '?';
  final confidenceText = [11, 13, 15, 23]
      .map((i) {
        final confidence = j[i + side].confidence;
        return confidence.isFinite ? '${(confidence * 100).round()}' : '?';
      })
      .join('/');
  final cues = observation.cues;
  final drop = cues[DepthCue.shoulderDrop];
  return '${observation.perspective.name} · ${side == 0 ? 'L' : 'R'} S/E/W/H $confidenceText% · '
      'arm/torso ${degrees(_angle(w, s, h, aspect))} · '
      'elbow ${degrees(_angle(s, e, w, aspect))} '
      '(L ${degrees(cues[DepthCue.leftElbow] ?? double.nan)} '
      'R ${degrees(cues[DepthCue.rightElbow] ?? double.nan)}) · '
      'drop ${drop?.toStringAsFixed(2) ?? '?'} · '
      'age ${(now - sample.timestampMs).round()}ms';
}

/// Linear map from one cue's raw value to depth: 0 at the learned bottom,
/// 1 at the learned top. [weight] is the squared discriminability (d′²) the
/// cue showed during calibration, the Fisher-optimal weight for fusing
/// independent linear cues.
class CueModel {
  const CueModel({
    required this.cue,
    required this.top,
    required this.bottom,
    required this.weight,
  });
  final DepthCue cue;
  final double top, bottom, weight;

  /// Clamped just past both ends so one glitching cue cannot drag the fused
  /// depth arbitrarily far.
  double depth(double value) {
    final span = top - bottom;
    if (span == 0) return 1;
    return ((value - bottom) / span).clamp(-.15, 1.15);
  }
}

class PushUpCalibration {
  const PushUpCalibration({
    required this.cues,
    required this.cycleSeconds,
    required this.bodyLength,
    required this.side,
    this.armLength = 0,
    this.perspective = BodyPerspective.side,
  });
  final List<CueModel> cues;
  final double cycleSeconds, bodyLength, armLength;
  final int side;
  final BodyPerspective perspective;

  Iterable<CueModel> get _elbows =>
      cues.where((c) => c.cue != DepthCue.shoulderDrop);

  /// Learned elbow angles at the top and bottom, for diagnostics.
  double? get topElbow => _mean(_elbows.map((c) => c.top));
  double? get bottomElbow => _mean(_elbows.map((c) => c.bottom));
}

double? _mean(Iterable<double> values) {
  final list = values.toList();
  if (list.isEmpty) return null;
  return list.reduce((a, b) => a + b) / list.length;
}

double _median(List<double> values) {
  final sorted = [...values]..sort();
  final middle = sorted.length ~/ 2;
  return sorted.length.isOdd
      ? sorted[middle]
      : (sorted[middle - 1] + sorted[middle]) / 2;
}

/// Median absolute deviation scaled to match a normal σ (Rousseeuw & Croux).
double _robustSigma(List<double> values, double center) =>
    1.4826 * _median(values.map((v) => (v - center).abs()).toList());

enum BodyCalibrationStep { position, lower, raise, complete }

// A three-frame median rejects isolated landmark spikes at the cost of one
// frame of lag; it precedes every time-based smoother below.
class _MedianFilter {
  final List<double> _recent = [];

  double add(double value) {
    _recent.add(value);
    if (_recent.length > 3) _recent.removeAt(0);
    final sorted = [..._recent]..sort();
    return sorted[sorted.length ~/ 2];
  }

  void reset() => _recent.clear();
}

// One Euro filter (Casiez, Roussel & Vogel, CHI 2012): a first-order low-pass
// whose cutoff rises with the signal's speed. A held position is smoothed
// hard, so landmark jitter cannot move the bird, while a real push-up passes
// through with little lag. Timestamps keep it consistent at any camera rate.
class _OneEuroFilter {
  _OneEuroFilter({this.minCutoffHz = 1, this.beta = 2});
  final double minCutoffHz, beta;
  static const derivativeCutoffHz = 1.0;
  double? _value, _derivative, _time;

  static double _alpha(double cutoffHz, double dtSeconds) {
    final tau = 1 / (2 * math.pi * cutoffHz);
    return 1 / (1 + tau / dtSeconds);
  }

  double add(double value, double timestampMs) {
    final previous = _value;
    if (previous == null) {
      _value = value;
      _derivative = 0;
      _time = timestampMs;
      return value;
    }
    final dt = math.max((timestampMs - _time!) / 1000, .001);
    _time = timestampMs;
    final rate = (value - previous) / dt;
    final derivativeAlpha = _alpha(derivativeCutoffHz, dt);
    _derivative = derivativeAlpha * rate + (1 - derivativeAlpha) * _derivative!;
    final alpha = _alpha(minCutoffHz + beta * _derivative!.abs(), dt);
    return _value = alpha * value + (1 - alpha) * previous;
  }

  void reset() {
    _value = null;
    _derivative = null;
    _time = null;
  }
}

/// Learns a player's personal top and bottom from two push-ups.
///
/// Movement is segmented on the arm angle alone, which is the one cue that
/// moves the same way in every camera placement: a descent is a sustained
/// bend of at least 15° below the held top, a cycle needs at least 30° of
/// excursion, and the return must come back into the top fifth of it. The
/// frames at both ends of each cycle then label every cue (both elbows and,
/// in the front view, the shoulder drop), and each cue gets a robust linear
/// model weighted by how cleanly it separated the two ends.
class BodyCalibrator {
  BodyCalibrationStep step = BodyCalibrationStep.position;
  int cycles = 0;
  int? side;
  BodyPerspective? perspective;
  double previewHeight = 1;
  PushUpCalibration? result;
  String feedback = 'Find a comfortable top position';

  // Degrees of the robust arm angle unless stated otherwise.
  static const _steadyMs = 800.0, _steadySpread = 12.0;
  static const _descentDegrees = 15.0, _minimumRange = 30.0;
  static const _returnFraction = .2, _minimumCycleMs = 700.0;

  final _spikes = _MedianFilter();
  final _smooth = _OneEuroFilter(minCutoffHz: 1.5, beta: 1);
  final List<({double time, double angle})> _hold = [];
  final List<({double angle, Map<DepthCue, double> cues})> _cycle = [];
  final Map<DepthCue, List<double>> _tops = {}, _bottoms = {};
  final List<double> _ranges = [], _cycleTimes = [];
  double? _lastSample, _lastValid, _confirmSince, _descentStart;
  double? _peak, _trough;
  bool _shallow = false;
  double _length = 0, _arm = 0;

  void add(TrackingSample sample, double now) {
    if (result != null) return;
    if (_lastSample != null && sample.timestampMs <= _lastSample!) return;
    final o = observeBody(
      sample,
      now,
      preferredSide: side,
      preferredPerspective: perspective,
    );
    if (!o.valid) {
      if (_lastValid == null || now - _lastValid! > 200) {
        _confirmSince = null;
      }
      feedback = o.feedback;
      return;
    }
    final time = sample.timestampMs;
    _lastSample = time;
    if (_lastValid != null && time - _lastValid! > 500) {
      // Keep completed cycles, but never join a descent and ascent across a
      // tracking gap. A partial movement must be seen again in full.
      _restart();
    }
    _lastValid = time;
    side = o.side;
    final raw = _spikes.add(o.elbow);
    final angle = _smooth.add(raw, time);
    _cycle.add((angle: raw, cues: o.cues));
    if (_cycle.length > 600) _cycle.removeAt(0);

    switch (step) {
      case BodyCalibrationStep.position:
        // A steady top gives the descent detector a trustworthy reference;
        // settling into the plank must not read as the first push-up.
        _hold.add((time: time, angle: raw));
        _hold.removeWhere((h) => time - h.time > _steadyMs * 1.25);
        final angles = _hold.map((h) => h.angle);
        final steady =
            _hold.length >= 5 &&
            time - _hold.first.time >= _steadyMs &&
            angles.reduce(math.max) - angles.reduce(math.min) <= _steadySpread;
        if (steady) {
          _length = o.bodyLength;
          _arm = o.armLength;
          perspective = o.perspective;
          _peak = angle;
          _trough = null;
          _descentStart = null;
          _cycle
            ..clear()
            ..add((angle: raw, cues: o.cues));
          step = BodyCalibrationStep.lower;
        }
      case BodyCalibrationStep.lower:
        _peak = math.max(_peak!, angle);
        if (_peak! - angle >= _descentDegrees) {
          _descentStart ??= time;
          _trough = math.min(_trough ?? angle, angle);
          _confirmSince ??= time;
          if (time - _confirmSince! >= 120) {
            step = BodyCalibrationStep.raise;
            _confirmSince = null;
          }
        } else {
          _confirmSince = null;
          _trough = null;
          _descentStart = null;
        }
      case BodyCalibrationStep.raise:
        _trough = math.min(_trough!, angle);
        final range = _peak! - _trough!;
        if (angle < _peak! - range * _returnFraction) {
          _confirmSince = null;
          break;
        }
        _confirmSince ??= time;
        if (time - _confirmSince! < 80) break;
        _confirmSince = null;
        if (range >= _requiredRange &&
            time - _descentStart! >= _minimumCycleMs) {
          _completeCycle(time, range);
        } else {
          // Back at the top after too little movement (a wobble, a bounce):
          // forget it rather than average it into the learned range.
          step = BodyCalibrationStep.lower;
          _trough = null;
          _descentStart = null;
          _shallow = true;
        }
      case BodyCalibrationStep.complete:
        break;
    }

    // Only a confirmed descent moves the preview bird; before that, the first
    // cycle's range gives the second descent an immediate, stable scale.
    final peak = _peak, trough = _trough;
    final range = switch (step) {
      BodyCalibrationStep.raise => peak! - trough!,
      BodyCalibrationStep.lower when _ranges.isNotEmpty => _ranges.first,
      _ => 0.0,
    };
    previewHeight = range >= _descentDegrees
        ? ((angle - (peak! - range)) / range).clamp(0.0, 1.0)
        : 1;
    feedback = switch (step) {
      BodyCalibrationStep.position => 'Find a comfortable top position',
      BodyCalibrationStep.lower =>
        _shallow
            ? 'Lower a little more · ${cycles + 1} of 2'
            : 'Lower comfortably · ${cycles + 1} of 2',
      BodyCalibrationStep.raise =>
        _peak! - _trough! >= _requiredRange
            ? 'Push back up · ${cycles + 1} of 2'
            : cycles == 0
            ? 'Lower a little more · 1 of 2'
            : 'Match your first comfortable range · 2 of 2',
      BodyCalibrationStep.complete => 'Calibrated! Try moving your bird.',
    };
  }

  // A brief lean after a deep first movement is not the second push-up.
  // Mixing those depths made the usable range too narrow and unstable.
  double get _requiredRange => _ranges.isEmpty
      ? _minimumRange
      : math.max(_minimumRange, _ranges.first * .55);

  void _restart() {
    step = BodyCalibrationStep.position;
    _peak = _trough = _confirmSince = _descentStart = null;
    _shallow = false;
    _spikes.reset();
    _smooth.reset();
    _hold.clear();
    _cycle.clear();
  }

  void _completeCycle(double time, double range) {
    final peak = _peak!, trough = _trough!;
    final byAngle = [..._cycle]..sort((a, b) => a.angle.compareTo(b.angle));
    var tops = _cycle.where((f) => f.angle >= peak - range * .2).toList();
    var bottoms = _cycle.where((f) => f.angle <= trough + range * .3).toList();
    // The smoothed peak/trough lag the raw angle; a fast cycle can leave few
    // raw frames inside either band. Fall back to the extreme frames.
    final fallback = math.min(8, byAngle.length);
    if (tops.length < fallback) {
      tops = byAngle.sublist(byAngle.length - fallback);
    }
    if (bottoms.length < fallback) bottoms = byAngle.sublist(0, fallback);
    for (final f in tops) {
      f.cues.forEach((cue, v) => (_tops[cue] ??= []).add(v));
    }
    for (final f in bottoms) {
      f.cues.forEach((cue, v) => (_bottoms[cue] ??= []).add(v));
    }
    _ranges.add(range);
    _cycleTimes.add((time - _descentStart!) / 1000);
    cycles++;
    _shallow = false;
    if (cycles == 2) {
      result = PushUpCalibration(
        cues: _models(),
        cycleSeconds: _cycleTimes.reduce(math.max).clamp(2.0, 12.0),
        bodyLength: _length,
        armLength: _arm,
        side: side!,
        perspective: perspective!,
      );
      step = BodyCalibrationStep.complete;
    } else {
      step = BodyCalibrationStep.lower;
      _peak = _cycle.last.angle;
      _trough = null;
      _descentStart = null;
      final last = _cycle.last;
      _cycle
        ..clear()
        ..add(last);
    }
  }

  /// One robust linear model per cue, weighted by d′² (Fisher's linear
  /// discriminant for independent cues). Medians and MAD keep a few glitched
  /// frames from shifting either endpoint; the σ floor stops a cue that
  /// happened to be perfectly still from dominating the fusion.
  List<CueModel> _models() {
    final models = <CueModel>[];
    for (final cue in DepthCue.values) {
      final top = _tops[cue], bottom = _bottoms[cue];
      if (top == null ||
          bottom == null ||
          top.length < 3 ||
          bottom.length < 3) {
        continue;
      }
      final topCenter = _median(top), bottomCenter = _median(bottom);
      final separation = (topCenter - bottomCenter).abs();
      if (separation == 0) continue;
      final topSigma = _robustSigma(top, topCenter);
      final bottomSigma = _robustSigma(bottom, bottomCenter);
      final sigma = math.sqrt(
        (topSigma * topSigma + bottomSigma * bottomSigma) / 2,
      );
      final dPrime = math.min(
        separation / math.max(sigma, .05 * separation),
        15.0,
      );
      models.add(
        CueModel(
          cue: cue,
          top: topCenter,
          bottom: bottomCenter,
          weight: dPrime * dPrime,
        ),
      );
    }
    if (models.isEmpty) {
      // Neither arm alone was labelled often enough; both bend through the
      // same range, so pool them.
      final top = [
        ...?_tops[DepthCue.leftElbow],
        ...?_tops[DepthCue.rightElbow],
      ];
      final bottom = [
        ...?_bottoms[DepthCue.leftElbow],
        ...?_bottoms[DepthCue.rightElbow],
      ];
      return [
        CueModel(
          cue: DepthCue.leftElbow,
          top: _median(top),
          bottom: _median(bottom),
          weight: 1,
        ),
      ];
    }
    // d′ ≥ 2 means the endpoints overlap by well under one part in six.
    // Keep only cues that clear it; otherwise the single best one.
    final reliable = models.where((m) => m.weight >= 4).toList();
    if (reliable.isNotEmpty) return reliable;
    models.sort((a, b) => b.weight.compareTo(a.weight));
    return [models.first];
  }
}

class MovementInput {
  const MovementInput({
    required this.valid,
    this.height = 0.5,
    this.flap = false,
    this.repetitions = 0,
    this.feedback = '',
  });
  final bool valid, flap;
  final double height;
  final int repetitions;
  final String feedback;
}

abstract interface class MovementInterpreter {
  MovementInput add(TrackingSample sample, double now);
  void reset();
}

/// Turns each frame into a bird height from the calibrated cue models.
///
/// Every visible cue votes with its own linear depth, weighted by its
/// calibration d′²; with three or more votes, one far from the weighted
/// median is dropped as a landmark glitch. A three-frame median and a One
/// Euro filter then smooth the fused depth, and a small margin at both ends
/// lets a naturally noisy top or bottom still reach exactly 1 or 0.
class PushUpInterpreter implements MovementInterpreter {
  PushUpInterpreter(this.calibration);
  final PushUpCalibration calibration;
  static const _margin = .06, _outlierDistance = .35;
  final _spikes = _MedianFilter();
  final _smooth = _OneEuroFilter();
  double? _height, _last, _downAt, _scaleChangedAt, _referenceArm;
  int? _side;
  bool _wasUp = false;
  int _reps = 0;
  @override
  MovementInput add(TrackingSample sample, double now) {
    final o = observeBody(
      sample,
      now,
      preferredSide: _side ?? calibration.side,
      preferredPerspective: calibration.perspective,
    );
    if (!o.valid) {
      return MovementInput(
        valid: false,
        height: _height ?? 0.5,
        repetitions: _reps,
        feedback: o.feedback,
      );
    }
    if (_last != null && sample.timestampMs <= _last!) {
      return MovementInput(
        valid: false,
        height: _height ?? 0.5,
        repetitions: _reps,
        feedback: 'Waiting for a fresh frame',
      );
    }
    _referenceArm ??= calibration.armLength > 0
        ? calibration.armLength
        : o.armLength;
    final torsoScale = o.bodyLength / calibration.bodyLength;
    final armScale = o.armLength / _referenceArm!;
    // A changing torso projection is normal. Require sustained, agreeing scale
    // changes in both torso and arm before asking for a new calibration.
    final changedScale =
        calibration.perspective == BodyPerspective.side &&
        ((torsoScale < .65 && armScale < .65) ||
            (torsoScale > 1.35 && armScale > 1.35));
    if (changedScale) {
      _scaleChangedAt ??= sample.timestampMs;
      if (sample.timestampMs - _scaleChangedAt! >= 300) {
        _downAt = null;
        _wasUp = false;
        return MovementInput(
          valid: false,
          height: _height ?? .5,
          repetitions: _reps,
          feedback: 'Camera distance changed · recalibrate',
        );
      }
    } else {
      _scaleChangedAt = null;
    }
    if (_last != null && sample.timestampMs - _last! > 500) {
      _spikes.reset();
      _smooth.reset();
      _downAt = null;
      _wasUp = false;
    }
    _side = o.side;
    final depth = _fuse(o.cues);
    if (depth == null) {
      return MovementInput(
        valid: false,
        height: _height ?? 0.5,
        repetitions: _reps,
        feedback: 'Keep an arm in view',
      );
    }
    final smoothed = _smooth.add(_spikes.add(depth), sample.timestampMs);
    _height = ((smoothed - _margin) / (1 - 2 * _margin)).clamp(0.0, 1.0);
    _last = sample.timestampMs;
    if (_height! > 0.78) {
      if (_downAt != null && sample.timestampMs - _downAt! > 300) {
        _reps++;
        _downAt = null;
      }
      _wasUp = true;
    } else if (_height! < 0.22 && _wasUp) {
      _downAt = sample.timestampMs;
      _wasUp = false;
    }
    return MovementInput(
      valid: true,
      height: _height!,
      repetitions: _reps,
      feedback: o.feedback,
    );
  }

  double? _fuse(Map<DepthCue, double> cues) {
    final votes = <({double depth, double weight})>[];
    for (final entry in cues.entries) {
      final model = _modelFor(entry.key);
      if (model == null) continue;
      votes.add((depth: model.depth(entry.value), weight: model.weight));
    }
    if (votes.isEmpty) return null;
    if (votes.length >= 3) {
      // One misplaced landmark should not drag the fused depth: with enough
      // votes, drop any that sits far from the weighted median.
      final center = _weightedMedian(votes);
      votes.removeWhere((v) => (v.depth - center).abs() > _outlierDistance);
    }
    var sum = 0.0, weight = 0.0;
    for (final v in votes) {
      sum += v.depth * v.weight;
      weight += v.weight;
    }
    return sum / weight;
  }

  CueModel? _modelFor(DepthCue cue) {
    for (final model in calibration.cues) {
      if (model.cue == cue) return model;
    }
    // Both arms bend through the same range, so a model learned from one arm
    // serves the other when it becomes the visible one.
    if (cue == DepthCue.leftElbow || cue == DepthCue.rightElbow) {
      for (final model in calibration.cues) {
        if (model.cue != DepthCue.shoulderDrop) return model;
      }
    }
    return null;
  }

  static double _weightedMedian(List<({double depth, double weight})> votes) {
    final sorted = [...votes]..sort((a, b) => a.depth.compareTo(b.depth));
    final half = sorted.fold(0.0, (sum, v) => sum + v.weight) / 2;
    var cumulative = 0.0;
    for (final v in sorted) {
      cumulative += v.weight;
      if (cumulative >= half) return v.depth;
    }
    return sorted.last.depth;
  }

  @override
  void reset() {
    _height = null;
    _last = null;
    _downAt = null;
    _wasUp = false;
    _reps = 0;
    _spikes.reset();
    _smooth.reset();
    _side = null;
    _scaleChangedAt = null;
    _referenceArm = null;
  }
}
