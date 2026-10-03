// Level 2-6 and Neferhoo's fight as they flew at rules version 50, frozen.
@Timeout(Duration(minutes: 20))
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/session_replay.dart';

import 'frozen_flights.dart' show FrozenResult, fnvHex;
import 'frozen_rules50_flights.dart';

/// Neferhoo's level as rules 50 flew it, recorded from an untouched copy of
/// the landed tree (`egypt-int/base2`) before the tougher Neferhoo (rules 52:
/// 600 health, faster letters, mummy bats) changed anything. It pins:
///
/// - 2-6's data: plan JSON, laid route, marks, card and the rules it needs;
/// - the shared bot through the whole level at 640, 800 and 864 px and 2.2,
///   both weapons, mortal and sloppy;
/// - R1's pilots (family, first-timer, expert, learner and the slow,
///   dodge-only player) fighting him from the fight's first frame;
/// - four saved rules 50 tapes (two of the bot, a family pilot at 640 and a
///   first-timer at 2.2): they must reload, re-encode to the same bytes and
///   replay to the same digests, and recording them again at 50 must
///   reproduce them byte for byte.
///
/// At 50 everything must match. At the current version (51 and later), 2-6's
/// data and everything before Neferhoo arrives must match too: the level, its
/// route and its run-up are untouched, and recording the same flights at the
/// current version gives the same inputs and the same run-up. Nothing here
/// may be re-recorded to make a failure go away: a difference means a rule,
/// a random draw or a plan key changed for old data.
///
/// The fixture is written when it is missing, or with
/// `--dart-define=RECORD_FROZEN_RULES50=true`, which must be used only from a
/// tree that flies rules 50 as `egypt-int/base2` did.
const _record = bool.fromEnvironment('RECORD_FROZEN_RULES50');
final _fixture = File('test/fixtures/frozen_rules50.json');

Map<String, dynamic> _stored() =>
    (jsonDecode(_fixture.readAsStringSync()) as Map).cast<String, dynamic>();

String _tapeText(ReplayTape tape) => jsonEncode(tape.toJson());

ReplayTape _load(Frozen50Tape frozen) => ReplayTape.fromJson(
  jsonDecode(File(frozen.file).readAsStringSync()) as Map<String, dynamic>,
);

Map<String, Object?> _json(Frozen50Run run) => {
  ...run.result.toJson(),
  'runUp': run.runUp,
};

void _recordFixture() {
  final tapes = <String, Object>{};
  for (final frozen in frozen50Tapes) {
    final tape = frozen.record();
    File(frozen.file)
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(_tapeText(tape));
    tapes[frozen.name] = {
      'file': frozen.file,
      'sha': fnvHex(_tapeText(tape)),
      'events': tape.events.length,
      ..._json(replay50(tape)),
    };
  }
  _fixture.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert({
      'rulesVersion': frozen50Version,
      'catalog': catalog50Entry(),
      'flights': {for (final f in frozen50Flights) f.name: _json(f.fly())},
      'pilots': {for (final p in frozen50Pilots) p.name: p.fly().toJson()},
      'tapes': tapes,
    })}\n',
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
    test('records the frozen rules 50 fixture', () {
      _recordFixture();
      expect(_fixture.existsSync(), isTrue);
    });
    return;
  }

  // These timed fixtures precede the shorter countdown introduced at 57.
  const current = FlightSimulation.quickStartRulesVersion - 1;

  test('the fixture covers 2-6 as rules 50 played it', () {
    final stored = _stored();
    expect(stored['rulesVersion'], frozen50Version);
    expect((stored['flights'] as Map).keys, [
      for (final f in frozen50Flights) f.name,
    ]);
    expect((stored['pilots'] as Map).keys, [
      for (final p in frozen50Pilots) p.name,
    ]);
    expect((stored['tapes'] as Map).keys, [
      for (final t in frozen50Tapes) t.name,
    ]);
    final catalog = (stored['catalog'] as Map).cast<String, dynamic>();
    expect(catalog['boss'], 'neferhoo');
    expect(catalog['minRulesVersion'], frozen50Version);
    // Every frozen bot flight finishes the level and beats him.
    for (final f in frozen50Flights.where((f) => f.keepAlive)) {
      final outcome = (stored['flights'] as Map)[f.name]['outcome'] as String;
      expect(outcome, contains('end=completed'), reason: f.name);
      expect(outcome, contains('bosses=1'), reason: f.name);
    }
  });

  for (final version in [
    frozen50Version,
    if (current != frozen50Version) current,
  ]) {
    test('2-6 keeps its plan, route, marks and card data, rules $version', () {
      final expected = (_stored()['catalog'] as Map).cast<String, dynamic>();
      final entry = catalog50Entry(version: version);
      expect(entry['plan'], expected['plan'], reason: 'plan');
      expect(entry, expected);
    });
  }

  test('the shared bot flies 2-6 as recorded, rules $frozen50Version', () {
    final flights = (_stored()['flights'] as Map).cast<String, dynamic>();
    for (final flight in frozen50Flights) {
      final expected = (flights[flight.name] as Map).cast<String, dynamic>();
      final run = flight.fly();
      _matches(expected, run.result, flight.name);
      expect(run.runUp, expected['runUp'], reason: flight.name);
    }
  });

  if (current != frozen50Version) {
    test('rules $current flies 2-6 exactly as 50 until Neferhoo arrives', () {
      final flights = (_stored()['flights'] as Map).cast<String, dynamic>();
      for (final flight in frozen50Flights) {
        final expected = (flights[flight.name] as Map).cast<String, dynamic>();
        final run = flight.fly(version: current);
        expect(run.runUp, expected['runUp'], reason: flight.name);
        expect(run.runUp, isNot(contains('boss=null')), reason: flight.name);
      }
    });
  }

  test('his pilots fight him as recorded, rules $frozen50Version', () {
    final pilots = (_stored()['pilots'] as Map).cast<String, dynamic>();
    for (final pilot in frozen50Pilots) {
      _matches(
        (pilots[pilot.name] as Map).cast<String, dynamic>(),
        pilot.fly(),
        pilot.name,
      );
    }
  });

  test('saved rules 50 tapes reload, re-encode to the same bytes and replay '
      'to the same digests (under rules $current code)', () {
    final tapes = (_stored()['tapes'] as Map).cast<String, dynamic>();
    for (final frozen in frozen50Tapes) {
      final text = File(frozen.file).readAsStringSync();
      final expected = (tapes[frozen.name] as Map).cast<String, dynamic>();
      expect(fnvHex(text), expected['sha'], reason: frozen.name);
      final tape = _load(frozen);
      expect(tape.recordedVersion, frozen50Version, reason: frozen.name);
      expect(tape.levelId, frozen50Level, reason: frozen.name);
      expect(tape.events, hasLength(expected['events'] as int));
      // Saved again, a 50 tape is the same bytes: no new key for old data.
      expect(_tapeText(tape), text, reason: frozen.name);
      expect(ReplayPlayer(tape).simulation.rulesVersion, frozen50Version);
      final run = replay50(tape);
      _matches(expected, run.result, frozen.name);
      expect(run.runUp, expected['runUp'], reason: frozen.name);
    }
  });

  test('recording the frozen flights again at 50 reproduces the saved tapes', () {
    for (final frozen in frozen50Tapes) {
      final saved = _load(frozen);
      expect(
        _tapeText(frozen.record(plan: saved.plan)),
        File(frozen.file).readAsStringSync(),
        reason: frozen.name,
      );
    }
  });

  if (current != frozen50Version) {
    test('the same flights recorded at rules $current fly the same run-up', () {
      final tapes = (_stored()['tapes'] as Map).cast<String, dynamic>();
      for (final frozen in frozen50Tapes) {
        final saved = _load(frozen);
        final now = frozen.record(version: current, plan: saved.plan);
        expect(now.recordedVersion, current);
        final expected = (tapes[frozen.name] as Map).cast<String, dynamic>();
        final run = replay50(now);
        expect(run.runUp, expected['runUp'], reason: frozen.name);
        // The same inputs, frame for frame, until he arrives.
        final arrival = double.parse(
          (expected['runUp'] as String).split('boss=').last,
        );
        // (a tape's clock runs from before the countdown: the cut is early)
        List<String> before(ReplayTape tape) => [
          for (final event in tape.events)
            if ((event[0] as num) < arrival * 1000 - 1000) jsonEncode(event),
        ];
        expect(before(now), before(saved), reason: frozen.name);
        expect(before(saved), isNotEmpty, reason: frozen.name);
      }
    });
  }
}
