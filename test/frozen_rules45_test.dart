// Endless, co-op, duel and chapters 1 to 3 as they flew at rules version 45.
@Timeout(Duration(minutes: 20))
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/session_replay.dart';

import 'frozen_flights.dart' show FrozenResult, fnvHex;
import 'frozen_rules45_flights.dart';

/// The game as it flew at rules version 45 (boss stages 44, the tougher King
/// Coo 45), recorded from `egypt-int/base` untouched, before the Egypt
/// program (rules 50: Neferhoo and the new level 2-6) changed anything. It
/// pins:
///
/// - the 20 levels of chapters 1 to 3 that 45 could fly: their plan JSON
///   (written with the id the base gave them), laid route, vents, marks and
///   card data;
/// - bot flights of each (staged bosses, King Coo's vanguard and stragglers,
///   the Gargoyle, steam and pigeons included) at three widths, both weapons,
///   mortal and sloppy pilots, and New York's pilots against both staged
///   guardians at 640 and 800 px, as state digests that also cover what rules
///   43 to 45 added (`frozenState`);
/// - endless solo flights at three widths, a roped and a free co-op flight
///   and a duel;
/// - six saved rules 45 tapes (endless, Baron Bat and the Spitter King
///   staged, a Lantern Bazaar, King Coo and the Gargoyle staged): they must
///   reload, re-encode to the same bytes and replay to the same digests, and
///   recording them again at 45 must reproduce them byte for byte.
///
/// Every flight runs at 45 and must match the recording. (The Egypt program
/// also flew them at its own version; on landing, the main tree had moved on
/// to 49, whose fiercer Gargoyle, fair hearts and tougher endless Baron change
/// some of them by design, so `frozen_rules49_test.dart`, recorded from the
/// main tree before the landing, pins the current version instead.) Ancient
/// Arabia's levels are found by the ids they have now (`currentIdOf`);
/// nothing else may differ. Nothing here may be
/// re-recorded to make a failure go away: a difference means a rule, a
/// random draw or a plan key changed for old data.
///
/// The fixture is written when it is missing, or with
/// `--dart-define=RECORD_FROZEN_RULES45=true`, which must be used only from
/// a tree that flies rules 45 as `egypt-int/base` did.
const _record = bool.fromEnvironment('RECORD_FROZEN_RULES45');
final _fixture = File('test/fixtures/frozen_rules45.json');

Map<String, dynamic> _stored() =>
    (jsonDecode(_fixture.readAsStringSync()) as Map).cast<String, dynamic>();

String _tapeText(ReplayTape tape) => jsonEncode(tape.toJson());

ReplayTape _load(Frozen45Tape frozen) => ReplayTape.fromJson(
  jsonDecode(File(frozen.file).readAsStringSync()) as Map<String, dynamic>,
);

void _recordFixture() {
  final catalog = {for (final id in frozen45Levels) id: catalog45Entry(id)};
  final flights = {
    for (final flight in frozen45Flights) flight.name: flight.fly().toJson(),
  };
  final pilots = {
    for (final flight in frozen45PilotFlights)
      flight.name: flight.fly().toJson(),
  };
  final endless = {
    for (final flight in frozen45Endless) flight.name: flight.fly().toJson(),
  };
  final tapes = <String, Object>{};
  for (final frozen in frozen45Tapes) {
    final tape = frozen.record();
    File(frozen.file)
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(_tapeText(tape));
    tapes[frozen.name] = {
      'file': frozen.file,
      'sha': fnvHex(_tapeText(tape)),
      'events': tape.events.length,
      ...replay45(tape).toJson(),
    };
  }
  _fixture.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert({'rulesVersion': frozen45Version, 'catalog': catalog, 'flights': flights, 'pilots': pilots, 'endless': endless, 'tapes': tapes})}\n',
  );
}

void _matches(
  Map<String, dynamic> expected,
  FrozenResult result,
  String name,
) {
  expect(result.outcome, expected['outcome'], reason: name);
  expect(result.summary, expected['summary'], reason: name);
  expect(result.checkpoints, expected['checkpoints'], reason: name);
}

void main() {
  if (_record || !_fixture.existsSync()) {
    test('records the frozen rules 45 fixture', () {
      _recordFixture();
      expect(_fixture.existsSync(), isTrue);
    });
    return;
  }

  // The current version is frozen_rules49_test's (see above).
  final versions = [frozen45Version];

  test('the fixture covers chapters 1 to 3 as rules 45 played them', () {
    final stored = _stored();
    expect(stored['rulesVersion'], frozen45Version);
    expect(frozen45Levels, hasLength(20));
    expect((stored['catalog'] as Map).keys, frozen45Levels);
    expect({for (final f in frozen45Flights) f.level}, frozen45Levels.toSet());
    expect((stored['flights'] as Map).keys, [
      for (final f in frozen45Flights) f.name,
    ]);
    expect((stored['pilots'] as Map).keys, [
      for (final f in frozen45PilotFlights) f.name,
    ]);
    expect((stored['endless'] as Map).keys, [
      for (final f in frozen45Endless) f.name,
    ]);
    expect((stored['tapes'] as Map).keys, [
      for (final t in frozen45Tapes) t.name,
    ]);
  });

  test('the 20 levels keep their plan, route, marks and card data', () {
    final catalog = (_stored()['catalog'] as Map).cast<String, dynamic>();
    for (final id in frozen45Levels) {
      final entry = catalog45Entry(id);
      final expected = (catalog[id] as Map).cast<String, dynamic>();
      // The plan first: a new key written for an old plan shows here.
      expect(entry['plan'], expected['plan'], reason: '$id plan');
      expect(entry, expected, reason: id);
    }
  });

  for (final version in versions) {
    test('bot flights of the 20 levels match the recording, rules $version', () {
      final flights = (_stored()['flights'] as Map).cast<String, dynamic>();
      for (final flight in frozen45Flights) {
        _matches(
          (flights[flight.name] as Map).cast<String, dynamic>(),
          flight.fly(version: version),
          flight.name,
        );
      }
    });

    test('New York pilots against the staged guardians match the recording, '
        'rules $version', () {
      final pilots = (_stored()['pilots'] as Map).cast<String, dynamic>();
      for (final flight in frozen45PilotFlights) {
        _matches(
          (pilots[flight.name] as Map).cast<String, dynamic>(),
          flight.fly(version: version),
          flight.name,
        );
      }
    });

    test('endless, co-op and duel flights match the recording, rules '
        '$version', () {
      final endless = (_stored()['endless'] as Map).cast<String, dynamic>();
      for (final flight in frozen45Endless) {
        _matches(
          (endless[flight.name] as Map).cast<String, dynamic>(),
          flight.fly(version: version),
          flight.name,
        );
      }
    });
  }

  test('the frozen flights finish, beat their bosses and lose some hearts', () {
    final flights = (_stored()['flights'] as Map).cast<String, dynamic>();
    for (final id in frozen45Levels) {
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
    for (final flight in frozen45PilotFlights.where((f) => f.keepAlive)) {
      expect(
        (pilots[flight.name] as Map)['outcome'],
        contains('bosses=1'),
        reason: flight.name,
      );
    }
  });

  test('saved rules 45 tapes reload, re-encode to the same bytes and replay', () {
    final tapes = (_stored()['tapes'] as Map).cast<String, dynamic>();
    for (final frozen in frozen45Tapes) {
      final text = File(frozen.file).readAsStringSync();
      final expected = (tapes[frozen.name] as Map).cast<String, dynamic>();
      expect(fnvHex(text), expected['sha'], reason: frozen.name);
      final tape = _load(frozen);
      expect(tape.recordedVersion, frozen45Version, reason: frozen.name);
      expect(tape.levelId, frozen.level, reason: frozen.name);
      expect(tape.events, hasLength(expected['events'] as int));
      // Saved again, a 45 tape is the same bytes: no new key for old data.
      expect(_tapeText(tape), text, reason: frozen.name);
      expect(ReplayPlayer(tape).simulation.rulesVersion, frozen45Version);
      _matches(expected, replay45(tape), frozen.name);
    }
  });

  test('recording the frozen flights again reproduces the saved tapes', () {
    for (final frozen in frozen45Tapes) {
      final saved = _load(frozen);
      expect(
        _tapeText(frozen.record(plan: saved.plan)),
        File(frozen.file).readAsStringSync(),
        reason: frozen.name,
      );
    }
  });

  test('the saved tapes are an endless flight, two staged chapter bosses (a '
      'win and a knock-out), a plain Arabian level and both staged '
      'guardians', () {
    final tapes = (_stored()['tapes'] as Map).cast<String, dynamic>();
    expect([for (final t in frozen45Tapes) t.level], [
      null,
      '1-8',
      '2-8',
      '2-6',
      '3-2',
      '3-4',
    ]);
    for (final frozen in frozen45Tapes.skip(1)) {
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
        frozenPlanJson(frozen.level!, frozenLevel(frozen.level!).plan),
        jsonEncode(tape.plan!.toJson()),
        reason: '${frozen.name}: the catalog still flies the taped plan',
      );
    }
  });
}
