// Level 2-6 and the tougher Neferhoo's fight as they flew at rules version
// 54, frozen.
@Timeout(Duration(minutes: 20))
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/session_replay.dart';

import 'frozen_flights.dart' show FrozenResult, fnvHex;
import 'frozen_rules50_flights.dart';
import 'neferhoo_pilot.dart';

/// Neferhoo's level as rules 54 flew it: the tougher Neferhoo of rules 52
/// (600 health, letters 1.4 times faster, mummy bats from the full fight on),
/// unchanged by 53 (endless bosses grow) and 54 (King Coo's quick restart).
/// Recorded from an untouched copy of the main tree
/// (`egypt-int/v3`, main at 2026-10-03 05:25 UTC, rules 54) before the faster
/// Neferhoo (rules 55: 700 health, a tighter cycle, a second mail call, more
/// letters and more bats) changed anything. A small set of the
/// `frozen_rules50` flights, at 54:
///
/// - at 54 everything must match, and saved 54 tapes reload, re-encode to the
///   same bytes, replay to the same digests and re-record byte for byte;
/// - at the current version (55 and later), 2-6's data and everything before
///   Neferhoo arrives must match too.
///
/// Nothing here may be re-recorded to make a failure go away. The fixture is
/// written when it is missing, or with
/// `--dart-define=RECORD_FROZEN_RULES54=true`, which must be used only from a
/// tree that flies rules 54 as main did on 2026-10-03.
const _record = bool.fromEnvironment('RECORD_FROZEN_RULES54');
const frozen54Version = 54;
final _fixture = File('test/fixtures/frozen_rules54.json');

const _w640 = 640 / 360;

/// The shared bot at 2.2 (kept alive), and mortal, sloppy flights at 640 and
/// at 2.2 with the upgraded weapon.
const _flights = [
  Frozen50Flight(),
  Frozen50Flight(width: _w640, keepAlive: false, sloppy: true),
  Frozen50Flight(damage: 30, keepAlive: false, sloppy: true),
];

/// R1's pilots on the app's 2.2 sky and at 640, and the careful dodge-only
/// one kept alive through two minutes.
const _pilots = [
  Frozen50Pilot(family, 2.2, 1),
  Frozen50Pilot(kid, 2.2, 3),
  Frozen50Pilot(expert, _w640, 5),
  Frozen50Pilot(coarse, 2.2, 7, keepAlive: true, seconds: 120),
];

/// The shared bot through the whole level, and a first-timer's fight.
const _tapes = [
  Frozen50Tape('bot-2-6-w2.2', seed: 26),
  Frozen50Tape('kid-2-6-w2.2', skill: kid, seed: 3),
];

Map<String, dynamic> _stored() =>
    (jsonDecode(_fixture.readAsStringSync()) as Map).cast<String, dynamic>();

String _tapeFile(Frozen50Tape frozen) =>
    'test/fixtures/frozen_rules54_tapes/${frozen.name}.json';

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
  for (final frozen in _tapes) {
    final tape = frozen.record(version: frozen54Version);
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
      'rulesVersion': frozen54Version,
      'catalog': catalog50Entry(version: frozen54Version),
      'flights': {for (final f in _flights) f.name: _json(f.fly(version: frozen54Version))},
      'pilots': {for (final p in _pilots) p.name: p.fly(version: frozen54Version).toJson()},
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
    test('records the frozen rules 54 fixture', () {
      expect(
        FlightSimulation.currentRulesVersion,
        frozen54Version,
        reason: 'record only from a tree whose current rules are 54',
      );
      _recordFixture();
      expect(_fixture.existsSync(), isTrue);
    });
    return;
  }

  const current = FlightSimulation.currentRulesVersion;

  test('the fixture covers 2-6 as rules 54 played it', () {
    final stored = _stored();
    expect(stored['rulesVersion'], frozen54Version);
    expect(FlightSimulation.cooRestartRulesVersion, frozen54Version);
    expect((stored['flights'] as Map).keys, [for (final f in _flights) f.name]);
    expect((stored['pilots'] as Map).keys, [for (final p in _pilots) p.name]);
    expect((stored['tapes'] as Map).keys, [for (final t in _tapes) t.name]);
    final kept = (stored['flights'] as Map)[_flights.first.name] as Map;
    expect(kept['outcome'], contains('end=completed'));
    expect(kept['outcome'], contains('bosses=1'));
  });

  for (final version in [
    frozen54Version,
    if (current != frozen54Version) current,
  ]) {
    test('2-6 keeps its plan, route, marks and card data, rules $version', () {
      final expected = (_stored()['catalog'] as Map).cast<String, dynamic>();
      expect(catalog50Entry(version: version), expected);
    });
  }

  test('the shared bot flies 2-6 as recorded, rules $frozen54Version', () {
    final flights = (_stored()['flights'] as Map).cast<String, dynamic>();
    for (final flight in _flights) {
      final expected = (flights[flight.name] as Map).cast<String, dynamic>();
      final run = flight.fly(version: frozen54Version);
      _matches(expected, run.result, flight.name);
      expect(run.runUp, expected['runUp'], reason: flight.name);
    }
  });

  if (current != frozen54Version) {
    test('rules $current flies 2-6 exactly as 54 until Neferhoo arrives', () {
      final flights = (_stored()['flights'] as Map).cast<String, dynamic>();
      for (final flight in _flights) {
        final expected = (flights[flight.name] as Map).cast<String, dynamic>();
        final run = flight.fly(version: current);
        expect(run.runUp, expected['runUp'], reason: flight.name);
        expect(run.runUp, isNot(contains('boss=null')), reason: flight.name);
      }
    });
  }

  test('his pilots fight him as recorded, rules $frozen54Version', () {
    final pilots = (_stored()['pilots'] as Map).cast<String, dynamic>();
    for (final pilot in _pilots) {
      _matches(
        (pilots[pilot.name] as Map).cast<String, dynamic>(),
        pilot.fly(version: frozen54Version),
        pilot.name,
      );
    }
  });

  test('saved rules 54 tapes reload, re-encode to the same bytes and replay '
      'to the same digests (under rules $current code)', () {
    final tapes = (_stored()['tapes'] as Map).cast<String, dynamic>();
    for (final frozen in _tapes) {
      final text = File(_tapeFile(frozen)).readAsStringSync();
      final expected = (tapes[frozen.name] as Map).cast<String, dynamic>();
      expect(fnvHex(text), expected['sha'], reason: frozen.name);
      final tape = _load(frozen);
      expect(tape.recordedVersion, frozen54Version, reason: frozen.name);
      expect(tape.levelId, frozen50Level, reason: frozen.name);
      expect(tape.events, hasLength(expected['events'] as int));
      expect(_tapeText(tape), text, reason: frozen.name);
      expect(ReplayPlayer(tape).simulation.rulesVersion, frozen54Version);
      final run = replay50(tape);
      _matches(expected, run.result, frozen.name);
      expect(run.runUp, expected['runUp'], reason: frozen.name);
    }
  });

  test(
    'recording the frozen flights again at 54 reproduces the saved tapes',
    () {
      for (final frozen in _tapes) {
        final saved = _load(frozen);
        expect(
          _tapeText(frozen.record(version: frozen54Version, plan: saved.plan)),
          File(_tapeFile(frozen)).readAsStringSync(),
          reason: frozen.name,
        );
      }
    },
  );
}
