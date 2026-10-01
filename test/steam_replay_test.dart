import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/session_replay.dart';

import 'ny_arena.dart';
import 'recorded_flight.dart';
import 'steam_bot.dart';

/// Replay and seek for the steam geysers (spec section 2, "Determinism,
/// replay"): a vent's state is a function of the route clock and the course,
/// so a recorded flight re-runs to the same vents, the same scalds and the
/// same counters, forward, after a backward seek, and from a saved tape.

LevelPlan steamPlan(int seed) => rulesPlan(
  id: '3-3',
  length: 60,
  start: 100,
  seed: seed,
  lineup: const [EnemyKind.simpleBat, EnemyKind.alleyPigeon],
  flocks: const [1, 2],
  steam: SteamPlan.steady,
  marks: const StarMarks(40, 70),
);

void main() {
  // A player who sees the hiss (clears every hop), the shared bot, which
  // ignores vents and so is scalded and rides a billow or two, and the same
  // bot on a level where the scalds end the flight.
  final pilots = <String, (int, bool Function(FlightSimulation sim))>{
    'the steam tapper': (3104, (sim) => steamTapper(sim)),
    'the shared bot': (3104, rideTheSky),
    'a bot scalded to the end': (3101, rideTheSky),
  };
  final recorded =
      <
        String,
        ({ReplayTape tape, Map<double, String> live, FlightSimulation sim})
      >{};

  setUpAll(() {
    for (final MapEntry(:key, :value) in pilots.entries) {
      recorded[key] = recordWith(
        steamPlan(value.$1),
        value.$2,
        steamSnapshot,
        seconds: 80,
      );
    }
  });

  test('the recorded flights meet vents, scalds, rides and clears', () {
    final tapper = recorded['the steam tapper']!.sim;
    final bot = recorded['the shared bot']!.sim;
    final dead = recorded['a bot scalded to the end']!.sim;
    expect(tapper.steamHisses, greaterThan(3));
    expect(tapper.steamBursts, greaterThan(3));
    expect(tapper.steamClears, greaterThan(0));
    expect(tapper.steamScalds, 0);
    expect(bot.steamScalds, greaterThan(0));
    expect(bot.steamRides, greaterThan(0));
    expect(dead.endReason, EndReason.collision);
    expect(dead.steamScalds, greaterThan(1));
  });

  for (final name in pilots.keys) {
    group(name, () {
      test('replays to every checkpoint, forward and after backward seeks', () {
        final r = recorded[name]!;
        final player = ReplayPlayer(r.tape);
        final times = r.live.keys.toList();
        expect(times.length, greaterThan(20));
        var saw = 0;
        for (final t in times) {
          player.seek(t);
          expect(steamSnapshot(player.simulation), r.live[t], reason: '$t');
          saw += player.simulation.steamVents.length;
        }
        expect(saw, greaterThan(0), reason: 'vents were on screen');
        for (final i in [
          times.length ~/ 2,
          3,
          times.length - 2,
          0,
          times.length ~/ 3,
        ]) {
          player.seek(times[i]);
          expect(
            steamSnapshot(player.simulation),
            r.live[times[i]],
            reason: 'back to ${times[i]}',
          );
        }
      });

      test('a saved tape reloads, re-encodes identically and replays', () {
        final r = recorded[name]!;
        final text = jsonEncode(r.tape.toJson());
        final loaded = ReplayTape.fromJson(
          jsonDecode(text) as Map<String, dynamic>,
        );
        expect(jsonEncode(loaded.toJson()), text);
        expect(loaded.plan!.steam.pattern, 'HR');
        final player = ReplayPlayer(loaded)..seek(loaded.durationMs);
        final end = player.simulation;
        expect(end.steamScalds, r.sim.steamScalds);
        expect(end.steamClears, r.sim.steamClears);
        expect(end.steamRides, r.sim.steamRides);
        expect(end.steamHisses, r.sim.steamHisses);
        expect(end.steamBursts, r.sim.steamBursts);
        expect(end.score, r.sim.score);
        expect(steamSnapshot(end), steamSnapshot(r.sim));
      });

      test('flying the same level again records the same flight', () {
        final again = recordWith(
          steamPlan(pilots[name]!.$1),
          pilots[name]!.$2,
          steamSnapshot,
          seconds: 80,
        );
        expect(again.live, recorded[name]!.live);
        expect(
          jsonEncode(again.tape.toJson()),
          jsonEncode(recorded[name]!.tape.toJson()),
        );
      });
    });
  }

  test('every width sees the same vents in the same states at the bird', () {
    // Position-locked: where the vent stands, it is in one state.
    final at = <double, List<String>>{};
    for (final width in [1.6, 1.78, 2.2, 2.4]) {
      final sim = arenaOf(steamPlan(3103));
      final states = <String>[];
      final seen = <int>{};
      runUntil(
        sim,
        (s) => s.phase == RunPhase.ended,
        width: width,
        holdY: .3,
        immortal: true,
        seconds: 200,
        watch: (s) {
          for (final v in s.steamVents) {
            if (v.x <= birdX && seen.add(v.geyser.slot)) {
              states.add('${v.geyser.slot} ${v.phaseAt(s.routeSeconds).name}');
            }
          }
        },
      );
      at[width] = states;
    }
    expect(at[2.2], isNotEmpty);
    for (final width in at.keys) {
      expect(at[width], at[2.2], reason: 'width $width');
    }
  });

  test('a pause and a resume change nothing about a vent', () {
    final sim = arenaOf(steamPlan(3103));
    runUntil(sim, (s) => s.steamVents.isNotEmpty, holdY: .3, immortal: true);
    final before = steamSnapshot(sim);
    sim.takeBreak();
    for (var i = 0; i < 30; i++) {
      frame(sim);
    }
    expect(steamSnapshot(sim), before);
  });
}
