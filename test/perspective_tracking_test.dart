import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/tracking.dart';

List<TrackingSample> recordedSamples([String name = 'front_pushups']) {
  final fixture =
      jsonDecode(File('test/fixtures/$name.json').readAsStringSync()) as Map;
  final ids = fixture['ids'] as List;
  return (fixture['frames'] as List).map((frame) {
    final joints = List.filled(33, const Joint(0, 0, 0, 0));
    if (frame['detected'] as bool) {
      for (var i = 0; i < ids.length; i++) {
        final p = frame['joints'][i] as List;
        joints[ids[i] as int] = Joint(
          (p[0] as num).toDouble(),
          (p[1] as num).toDouble(),
          (p[2] as num).toDouble(),
          (p[3] as num).toDouble(),
        );
      }
    }
    final t = (frame['t'] as num).toDouble();
    return TrackingSample(
      mode: PlayMode.pushUp,
      timestampMs: t,
      receivedMs: t + (frame['age'] as num).toDouble(),
      joints: joints,
      detected: frame['detected'] as bool,
      aspectRatio: (fixture['aspect'] as num).toDouble(),
    );
  }).toList();
}

List<double> sorted(Iterable<double> values) => [...values]..sort();

void main() {
  test('last scored game: straight arms are the top, the deep bottom is 0', () {
    // Elbow models from this player's head-on view: ~176° stretched, ~115°
    // at the bottom. The original run locked a side view while the player
    // stood; the default perspective keeps covering that path.
    final control = PushUpInterpreter(
      const PushUpCalibration(
        cues: [
          CueModel(
            cue: DepthCue.leftElbow,
            top: 175.3,
            bottom: 118.4,
            weight: 37,
          ),
          CueModel(
            cue: DepthCue.rightElbow,
            top: 177.0,
            bottom: 111.5,
            weight: 62,
          ),
        ],
        cycleSeconds: 3,
        bodyLength: .45,
        armLength: .33,
        side: 1,
      ),
    );
    final top = <double>[], bottom = <double>[];
    var repetitions = 0;
    for (final sample in recordedSamples('last_game_top')) {
      if (sample.timestampMs < 16000) continue;
      final input = control.add(sample, sample.receivedMs);
      if (!input.valid) continue;
      repetitions = input.repetitions;
      final t = sample.timestampMs;
      // 17–24 s and 28.5 s onwards are held tops; 25.4–26 s the one deep
      // push-up's bottom.
      if (t >= 17000 && t <= 24000 || t >= 28500) top.add(input.height);
      if (t >= 25400 && t <= 26000) bottom.add(input.height);
    }
    expect(top.length, greaterThan(150));
    expect(bottom.length, greaterThan(8));
    final tops = sorted(top), bottoms = sorted(bottom);
    expect(tops[tops.length ~/ 2], 1);
    expect(tops[tops.length ~/ 10], greaterThan(.95));
    expect(tops.first, greaterThan(.85));
    expect(bottoms[bottoms.length ~/ 2], lessThan(.1));
    expect(repetitions, 1);
  });
  test('last scored game: standing up front never calibrates the plank', () {
    // Until ~15.7 s the player is upright by the phone (shoulders near the
    // top of the frame, hips at 0.8, hands hanging at the hips, both elbows
    // straight). The shipped build found a steady "top" there at 8.2 s and
    // locked a side view; the plank from 15.8 s is plainly head-on.
    final calibration = BodyCalibrator();
    var upright = 0, uprightValid = 0, plank = 0, plankValid = 0;
    for (final sample in recordedSamples('last_game_top')) {
      calibration.add(sample, sample.receivedMs);
      if (!sample.detected) continue;
      final t = sample.timestampMs;
      final valid = observeBody(sample, sample.receivedMs).valid;
      if (t >= 2900 && t <= 15700) {
        upright++;
        if (valid) uprightValid++;
        expect(
          calibration.step,
          BodyCalibrationStep.position,
          reason: '${t.round()} ms: ${calibration.feedback}',
        );
      } else if (t > 15800) {
        plank++;
        if (observeBody(
          sample,
          sample.receivedMs,
          preferredPerspective: BodyPerspective.front,
        ).valid) {
          plankValid++;
        }
      }
    }
    expect(upright, greaterThan(250));
    expect(uprightValid / upright, lessThan(.15));
    expect(plankValid, plank);
    expect(calibration.perspective, BodyPerspective.front);
    // The one deep push-up at 24.9–27.8 s is the first calibration cycle.
    expect(calibration.cycles, 1);
  });
  test('a camera moved after a tracking gap decides the view again', () {
    // One head-on push-up is learned, then the phone goes beside the
    // player. Keeping the old front view would demand both shoulders
    // forever; mixing the two views' endpoints would skew the models.
    final c = BodyCalibrator();
    for (final sample in recordedSamples()) {
      if (sample.timestampMs > 26000) break;
      c.add(sample, sample.receivedMs);
    }
    expect(c.cycles, 1);
    expect(c.perspective, BodyPerspective.front);
    for (var t = 27000.0; t <= 28500; t += 40) {
      final joints = List.filled(33, const Joint(0, 0, 0, 0));
      for (final (id, x, y) in [
        (11, .3, .5),
        (13, .3, .65),
        (15, .3, .8),
        (23, .6, .55),
      ]) {
        joints[id] = Joint(x, y, 0, 1);
      }
      c.add(
        TrackingSample(
          mode: PlayMode.pushUp,
          timestampMs: t,
          receivedMs: t,
          joints: joints,
          aspectRatio: 4 / 3,
        ),
        t,
      );
    }
    expect(c.perspective, BodyPerspective.side);
    expect(c.step, BodyCalibrationStep.lower);
    expect(c.cycles, 0);
  });
  test('stretched arms are the top throughout front-view calibration', () {
    // Fixture time is absolute; the window starts at 322788 ms. The player
    // holds a top with small wobbles (elbows never below ~150°) until the
    // first deep push-up begins at 352.9 s, after the recording's end.
    final calibration = BodyCalibrator();
    var heldChecked = 0;
    for (final sample in recordedSamples('front_extended_top')) {
      calibration.add(sample, sample.receivedMs);
      final t = sample.timestampMs;
      final observation = observeBody(
        sample,
        sample.receivedMs,
        preferredSide: calibration.side,
        preferredPerspective: calibration.perspective,
      );
      // 338.8–340.8 s: one noisy dip has passed, both arms remain extended
      // (173–178°), yet the old projected height sat 0.08 below its running
      // peak and the old calibrator kept asking to push back up.
      if (observation.valid && t >= 338800 && t <= 340800) {
        heldChecked++;
        expect(
          calibration.step,
          BodyCalibrationStep.lower,
          reason: '${t.round()} ms: ${calibration.feedback}',
        );
        expect(calibration.previewHeight, greaterThan(.9));
      }
      if (t <= 352500) {
        expect(calibration.cycles, 0, reason: '${t.round()} ms');
      }
    }
    expect(heldChecked, greaterThan(30));
    expect(calibration.result, isNull);
    expect(calibration.perspective, BodyPerspective.front);
  });
  test('a held top cannot become down during front-view calibration', () {
    final calibration = BodyCalibrator();
    var checked = 0;
    for (final sample in recordedSamples('front_calibration_hold')) {
      if (sample.timestampMs > 160900) break;
      calibration.add(sample, sample.receivedMs);
      final observation = observeBody(sample, sample.receivedMs);
      if (!observation.valid ||
          sample.timestampMs < 152500 ||
          sample.timestampMs > 155500) {
        continue;
      }
      checked++;
      // The user's reported top hold has stable extended elbows throughout,
      // while shoulder-width projection changes by enough to look like descent.
      expect(calibration.previewHeight, greaterThan(.9));
      expect(calibration.step, BodyCalibrationStep.lower);
    }
    expect(checked, greaterThan(40));
    expect(calibration.cycles, 0);
  });
  test('a model learned from one recording controls a later one', () {
    // Both front-view recordings come from the same session and placement.
    // The models learned from the first two push-ups must hold the later
    // top (where the shipped build sat mid-screen) at 1 and its bottom at 0.
    final calibration = BodyCalibrator();
    for (final sample in recordedSamples()) {
      calibration.add(sample, sample.receivedMs);
    }
    expect(calibration.result, isNotNull);
    final control = PushUpInterpreter(calibration.result!);
    final top = <double>[];
    final bottom = <double>[];
    for (final sample in recordedSamples('front_top_hold')) {
      if (sample.timestampMs < 117000) continue;
      final input = control.add(sample, sample.receivedMs);
      if (!input.valid) continue;
      if (sample.timestampMs >= 118000 && sample.timestampMs <= 121000) {
        top.add(input.height);
      }
      if (sample.timestampMs >= 122500 && sample.timestampMs <= 123500) {
        bottom.add(input.height);
      }
    }
    expect(top.length, greaterThan(40));
    expect(bottom.length, greaterThan(10));
    final tops = sorted(top), bottoms = sorted(bottom);
    // Screenshot frame-22 confirms extended arms while output sat mid-screen.
    expect(tops[tops.length ~/ 2], 1);
    expect(tops[tops.length ~/ 10], greaterThan(.95));
    expect(bottoms[bottoms.length ~/ 2], lessThan(.1));
  });
  test(
    'recorded top wobble does not count as the first calibration push-up',
    () {
      final calibration = BodyCalibrator();
      double? firstCycleAt;
      for (final sample in recordedSamples('front_top_hold')) {
        calibration.add(sample, sample.receivedMs);
        // The only real push-up starts at ~121.8 s and returns by ~124.6 s.
        if (sample.timestampMs <= 121000) {
          expect(calibration.cycles, 0, reason: '${sample.timestampMs} ms');
        }
        if (calibration.cycles == 1) firstCycleAt ??= sample.timestampMs;
      }
      expect(firstCycleAt, isNotNull, reason: calibration.feedback);
      expect(firstCycleAt, lessThan(125200));
      expect(calibration.result, isNull);
    },
  );
  test(
    'a partial movement after one full push-up does not finish calibration',
    () {
      final c = BodyCalibrator();
      for (final sample in recordedSamples()) {
        if (sample.timestampMs > 28500) break;
        c.add(sample, sample.receivedMs);
      }
      // The captured second excursion is only a small fraction of the first.
      expect(c.cycles, 1);
      expect(c.result, isNull);
    },
  );
  test(
    'a held full top reaches full bird height despite front-view projection drift',
    () {
      final samples = recordedSamples();
      final c = BodyCalibrator();
      for (final sample in samples) {
        c.add(sample, sample.receivedMs);
      }
      expect(c.result, isNotNull);
      final control = PushUpInterpreter(c.result!);
      // Use the recorded extended-arm hold and widen its image projection.
      // The arms stay extended, but shoulder-width normalization alone halves
      // the output: the symptom reported during gameplay.
      final top = samples.firstWhere(
        (s) => s.timestampMs >= 39000 && s.detected,
      );
      MovementInput? input;
      for (var t = 41000.0; t <= 42000; t += 40) {
        final shifted = TrackingSample(
          mode: PlayMode.pushUp,
          timestampMs: t,
          receivedMs: t,
          aspectRatio: top.aspectRatio,
          joints: top.joints
              .map((p) => Joint(.5 + (p.x - .5) * 1.15, p.y, p.z, p.confidence))
              .toList(),
        );
        input = control.add(shifted, t);
        expect(input.valid, isTrue, reason: input.feedback);
      }
      expect(input!.height, greaterThan(.95));
    },
  );
  test(
    'front-view signal survives camera roll, mirroring and one hidden wrist',
    () {
      final fixture =
          jsonDecode(
                File('test/fixtures/front_pushups.json').readAsStringSync(),
              )
              as Map;
      final frame = (fixture['frames'] as List).firstWhere(
        (f) => f['t'] >= 38000 && f['detected'],
      );
      final aspect = (fixture['aspect'] as num).toDouble();
      final original = List.filled(33, const Joint(0, 0, 0, 0));
      final ids = fixture['ids'] as List;
      for (var i = 0; i < ids.length; i++) {
        final p = frame['joints'][i];
        original[ids[i] as int] = Joint(
          (p[0] as num).toDouble(),
          (p[1] as num).toDouble(),
          0,
          (p[3] as num).toDouble(),
        );
      }
      double? baseline;
      for (final roll in [0, -30, 30]) {
        for (final mirror in [false, true]) {
          final angle = roll * math.pi / 180;
          final transformed = original.map((p) {
            final x = (p.x - .5) * aspect * .65, y = (p.y - .5) * .65;
            return Joint(
              .5 +
                  (mirror ? -1 : 1) *
                      (x * math.cos(angle) - y * math.sin(angle)) /
                      aspect,
              .5 + x * math.sin(angle) + y * math.cos(angle),
              0,
              p.confidence,
            );
          }).toList();
          // Either arm can supply the hand reference in a frontal view.
          final wrist = transformed[15];
          transformed[15] = Joint(wrist.x, wrist.y, 0, 0);
          final sample = TrackingSample(
            mode: PlayMode.pushUp,
            timestampMs: 0,
            receivedMs: 0,
            aspectRatio: aspect,
            joints: transformed,
          );
          final observation = observeBody(sample, 0);
          expect(observation.valid, isTrue, reason: observation.feedback);
          expect(observation.perspective, BodyPerspective.front);
          final drop = observation.cues[DepthCue.shoulderDrop]!;
          baseline ??= drop;
          expect(drop, closeTo(baseline, .0001));
          expect(observation.cues[DepthCue.rightElbow], greaterThan(150));
          transformed[11] = const Joint(.5, .5, 0, 0);
          expect(
            observeBody(
              sample,
              0,
              preferredPerspective: BodyPerspective.front,
            ).valid,
            isFalse,
          );
        }
      }
    },
  );
  test('captured front-view push-ups map a held top above a held bottom', () {
    final samples = recordedSamples();
    final calibration = BodyCalibrator();
    for (final sample in samples) {
      calibration.add(sample, sample.receivedMs);
    }
    expect(calibration.result, isNotNull);
    // Replay the actual movement as gameplay after two full calibration
    // excursions. A partial second excursion no longer unlocks play early.
    final control = PushUpInterpreter(calibration.result!);
    final topHeights = <double>[];
    final bottomHeights = <double>[];
    for (final sample in samples) {
      final input = control.add(sample, sample.receivedMs);
      if (!input.valid) continue;
      final t = sample.timestampMs;
      if (t >= 38000 && t <= 39800) topHeights.add(input.height);
      if (t >= 36000 && t <= 36600) bottomHeights.add(input.height);
    }
    expect(topHeights.length, greaterThan(10));
    expect(bottomHeights.length, greaterThan(3));
    topHeights.sort();
    bottomHeights.sort();
    expect(
      topHeights[topHeights.length ~/ 2],
      greaterThan(.95),
      reason: 'The screenshot shows a held full top',
    );
    expect(bottomHeights[bottomHeights.length ~/ 2], lessThan(.25));
  });
}
