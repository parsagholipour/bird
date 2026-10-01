// New York's four levels are flown by a bot, several times over.
@Timeout(Duration(minutes: 8))
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/campaign.dart';
import 'package:push_up_bird/domain/session_replay.dart';

import 'frozen_flights.dart' show fnvHex, replayFrozen;
import 'frozen_ny_flights.dart';

/// The catalog's New York levels (3-1 to 3-4) as the level-data step shipped
/// them, frozen at rules version 43: the R0 fixtures pin chapters 1 and 2 and
/// endless at 41 (`frozen_rules41_test.dart`, never touched); these pin the
/// new data and the new rules. The fixture pins:
///
/// - the four levels' plan JSON and laid route (catalog): passages, route
///   stars, marks, the steam vents' positions, the pigeon budget, the guardian
///   card lines and sprint flags;
/// - bot flights of each level (three widths, both weapons, mortal and sloppy
///   pilots) as state digests with finish or boss outcome and star totals;
/// - pilot flights (`ny_pilots.dart`: sharp, average and casual, at the base
///   weapon) of each guardian at 640 and 800 px wide, Steam Alley and Moth
///   Light, as digests: a guardian win for each mini-boss at both widths;
/// - four saved rules-43 tapes as the app would save them: King Coo beaten at
///   640 px, the Gargoyle beaten at 800 px, a whole Steam Alley, and a LEGACY
///   tape of Steam Alley as it was shipped before the fix round (80 s, seed
///   3103, cut after 40 s). They must reload, re-encode to the same bytes and
///   replay to the same digests, and recording the same flights again must
///   reproduce them byte for byte (that last check also pins the pilots of
///   `ny_pilots.dart`); the legacy tape proves a retuned level still replays
///   the way it was flown.
///
/// Re-recorded by the fix round (R5, `docs/validation.md`), deliberately,
/// because 3-1, 3-3 and 3-4's data changed: the only fixture entries that
/// moved are the catalog entries of those three levels and every flight that
/// flies them; 3-2's entries and tape are byte-identical to before.
///
/// Nothing here may be re-recorded to make a failure go away: a difference
/// means a rule, a random draw or a plan key changed for New York's data.
/// One deliberate exception, the Gargoyle's fix round: the slit's corridor
/// (.214 to .314) and the lamp judged as a rock leaves changed his fight, so
/// the six 3-4 bot flights, the six Gargoyle pilot flights and the tape
/// `campaign-3-4-gargoyle-800` were re-recorded; everything else is
/// byte-identical to the earlier recording.
/// The fixture is written when it is missing, or with
/// `--dart-define=RECORD_FROZEN_NY43=true`, from a tree that flies rules 43
/// and the New York data as shipped.
const _record = bool.fromEnvironment('RECORD_FROZEN_NY43');
final _fixture = File('test/fixtures/frozen_ny43.json');

Map<String, dynamic> _stored() =>
    (jsonDecode(_fixture.readAsStringSync()) as Map).cast<String, dynamic>();

String _tapeText(ReplayTape tape) => jsonEncode(tape.toJson());

ReplayTape _load(FrozenNyTape frozen) => ReplayTape.fromJson(
  jsonDecode(File(frozen.file).readAsStringSync()) as Map<String, dynamic>,
);

void _recordFixture() {
  final catalog = {
    for (final level in nyLevels) level.id: catalogNyEntry(level),
  };
  final flights = {
    for (final flight in frozenNyFlights) flight.name: flight.fly().toJson(),
  };
  final pilots = {
    for (final flight in frozenNyPilotFlights)
      flight.name: flight.fly().toJson(),
  };
  final tapes = <String, Object>{};
  for (final frozen in frozenNyTapes) {
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
    '${const JsonEncoder.withIndent('  ').convert({'rulesVersion': frozenNyVersion, 'catalog': catalog, 'flights': flights, 'pilots': pilots, 'tapes': tapes})}\n',
  );
}

void main() {
  if (_record || !_fixture.existsSync()) {
    test('records the frozen rules 43 New York fixture', () {
      _recordFixture();
      expect(_fixture.existsSync(), isTrue);
    });
    return;
  }

  test('the fixture covers exactly 3-1 to 3-4', () {
    final stored = _stored();
    expect(stored['rulesVersion'], frozenNyVersion);
    expect(nyLevels.map((l) => l.id), ['3-1', '3-2', '3-3', '3-4']);
    expect((stored['catalog'] as Map).keys, [for (final l in nyLevels) l.id]);
    final flown = {for (final f in frozenNyFlights) f.level};
    expect(flown, {for (final l in nyLevels) l.id});
    expect((stored['flights'] as Map).keys, [
      for (final f in frozenNyFlights) f.name,
    ]);
    expect((stored['pilots'] as Map).keys, [
      for (final f in frozenNyPilotFlights) f.name,
    ]);
    expect((stored['tapes'] as Map).keys, [
      for (final t in frozenNyTapes) t.name,
    ]);
  });

  test('the four levels keep their saved plan JSON and their laid route', () {
    final catalog = (_stored()['catalog'] as Map).cast<String, dynamic>();
    for (final level in nyLevels) {
      final entry = catalogNyEntry(level);
      final expected = (catalog[level.id] as Map).cast<String, dynamic>();
      // The plan first: a changed key or number shows here.
      expect(entry['plan'], expected['plan'], reason: '${level.id} plan');
      expect(entry, expected, reason: level.id);
    }
    // Star totals as shipped by the fix round: 81, 36, 90 and 36 route stars
    // (96 and 114 for 3-1 and 3-3 at their old 70 s and 80 s).
    expect(
      [
        for (final level in nyLevels)
          (catalog[level.id] as Map)['routeStars'] as int,
      ],
      [81, 36, 90, 36],
    );
    expect((catalog['3-3'] as Map)['geysers'], 7);
    expect((catalog['3-4'] as Map)['geysers'], 3);
    expect(nyLevels.length * 3, 12);
  });

  test('bot flights of all four levels match the recording, rules 43', () {
    final flights = (_stored()['flights'] as Map).cast<String, dynamic>();
    for (final flight in frozenNyFlights) {
      final result = flight.fly();
      final expected = (flights[flight.name] as Map).cast<String, dynamic>();
      expect(result.outcome, expected['outcome'], reason: flight.name);
      expect(result.summary, expected['summary'], reason: flight.name);
      expect(result.checkpoints, expected['checkpoints'], reason: flight.name);
    }
  });

  test(
    'pilot flights of both guardians and Steam Alley match the recording',
    () {
      final pilots = (_stored()['pilots'] as Map).cast<String, dynamic>();
      for (final flight in frozenNyPilotFlights) {
        final result = flight.fly();
        final expected = (pilots[flight.name] as Map).cast<String, dynamic>();
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

  test('every guardian pilot flight is a win, at 640 and 800 px wide', () {
    final pilots = (_stored()['pilots'] as Map).cast<String, dynamic>();
    final wins = <String, Set<String>>{};
    for (final flight in frozenNyPilotFlights) {
      final outcome = (pilots[flight.name] as Map)['outcome'] as String;
      final guardian = Campaign.level(flight.level)!.isGuardian;
      expect(outcome, contains('end=completed'), reason: flight.name);
      expect(outcome, contains('bosses=${guardian ? 1 : 0}'));
      if (guardian) {
        wins
            .putIfAbsent(flight.level, () => {})
            .add(flight.width < 2 ? '640' : '800');
      }
    }
    expect(wins, {
      '3-2': {'640', '800'},
      '3-4': {'640', '800'},
    });
    // Each guardian at three skills at each width.
    expect(
      frozenNyPilotFlights.where((f) => f.level == '3-2' && f.width < 2),
      hasLength(3),
    );
  });

  test('a level below its rules version refuses to fly (rules 41)', () {
    for (final level in nyLevels.skip(1)) {
      expect(
        () => FrozenNyFlight(level.id).fly(version: 41),
        throwsArgumentError,
        reason: level.id,
      );
    }
    // Moth Light is a rules 41 plan and still flies at 41 (as in chapter 2).
    expect(FrozenNyFlight('3-1').fly(version: 41).outcome, contains('end='));
  });

  test('the frozen bot flights finish the levels and beat the guardians', () {
    final flights = (_stored()['flights'] as Map).cast<String, dynamic>();
    for (final level in nyLevels) {
      // Topped-up hearts and the upgraded weapon: the bot always finishes.
      final outcome = (flights[level.id] as Map)['outcome'] as String;
      expect(outcome, contains('end=completed'), reason: level.id);
      expect(outcome, contains('finish=crossed'), reason: level.id);
      expect(
        outcome,
        contains('bosses=${level.isBoss ? 1 : 0}'),
        reason: level.id,
      );
    }
    // Hurt flights exist too: at least one run that ended on its hearts.
    final ended = [
      for (final f in flights.values)
        if (((f as Map)['outcome'] as String).contains('end=collision')) f,
    ];
    expect(ended, isNotEmpty);
  });

  test(
    'saved rules 43 tapes reload, re-encode to the same bytes and replay',
    () {
      final tapes = (_stored()['tapes'] as Map).cast<String, dynamic>();
      for (final frozen in frozenNyTapes) {
        final text = File(frozen.file).readAsStringSync();
        final expected = (tapes[frozen.name] as Map).cast<String, dynamic>();
        expect(fnvHex(text), expected['sha'], reason: frozen.name);
        final tape = _load(frozen);
        expect(tape.recordedVersion, frozenNyVersion, reason: frozen.name);
        expect(tape.levelId, frozen.level, reason: frozen.name);
        expect(tape.weaponDamage, 10, reason: 'the weapon the campaign gives');
        expect(tape.events, hasLength(expected['events'] as int));
        // Saved again, a 43 tape is the same bytes.
        expect(_tapeText(tape), text, reason: frozen.name);
        final player = ReplayPlayer(tape);
        expect(player.simulation.rulesVersion, frozenNyVersion);
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

  test('the saved tapes are a guardian win each and a whole Steam Alley', () {
    final tapes = (_stored()['tapes'] as Map).cast<String, dynamic>();
    final current = [
      for (final t in frozenNyTapes)
        if (!t.legacy) t,
    ];
    expect([for (final t in current) t.level], ['3-2', '3-3', '3-4']);
    for (final frozen in current) {
      final outcome = (tapes[frozen.name] as Map)['outcome'] as String;
      final guardian = Campaign.level(frozen.level)!.isGuardian;
      expect(outcome, contains('end=completed'), reason: frozen.name);
      expect(outcome, contains('finish=crossed'), reason: frozen.name);
      expect(outcome, contains('bosses=${guardian ? 1 : 0}'));
    }
    final steam = _load(current[1]).plan!;
    expect(steam.steam, isNotNull);
    expect(steam.steam.isEmpty, isFalse);
  });

  test('recording the frozen flights again reproduces the saved tapes', () {
    for (final frozen in frozenNyTapes) {
      expect(
        _tapeText(frozen.record()),
        File(frozen.file).readAsStringSync(),
        reason: frozen.name,
      );
    }
  });

  test('the saved tapes carry the catalog\'s plans, but the legacy one', () {
    for (final frozen in frozenNyTapes) {
      final tape = _load(frozen);
      final catalog = Campaign.level(frozen.level)!.plan.toJson();
      if (frozen.legacy) {
        expect(tape.plan!.toJson(), frozen.plan!.toJson());
        expect(tape.plan!.toJson(), isNot(catalog), reason: frozen.name);
      } else {
        expect(tape.plan!.toJson(), catalog, reason: frozen.name);
      }
    }
  });

  test('a level retuned after a flight was saved still replays it the way '
      'it was flown', () {
    // Steam Alley was 80 s with seed 3103 until the fix round made it 65 s
    // with seed 3111. A tape saved before keeps its whole plan, so it replays
    // on the old level, to the digest it was recorded with, whatever the
    // catalog says now.
    final legacy = frozenNyTapes.singleWhere((t) => t.legacy);
    final tape = _load(legacy);
    final catalogPlan = Campaign.level('3-3')!.plan;
    expect((tape.plan!.length, tape.plan!.seed), (80.0, 3103));
    expect((catalogPlan.length, catalogPlan.seed), (65.0, 3111));
    final stored = (_stored()['tapes'] as Map)[legacy.name] as Map;
    final result = replayFrozen(tape);
    expect(result.outcome, stored['outcome']);
    expect(result.checkpoints, stored['checkpoints']);
    // Four vents and two pigeon formations of the old route were flown.
    final end = ReplayPlayer(tape)..seek(tape.durationMs);
    expect(end.simulation.steamBursts, 4);
    expect(end.simulation.pigeonWarnings, greaterThan(0));
  });
}
