// Endless, co-op, duel and chapters 1 to 3 as they flew at rules version 49.
@Timeout(Duration(minutes: 20))
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/session_replay.dart';

import 'frozen_flights.dart' show FrozenResult, fnvHex;
import 'frozen_rules49_flights.dart';

/// The game as it flew at rules version 49 (boss stages 44, the tougher King
/// Coo 45, the fiercer Searchlight Gargoyle 46, fair hearts 47, the tougher
/// endless Baron Bat 48, level feathers 49), recorded from an untouched
/// snapshot of the main tree before the Neferhoo landing (rules 50:
/// Neferhoo and the new level 2-6) changed anything. It pins:
///
/// - the 20 levels of chapters 1 to 3 that 49 could fly: their plan JSON
///   (written with the id the snapshot gave them), laid route, vents, marks
///   and card data;
/// - bot flights of each (staged bosses, King Coo's vanguard and stragglers,
///   the fierce Gargoyle, steam and pigeons included) at three widths, both
///   weapons, mortal and sloppy pilots, and New York's pilots against both
///   staged guardians at 640 and 800 px, as state digests that also cover
///   what rules 43 to 49 added (`frozen49State`);
/// - endless solo flights at three widths, a roped and a free co-op flight
///   and a duel;
/// - six saved rules 49 tapes (endless, Baron Bat and the Spitter King
///   staged, a Lantern Bazaar, King Coo and the Gargoyle staged): they must
///   reload, re-encode to the same bytes and replay to the same digests,
///   recording them again at 49 must reproduce them byte for byte, and
///   recording the same flights at the current version must replay to the
///   same digests.
///
/// Every flight runs at 49 and at the current rules version: they must match
/// the recording at both. Ancient Arabia's levels are found by the ids they
/// have now (`current49IdOf`); nothing else may differ. Nothing here may be
/// re-recorded to make a failure go away: a difference means a rule, a
/// random draw or a plan key changed for old data.
///
/// The fixture is written when it is missing, or with
/// `--dart-define=RECORD_FROZEN_RULES49=true`, which must be used only from
/// a tree that flies rules 49 as the main tree did before the landing.
const _record = bool.fromEnvironment('RECORD_FROZEN_RULES49');
final _fixture = File('test/fixtures/frozen_rules49.json');

Map<String, dynamic> _stored() =>
    (jsonDecode(_fixture.readAsStringSync()) as Map).cast<String, dynamic>();

String _tapeText(ReplayTape tape) => jsonEncode(tape.toJson());

ReplayTape _load(Frozen49Tape frozen) => ReplayTape.fromJson(
  jsonDecode(File(frozen.file).readAsStringSync()) as Map<String, dynamic>,
);

void _recordFixture() {
  final catalog = {for (final id in frozen49Levels) id: catalog49Entry(id)};
  final flights = {
    for (final flight in frozen49Flights) flight.name: flight.fly().toJson(),
  };
  final pilots = {
    for (final flight in frozen49PilotFlights)
      flight.name: flight.fly().toJson(),
  };
  final endless = {
    for (final flight in frozen49Endless) flight.name: flight.fly().toJson(),
  };
  final tapes = <String, Object>{};
  for (final frozen in frozen49Tapes) {
    final tape = frozen.record();
    File(frozen.file)
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(_tapeText(tape));
    tapes[frozen.name] = {
      'file': frozen.file,
      'sha': fnvHex(_tapeText(tape)),
      'events': tape.events.length,
      ...replay49(tape).toJson(),
    };
  }
  _fixture.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert({'rulesVersion': frozen49Version, 'catalog': catalog, 'flights': flights, 'pilots': pilots, 'endless': endless, 'tapes': tapes})}\n',
  );
}

void _matches(Map<String, dynamic> expected, FrozenResult result, String name) {
  expect(result.outcome, expected['outcome'], reason: name);
  expect(result.summary, expected['summary'], reason: name);
  expect(result.checkpoints, expected['checkpoints'], reason: name);
}

void main() {
  if (_record || !_fixture.existsSync()) {
    test('records the frozen rules 49 fixture', () {
      _recordFixture();
      expect(_fixture.existsSync(), isTrue);
    });
    return;
  }

  // From rules 51 a flight that collects every ring of a rush path sprints
  // longer, so such a flight matches the recording up to 50 only
  // (all_rings_bonus_test.dart pins the bonus). From rules 54 King Coo
  // starts his fury early, so a 3-2 flight that reaches it matches up to 53
  // only (king_coo_restart_test.dart). From rules 56 his stragglers return
  // in pairs, so flights with any returns match up to 55 only
  // (boss_stages_test.dart). Every other flight still matches.
  final versions = {
    frozen49Version,
    FlightSimulation.allRingsRulesVersion - 1,
    FlightSimulation.cooRestartRulesVersion - 1,
    FlightSimulation.cooPairsRulesVersion - 1,
    FlightSimulation.currentRulesVersion,
  };
  bool changed(FrozenResult result, int version) =>
      (version >= FlightSimulation.allRingsRulesVersion &&
          result.allRings > 0) ||
      (version >= FlightSimulation.cooRestartRulesVersion &&
          result.cooRestarts > 0) ||
      (version >= FlightSimulation.cooPairsRulesVersion &&
          result.cooStragglers > 0);
  void matchesUnlessChanged(
    Map<String, dynamic> expected,
    FrozenResult result,
    int version,
    String name,
  ) {
    if (changed(result, version)) return;
    _matches(expected, result, name);
  }

  test('the fixture covers chapters 1 to 3 as rules 49 played them', () {
    final stored = _stored();
    expect(stored['rulesVersion'], frozen49Version);
    expect(frozen49Levels, hasLength(20));
    expect((stored['catalog'] as Map).keys, frozen49Levels);
    expect({for (final f in frozen49Flights) f.level}, frozen49Levels.toSet());
    expect((stored['flights'] as Map).keys, [
      for (final f in frozen49Flights) f.name,
    ]);
    expect((stored['pilots'] as Map).keys, [
      for (final f in frozen49PilotFlights) f.name,
    ]);
    expect((stored['endless'] as Map).keys, [
      for (final f in frozen49Endless) f.name,
    ]);
    expect((stored['tapes'] as Map).keys, [
      for (final t in frozen49Tapes) t.name,
    ]);
  });

  test('the 20 levels keep their plan, route, marks and card data', () {
    final catalog = (_stored()['catalog'] as Map).cast<String, dynamic>();
    for (final id in frozen49Levels) {
      final entry = catalog49Entry(id);
      final expected = (catalog[id] as Map).cast<String, dynamic>();
      // The plan first: a new key written for an old plan shows here.
      expect(entry['plan'], expected['plan'], reason: '$id plan');
      expect(entry, expected, reason: id);
    }
  });

  for (final version in versions) {
    test(
      'bot flights of the 20 levels match the recording, rules $version',
      () {
        final flights = (_stored()['flights'] as Map).cast<String, dynamic>();
        for (final flight in frozen49Flights) {
          matchesUnlessChanged(
            (flights[flight.name] as Map).cast<String, dynamic>(),
            flight.fly(version: version),
            version,
            flight.name,
          );
        }
      },
    );

    test('New York pilots against the staged guardians match the recording, '
        'rules $version', () {
      final pilots = (_stored()['pilots'] as Map).cast<String, dynamic>();
      for (final flight in frozen49PilotFlights) {
        matchesUnlessChanged(
          (pilots[flight.name] as Map).cast<String, dynamic>(),
          flight.fly(version: version),
          version,
          flight.name,
        );
      }
    });

    test('endless, co-op and duel flights match the recording, rules '
        '$version', () {
      final endless = (_stored()['endless'] as Map).cast<String, dynamic>();
      for (final flight in frozen49Endless) {
        matchesUnlessChanged(
          (endless[flight.name] as Map).cast<String, dynamic>(),
          flight.fly(version: version),
          version,
          flight.name,
        );
      }
    });
  }

  test('the frozen flights finish, beat their bosses and lose some hearts', () {
    final flights = (_stored()['flights'] as Map).cast<String, dynamic>();
    for (final id in frozen49Levels) {
      final outcome = (flights[id] as Map)['outcome'] as String;
      final boss = (_stored()['catalog'] as Map)[id]['boss'] as String;
      expect(outcome, contains('end=completed'), reason: id);
      expect(outcome, contains('finish=crossed'), reason: id);
      expect(outcome, contains('bosses=${boss.isEmpty ? 0 : 1}'), reason: id);
    }
    final hurt = [
      for (final f in flights.values)
        if (((f as Map)['outcome'] as String).contains('end=collision')) f,
    ];
    expect(hurt, isNotEmpty);
    final pilots = (_stored()['pilots'] as Map).cast<String, dynamic>();
    for (final flight in frozen49PilotFlights.where((f) => f.keepAlive)) {
      expect(
        (pilots[flight.name] as Map)['outcome'],
        contains('bosses=1'),
        reason: flight.name,
      );
    }
  });

  test(
    'saved rules 49 tapes reload, re-encode to the same bytes and replay',
    () {
      final tapes = (_stored()['tapes'] as Map).cast<String, dynamic>();
      for (final frozen in frozen49Tapes) {
        final text = File(frozen.file).readAsStringSync();
        final expected = (tapes[frozen.name] as Map).cast<String, dynamic>();
        expect(fnvHex(text), expected['sha'], reason: frozen.name);
        final tape = _load(frozen);
        expect(tape.recordedVersion, frozen49Version, reason: frozen.name);
        expect(tape.levelId, frozen.level, reason: frozen.name);
        expect(tape.events, hasLength(expected['events'] as int));
        // Saved again, a 49 tape is the same bytes: no new key for old data.
        expect(_tapeText(tape), text, reason: frozen.name);
        expect(ReplayPlayer(tape).simulation.rulesVersion, frozen49Version);
        _matches(expected, replay49(tape), frozen.name);
      }
    },
  );

  test('recording the frozen flights again reproduces the saved tapes', () {
    for (final frozen in frozen49Tapes) {
      final saved = _load(frozen);
      expect(
        _tapeText(frozen.record(plan: saved.plan)),
        File(frozen.file).readAsStringSync(),
        reason: frozen.name,
      );
    }
  });

  test('the same flights recorded at 50 and at the current version replay '
      'the same', () {
    final tapes = (_stored()['tapes'] as Map).cast<String, dynamic>();
    for (final version in versions.skip(1)) {
      for (final frozen in frozen49Tapes) {
        final saved = _load(frozen);
        final now = frozen.record(version: version, plan: saved.plan);
        expect(now.recordedVersion, version);
        final replayed = replay49(now);
        // A flight that earns the all-rings bonus at 51, or whose King Coo
        // restarts at 54 or sends stragglers at 56, flies on differently.
        if (changed(replayed, version)) continue;
        // The same inputs, frame for frame: only the version differs.
        expect(jsonEncode(now.events), jsonEncode(saved.events));
        final expected = (tapes[frozen.name] as Map).cast<String, dynamic>();
        _matches(expected, replayed, '${frozen.name} recorded at $version');
      }
    }
  });

  test('the saved tapes are an endless flight, two staged chapter bosses (a '
      'win and a knock-out), a plain Arabian level and both staged '
      'guardians', () {
    final tapes = (_stored()['tapes'] as Map).cast<String, dynamic>();
    expect(
      [for (final t in frozen49Tapes) t.level],
      [null, '1-8', '2-8', '2-6', '3-2', '3-4'],
    );
    for (final frozen in frozen49Tapes.skip(1)) {
      final outcome = (tapes[frozen.name] as Map)['outcome'] as String;
      // The Spitter King's tape is a knock-out in his staged fight (the
      // narrow screen, a mortal bot); every other campaign tape is a finish.
      expect(
        outcome,
        contains(frozen.level == '2-8' ? 'end=collision' : 'end=completed'),
        reason: frozen.name,
      );
      final tape = _load(frozen);
      expect(
        frozen49PlanJson(frozen.level!, frozen49Level(frozen.level!).plan),
        jsonEncode(tape.plan!.toJson()),
        reason: '${frozen.name}: the catalog still flies the taped plan',
      );
    }
  });
}
