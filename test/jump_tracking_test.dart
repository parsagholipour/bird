import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/jump_tracking.dart';
import 'package:push_up_bird/domain/tracking.dart';

TrackingSample jumpSample(
  double time, {
  double rise = 0,
  double? leftLift,
  double? rightLift,
  double? toeLift,
  double confidence = 1,
  double width = .2,
  double scale = 1,
  bool detected = true,
}) {
  final joints = List.filled(33, const Joint(0, 0, 0, 0));
  for (final side in [0, 1]) {
    final foot = side == 0 ? leftLift ?? rise : rightLift ?? rise;
    final x = .5 + (side == 0 ? -width / 2 : width / 2) * scale;
    double y(double value, double lift) =>
        .9 - (.9 - value) * scale - lift * scale;
    joints[11 + side] = Joint(x, y(.25, rise), 0, confidence);
    joints[23 + side] = Joint(x, y(.5, rise), 0, confidence);
    joints[25 + side] = Joint(x, y(.7, rise), 0, confidence);
    joints[27 + side] = Joint(x, y(.86, foot), 0, confidence);
    joints[31 + side] = Joint(x, y(.9, toeLift ?? foot), 0, confidence);
  }
  return TrackingSample(
    mode: PlayMode.jump,
    timestampMs: time,
    receivedMs: time,
    joints: joints,
    detected: detected,
  );
}

JumpCalibration calibrate({double scale = 1}) {
  final calibrator = JumpCalibrator();
  for (var time = 0.0; time <= 1000; time += 40) {
    calibrator.add(jumpSample(time, scale: scale), time);
  }
  expect(calibrator.result, isNotNull);
  return calibrator.result!;
}

void main() {
  test(
    'standing calibration needs a stable second of a visible body, not a face',
    () {
      final result = calibrate();
      expect(result.standing.bodyHeight, closeTo(.65, .001));
      final calibrator = JumpCalibrator();
      for (var time = 0.0; time <= 1800; time += 40) {
        calibrator.add(jumpSample(time, rise: (time % 200) / 2000), time);
      }
      expect(calibrator.result, isNull);
    },
  );

  test('calibration tolerates foot jitter and brief missing frames', () {
    final calibrator = JumpCalibrator();
    for (var time = 0.0; time <= 1200; time += 40) {
      final sample = jumpSample(
        time,
        rise: time % 120 == 0 ? .003 : -.003,
        leftLift: time % 80 == 0 ? .025 : -.025,
        rightLift: time % 80 == 0 ? -.025 : .025,
        detected: time != 440 && time != 880,
      );
      calibrator.add(sample, time);
    }
    expect(calibrator.result, isNotNull);
    expect(calibrator.result!.standing.hipY, closeTo(.5, .005));
  });

  test('brief duplicate frames do not throw away calibration', () {
    final calibrator = JumpCalibrator();
    for (var time = 0.0; time <= 1000; time += 40) {
      calibrator.add(jumpSample(time), time);
      if (time == 800) calibrator.add(jumpSample(time), time + 10);
    }
    expect(calibrator.result, isNotNull);
  });

  test('continuous torso motion cannot become the standing baseline', () {
    final calibrator = JumpCalibrator();
    for (var time = 0.0; time <= 3000; time += 40) {
      calibrator.add(jumpSample(time, rise: time * .00004), time);
    }
    expect(calibrator.result, isNull);
  });

  test('delayed frames ask the player to wait rather than step back', () {
    expect(observeJump(jumpSample(0), 250).feedback, 'Camera is catching up');
  });

  test('calibration restarts after sustained missing or gapped frames', () {
    for (final interruption in ['missing', 'gap']) {
      final calibrator = JumpCalibrator();
      for (var time = 0.0; time <= 800; time += 40) {
        calibrator.add(jumpSample(time), time);
      }
      switch (interruption) {
        case 'missing':
          calibrator.add(jumpSample(1200, detected: false), 1200);
        case 'gap':
          calibrator.add(jumpSample(1200), 1200);
      }
      for (var time = 1240.0; time <= 1640; time += 40) {
        calibrator.add(jumpSample(time), time);
      }
      expect(calibrator.result, isNull, reason: interruption);
    }
  });

  test('each small jump gives one flap and landing rearms the next jump', () {
    final interpreter = JumpInterpreter(calibrate());
    final flaps = <double>[];
    for (var time = 0.0; time < 1800; time += 40) {
      final rise =
          (time >= 240 && time <= 600) || (time >= 1120 && time <= 1440)
          ? .05
          : 0.0;
      final input = interpreter.add(jumpSample(time, rise: rise), time);
      expect(input.valid, isTrue);
      expect(
        input.repetitions,
        0,
        reason: 'Jumps must not become push-up repetitions',
      );
      if (input.flap) flaps.add(time);
    }
    expect(flaps, [280, 1160]);
  });

  test('thresholds scale to the person at different camera distances', () {
    for (final scale in [.6, 1.0, 1.1]) {
      final interpreter = JumpInterpreter(calibrate(scale: scale));
      var flaps = 0;
      for (var time = 0.0; time <= 480; time += 40) {
        final input = interpreter.add(
          jumpSample(time, scale: scale, rise: time >= 240 ? .05 : 0),
          time,
        );
        if (input.flap) flaps++;
      }
      expect(flaps, 1, reason: 'scale $scale');
    }
  });

  test(
    'a crouch, takeoff and landing produces one prompt boost at camera rates',
    () {
      for (final hz in [15, 20, 30]) {
        final interpreter = JumpInterpreter(calibrate());
        final flaps = <double>[];
        for (var frame = 0; frame < hz * 3; frame++) {
          final time = frame * 1000 / hz;
          final inAir = time >= 1000 && time < 1400;
          final fraction = (time - 1000) / 400;
          final rise = inAir
              ? .07 * 4 * fraction * (1 - fraction)
              : time >= 700 && time < 1000
              ? -.035
              : 0.0;
          final input = interpreter.add(
            jumpSample(
              time,
              rise: rise,
              leftLift: inAir ? rise : 0,
              rightLift: inAir ? rise : 0,
            ),
            time,
          );
          if (input.flap) flaps.add(time);
        }
        expect(flaps, hasLength(1), reason: '$hz Hz');
        expect(
          flaps.single,
          inInclusiveRange(1000, 1200),
          reason: 'Boost during takeoff, before the top of the jump',
        );
      }
    },
  );

  test('jitter, crouching and spikes do not flap', () {
    for (final kind in ['jitter', 'crouch', 'spike']) {
      final interpreter = JumpInterpreter(calibrate());
      for (var time = 0.0; time <= 1000; time += 40) {
        final moving = time >= 240;
        final sample = switch (kind) {
          'jitter' => jumpSample(
            time,
            rise: moving ? (time % 80 == 0 ? .008 : -.008) : 0,
          ),
          'crouch' => jumpSample(
            time,
            rise: moving ? -.08 : 0,
            leftLift: 0,
            rightLift: 0,
          ),
          _ => jumpSample(time, rise: time == 240 ? .08 : 0),
        };
        expect(
          interpreter.add(sample, time).flap,
          isFalse,
          reason: '$kind at $time',
        );
      }
    }
  });

  test(
    'paired torso takeoff counts when low camera feet move the wrong way',
    () {
      final interpreter = JumpInterpreter(calibrate());
      final flaps = <double>[];
      for (var time = 0.0; time <= 1600; time += 40) {
        final jumping = time >= 240 && time < 400 || time >= 800 && time < 1000;
        final input = interpreter.add(
          jumpSample(
            time,
            rise: jumping ? .028 : 0,
            leftLift: jumping ? -.025 : 0,
            rightLift: jumping ? -.015 : 0,
          ),
          time,
        );
        if (input.flap) flaps.add(time);
      }
      expect(flaps, [280, 840]);
    },
  );

  test('moving shoulders without moving hips does not flap', () {
    final interpreter = JumpInterpreter(calibrate());
    for (var time = 0.0; time <= 800; time += 40) {
      final sample = jumpSample(time, rise: time >= 240 ? .05 : 0);
      sample.joints[23] = const Joint(.4, .5, 0, 1);
      sample.joints[24] = const Joint(.6, .5, 0, 1);
      expect(interpreter.add(sample, time).flap, isFalse);
    }
  });

  test('small hops count even when the camera sees very little foot lift', () {
    final interpreter = JumpInterpreter(calibrate());
    final flaps = <double>[];
    for (var time = 0.0; time <= 600; time += 40) {
      final hopping = time >= 240 && time <= 400;
      final input = interpreter.add(
        jumpSample(
          time,
          rise: hopping ? .028 : 0,
          leftLift: hopping ? .008 : 0,
          rightLift: hopping ? .015 : 0,
        ),
        time,
      );
      if (input.flap) flaps.add(time);
    }
    expect(flaps, [280]);
  });

  test('unequal projected foot lift still detects the recorded takeoff', () {
    final interpreter = JumpInterpreter(calibrate());
    for (var time = 0.0; time <= 200; time += 40) {
      interpreter.add(jumpSample(time), time);
    }
    // Rounded, body-height-normalized motion from the phone's first missed
    // jump: hips rise clearly while the left toe barely moves in the image.
    const motion = [
      (240.0, .051, -.005, -.012),
      (273.0, .073, -.003, .038),
      (339.0, .112, .007, .065),
      (372.0, .122, .014, .064),
      (405.0, .114, .013, .061),
      (439.0, .106, .007, .049),
    ];
    var flaps = 0;
    for (final (time, rise, left, right) in motion) {
      final input = interpreter.add(
        jumpSample(
          time,
          rise: rise * .65,
          leftLift: left * .65,
          rightLift: right * .65,
        ),
        time,
      );
      if (input.flap) flaps++;
    }
    expect(flaps, 1);
  });

  for (final landingShift in [-.025, .025]) {
    test('landing at $landingShift rearms and measures the next takeoff', () {
      final interpreter = JumpInterpreter(calibrate());
      final flaps = <double>[];
      for (var time = 0.0; time <= 1400; time += 40) {
        final jumping = (time >= 240 && time <= 400) || time >= 960;
        final movedLanding = time > 400 ? landingShift : 0.0;
        final input = interpreter.add(
          jumpSample(
            time,
            rise: jumping ? .05 : 0,
            leftLift: movedLanding + (jumping ? .012 : 0),
            rightLift: movedLanding + (jumping ? .03 : 0),
          ),
          time,
        );
        if (input.flap) flaps.add(time);
      }
      expect(flaps, [280, 1000]);
    });
  }

  test(
    'a single rejected takeoff frame does not erase a confirmed landing',
    () {
      for (final interruption in ['missing', 'narrow shoulders', 'late']) {
        final interpreter = JumpInterpreter(calibrate());
        for (var time = 0.0; time <= 200; time += 40) {
          interpreter.add(jumpSample(time), time);
        }
        final bad = switch (interruption) {
          'missing' => jumpSample(240, detected: false),
          'narrow shoulders' => jumpSample(240, width: .09),
          _ => jumpSample(240),
        };
        expect(
          interpreter.add(bad, interruption == 'late' ? 450 : 240).valid,
          isFalse,
        );
        expect(
          interpreter
              .add(
                jumpSample(280, rise: .05),
                interruption == 'late' ? 460 : 280,
              )
              .flap,
          isFalse,
        );
        expect(
          interpreter
              .add(
                jumpSample(320, rise: .07),
                interruption == 'late' ? 470 : 320,
              )
              .flap,
          isTrue,
          reason: interruption,
        );
      }
    },
  );

  test(
    'invalid body, stale/future samples and camera distance changes are rejected',
    () {
      final interpreter = JumpInterpreter(calibrate());
      final hiddenFeet = jumpSample(0);
      hiddenFeet.joints[31] = const Joint(.4, .9, 0, 0);
      hiddenFeet.joints[27] = const Joint(.4, .86, 0, 0);
      final invalidCoordinate = jumpSample(0);
      invalidCoordinate.joints[11] = const Joint(double.nan, .25, 0, 1);
      for (final sample in [
        hiddenFeet,
        invalidCoordinate,
        jumpSample(0, confidence: .2),
        jumpSample(0, detected: false),
        jumpSample(-250),
        jumpSample(20),
        jumpSample(0, width: .3),
        const TrackingSample(
          mode: PlayMode.jump,
          timestampMs: 0,
          receivedMs: 0,
          joints: [],
        ),
      ]) {
        expect(interpreter.add(sample, 0).valid, isFalse);
      }
    },
  );

  test('uncertain feet do not hide a clearly tracked standing body', () {
    final sample = jumpSample(0);
    for (final id in [25, 26, 27, 28, 31, 32]) {
      final joint = sample.joints[id];
      sample.joints[id] = Joint(joint.x, joint.y, joint.z, .4);
    }
    expect(observeJump(sample, 0).valid, isTrue);
    sample.joints[31] = const Joint(.4, .9, 0, 0);
    expect(observeJump(sample, 0).valid, isTrue);
  });

  test(
    'tracking loss, gaps, reset and duplicate frames require landing again',
    () {
      for (final interruption in ['missing', 'gap', 'reset', 'duplicate']) {
        final interpreter = JumpInterpreter(calibrate());
        for (var time = 0.0; time <= 200; time += 40) {
          interpreter.add(jumpSample(time), time);
        }
        switch (interruption) {
          case 'missing':
            interpreter.add(jumpSample(240, detected: false), 240);
          case 'gap':
            break;
          case 'reset':
            interpreter.reset();
          case 'duplicate':
            interpreter.add(jumpSample(200), 240);
        }
        for (var time = 600.0; time <= 1000; time += 40) {
          expect(
            interpreter.add(jumpSample(time, rise: .08), time).flap,
            isFalse,
          );
        }
        for (var time = 1040.0; time <= 1240; time += 40) {
          interpreter.add(jumpSample(time), time);
        }
        interpreter.add(jumpSample(1280, rise: .06), 1280);
        expect(interpreter.add(jumpSample(1320, rise: .08), 1320).flap, isTrue);
      }
    },
  );
}
