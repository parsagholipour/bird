// Every campaign level is flown by a bot, several times over.
@Timeout(Duration(minutes: 8))
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/campaign.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/session_replay.dart';

import 'frozen_flights.dart';

/// Chapters 1 and 2 and endless flights as they flew at rules version 41,
/// before the co-op (42) and New York (43) programs changed anything. The fixture was
/// recorded from the committed game at 41, untouched, and pins:
///
/// - the 16 playable levels' plan JSON and laid route (catalog);
/// - a bot flight of each level, plus variations (narrow and wide screens,
///   the base weapon, a mortal bird), as state digests with their finish or
///   boss outcome and star totals;
/// - three saved rules-41 tapes (one endless, two campaign) as the app would
///   save them: they must reload, re-encode to the same bytes and replay to
///   the same digests, and recording the same flight again must reproduce
///   them byte for byte.
///
/// Every flight is run at 41, at 42 (Fly Together's version) and at the
/// current rules version (43, New York): endless flights and chapters 1 and 2
/// must behave identically at all three, and a tape recorded at 41 replays at
/// 41. Nothing here may be re-recorded to make a
/// failure go away: a difference means a rule, a random draw or a plan key
/// changed for old data.
///
/// The fixture is written when it is missing, or with
/// `--dart-define=RECORD_FROZEN_RULES41=true`, which must be used only from
/// a tree that flies rules 41 as it was committed.
const _record = bool.fromEnvironment('RECORD_FROZEN_RULES41');
final _fixture = File('test/fixtures/frozen_rules41.json');

Map<String, dynamic> _stored() =>
    (jsonDecode(_fixture.readAsStringSync()) as Map).cast<String, dynamic>();

String _tapeText(ReplayTape tape) => jsonEncode(tape.toJson());

ReplayTape _load(FrozenTape frozen) => ReplayTape.fromJson(
  jsonDecode(File(frozen.file).readAsStringSync()) as Map<String, dynamic>,
);

/// Records whatever part of the fixture is missing or asked for.
void _recordFixture() {
  final catalog = {
    for (final level in frozenLevels) level.id: catalogEntry(level),
  };
  final flights = {
    for (final flight in frozenFlights) flight.name: flight.fly().toJson(),
  };
  final tapes = <String, Object>{};
  for (final frozen in frozenTapes) {
    final tape = frozen.record();
    File(frozen.file)
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(_tapeText(tape));
    tapes[frozen.name] = {
      'file': frozen.file,
      'sha': fnvHex(_tapeText(tape)),
      'events': tape.events.length,
      ...replayFrozen(tape).toJson(),
    };
  }
  _fixture.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert({'rulesVersion': frozenVersion, 'catalog': catalog, 'flights': flights, 'tapes': tapes})}\n',
  );
}

void main() {
  if (_record || !_fixture.existsSync()) {
    test('records the frozen rules 41 fixture', () {
      _recordFixture();
      expect(_fixture.existsSync(), isTrue);
    });
    return;
  }

  // Runs at 41, at co-op's 42 and at whatever version is current (43).
  final versions = {
    frozenVersion,
    FlightSimulation.coopRulesVersion,
    FlightSimulation.currentRulesVersion,
  };

  test('the fixture covers exactly chapters 1 and 2 (16 levels)', () {
    final stored = _stored();
    expect(stored['rulesVersion'], frozenVersion);
    expect(frozenLevels, hasLength(16));
    expect((stored['catalog'] as Map).keys, [
      for (final level in frozenLevels) level.id,
    ]);
    final flown = {for (final f in frozenFlights) f.level};
    expect(flown, {for (final level in frozenLevels) level.id});
    expect((stored['flights'] as Map).keys, [
      for (final f in frozenFlights) f.name,
    ]);
    expect((stored['tapes'] as Map).keys, [
      for (final t in frozenTapes) t.name,
    ]);
  });

  test('the 16 levels keep their saved plan JSON and their laid route', () {
    final catalog = (_stored()['catalog'] as Map).cast<String, dynamic>();
    for (final level in frozenLevels) {
      final entry = catalogEntry(level);
      final expected = (catalog[level.id] as Map).cast<String, dynamic>();
      // The plan first: a new key written for an old plan shows here.
      expect(entry['plan'], expected['plan'], reason: '${level.id} plan');
      expect(entry, expected, reason: level.id);
    }
    // Star totals across the campaign as played at 41.
    final stars = [
      for (final level in frozenLevels)
        (catalog[level.id] as Map)['routeStars'] as int,
    ];
    expect(stars.every((s) => s > 0), isTrue);
    expect(frozenLevels.length * 3, 48);
  });

  for (final version in versions) {
    test(
      'bot flights of all 16 levels match the recording, rules $version',
      () {
        final flights = (_stored()['flights'] as Map).cast<String, dynamic>();
        for (final flight in frozenFlights) {
          final result = flight.fly(version: version);
          final expected = (flights[flight.name] as Map)
              .cast<String, dynamic>();
          expect(result.outcome, expected['outcome'], reason: flight.name);
          expect(result.summary, expected['summary'], reason: flight.name);
          expect(
            result.checkpoints,
            expected['checkpoints'],
            reason: flight.name,
          );
        }
      },
    );
  }

  test('the frozen flights finish their levels and defeat their bosses', () {
    final flights = (_stored()['flights'] as Map).cast<String, dynamic>();
    for (final level in frozenLevels) {
      final outcome = (flights[level.id] as Map)['outcome'] as String;
      expect(outcome, contains('end=completed'), reason: level.id);
      expect(outcome, contains('finish=crossed'), reason: level.id);
      expect(
        outcome,
        contains('bosses=${level.isBoss ? 1 : 0}'),
        reason: level.id,
      );
    }
  });

  test(
    'saved rules 41 tapes reload, re-encode to the same bytes and replay',
    () {
      final tapes = (_stored()['tapes'] as Map).cast<String, dynamic>();
      for (final frozen in frozenTapes) {
        final text = File(frozen.file).readAsStringSync();
        final expected = (tapes[frozen.name] as Map).cast<String, dynamic>();
        expect(fnvHex(text), expected['sha'], reason: frozen.name);
        final tape = _load(frozen);
        expect(tape.recordedVersion, frozenVersion, reason: frozen.name);
        expect(tape.levelId, frozen.level, reason: frozen.name);
        expect(tape.events, hasLength(expected['events'] as int));
        // Saved again, a 41 tape is the same bytes: no new key for old data.
        expect(_tapeText(tape), text, reason: frozen.name);
        final player = ReplayPlayer(tape);
        expect(player.simulation.rulesVersion, frozenVersion);
        final result = replayFrozen(tape);
        expect(result.outcome, expected['outcome'], reason: frozen.name);
        expect(result.summary, expected['summary'], reason: frozen.name);
        expect(
          result.checkpoints,
          expected['checkpoints'],
          reason: frozen.name,
        );
      }
    },
  );

  test('recording the frozen flights again reproduces the saved tapes', () {
    for (final frozen in frozenTapes) {
      expect(
        _tapeText(frozen.record()),
        File(frozen.file).readAsStringSync(),
        reason: frozen.name,
      );
    }
  });

  test('the saved tapes cover an endless flight and two campaign levels', () {
    expect(frozenTapes.where((t) => t.level == null), hasLength(1));
    expect(frozenTapes.where((t) => t.level != null), hasLength(2));
    final endless = _load(frozenTapes.first);
    expect(endless.plan, isNull);
    final json = jsonDecode(File(frozenTapes.first.file).readAsStringSync());
    expect((json as Map).containsKey('plan'), isFalse);
    for (final frozen in frozenTapes.skip(1)) {
      final tape = _load(frozen);
      expect(tape.plan!.toJson(), Campaign.level(frozen.level!)!.plan.toJson());
    }
  });
}
