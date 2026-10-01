import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/campaign.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/session_replay.dart';
import 'package:push_up_bird/domain/tracking.dart';
import 'package:push_up_bird/game/flight_voice_director.dart';
import 'package:push_up_bird/game/flight_voices.dart';
import 'recorded_flight.dart' show rideTheSky;

/// Flies the seeded autopilot through [level] (or five minutes of endless
/// Tap & Fly), sprinting whenever it can, and lists the clips said.
List<String> fly(
  CampaignLevel? level,
  FlightVoiceMemory memory,
  int seed, {
  double talk = FlightVoiceDirector.talkativeness,
}) {
  var now = 0.0;
  final recorder = FlightRecorder(
    ReplayTape(
      mode: PlayMode.touch,
      course: FlightCourse.starTrail,
      practice: level == null,
      seed: 7,
      cycleSeconds: 3,
      bird: seed % 4,
      reducedMotion: false,
      originMs: 0,
      weaponDamage: 60,
      plan: level?.plan,
    ),
    () => now,
  );
  final sim = recorder.simulation;
  final voices = FlightVoices(
    talk: talk,
    bird: seed % 4,
    mode: PlayMode.touch,
    level: level,
    memory: memory,
    random: Random(seed),
  );
  voices.update(sim, mute: true);
  final said = <String>[];
  for (var frame = 1; frame <= 6000; frame++) {
    now = frame * 50.0;
    recorder.apply(
      MovementInput(valid: true, flap: rideTheSky(sim)),
      TrackingSample(
        mode: PlayMode.touch,
        timestampMs: now,
        receivedMs: now,
        joints: const [],
      ),
      now,
    );
    if (sim.canShoot && (sim.boss != null || sim.enemies.isNotEmpty)) {
      recorder.command('shoot');
    }
    if (sim.canSprint) recorder.command('sprint');
    recorder.tick(.05, now, 2.2);
    final line = voices.update(sim);
    if (line != null) said.add(line.clip.name);
    if (sim.phase == RunPhase.ended) break;
  }
  return said;
}

void main() {
  test('a busy endless flight talks in moderation and never repeats', () {
    final memory = FlightVoiceMemory();
    final said = fly(null, memory, 2);
    // Five minutes with five bosses, five rushes and a gale.
    expect(said.length, inInclusiveRange(8, 30));
    // Each clip's pool (the story's sprint calls are named their own way).
    final bank = FlightVoices.recorded;
    final poolOf = {
      for (final pool in bank.pools)
        for (final clip in bank[pool]) clip.name: pool,
    };
    final moments = said.map((name) => poolOf[name]).toSet();
    expect(moments.length, greaterThanOrEqualTo(6));
    for (var i = 0; i < said.length; i++) {
      final next = said.indexOf(said[i], i + 1);
      if (next < 0) continue;
      final size = bank[poolOf[said[i]]!].length;
      expect(
        next - i,
        greaterThanOrEqualTo(FlightVoiceDirector.rest(size)),
        reason: '${said[i]} came back too soon',
      );
    }
  });

  test('the characters talk half as much as the first tuning did', () {
    // Endless and five campaign levels, four birds: every kind of line can
    // still be said, but about half as many are.
    var full = 0, shipped = 0;
    for (final seed in [1, 2, 3, 4]) {
      for (final level in [
        null,
        for (final id in ['1-2', '2-3', '3-4', '4-2', '5-8'])
          Campaign.levels.firstWhere((l) => l.id == id),
      ]) {
        full += fly(level, FlightVoiceMemory(), seed, talk: 1).length;
        shipped += fly(level, FlightVoiceMemory(), seed).length;
      }
    }
    expect(shipped / full, closeTo(.5, .06));
  });

  test('the next flights carry on where the last left off', () {
    final memory = FlightVoiceMemory();
    final level = Campaign.levels.firstWhere((l) => l.id == '2-3');
    final first = fly(level, memory, 1);
    final second = fly(level, memory, 1);
    expect(first, isNotEmpty);
    // The same bird, route and dice: yet no line of the first flight opens
    // the second.
    expect(second.first, isNot(first.first));
    expect(
      second.toSet().intersection(first.toSet()).length,
      lessThan(first.length ~/ 2),
    );
  });
}
