import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/session_replay.dart';
import 'package:push_up_bird/domain/tracking.dart';
import 'package:push_up_bird/game/play_controller.dart';
import 'package:push_up_bird/tracking/native_tracking_source.dart';
import 'package:push_up_bird/tracking/tracking_api.g.dart';
import 'jump_tracking_test.dart' show jumpSample;
import 'play_session_test.dart' show SessionSource, SilentAudio;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'native camera uses pose detection and labels packets with the active mode',
    () async {
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      final calls = <List<Object?>>[];
      for (final method in ['monotonicTimeMs', 'start', 'stop']) {
        final channel = BasicMessageChannel<Object?>(
          'dev.flutter.pigeon.push_up_bird.TrackingHostApi.$method',
          TrackingHostApi.pigeonChannelCodec,
        );
        messenger.setMockDecodedMessageHandler<Object?>(channel, (
          message,
        ) async {
          if (method == 'start') {
            calls.add(List<Object?>.from(message! as List));
          }
          return [method == 'monotonicTimeMs' ? 0 : null];
        });
        addTearDown(
          () => messenger.setMockDecodedMessageHandler<Object?>(channel, null),
        );
      }
      final source = NativeTrackingSource();
      final samples = <TrackingSample>[];
      final subscription = source.samples.listen(samples.add);
      addTearDown(subscription.cancel);
      addTearDown(source.dispose);
      TrackingPacket packet(int session, DetectorKind detector) =>
          TrackingPacket(
            session: session,
            detector: detector,
            capturedAtMs: 0,
            sentAtMs: 0,
            inferenceMs: 10,
            imageWidth: 640,
            imageHeight: 480,
            landmarks: [],
            smile: 1,
            detected: true,
            sensorTimestamp: true,
          );
      await source.start(PlayMode.jump);
      expect(calls.single.first, DetectorKind.pose);
      final jumpSession = calls.single[2] as int;
      source.onSample(packet(jumpSession, DetectorKind.face));
      expect(samples, isEmpty);
      source.onSample(packet(jumpSession, DetectorKind.pose));
      expect(samples.single.mode, PlayMode.jump);
      await source.start(PlayMode.pushUp);
      final bodySession = calls.last[2] as int;
      source.onSample(packet(jumpSession, DetectorKind.pose));
      expect(samples.length, 1);
      source.onSample(packet(bodySession, DetectorKind.pose));
      expect(samples.last.mode, PlayMode.pushUp);
      await source.stop();
      source.onSample(packet(bodySession, DetectorKind.pose));
      expect(samples.length, 2);
    },
  );

  test(
    'standing calibration starts a jump flight and one jump boosts the bird once',
    () async {
      final source = SessionSource();
      final controller = PlayController(
        mode: PlayMode.jump,
        practice: true,
        source: source,
        audio: SilentAudio(),
        saveRun: (_) async {},
        saveSession: (_) async {},
      );
      addTearDown(controller.dispose);
      await controller.startCamera();
      for (var time = 1000.0; time <= 2080; time += 40) {
        source.time = time;
        source.sampleStream.add(jumpSample(time));
        await Future<void>.delayed(Duration.zero);
      }
      expect(controller.stage, PlayStage.flying);
      expect(controller.simulation!.rules, isA<JumpFlyMode>());
      for (var time = 2120.0; time <= 5200; time += 40) {
        source.time = time;
        source.sampleStream.add(jumpSample(time));
        controller.advance(.04, time, 2.2);
      }
      expect(controller.simulation!.phase, RunPhase.playing);
      for (var time = 5240.0; time <= 5440; time += 40) {
        source.time = time;
        source.sampleStream.add(
          jumpSample(time, rise: .028, leftLift: .008, rightLift: .015),
        );
      }
      expect(controller.simulation!.flaps, 1);
      expect(controller.simulation!.velocity, -.55);
      expect(controller.simulation!.repetitions, 0);
    },
  );

  test(
    'physical jumps have about three times the height and twice the airtime',
    () {
      double measuredRise(GameMode rules) {
        final simulation = FlightSimulation(rules: rules, practice: true)
          ..phase = RunPhase.playing;
        var highest = simulation.birdY;
        for (var frame = 0; frame < 120; frame++) {
          final time = frame * 1000 / 120;
          simulation.apply(
            MovementInput(valid: true, flap: frame == 0),
            TrackingSample(
              mode: rules.mode,
              timestampMs: time,
              receivedMs: time,
              joints: [],
            ),
            time,
          );
          simulation.tick(1 / 120, time);
          if (simulation.birdY < highest) highest = simulation.birdY;
        }
        return .5 - highest;
      }

      final jump = JumpFlyMode(), old = LegacyFlapMode();
      expect(measuredRise(jump), greaterThan(measuredRise(old) * 2.8));
      final airtime = -2 * jump.flapImpulse / jump.gravity;
      expect(airtime, greaterThan(-2 * old.flapImpulse / old.gravity * 2));
      expect(jump.intervalFor(0), greaterThan(old.intervalFor(0)));
    },
  );

  test(
    'old smile journals keep their physics and new jump journals round-trip',
    () {
      final current = ReplayTape(
        mode: PlayMode.jump,
        practice: true,
        seed: 1,
        cycleSeconds: 3,
        bird: 0,
        reducedMotion: false,
        originMs: 0,
      );
      final oldJson = current.toJson()
        ..['version'] = 7
        ..['mode'] = 'smile'
        ..['events'] = [
          [0, 'input', 0, 0, 'smile', true, .5, false, 0, ''],
        ];
      final old = ReplayTape.fromJson(oldJson);
      expect(old.mode, PlayMode.jump);
      expect(old.createSimulation().rules.gravity, .85);
      expect(old.createSimulation().rules.flapImpulse, -.40);
      final player = ReplayPlayer(old);
      player.seek(0);
      expect(player.simulation.hasTracking, isTrue);
      final restored = ReplayTape.fromJson(current.toJson());
      expect(restored.createSimulation().rules, isA<JumpFlyMode>());
      expect(restored.mode.name, 'jump');
      expect(
        PlayMode.jump.index,
        1,
        reason: 'Existing saved records keep their mode slot',
      );
      expect(PlayMode.touch.index, 2);
    },
  );
}
