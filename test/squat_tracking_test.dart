import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/squat_tracking.dart';
import 'package:push_up_bird/domain/tracking.dart';

TrackingSample squatSample(
  double time, {
  double depth = 0,
  double scale = 1,
  double shoulderBend = 0,
  double footLift = 0,
  bool detected = true,
}) {
  final joints = List.filled(33, const Joint(0, 0, 0, 0));
  for (final side in [0, 1]) {
    final x = .5 + (side == 0 ? -.1 : .1) * scale;
    double y(double value) => .9 - (.9 - value) * scale;
    joints[11 + side] = Joint(x, y(.25 + depth + shoulderBend), 0, 1);
    joints[23 + side] = Joint(x, y(.5 + depth), 0, 1);
    joints[25 + side] = Joint(x, y(.7 + depth * .2), 0, 1);
    joints[27 + side] = Joint(x, y(.9 - footLift), 0, 1);
  }
  return TrackingSample(
    mode: PlayMode.squat,
    timestampMs: time,
    receivedMs: time,
    joints: joints,
    detected: detected,
  );
}

SquatCalibration calibrateSquat({double scale = 1}) {
  final c = SquatCalibrator();
  for (var t = 0.0; t <= 2200; t += 40) {
    c.add(
      squatSample(t, scale: scale, depth: t >= 1000 && t < 1640 ? .14 : 0),
      t,
    );
  }
  expect(c.result, isNotNull);
  return c.result!;
}

void main() {
  test(
    'smooth squats calibrate and count at 15, 20 and 30 camera frames per second',
    () {
      for (final hz in [15, 20, 30]) {
        double depth(double time) {
          final cycle = time % 5000;
          if (cycle < 1200) return 0;
          if (cycle < 2200) return .14 * (cycle - 1200) / 1000;
          if (cycle < 3000) return .14;
          if (cycle < 4000) return .14 * (4000 - cycle) / 1000;
          return 0;
        }

        final calibrator = SquatCalibrator();
        for (var frame = 0; frame < hz * 5; frame++) {
          final time = frame * 1000 / hz;
          calibrator.add(squatSample(time, depth: depth(time)), time);
        }
        expect(calibrator.result, isNotNull, reason: '$hz Hz');
        final interpreter = SquatInterpreter(calibrator.result!);
        MovementInput? last;
        for (var frame = hz * 5; frame < hz * 10; frame++) {
          final time = frame * 1000 / hz;
          last = interpreter.add(squatSample(time, depth: depth(time)), time);
          expect(last.valid, isTrue);
        }
        expect(last!.repetitions, 1, reason: '$hz Hz');
        expect(last.height, 1);
      }
    },
  );

  test('learns a comfortable squat and requires standing back up', () {
    final c = SquatCalibrator();
    for (var t = 0.0; t <= 1600; t += 40) {
      c.add(squatSample(t, depth: t >= 1000 ? .14 : 0), t);
    }
    expect(c.step, SquatCalibrationStep.rise);
    expect(c.result, isNull);
    for (var t = 1640.0; t <= 2000; t += 40) {
      c.add(squatSample(t), t);
    }
    expect(c.result!.standing.hipHeight, closeTo(.4, .001));
    expect(c.result!.bottomHipHeight, closeTo(.26, .001));
    expect(c.progress, 1);
  });

  test(
    'jitter, a waist bend and one-frame spikes do not calibrate a squat',
    () {
      for (final kind in ['jitter', 'bend', 'spike']) {
        final c = SquatCalibrator();
        for (var t = 0.0; t <= 2500; t += 40) {
          final depth = kind == 'jitter'
              ? (t % 80 == 0 ? .005 : 0.0)
              : kind == 'spike' && t == 1200
              ? .14
              : 0.0;
          c.add(
            squatSample(
              t,
              depth: depth,
              shoulderBend: kind == 'bend' && t >= 1000 ? .1 : 0,
            ),
            t,
          );
        }
        expect(c.result, isNull, reason: kind);
      }
    },
  );

  test('lost, stale and duplicate frames or gaps restart range learning', () {
    for (final kind in ['missing', 'stale', 'duplicate', 'gap']) {
      final c = SquatCalibrator();
      for (var t = 0.0; t <= 1200; t += 40) {
        c.add(squatSample(t, depth: t >= 1000 ? .14 : 0), t);
      }
      switch (kind) {
        case 'missing':
          c.add(squatSample(1240, detected: false), 1240);
        case 'stale':
          c.add(squatSample(1240), 1500);
        case 'duplicate':
          c.add(squatSample(1200), 1240);
        case 'gap':
          c.add(squatSample(1600), 1600);
      }
      expect(c.step, SquatCalibrationStep.standing, reason: kind);
      expect(c.result, isNull);
    }
  });

  test('standing, half squat and full squat map to high, middle and low', () {
    for (final scale in [.65, 1.0, 1.1]) {
      final interpreter = SquatInterpreter(calibrateSquat(scale: scale));
      var time = 3000.0;
      for (final depth in [0.0, .07, .14, 0.0]) {
        MovementInput? input;
        for (var frame = 0; frame < 18; frame++) {
          time += 40;
          input = interpreter.add(
            squatSample(time, scale: scale, depth: depth),
            time,
          );
          expect(input.valid, isTrue);
          expect(input.flap, isFalse);
        }
        expect(input!.height, closeTo(1 - depth / .14, .03));
      }
    }
  });

  test(
    'counts only complete squats and holding still does not add repetitions',
    () {
      final i = SquatInterpreter(calibrateSquat());
      MovementInput? input;
      for (var t = 3000.0; t <= 6000; t += 40) {
        input = i.add(
          squatSample(t, depth: t >= 3600 && t < 4400 ? .14 : 0),
          t,
        );
      }
      expect(input!.repetitions, 1);
      i.reset();
      expect(i.add(squatSample(7000), 7000).repetitions, 0);
    },
  );

  test(
    'rejects missing joints, stale frames, lifted feet and changed distance',
    () {
      final i = SquatInterpreter(calibrateSquat());
      final hidden = squatSample(3000);
      hidden.joints[27] = const Joint(.4, .9, 0, .1);
      final invalid = squatSample(3000);
      invalid.joints[23] = const Joint(.4, double.nan, 0, 1);
      for (final s in [
        hidden,
        invalid,
        squatSample(3000, detected: false),
        squatSample(2700),
        squatSample(3020),
        squatSample(3000, scale: .7),
        squatSample(3000, footLift: .1),
      ]) {
        expect(i.add(s, 3000).valid, isFalse);
      }
    },
  );

  test('a squat interrupted by tracking loss cannot award a repetition', () {
    final i = SquatInterpreter(calibrateSquat());
    for (var t = 3000.0; t < 4400; t += 40) {
      i.add(squatSample(t, depth: t >= 3500 ? .14 : 0), t);
    }
    i.add(squatSample(4400, detected: false), 4400);
    MovementInput? input;
    for (var t = 4440.0; t < 5000; t += 40) {
      input = i.add(squatSample(t), t);
    }
    expect(input!.repetitions, 0);
  });
}
