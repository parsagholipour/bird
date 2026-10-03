// Level 2-6 and Neferhoo's fight as they flew at rules version 51, frozen.
@Timeout(Duration(minutes: 20))
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/session_replay.dart';

import 'frozen_flights.dart' show FrozenResult, fnvHex;
import 'frozen_rules50_flights.dart';

/// Neferhoo's level as rules 51 (the all-rings bonus) flew it, recorded from
/// an untouched copy of the main tree (`egypt-int/rehearsal2`, tag
/// `pure-main` plus the test helpers' `version` parameters) before the
/// tougher Neferhoo (600 health, faster letters, mummy bats) changed
/// anything. Main took 51 for the all-rings bonus while the tougher Neferhoo
/// was being built against 50, so the tougher Neferhoo became 52 and this
/// fixture pins the version it now has to leave alone. It flies the same
/// flights as `frozen_rules50` (the shared bot at 640, 800, 864 px and 2.2,
/// R1's pilots, four tapes), at 51:
///
/// - at 51 everything must match, and saved 51 tapes reload, re-encode to the
///   same bytes, replay to the same digests and re-record byte for byte;
/// - 51 flies 2-6 exactly as 50 did (2-6 lays no rush path, so the all-rings
///   bonus never applies): the flights' and pilots' digests equal
///   `frozen_rules50`'s;
/// - at the current version (52 and later), 2-6's data and everything before
///   Neferhoo arrives must match too.
///
/// Nothing here may be re-recorded to make a failure go away. The fixture is
/// written when it is missing, or with
/// `--dart-define=RECORD_FROZEN_RULES51=true`, which must be used only from a
/// tree that flies rules 51 as main did on 2026-10-03.
const _record = bool.fromEnvironment('RECORD_FROZEN_RULES51');
const frozen51Version = 51;
final _fixture = File('test/fixtures/frozen_rules51.json');
final _fixture50 = File('test/fixtures/frozen_rules50.json');

Map<String, dynamic> _read(File file) =>
    (jsonDecode(file.readAsStringSync()) as Map).cast<String, dynamic>();
Map<String, dynamic> _stored() => _read(_fixture);

String _tapeFile(Frozen50Tape frozen) =>
    'test/fixtures/frozen_rules51_tapes/${frozen.name}.json';

String _tapeText(ReplayTape tape) => jsonEncode(tape.toJson());

ReplayTape _load(Frozen50Tape frozen) => ReplayTape.fromJson(
  jsonDecode(File(_tapeFile(frozen)).readAsStringSync())
      as Map<String, dynamic>,
);

Map<String, Object?> _json(Frozen50Run run) => {
  ...run.result.toJson(),
  'runUp': run.runUp,
};

void _recordFixture() {
  final tapes = <String, Object>{};
  for (final frozen in frozen50Tapes) {
    final tape = frozen.record(version: frozen51Version);
    File(_tapeFile(frozen))
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(_tapeText(tape));
    tapes[frozen.name] = {
      'file': _tapeFile(frozen),
      'sha': fnvHex(_tapeText(tape)),
      'events': tape.events.length,
      ..._json(replay50(tape)),
    };
  }
  _fixture.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert({
      'rulesVersion': frozen51Version,
      'catalog': catalog50Entry(version: frozen51Version),
      'flights': {for (final f in frozen50Flights) f.name: _json(f.fly(version: frozen51Version))},
      'pilots': {for (final p in frozen50Pilots) p.name: p.fly(version: frozen51Version).toJson()},
      'tapes': tapes,
    })}\n',
  );
}

void _matches(Map<String, dynamic> expected, FrozenResult result, String name) {
  expect(result.outcome, expected['outcome'], reason: name);
  expect(result.summary, expected['summary'], reason: name);
  expect(result.checkpoints, expected['checkpoints'], reason: name);
}

void main() {
  if (_record || !_fixture.existsSync()) {
    test('records the frozen rules 51 fixture', () {
      expect(
        FlightSimulation.currentRulesVersion,
        frozen51Version,
        reason: 'record only from a tree whose current rules are 51',
      );
      _recordFixture();
      expect(_fixture.existsSync(), isTrue);
    });
    return;
  }

  // These timed fixtures precede the shorter countdown introduced at 57.
  const current = FlightSimulation.quickStartRulesVersion - 1;

  test('the fixture covers 2-6 as rules 51 played it', () {
    final stored = _stored();
    expect(stored['rulesVersion'], frozen51Version);
    expect(FlightSimulation.allRingsRulesVersion, frozen51Version);
    expect((stored['flights'] as Map).keys, [
      for (final f in frozen50Flights) f.name,
    ]);
    expect((stored['pilots'] as Map).keys, [
      for (final p in frozen50Pilots) p.name,
    ]);
    expect((stored['tapes'] as Map).keys, [
      for (final t in frozen50Tapes) t.name,
    ]);
    for (final f in frozen50Flights.where((f) => f.keepAlive)) {
      final outcome = (stored['flights'] as Map)[f.name]['outcome'] as String;
      expect(outcome, contains('end=completed'), reason: f.name);
      expect(outcome, contains('bosses=1'), reason: f.name);
    }
  });

  test('51 flew 2-6 exactly as 50: the same catalog, flights and pilots', () {
    final at51 = _stored(), at50 = _read(_fixture50);
    expect(at51['catalog'], at50['catalog']);
    expect(at51['flights'], at50['flights']);
    expect(at51['pilots'], at50['pilots']);
  });

  for (final version in [
    frozen51Version,
    if (current != frozen51Version) current,
  ]) {
    test('2-6 keeps its plan, route, marks and card data, rules $version', () {
      final expected = (_stored()['catalog'] as Map).cast<String, dynamic>();
      expect(catalog50Entry(version: version), expected);
    });
  }

  test('the shared bot flies 2-6 as recorded, rules $frozen51Version', () {
    final flights = (_stored()['flights'] as Map).cast<String, dynamic>();
    for (final flight in frozen50Flights) {
      final expected = (flights[flight.name] as Map).cast<String, dynamic>();
      final run = flight.fly(version: frozen51Version);
      _matches(expected, run.result, flight.name);
      expect(run.runUp, expected['runUp'], reason: flight.name);
    }
  });

  if (current != frozen51Version) {
    test('rules $current flies 2-6 exactly as 51 until Neferhoo arrives', () {
      final flights = (_stored()['flights'] as Map).cast<String, dynamic>();
      for (final flight in frozen50Flights) {
        final expected = (flights[flight.name] as Map).cast<String, dynamic>();
        final run = flight.fly(version: current);
        expect(run.runUp, expected['runUp'], reason: flight.name);
        expect(run.runUp, isNot(contains('boss=null')), reason: flight.name);
      }
    });
  }

  test('his pilots fight him as recorded, rules $frozen51Version', () {
    final pilots = (_stored()['pilots'] as Map).cast<String, dynamic>();
    for (final pilot in frozen50Pilots) {
      _matches(
        (pilots[pilot.name] as Map).cast<String, dynamic>(),
        pilot.fly(version: frozen51Version),
        pilot.name,
      );
    }
  });

  test('saved rules 51 tapes reload, re-encode to the same bytes and replay '
      'to the same digests (under rules $current code)', () {
    final tapes = (_stored()['tapes'] as Map).cast<String, dynamic>();
    for (final frozen in frozen50Tapes) {
      final text = File(_tapeFile(frozen)).readAsStringSync();
      final expected = (tapes[frozen.name] as Map).cast<String, dynamic>();
      expect(fnvHex(text), expected['sha'], reason: frozen.name);
      final tape = _load(frozen);
      expect(tape.recordedVersion, frozen51Version, reason: frozen.name);
      expect(tape.levelId, frozen50Level, reason: frozen.name);
      expect(tape.events, hasLength(expected['events'] as int));
      expect(_tapeText(tape), text, reason: frozen.name);
      expect(ReplayPlayer(tape).simulation.rulesVersion, frozen51Version);
      final run = replay50(tape);
      _matches(expected, run.result, frozen.name);
      expect(run.runUp, expected['runUp'], reason: frozen.name);
    }
  });

  test(
    'recording the frozen flights again at 51 reproduces the saved tapes',
    () {
      for (final frozen in frozen50Tapes) {
        final saved = _load(frozen);
        expect(
          _tapeText(frozen.record(version: frozen51Version, plan: saved.plan)),
          File(_tapeFile(frozen)).readAsStringSync(),
          reason: frozen.name,
        );
      }
    },
  );
}
