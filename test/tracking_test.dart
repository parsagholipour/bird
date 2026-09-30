import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/tracking.dart';

TrackingSample bodySample(
  double t, {
  bool down = false,
  bool faceVisible = false,
  bool standing = false,
  bool bent = false,
  double confidence = 1,
  bool hiddenFarSide = true,
}) {
  final joints = List.generate(
    33,
    (_) => Joint(.5, .5, 0, faceVisible ? 1 : 0),
  );
  // Geometrically consistent arms: both segments length .15.
  final shoulderY = down ? .65 : .5;
  final elbowX = .25 + (down ? math.sqrt(.15 * .15 - .075 * .075) : 0);
  for (final side in [0, 1]) {
    final conf = hiddenFarSide && side == 1 ? 0.0 : confidence;
    joints[11 + side] = Joint(.25, shoulderY, 0, conf);
    joints[13 + side] = Joint(elbowX, (shoulderY + .8) / 2, 0, conf);
    joints[15 + side] = Joint(.25, .8, 0, conf);
    joints[23 + side] = Joint(
      standing ? .26 : .5,
      bent ? .45 : shoulderY + (.8 - shoulderY) * .25 / .55,
      0,
      conf,
    );
    joints[25 + side] = Joint(
      standing ? .26 : .65,
      shoulderY + (.8 - shoulderY) * .4 / .55,
      0,
      conf,
    );
    joints[27 + side] = Joint(standing ? .27 : .8, .8, 0, conf);
  }
  return TrackingSample(
    mode: PlayMode.pushUp,
    timestampMs: t,
    receivedMs: t,
    joints: joints,
    aspectRatio: 1,
  );
}

// Continuous, constant-length arms with a comfortable (not locked) top.
TrackingSample movingBody(double t, double depth, {int side = 0}) {
  final sample = bodySample(t);
  final shoulderY = .5 + depth * .15;
  final halfHeight = (.8 - shoulderY) / 2;
  // At depth 0 the arm is exactly straight; rounding must not make this NaN.
  final elbowX =
      .25 + math.sqrt(math.max(0, .15 * .15 - halfHeight * halfHeight));
  for (final s in [0, 1]) {
    final confidence = s == side ? 1.0 : 0.0;
    sample.joints[11 + s] = Joint(.25, shoulderY, 0, confidence);
    sample.joints[13 + s] = Joint(elbowX, (shoulderY + .8) / 2, 0, confidence);
    sample.joints[15 + s] = Joint(.25, .8, 0, confidence);
    for (final (id, x) in [(23, .5), (25, .65), (27, .8)]) {
      sample.joints[id + s] = Joint(
        x,
        shoulderY + (.8 - shoulderY) * (x - .25) / .55,
        0,
        confidence,
      );
    }
  }
  return sample;
}

// Side view with a horizontal torso behind the shoulder. The arm keeps both
// .15 segments; [elbow] folds it and [lean] tilts the whole arm forward, which
// lowers the wrist's perpendicular distance from the torso without bending.
TrackingSample leaningBody(double t, {double lean = 0, double elbow = 180}) {
  final sample = bodySample(t);
  const wrist = (x: .25, y: .8);
  final lower = lean * math.pi / 180;
  final upper = lower + (180 - elbow) * math.pi / 180;
  final e = (
    x: wrist.x + .15 * math.sin(lower),
    y: wrist.y - .15 * math.cos(lower),
  );
  final s = (x: e.x + .15 * math.sin(upper), y: e.y - .15 * math.cos(upper));
  for (final side in [0, 1]) {
    final confidence = side == 0 ? 1.0 : 0.0;
    sample.joints[11 + side] = Joint(s.x, s.y, 0, confidence);
    sample.joints[13 + side] = Joint(e.x, e.y, 0, confidence);
    sample.joints[15 + side] = Joint(wrist.x, wrist.y, 0, confidence);
    sample.joints[23 + side] = Joint(s.x + .3, s.y, 0, confidence);
    sample.joints[25 + side] = Joint(s.x + .4, s.y, 0, confidence);
    sample.joints[27 + side] = Joint(s.x + .55, s.y, 0, confidence);
  }
  return sample;
}

/// An elbow-only model spanning [top] and [bottom] samples, as the
/// calibrator would learn from a player with one arm in view.
PushUpCalibration elbowCalibration(
  TrackingSample top,
  TrackingSample bottom, {
  double bodyLength = .28,
  double armLength = 0,
}) => PushUpCalibration(
  cues: [
    CueModel(
      cue: DepthCue.leftElbow,
      top: observeBody(top, 0).cues[DepthCue.leftElbow]!,
      bottom: observeBody(bottom, 0).cues[DepthCue.leftElbow]!,
      weight: 100,
    ),
  ],
  cycleSeconds: 3,
  bodyLength: bodyLength,
  armLength: armLength,
  side: 0,
);

PushUpCalibration comfortableCalibration() {
  final top = observeBody(movingBody(0, .22), 0);
  return elbowCalibration(
    movingBody(0, .22),
    movingBody(0, .8),
    bodyLength: top.bodyLength,
    armLength: top.armLength,
  );
}

double elbowOf(TrackingSample sample) =>
    observeBody(sample, 0).cues[DepthCue.leftElbow]!;

void main() {
  test('continuous comfortable push-ups calibrate and move the bird', () {
    final c = BodyCalibrator();
    // The projected elbow reaches only ~126 degrees at the top and ~74 at
    // the bottom. A second of settling, then two natural cycles without
    // pausing at either end.
    for (var t = 0.0; t <= 5280; t += 40) {
      final depth = t < 1200
          ? .22
          : .22 + .58 * (1 - math.cos((t - 1200) * math.pi / 1000)) / 2;
      c.add(movingBody(t, depth), t);
    }
    expect(c.result, isNotNull, reason: 'Motion was ignored: ${c.feedback}');
    expect(c.result!.topElbow, closeTo(126, 4));
    expect(c.result!.bottomElbow, closeTo(74, 6));
    final control = PushUpInterpreter(c.result!);
    final game = FlightSimulation(
      rules: PushUpFlightMode(cycleSeconds: c.result!.cycleSeconds),
      practice: true,
    );
    var input = control.add(movingBody(5000, .22), 5000);
    expect(input.valid, isTrue, reason: input.feedback);
    expect(input.height, greaterThan(.8));
    game.apply(input, movingBody(5000, .22), 5000);
    final birdAtTop = game.birdY;
    for (var t = 5040.0; t <= 5520; t += 40) {
      input = control.add(movingBody(t, .8), t);
    }
    expect(input.valid, isTrue, reason: input.feedback);
    expect(input.height, lessThan(.2));
    game.apply(input, movingBody(5520, .8), 5520);
    expect(game.birdY - birdAtTop, greaterThan(.5));
    for (var t = 5560.0; t <= 6080; t += 40) {
      input = control.add(movingBody(t, .22), t);
    }
    expect(input.repetitions, 1);
  });
  test('a forward lean with nearly straight arms is not a descent', () {
    final c = BodyCalibrator();
    // Leaning moves every projected distance while the arm stays stretched.
    // The arm angle, the only cue used to segment movement, does not care.
    expect(elbowOf(leaningBody(0, lean: 25, elbow: 171)), closeTo(171, .01));
    expect(elbowOf(leaningBody(0, lean: 30)), closeTo(180, .01));
    var time = 0.0;
    void run(double until, {double lean = 0, double elbow = 180}) {
      for (; time < until; time += 40) {
        c.add(leaningBody(time, lean: lean, elbow: elbow), time);
      }
    }

    run(2000);
    expect(c.step, BodyCalibrationStep.lower);
    // A 171-degree elbow is "9 degrees bent" against a 180-degree top: this
    // is settling, not a push-up, and must not lower the preview bird either.
    run(2400, lean: 25, elbow: 171);
    for (; time < 4000; time += 40) {
      c.add(leaningBody(time, lean: 25, elbow: 171), time);
      expect(c.step, BodyCalibrationStep.lower, reason: c.feedback);
      expect(c.previewHeight, greaterThan(.9));
    }
    expect(c.cycles, 0);
    // Real push-ups whose returns keep a forward lean still complete.
    run(4800, elbow: 90);
    expect(c.step, BodyCalibrationStep.raise);
    run(5600, lean: 30);
    expect(c.cycles, 1, reason: c.feedback);
    expect(c.previewHeight, closeTo(1, .001));
    run(6400, elbow: 90);
    run(7400, lean: 30);
    expect(c.result, isNotNull, reason: c.feedback);
    expect(c.result!.topElbow, greaterThan(172));
    expect(c.result!.bottomElbow, lessThan(100));
  });
  test('calibration tolerates frame loss, camera roll and a smaller range', () {
    for (final hz in [12, 20, 30]) {
      for (final roll in [-45, 0, 45]) {
        final c = BodyCalibrator();
        final random = math.Random(17);
        for (var frame = 0; frame <= 5.6 * hz; frame++) {
          final t = frame * 1000 / hz;
          final depth = t < 1200 || t > 5200
              ? .22
              : .22 + .38 * (1 - math.cos((t - 1200) * math.pi / 1000)) / 2;
          final original = movingBody(t, depth, side: t < 3300 ? 0 : 1);
          final radians = roll * math.pi / 180;
          final sample = TrackingSample(
            mode: PlayMode.pushUp,
            timestampMs: t,
            receivedMs: t + 100,
            aspectRatio: 16 / 9,
            detected: frame % 7 != 6,
            joints: original.joints.map((p) {
              final x = p.x - .5, y = p.y - .5;
              final jitter = (random.nextDouble() - .5) * .002;
              return Joint(
                .5 -
                    (x * math.cos(radians) - y * math.sin(radians)) / (16 / 9) +
                    jitter,
                .5 + x * math.sin(radians) + y * math.cos(radians) + jitter,
                0,
                p.confidence * .45,
              );
            }).toList(),
          );
          c.add(sample, t + 100);
        }
        expect(c.result, isNotNull, reason: '$hz Hz, $roll°: ${c.feedback}');
        expect(c.cycles, 2);
        // The side switched mid-way, so both arms were learned.
        expect(
          c.result!.cues.map((m) => m.cue),
          containsAll([DepthCue.leftElbow, DepthCue.rightElbow]),
          reason: '$hz Hz, $roll°',
        );
        expect(c.result!.topElbow! - c.result!.bottomElbow!, greaterThan(25));
      }
    }
  });
  test(
    'jitter and isolated landmark spikes neither calibrate nor count reps',
    () {
      final c = BodyCalibrator();
      final control = PushUpInterpreter(comfortableCalibration());
      final random = math.Random(7);
      for (var t = 0.0; t <= 5000; t += 40) {
        final spike = t > 200 && t % 400 == 0;
        final depth = spike ? .8 : .22 + random.nextDouble() * .02;
        final sample = movingBody(t, depth);
        c.add(sample, t);
        final input = control.add(sample, t);
        expect(input.height, greaterThan(.9));
        expect(input.repetitions, 0);
      }
      expect(c.cycles, 0);
      expect(c.result, isNull);
    },
  );
  test('duplicate and out-of-order frames cannot advance calibration', () {
    final c = BodyCalibrator();
    c.add(movingBody(0, .22), 0);
    for (var now = 20.0; now <= 200; now += 20) {
      c.add(movingBody(0, .22), now);
      c.add(movingBody(-1, .22), now);
    }
    expect(c.step, BodyCalibrationStep.position);
    expect(c.cycles, 0);
  });
  test('tracking gaps cannot complete a partly observed push-up', () {
    final c = BodyCalibrator();
    final control = PushUpInterpreter(comfortableCalibration());
    for (var t = 0.0; t <= 2000; t += 40) {
      final sample = movingBody(t, t < 1200 ? .22 : .8);
      c.add(sample, t);
      control.add(sample, t);
    }
    expect(c.step, BodyCalibrationStep.raise);
    for (var t = 2800.0; t <= 3600; t += 40) {
      final sample = movingBody(t, .22);
      c.add(sample, t);
      expect(control.add(sample, t).repetitions, 0);
    }
    expect(c.cycles, 0);
  });
  test('a sustained change in arm and torso scale requests recalibration', () {
    final control = PushUpInterpreter(comfortableCalibration());
    control.add(movingBody(0, .22), 0);
    var input = const MovementInput(valid: false);
    for (var t = 40.0; t <= 600; t += 40) {
      final original = movingBody(t, .22);
      final sample = TrackingSample(
        mode: PlayMode.pushUp,
        timestampMs: t,
        receivedMs: t,
        aspectRatio: 1,
        joints: original.joints
            .map(
              (p) => Joint(
                .5 + (p.x - .5) * .55,
                .5 + (p.y - .5) * .55,
                0,
                p.confidence,
              ),
            )
            .toList(),
      );
      input = control.add(sample, t);
    }
    expect(input.valid, isFalse);
    expect(input.feedback, contains('recalibrate'));
  });
  test('real height changes reach the bird within 160ms of input', () {
    final control = PushUpInterpreter(comfortableCalibration());
    for (var t = 0.0; t <= 400; t += 40) {
      control.add(movingBody(t, .22), t);
    }
    var input = const MovementInput(valid: false);
    for (var t = 440.0; t <= 560; t += 40) {
      input = control.add(movingBody(t, .8), t);
    }
    expect(input.height, lessThan(.1));
  });
  test('bird keeps following when the calibrated side becomes hidden', () {
    // Only the left arm was learned; the right arm reuses its model.
    final control = PushUpInterpreter(
      elbowCalibration(movingBody(0, 0), movingBody(0, 1)),
    );
    control.add(movingBody(0, 0), 0);
    var input = const MovementInput(valid: false);
    for (var t = 40.0; t <= 600; t += 40) {
      input = control.add(movingBody(t, 1, side: 1), t);
    }
    expect(input.valid, isTrue, reason: input.feedback);
    expect(input.height, lessThan(.1));
  });
  test('torso foreshortening alone does not freeze bird control', () {
    final top = observeBody(movingBody(0, 0), 0);
    final control = PushUpInterpreter(
      elbowCalibration(
        movingBody(0, 0),
        movingBody(0, 1),
        bodyLength: top.bodyLength,
      ),
    );
    control.add(movingBody(0, 0), 0);
    var input = const MovementInput(valid: false);
    for (var t = 40.0; t <= 600; t += 40) {
      final sample = movingBody(t, 1);
      // The torso projects shorter as the body turns slightly; arms remain
      // tracked at the same scale and still bend all the way.
      final hip = sample.joints[23];
      sample.joints[23] = Joint(.40, .65 + (hip.y - .65) * .6, 0, 1);
      input = control.add(sample, t);
    }
    expect(input.valid, isTrue, reason: input.feedback);
    expect(input.height, lessThan(.1));
  });
  test(
    'an angled phone accepts the same push-up without a horizontal torso',
    () {
      for (final down in [false, true]) {
        final original = bodySample(0, down: down);
        final radians = 45 * math.pi / 180;
        final rotated = TrackingSample(
          mode: PlayMode.pushUp,
          timestampMs: 0,
          receivedMs: 0,
          aspectRatio: 1,
          joints: original.joints.map((p) {
            final x = p.x - .5, y = p.y - .5;
            return Joint(
              .5 + x * math.cos(radians) - y * math.sin(radians),
              .5 + x * math.sin(radians) + y * math.cos(radians),
              p.z,
              p.confidence,
            );
          }).toList(),
        );
        final observation = observeBody(rotated, 0);
        expect(observation.valid, isTrue, reason: observation.feedback);
        final reference = observeBody(original, 0);
        expect(observation.elbow, closeTo(reference.elbow, .0001));
        expect(observation.cues.keys, reference.cues.keys);
        for (final cue in reference.cues.keys) {
          expect(observation.cues[cue], closeTo(reference.cues[cue]!, .0001));
        }
      }
    },
  );
  test('an elbow folded past a push-up range is a misplaced landmark', () {
    // The tracked arm keeps its cue; a second arm folded to 40° contributes
    // none, so it cannot pull the fused depth down.
    final sample = bodySample(0, hiddenFarSide: false);
    sample.joints[16] = const Joint(.35, .55, 0, 1);
    final observation = observeBody(sample, 0);
    expect(observation.valid, isTrue, reason: observation.feedback);
    expect(observation.cues.containsKey(DepthCue.leftElbow), isTrue);
    expect(observation.cues.containsKey(DepthCue.rightElbow), isFalse);
    expect(observation.elbow, closeTo(180, .01));
  });
  test('when the arms disagree, the straighter one segments movement', () {
    final sample = bodySample(0, hiddenFarSide: false);
    // Right arm reads 100° while the left stays stretched: one misplaced
    // elbow, not a one-armed push-up.
    sample.joints[14] = Joint(
      .25 + .15 * math.sin(40 * math.pi / 180),
      .8 - .15 * math.cos(40 * math.pi / 180),
      0,
      1,
    );
    final observation = observeBody(sample, 0);
    expect(observation.valid, isTrue, reason: observation.feedback);
    expect(observation.cues[DepthCue.rightElbow], lessThan(120));
    expect(observation.elbow, closeTo(180, .01));
  });
  test('an upright body with hanging arms is not in push-up position', () {
    // Facing the camera, arms straight and slightly away from the body, as
    // recorded while the player knelt by the phone. Legs are out of view,
    // so only the arms and torso can tell this from a straight-armed top.
    TrackingSample upright(double roll) {
      final radians = roll * math.pi / 180;
      final joints = List.generate(33, (_) => const Joint(.5, .5, 0, 0));
      void put(int id, double x, double y) {
        final dx = x - .5, dy = y - .5;
        joints[id] = Joint(
          .5 + dx * math.cos(radians) - dy * math.sin(radians),
          .5 + dx * math.sin(radians) + dy * math.cos(radians),
          0,
          1,
        );
      }

      for (final (side, sign) in [(0, -1), (1, 1)]) {
        put(11 + side, .5 + sign * .1, .2);
        put(13 + side, .5 + sign * .175, .375);
        put(15 + side, .5 + sign * .25, .55);
        put(23 + side, .5 + sign * .07, .6);
      }
      return TrackingSample(
        mode: PlayMode.pushUp,
        timestampMs: 0,
        receivedMs: 0,
        joints: joints,
        aspectRatio: 1,
      );
    }

    for (final roll in [-45.0, 0.0, 45.0]) {
      for (final view in [null, ...BodyPerspective.values]) {
        final o = observeBody(upright(roll), 0, preferredPerspective: view);
        expect(o.valid, isFalse, reason: '$roll° $view');
      }
      final o = observeBody(upright(roll), 0);
      expect(o.feedback, contains('push-up position'), reason: '$roll°');
    }
    // Holding that pose never becomes a calibration top.
    final c = BodyCalibrator();
    for (var t = 0.0; t <= 3000; t += 40) {
      final sample = upright(0);
      c.add(
        TrackingSample(
          mode: PlayMode.pushUp,
          timestampMs: t,
          receivedMs: t,
          joints: sample.joints,
          aspectRatio: 1,
        ),
        t,
      );
    }
    expect(c.step, BodyCalibrationStep.position);
    expect(c.perspective, isNull);
  });
  test('a deep side-view bottom with the hands under the chest is valid', () {
    // The arm is only ~41° from the torso, as close as an upright body's,
    // but the hands sit a third of a torso behind the shoulder rather than
    // down by the hips.
    final joints = List.generate(33, (_) => const Joint(.5, .5, 0, 0));
    joints[11] = const Joint(.3, .62, 0, 1);
    joints[13] = const Joint(.4, .62, 0, 1);
    joints[15] = const Joint(.4, .72, 0, 1);
    joints[23] = const Joint(.6, .64, 0, 1);
    final o = observeBody(
      TrackingSample(
        mode: PlayMode.pushUp,
        timestampMs: 0,
        receivedMs: 0,
        joints: joints,
        aspectRatio: 1,
      ),
      0,
    );
    expect(o.valid, isTrue, reason: o.feedback);
    expect(o.perspective, BodyPerspective.side);
  });
  test('looking down and one fully visible body side are valid', () {
    expect(observeBody(bodySample(0), 0).valid, isTrue);
    expect(observeBody(bodySample(0, down: true), 0).valid, isTrue);
    expect(observeBody(bodySample(0, confidence: .45), 0).valid, isTrue);
  });
  test(
    'standing, crouching, partial joints, low confidence and stale frames are rejected',
    () {
      expect(observeBody(bodySample(0, standing: true), 0).valid, isFalse);
      expect(observeBody(bodySample(0, bent: true), 0).valid, isFalse);
      expect(observeBody(bodySample(0, confidence: .2), 0).valid, isFalse);
      expect(observeBody(bodySample(0), 201).valid, isFalse);
      expect(observeBody(bodySample(100), 0).valid, isFalse);
      final partial = bodySample(0);
      partial.joints[27] = const Joint(1.1, .8, 0, 1);
      expect(observeBody(partial, 0).valid, isTrue);
      partial.joints[15] = const Joint(.25, .8, 0, .1);
      expect(observeBody(partial, 0).valid, isFalse);
    },
  );
  test(
    'two complete down/up movements produce a measured range and cadence',
    () {
      final c = BodyCalibrator();
      var time = 0.0;
      void hold(bool down, {int frames = 20}) {
        for (var i = 0; i < frames; i++) {
          c.add(bodySample(time, down: down), time);
          time += 40;
        }
      }

      hold(false, frames: 25);
      hold(true);
      hold(false);
      hold(true);
      hold(false);
      expect(c.cycles, 2);
      expect(c.result, isNotNull);
      expect(c.result!.topElbow, closeTo(180, 1));
      expect(c.result!.bottomElbow, closeTo(60, 1));
      expect(c.result!.cycleSeconds, greaterThanOrEqualTo(2));
    },
  );
  test('a quick bounce or a shallow dip is not a calibration push-up', () {
    final c = BodyCalibrator();
    var time = 0.0;
    void hold(TrackingSample Function(double) sample, int frames) {
      for (var i = 0; i < frames; i++) {
        c.add(sample(time), time);
        time += 40;
      }
    }

    hold((t) => bodySample(t), 25);
    expect(c.step, BodyCalibrationStep.lower);
    // 160 ms at the bottom: a bounce, not a controlled push-up.
    hold((t) => bodySample(t, down: true), 4);
    hold((t) => bodySample(t), 20);
    expect(c.cycles, 0);
    expect(c.step, BodyCalibrationStep.lower);
    // A 20° dip is settling, not a push-up, however long it lasts.
    hold((t) => leaningBody(t, elbow: 160), 25);
    hold((t) => leaningBody(t), 20);
    expect(c.cycles, 0);
    expect(c.feedback, contains('Lower a little more'));
    // A real one still completes the first cycle afterwards.
    hold((t) => bodySample(t, down: true), 20);
    hold((t) => bodySample(t), 20);
    expect(c.cycles, 1, reason: c.feedback);
  });
  test('height maps continuously and repetition requires up/down/up', () {
    final control = PushUpInterpreter(
      elbowCalibration(bodySample(0), bodySample(0, down: true)),
    );
    var time = 0.0;
    MovementInput? input;
    void hold(bool down) {
      for (var i = 0; i < 15; i++) {
        input = control.add(bodySample(time, down: down), time);
        time += 40;
      }
    }

    hold(false);
    expect(input!.height, closeTo(1, .02));
    hold(true);
    expect(input!.height, closeTo(0, .02));
    expect(input!.repetitions, 0);
    hold(false);
    expect(input!.repetitions, 1);
    hold(false);
    expect(input!.repetitions, 1);
  });
}
