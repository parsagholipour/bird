import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/campaign.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/session_replay.dart';
import 'package:push_up_bird/domain/tracking.dart';

import 'built_pilot.dart';
import 'endless_plan_baseline_test.dart' show stateOf;

ReplayTape reload(ReplayTape tape) => ReplayTape.fromJson(
  jsonDecode(jsonEncode(tape.toJson())) as Map<String, dynamic>,
);

({EndReason? reason, int rating, String state}) outcome(FlightSimulation sim) =>
    (reason: sim.endReason, rating: sim.levelStars, state: stateOf(sim));

void main() {
  test('a built level replays from its saved tape exactly, in every mode', () {
    for (final mode in PlayMode.values) {
      final plan = sampleLevel(mode, pace: BuiltPace.steady);
      final (:tape, :simulation) = recordBuilt(plan, cycle: 5);
      final flown = outcome(simulation);
      expect(flown.reason, EndReason.completed, reason: mode.name);

      final json = tape.toJson();
      expect(json['level'], plan.id);
      expect(json.containsKey('plan'), isFalse);
      final saved = reload(tape);
      expect(saved.levelId, plan.id);
      expect(saved.plan, isNull);
      expect(saved.built!.toJson(), plan.toJson());
      final player = ReplayPlayer(saved);
      expect(player.simulation.levelId, plan.id);
      expect(player.simulation.region, plan.region);
      player.seek(saved.durationMs);
      expect(outcome(player.simulation), flown, reason: mode.name);
      player.seek(saved.durationMs / 2);
      expect(player.simulation.phase, isNot(RunPhase.ended), reason: mode.name);
      player.seek(saved.durationMs);
      expect(outcome(player.simulation), flown, reason: mode.name);
    }
  });

  test('the tape seed changes nothing on a built level', () {
    final plan = sampleLevel(PlayMode.touch);
    final (:tape, :simulation) = recordBuilt(plan);
    final json = tape.toJson()..['seed'] = 999;
    final other = ReplayTape.fromJson(
      jsonDecode(jsonEncode(json)) as Map<String, dynamic>,
    );
    final player = ReplayPlayer(other)..seek(other.durationMs);
    expect(outcome(player.simulation), outcome(simulation));
  });

  test('a tape refuses a built level it cannot fly', () {
    final plan = sampleLevel(PlayMode.squat);
    final (:tape, simulation: _) = recordBuilt(plan, seconds: 5);
    Map<String, dynamic> json() =>
        jsonDecode(jsonEncode(tape.toJson())) as Map<String, dynamic>;
    expect(ReplayTape.fromJson(json()).built!.id, plan.id);
    final broken = <String, void Function(Map<String, dynamic>)>{
      'another mode': (j) => j['mode'] = 'pushUp',
      'classic': (j) => j['course'] = 'classic',
      'another id': (j) => j['level'] = 'u-someoneelse',
      'no level': (j) => j.remove('level'),
      'campaign plan too': (j) =>
          j['plan'] = Campaign.level('1-1')!.plan.toJson(),
      'older rules': (j) => j['version'] = 63,
      'a partner': (j) => j['partner'] = 1,
      'broken plan': (j) => (j['built'] as Map)['finish'] = 10,
    };
    for (final MapEntry(:key, :value) in broken.entries) {
      final copy = json();
      value(copy);
      expect(
        () => ReplayTape.fromJson(copy),
        throwsFormatException,
        reason: key,
      );
    }
  });

  test('older tapes never read a built level', () {
    // A rules 63 tape names no built level, whatever it carries.
    final endless = ReplayTape(
      mode: PlayMode.touch,
      practice: true,
      seed: 3,
      cycleSeconds: 3,
      bird: 0,
      reducedMotion: false,
      originMs: 0,
      course: FlightCourse.starTrail,
      recordedVersion: 63,
    );
    final json =
        jsonDecode(jsonEncode(endless.toJson())) as Map<String, dynamic>
          ..['built'] = sampleLevel(PlayMode.touch).toJson();
    final read = ReplayTape.fromJson(json);
    expect(read.built, isNull);
    expect(read.levelId, isNull);
  });
}
