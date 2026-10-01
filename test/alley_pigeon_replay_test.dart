import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/session_replay.dart';

import 'ny_arena.dart';
import 'recorded_flight.dart';

/// Replay and seek for the Alley Pigeon (spec section 2, "Determinism and
/// replay"): a recorded flight re-runs the same ticks, so every raid
/// (warning, dive, snatch, escape, spook, free, kill) is reproduced exactly,
/// forward, after a backward seek, and from a saved tape.

LevelPlan raidPlan() => rulesPlan(
  flocks: const [1, 2, 3],
  length: 50,
  marks: const StarMarks(20, 30),
  panels: .25,
);

void main() {
  // Three flights of the same level: the bot that shoots with the upgraded
  // weapon (spooks and kills), the same with the base weapon (frees stars
  // first), and one that never shoots (thefts that get away).
  final flights = <String, ({bool shoot, int damage, double width})>{
    'kills at 800': (shoot: true, damage: 30, width: 2.2),
    'frees at 640': (shoot: true, damage: 10, width: 1.78),
    'thefts at 960': (shoot: false, damage: 10, width: 2.4),
  };
  final recorded =
      <
        String,
        ({ReplayTape tape, Map<double, String> live, FlightSimulation sim})
      >{};

  setUpAll(() {
    for (final MapEntry(:key, :value) in flights.entries) {
      recorded[key] = recordWith(
        raidPlan(),
        rideTheSky,
        pigeonSnapshot,
        width: value.width,
        weaponDamage: value.damage,
        shoot: value.shoot,
        seconds: 70,
      );
    }
  });

  test('the recorded flights meet every part of the raid', () {
    var warnings = 0,
        dives = 0,
        snatched = 0,
        freed = 0,
        lost = 0,
        defeated = 0;
    for (final r in recorded.values) {
      warnings += r.sim.pigeonWarnings;
      dives += r.sim.pigeonDives;
      snatched += r.sim.starsSnatched;
      freed += r.sim.starsFreed;
      lost += r.sim.starsLost;
      defeated += r.sim.pigeonsDefeated;
    }
    expect(warnings, greaterThan(0));
    expect(dives, greaterThan(0));
    expect(snatched, greaterThan(0));
    expect(lost, greaterThan(0));
    expect(defeated, greaterThan(0));
    expect(freed, greaterThan(0));
  });

  for (final name in flights.keys) {
    group(name, () {
      test('replays to every checkpoint, forward and after backward seeks', () {
        final r = recorded[name]!;
        final player = ReplayPlayer(r.tape);
        final times = r.live.keys.toList();
        expect(times.length, greaterThan(20));
        for (final t in times) {
          player.seek(t);
          expect(pigeonSnapshot(player.simulation), r.live[t], reason: '$t');
        }
        // Backward seeks re-run the journal from the start.
        for (final i in [
          times.length ~/ 2,
          3,
          times.length - 2,
          0,
          times.length ~/ 3,
        ]) {
          player.seek(times[i]);
          expect(
            pigeonSnapshot(player.simulation),
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
        final player = ReplayPlayer(loaded)..seek(loaded.durationMs);
        final end = pigeonSnapshot(player.simulation);
        final again = ReplayPlayer(r.tape)..seek(r.tape.durationMs);
        expect(end, pigeonSnapshot(again.simulation));
        expect(player.simulation.starsSnatched, r.sim.starsSnatched);
        expect(player.simulation.starsFreed, r.sim.starsFreed);
        expect(player.simulation.starsLost, r.sim.starsLost);
        expect(player.simulation.pigeonsDefeated, r.sim.pigeonsDefeated);
      });

      test('flying the same level again records the same flight', () {
        final value = flights[name]!;
        final again = recordWith(
          raidPlan(),
          rideTheSky,
          pigeonSnapshot,
          width: value.width,
          weaponDamage: value.damage,
          shoot: value.shoot,
          seconds: 70,
        );
        expect(again.live, recorded[name]!.live);
        expect(
          jsonEncode(again.tape.toJson()),
          jsonEncode(recorded[name]!.tape.toJson()),
        );
      });
    });
  }

  test('a tape that needs rules 43 is refused at 41 and at 42', () {
    final r = recorded['kills at 800']!;
    for (final older in [41, 42]) {
      final json =
          jsonDecode(jsonEncode(r.tape.toJson())) as Map<String, dynamic>;
      json['version'] = older;
      expect(() => ReplayTape.fromJson(json), throwsFormatException);
    }
  });

  test('a raid that is run at any frame rate leaves nothing dangling', () {
    // Different frame lengths are different flights, but every one must keep
    // its books: a carried star has its thief, a reservation its pigeon.
    for (final dt in [1 / 30, 1 / 60, 1 / 120]) {
      final sim = arenaOf(raidPlan(), weaponDamage: 30);
      runUntil(
        sim,
        (s) => s.distance > 20,
        dt: dt,
        holdY: .5,
        immortal: true,
        seconds: 200,
        watch: (s) {
          for (final star in s.stars) {
            if (star.carried) {
              expect(
                s.enemies.where((e) => e.pigeon?.loot == star),
                hasLength(1),
                reason: 'dt $dt: a carried star rides on its thief',
              );
            }
            if (star.thief != null) {
              expect(s.enemies, contains(star.thief), reason: 'dt $dt');
            }
          }
        },
      );
      expect(sim.starsSnatched, greaterThan(0), reason: 'dt $dt');
    }
  });
}
