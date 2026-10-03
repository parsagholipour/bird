import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/campaign.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/session_replay.dart';

import 'campaign_flight.dart';
import 'ny_plans.dart';

/// Rules version 43, "New York": one bump for the Alley Pigeon, steam
/// geysers and the mini-bosses, gated centrally by `LevelPlan.minRulesVersion`
/// and the `supports…` getters. (Version 42 is Fly Together, co-op and duel:
/// it is endless-only and a New York plan must not fly at it.) Endless and
/// chapters 1 and 2 must fly at 43 as at 42 and at 41 (frozen_rules41_test
/// and endless_plan_baseline_test pin that).

CampaignLevel level(String id) => Campaign.level(id)!;

Map<String, dynamic> roundTrip(Map<String, Object?> json) =>
    jsonDecode(jsonEncode(json)) as Map<String, dynamic>;

/// One plan per New York feature, and one that uses all of them.
final features = <String, LevelPlan>{
  'pigeon in the lineup': nyPlan(),
  'pigeon flocks': nyPlan(lineup: const [EnemyKind.simpleBat], flocks: [2, 3]),
  'steam layer': nyPlan(
    length: 80,
    lineup: const [EnemyKind.simpleBat],
    steam: SteamPlan.steady,
  ),
  'King Coo': nyPlan(
    lineup: const [EnemyKind.simpleBat],
    boss: BossKind.kingCoo,
  ),
  'Searchlight Gargoyle': nyPlan(
    id: '3-4',
    lineup: const [EnemyKind.simpleBat],
    boss: BossKind.searchlightGargoyle,
  ),
};

void main() {
  test('New York is rules version 43; co-op stays at 42', () {
    // 44 (staged campaign bosses), 45 (a tougher King Coo), 46 (a fiercer
    // Gargoyle), 47 (a campaign heart's reach), 48 (the returning endless
    // Baron's health), 49 (the Gargoyle's level feathers), 50 (Egypt's
    // guardian, Neferhoo), 51 (the all-rings bonus), 52 (a tougher
    // Neferhoo), 53 (growing endless bosses), 54 (King Coo's quick fury) and
    // 55 (a faster Neferhoo) came after it.
    expect(FlightSimulation.currentRulesVersion, greaterThanOrEqualTo(55));
    expect(FlightSimulation.newYorkRulesVersion, 43);
    expect(FlightSimulation.coopRulesVersion, 42);
    expect(FlightSimulation.campaignRulesVersion, 41);
    expect(ReplayTape.version, FlightSimulation.currentRulesVersion);
  });

  test('the three supports getters open at 43 and not at 42 or 41', () {
    for (final (version, open) in [(41, false), (42, false), (43, true)]) {
      final sim = nyFlight(level('2-9').plan, version: version);
      expect(sim.supportsAlleyPigeon, open, reason: 'pigeon $version');
      expect(sim.supportsSteamGeysers, open, reason: 'steam $version');
      expect(sim.supportsMiniBosses, open, reason: 'mini-bosses $version');
    }
    // Older endless flights never gain them.
    for (final version in [7, 27, 40]) {
      final sim = FlightSimulation(
        rules: TapFlyMode(rulesVersion: version),
        practice: false,
        course: FlightCourse.starTrail,
        rulesVersion: version,
      );
      expect(sim.supportsAlleyPigeon, isFalse, reason: '$version');
      expect(sim.supportsSteamGeysers, isFalse, reason: '$version');
      expect(sim.supportsMiniBosses, isFalse, reason: '$version');
    }
    // Jump and push-up flights do not fight, so the gates stay closed.
    final pushUp = FlightSimulation(
      rules: PushUpFlightMode(cycleSeconds: 3),
      practice: false,
    );
    expect(pushUp.supportsAlleyPigeon, isFalse);
    expect(pushUp.supportsMiniBosses, isFalse);
  });

  test('every chapter 1 and 2 level needs only rules 41', () {
    for (final chapter in Campaign.chapters.take(2)) {
      for (final level in chapter.levels) {
        // But Egypt's guardian (2-6), from rules 50 (rules50_version_test).
        if (level.id == '2-6') continue;
        expect(level.plan.minRulesVersion, 41, reason: level.id);
        expect(level.plan.usesNewYork, isFalse, reason: level.id);
      }
    }
    // Chapter 3: 3-1 and Paris keep their rules 41 data and need no more;
    // 3-2, 3-3 and 3-4 carry New York's pigeons, steam and guardians (the
    // level data step), so they need 43.
    for (final level in Campaign.chapters[2].levels) {
      final newYork = ['3-2', '3-3', '3-4'].contains(level.id);
      expect(level.plan.minRulesVersion, newYork ? 43 : 41, reason: level.id);
      expect(level.plan.usesNewYork, newYork, reason: level.id);
    }
    expect(FlightPlan.endless.minRulesVersion, 0);
  });

  test('a plan that uses New York needs 43', () {
    for (final MapEntry(:key, :value) in features.entries) {
      expect(value.problem, isNull, reason: key);
      expect(value.usesNewYork, isTrue, reason: key);
      expect(value.minRulesVersion, 43, reason: key);
    }
    expect(features['King Coo']!.hasMiniBoss, isTrue);
    expect(features['Searchlight Gargoyle']!.hasMiniBoss, isTrue);
    expect(features['pigeon in the lineup']!.hasMiniBoss, isFalse);
    // A chapter boss is not a mini-boss.
    expect(level('2-9').plan.hasMiniBoss, isFalse);
  });

  test('the simulation refuses a plan below its minimum rules version', () {
    for (final MapEntry(:key, :value) in features.entries) {
      expect(
        () => nyFlight(value, version: 41),
        throwsArgumentError,
        reason: key,
      );
      expect(
        () => nyFlight(value, version: 40),
        throwsArgumentError,
        reason: key,
      );
      // 42 is Fly Together's version: it knows no pigeon, vent or guardian.
      expect(
        () => nyFlight(value, version: 42),
        throwsArgumentError,
        reason: key,
      );
      expect(nyFlight(value, version: 43).levelId, value.id, reason: key);
    }
    // A plan with nothing new flies at 41, at 42 and at 43.
    for (final version in [41, 42, 43]) {
      expect(nyFlight(level('1-1').plan, version: version).levelId, '1-1');
    }
  });

  test('a replay tape rejects a plan newer than its rules version', () {
    for (final MapEntry(:key, :value) in features.entries) {
      final tape = recordLevel(level('1-1'), plan: value, seconds: 2).tape;
      final json = roundTrip(tape.toJson());
      expect(json['version'], FlightSimulation.currentRulesVersion);
      expect(ReplayTape.fromJson(json).plan!.toJson(), value.toJson());
      // The same journal claiming to be a rules 41 or 42 flight cannot hold
      // it.
      for (final older in [41, 42]) {
        expect(
          () => ReplayTape.fromJson({...json, 'version': older}),
          throwsFormatException,
          reason: '$key at $older',
        );
      }
    }
    // A plan with nothing new loads at 41 and at 42.
    final old = roundTrip(recordLevel(level('1-2'), seconds: 2).tape.toJson());
    for (final version in [41, 42]) {
      expect(ReplayTape.fromJson({...old, 'version': version}).levelId, '1-2');
    }
  });

  test('new plan keys are written only when a plan uses them', () {
    // The catalog's three rules 43 New York levels write their keys (and
    // only those); every other plan keeps the rules 41 key order.
    final newYork = {
      '3-2': (true, false),
      '3-3': (true, true),
      '3-4': (true, true),
    };
    for (final chapter in Campaign.chapters) {
      for (final level in chapter.levels) {
        final json = level.plan.toJson();
        final (flocks, steam) = newYork[level.id] ?? (false, false);
        expect(json.containsKey('flocks'), flocks, reason: level.id);
        expect(json.containsKey('steam'), steam, reason: level.id);
        expect(
          [...json.keys]..removeWhere(['flocks', 'steam'].contains),
          [
            'id',
            'region',
            'length',
            'start',
            'seed',
            'families',
            'lineup',
            'cadence',
            'toughness',
            'shoot',
            'sprint',
            'panels',
            'pieces',
            'boss',
            'marks',
          ],
          reason: '${level.id}: the rules 41 key order',
        );
      }
    }
    final json = features['pigeon flocks']!.toJson();
    expect(json['flocks'], [2, 3]);
    expect(json.containsKey('steam'), isFalse);
    final steam = features['steam layer']!.toJson();
    expect(steam['steam'], {
      'first': 4,
      'every': 4,
      'last': 34,
      'pattern': 'HR',
    });
    expect(steam.containsKey('flocks'), isFalse);
  });

  test('plans round-trip, and missing new keys read as empty', () {
    for (final MapEntry(:key, :value) in features.entries) {
      final back = LevelPlan.fromJson(roundTrip(value.toJson()));
      expect(
        jsonEncode(back.toJson()),
        jsonEncode(value.toJson()),
        reason: key,
      );
      expect(back.flocks, value.flocks, reason: key);
      expect(back.steam.isEmpty, value.steam.isEmpty, reason: key);
      expect(back.boss, value.boss, reason: key);
      expect(back.lineup, value.lineup, reason: key);
    }
    final old = LevelPlan.fromJson(roundTrip(level('2-7').plan.toJson()));
    expect(old.flocks, isEmpty);
    expect(old.steam.isEmpty, isTrue);
    expect(old.minRulesVersion, 41);
    expect(jsonEncode(old.toJson()), jsonEncode(level('2-7').plan.toJson()));
  });

  test('malformed new plan keys are rejected', () {
    final good = roundTrip(features['steam layer']!.toJson());
    final flocks = roundTrip(features['pigeon flocks']!.toJson());
    for (final (why, json) in <(String, Map<String, dynamic>)>[
      ('flocks not a list', {...flocks, 'flocks': 2}),
      ('empty flocks', {...flocks, 'flocks': <int>[]}),
      (
        'flock of zero',
        {
          ...flocks,
          'flocks': [0],
        },
      ),
      (
        'flock of four',
        {
          ...flocks,
          'flocks': [4],
        },
      ),
      (
        'flock not a number',
        {
          ...flocks,
          'flocks': ['two'],
        },
      ),
      ('steam not a map', {...good, 'steam': 'hiss'}),
      (
        'steam empty pattern',
        {
          ...good,
          'steam': {'first': 4, 'every': 4, 'last': 34, 'pattern': ''},
        },
      ),
      (
        'steam bad pattern',
        {
          ...good,
          'steam': {'first': 4, 'every': 4, 'last': 34, 'pattern': 'HX'},
        },
      ),
      (
        'steam too early',
        {
          ...good,
          'steam': {'first': 2, 'every': 4, 'last': 34, 'pattern': 'H'},
        },
      ),
      (
        'steam too dense',
        {
          ...good,
          'steam': {'first': 4, 'every': 2, 'last': 34, 'pattern': 'H'},
        },
      ),
      (
        'steam on an enemy passage',
        {
          ...good,
          'steam': {'first': 5, 'every': 4, 'last': 33, 'pattern': 'H'},
          'cadence': 2,
          'lineup': ['simpleBat'],
        },
      ),
      (
        'steam last before first',
        {
          ...good,
          'steam': {'first': 8, 'every': 4, 'last': 4, 'pattern': 'H'},
        },
      ),
      (
        'unknown boss',
        {
          ...good,
          'boss': 'kingKoo',
          'lineup': ['simpleBat'],
        },
      ),
      (
        'unknown enemy',
        {
          ...good,
          'lineup': ['alleyPidgeon'],
        },
      ),
    ]) {
      expect(
        () => LevelPlan.fromJson(json),
        throwsFormatException,
        reason: why,
      );
    }
  });

  test('a current tape of an old plan is the 41 format plus its version', () {
    // Recorded at 43 or later, a chapter 2 level carries no New York key:
    // only the version differs from what rules 41 saved.
    final json = roundTrip(recordLevel(level('2-3'), seconds: 3).tape.toJson());
    expect(json['version'], FlightSimulation.currentRulesVersion);
    final plan = json['plan'] as Map<String, dynamic>;
    expect(plan.containsKey('flocks'), isFalse);
    expect(plan.containsKey('steam'), isFalse);
    expect(jsonEncode(plan), jsonEncode(level('2-3').plan.toJson()));
  });
}
