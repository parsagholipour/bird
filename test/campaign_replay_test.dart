import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/campaign.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/session_replay.dart';
import 'package:push_up_bird/domain/tracking.dart';

import 'campaign_flight.dart';
import 'endless_plan_baseline_test.dart' show stateOf;
import 'recorded_flight.dart';

CampaignLevel level(String id) => Campaign.level(id)!;

ReplayTape reload(ReplayTape tape) => ReplayTape.fromJson(
  jsonDecode(jsonEncode(tape.toJson())) as Map<String, dynamic>,
);

({int score, int stars, EndReason? reason, int rating, String state}) outcome(
  FlightSimulation sim,
) => (
  score: sim.score,
  stars: sim.collectedStars,
  reason: sim.endReason,
  rating: sim.levelStars,
  state: stateOf(sim),
);

void main() {
  test('a campaign session replays from its saved tape exactly', () {
    for (final id in ['1-5', '2-3', '2-8']) {
      final (:tape, :simulation) = recordLevel(level(id));
      final flown = outcome(simulation);
      expect(flown.reason, EndReason.completed, reason: id);
      expect(flown.rating, greaterThan(0), reason: id);

      final saved = reload(tape);
      expect(saved.levelId, id);
      expect(saved.plan!.toJson(), level(id).plan.toJson());
      final player = ReplayPlayer(saved);
      expect(player.simulation.levelId, id);
      expect(player.simulation.region, level(id).region);
      player.seek(saved.durationMs);
      expect(outcome(player.simulation), flown, reason: id);
      // A backward seek reruns the journal from the start.
      player.seek(saved.durationMs / 3);
      expect(player.simulation.phase, isNot(RunPhase.ended), reason: id);
      player.seek(saved.durationMs);
      expect(outcome(player.simulation), flown, reason: id);
    }
  });

  test('a victory glide replays and seeks exactly, whatever was tapped', () {
    for (final id in ['1-8', '2-8']) {
      // The player keeps tapping once the boss falls; the glide ignores it.
      final (:tape, :simulation) = recordLevel(
        level(id),
        tapWhen: (sim) => sim.bossesDefeated > 0 || rideTheSky(sim),
      );
      final flown = outcome(simulation);
      expect(flown.reason, EndReason.completed, reason: id);
      expect(flown.rating, greaterThan(0), reason: id);

      final saved = reload(tape);
      final player = ReplayPlayer(saved)..seek(saved.durationMs);
      expect(outcome(player.simulation), flown, reason: id);
      // Back into the glide, a second before the line, then on to the end.
      player.seek(saved.durationMs - 1000);
      final glide = player.simulation;
      expect(glide.phase, RunPhase.playing, reason: id);
      expect(glide.victoryGlide, isTrue, reason: id);
      expect(glide.boss, isNull, reason: id);
      expect(glide.finishLine, isNotNull, reason: id);
      player.seek(saved.durationMs);
      expect(outcome(player.simulation), flown, reason: id);
    }
  });

  test('a replay flies the plan it was recorded with, not the catalog', () {
    final current = level('1-1').plan;
    final retuned = LevelPlan(
      id: current.id,
      region: current.region,
      length: 45,
      start: 30,
      seed: 99,
      families: current.families,
      shoot: false,
      sprint: false,
      marks: const StarMarks(20, 40),
    );
    final tape = reload(recordLevel(level('1-1'), plan: retuned).tape);
    expect(tape.plan!.length, 45);
    final player = ReplayPlayer(tape)..seek(tape.durationMs);
    final sim = player.simulation;
    expect(sim.endReason, EndReason.completed);
    expect(sim.routeSeconds, closeTo(45, .05));
    expect(
      sim.starsLaid,
      retuned
          .route(
            baseSpeed: TapFlyMode().speedFor(0) * .9,
            interval: sim.spawnInterval,
          )
          .stars,
    );
    expect(
      sim.levelStars,
      retuned.rate(finished: true, stars: sim.collectedStars),
    );
  });

  test('only campaign tapes from rules 41 carry a level and its plan', () {
    final campaign = recordLevel(level('1-2'), seconds: 5).tape.toJson();
    // A new recording carries the newest rules version (43, New York); the
    // frozen rules 41 tapes (frozen_rules41_test) pin the 41 format.
    expect(campaign['version'], FlightSimulation.currentRulesVersion);
    expect(campaign['level'], '1-2');
    expect(campaign['plan'], isA<Map<String, Object?>>());
    final endless = recordFlight(PlayMode.touch).toJson();
    expect(endless.containsKey('level'), isFalse);
    expect(endless.containsKey('plan'), isFalse);
    expect(ReplayTape.fromJson(endless).plan, isNull);
  });

  test('tapes from before rules 41 still load and replay', () {
    for (final version in [1, 7, 26, 33, 40]) {
      final tape = recordFlight(PlayMode.touch, version: version);
      final json =
          jsonDecode(jsonEncode(tape.toJson())) as Map<String, dynamic>;
      expect(json.containsKey('plan'), isFalse);
      final saved = ReplayTape.fromJson(json);
      expect(saved.levelId, isNull);
      final a = ReplayPlayer(tape)..seek(tape.durationMs);
      final b = ReplayPlayer(saved)..seek(saved.durationMs);
      expect(stateOf(b.simulation), stateOf(a.simulation), reason: '$version');
      // An old tape ignores a stray plan, the way it ignores weapon damage.
      final stray = ReplayTape.fromJson({
        ...json,
        'level': '1-1',
        'plan': level('1-1').plan.toJson(),
      });
      expect(stray.plan, isNull, reason: '$version');
    }
  });

  test('a tape whose level or plan is corrupt is rejected', () {
    final good =
        jsonDecode(
              jsonEncode(recordLevel(level('2-2'), seconds: 5).tape.toJson()),
            )
            as Map<String, dynamic>;
    expect(ReplayTape.fromJson(good).levelId, '2-2');
    final plan = good['plan'] as Map<String, dynamic>;
    for (final (why, json) in [
      ('no plan', {...good}..remove('plan')),
      ('no level', {...good}..remove('level')),
      ('plan is a list', {...good, 'plan': []}),
      ('level mismatch', {...good, 'level': '2-3'}),
      (
        'bad region',
        {
          ...good,
          'plan': {...plan, 'region': 'moon'},
        },
      ),
      (
        'bad length',
        {
          ...good,
          'plan': {...plan, 'length': 'far'},
        },
      ),
      (
        'missing marks',
        {
          ...good,
          'plan': {...plan}..remove('marks'),
        },
      ),
      (
        'bad piece',
        {
          ...good,
          'plan': {
            ...plan,
            'pieces': [
              {'kind': 'gale', 'at': 'soon', 'after': false},
            ],
          },
        },
      ),
      ('not touch', {...good, 'mode': 'jump'}),
      ('not a trail', {...good, 'course': 'classic'}),
    ]) {
      expect(
        () => ReplayTape.fromJson(json),
        throwsFormatException,
        reason: why,
      );
    }
  });
}
