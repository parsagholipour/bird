// Level 2-6 and Neferhoo as they fly at his rules version, frozen.
@Timeout(Duration(minutes: 10))
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/campaign.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/session_replay.dart';
import 'package:push_up_bird/domain/tracking.dart';

import 'frozen_flights.dart' show FrozenResult, fnvHex, outcomeOf;
import 'frozen_rules45_flights.dart' show frozenState;
import 'neferhoo_pilot.dart';
import 'recorded_flight.dart' show rideTheSky;

/// Egypt's guardian frozen (M1's fix round, after the W4 reviews): level 2-6
/// "Return to Sender" and Neferhoo's fight as the Egypt program left them,
/// so a later change to his rules, his level or the rules they stand on
/// shows here. It pins:
///
/// - the level's data: plan JSON, laid route, marks, card and delivery;
/// - the shared bot through the whole level (run-up, arrival, every stage,
///   defeat, the coast to the line) at 640, 800 and 864 px and 2.2 (the
///   letterboxed sky the main tree now flies), as digests of the whole state
///   each second ([frozenState] plus every latch of his fight: letters,
///   ankhs, counters, stages);
/// - R1's pilots (the design's family, careful, and a first-timer) fighting
///   him from the fight's first frame at 640, 800 and 2.2;
/// - a recorded tape of the bot's flight at 2.2: it must replay to the same
///   digests, and recording the same flight again must give the same journal.
///
/// Flights fly at `FlightSimulation.neferhooRulesVersion`. The fixture is
/// written when missing, or with `--dart-define=RECORD_FROZEN_EGYPT50=true`,
/// which may only be used on purpose: when the rules his level stands on
/// change by design (the landing renumbered him 46 → 50 and rules 47's
/// fair hearts change the hearts he floats in: re-record it then, once, and
/// say so). A difference otherwise means a rule changed for his flights.
const _record = bool.fromEnvironment('RECORD_FROZEN_EGYPT50');
final _fixture = File('test/fixtures/frozen_egypt50.json');
const _tapeDir = 'test/fixtures/frozen_egypt50_tapes';

int get _version => FlightSimulation.neferhooRulesVersion;

Map<String, dynamic> _stored() =>
    (jsonDecode(_fixture.readAsStringSync()) as Map).cast<String, dynamic>();

String _n(double v) => v.toString();

/// Every latch of his fight, as text.
String egyptState(FlightSimulation sim) {
  final boss = sim.boss;
  if (boss == null || !boss.isNeferhoo) return 'no-neferhoo\n';
  final f = boss.neferhoo;
  final b = StringBuffer()
    ..write('nef hp=${boss.hp} stage=${boss.stage}/${boss.stageReached} ')
    ..write('locks=${f.mailLocks}/${f.ankhLocks}/${f.ankhMoments} ')
    ..write('dealt=${f.lettersDealt} ret=${f.lettersReturned} ')
    ..write('land=${f.returnsLanded} thr=${f.ankhThrows} ')
    ..write('catch=${f.ankhCatches} scuff=${f.wrapScuffs}/')
    ..write('${f.scuffsSinceReturn} hits=${f.letterHits}/${f.ankhHits}\n')
    ..write('lane=${_n(f.laneY)} mail=${_n(f.mailLockedAt)} ')
    ..write('exp=${f.express} ankh=${_n(f.ankhLockedAt)} two=${f.twoAnkhs} ')
    ..write('last=${_n(f.lastReturnAt)}/${_n(f.lastLandAt)}/')
    ..write('${_n(f.lastScuffAt)} hint=${boss.neferhooHint}\n');
  for (final l in f.letters) {
    b.write(
      'L ${l.cycle}/${l.index} ${_n(l.lane)} ${_n(l.releaseAt)} '
      '${l.express} ${l.returnedAt} ${_n(l.struckX)} ${_n(l.struckY)} '
      '${l.homeAt} ${l.landedAt} ${l.spentAt} ${l.delivered}\n',
    );
  }
  for (final a in f.ankhs) {
    b.write(
      'A ${a.cycle} ${_n(a.laneA)} ${_n(a.laneB)} ${_n(a.lockedAt)} '
      '${_n(a.thrownAt)} ${_n(a.speed)} ${a.second} ${a.caughtAt}\n',
    );
  }
  return b.toString();
}

/// A running FNV hash of the state after every simulated second (a
/// checkpoint every ten seconds and at the end).
class EgyptDigest {
  final checkpoints = <String>[];
  int _hash = 0xcbf29ce484222325;

  void sample(FlightSimulation sim, int second) {
    for (final unit in '${frozenState(sim)}${egyptState(sim)}'.codeUnits) {
      _hash ^= unit;
      _hash = (_hash * 0x100000001b3) & 0xFFFFFFFFFFFFFFFF;
    }
    if (second % 10 == 0 || second < 0) {
      checkpoints.add(_hash.toRadixString(16));
    }
  }

  FrozenResult result(FlightSimulation sim, String extra) => FrozenResult(
    summary:
        't=${sim.elapsed.toStringAsFixed(2)} ${sim.phase.name} '
        '${sim.endReason?.name} stars=${sim.collectedStars} '
        'hearts=${sim.hearts} bosses=${sim.bossesDefeated} $extra',
    outcome: outcomeOf(sim),
    checkpoints: checkpoints,
  );
}

CampaignLevel get _level => Campaign.level('2-6')!;

TrackingSample _touch(double now) => TrackingSample(
  mode: PlayMode.touch,
  timestampMs: now,
  receivedMs: now,
  joints: const [],
);

/// The level's data.
Map<String, Object> egyptCatalog() {
  final level = _level;
  final sim = FlightSimulation(
    rules: TapFlyMode(rulesVersion: _version),
    practice: false,
    course: FlightCourse.starTrail,
    rulesVersion: _version,
    plan: level.plan,
  );
  final route = sim.route!;
  final positions = StringBuffer()
    ..write('goal=${route.goal} boss=${route.boss}\n');
  for (final x in route.passages) {
    positions.write('p $x\n');
  }
  for (final x in route.due) {
    positions.write('d $x\n');
  }
  for (final p in route.pieces) {
    positions.write('s ${p.piece.kind.name} ${p.number} ${p.start} ${p.end}\n');
  }
  return {
    'plan': jsonEncode(level.plan.toJson()),
    'route': fnvHex(positions.toString()),
    'passages': route.passages.length,
    'routeStars': route.stars,
    'marks': [level.marks.two, level.marks.three],
    'boss': level.boss?.name ?? '',
    'name': level.name,
    'cargo': level.delivery.cargo,
    'thanks': level.delivery.thanks,
    'hint': level.hint ?? '',
    'bossLine': Campaign.bossLine(level) ?? '',
    'campaignHp': Neferhoo.campaignHp,
  };
}

/// The shared bot through the whole level at [width] (the frozen bots'
/// loop, copied so edits to `campaign_flight.dart` cannot move a digest),
/// 50 frames a second, hearts topped up.
FrozenResult botFlight(double width, {int seconds = 300}) {
  final sim = FlightSimulation(
    rules: TapFlyMode(rulesVersion: _version),
    practice: false,
    course: FlightCourse.starTrail,
    rulesVersion: _version,
    weaponDamage: BirdRock.baseDamage,
    plan: _level.plan,
  );
  final digest = EgyptDigest();
  var now = 0.0;
  var second = 0;
  for (var frame = 1; frame <= seconds * 50; frame++) {
    now += 20;
    if (sim.hearts < 2) sim.hearts = 3;
    sim.apply(
      MovementInput(valid: true, height: .5, flap: rideTheSky(sim)),
      _touch(now),
      now,
    );
    if (sim.canSprint) sim.sprint();
    if (frame % 90 == 0) sim.startCharge();
    if (frame % 90 == 30 || (frame % 9 == 0 && sim.canShoot)) sim.shoot();
    sim.tick(.02, now, viewportWidth: width);
    if (frame % 50 == 0) digest.sample(sim, ++second);
    if (sim.phase == RunPhase.ended) break;
  }
  digest.sample(sim, -1);
  return digest.result(sim, 'route=${sim.routeSeconds.toStringAsFixed(3)}');
}

/// One of R1's pilots fighting him from the fight's first frame.
FrozenResult pilotFight(NeferhooSkill skill, double width, int seed) {
  final sim = neferhooArena(width: width, version: _version);
  final boss = sim.boss!;
  final digest = EgyptDigest();
  var second = 0;
  final run = flyNeferhoo(
    sim,
    NeferhooPilot(skill, seed: seed, careful: true),
    width: width,
    seconds: 240,
  );
  // (the digest of the end state; the run's own numbers in the summary)
  digest.sample(sim, ++second);
  digest.sample(sim, -1);
  return digest.result(
    sim,
    'fight=${run.fight?.toStringAsFixed(3)} hits=${run.hits} '
    'returns=${run.returns} hp=${boss.hp} state=${fnvHex(egyptState(sim))}',
  );
}

const _widths = {'640': 640 / 360, '800': 800 / 360, '864': 864 / 360, '2.2': 2.2};
final _pilots = <String, (NeferhooSkill, double, int)>{
  'family-640': (family, 640 / 360, 1),
  'family-2.2': (family, 2.2, 1),
  'kid-800': (kid, 800 / 360, 3),
};

String _tapeText(ReplayTape tape) => jsonEncode(tape.toJson());

ReplayTape _recordTape() {
  var now = 0.0;
  final tape = ReplayTape(
    mode: PlayMode.touch,
    practice: false,
    seed: 26,
    cycleSeconds: 3,
    bird: 2,
    reducedMotion: false,
    originMs: 0,
    course: FlightCourse.starTrail,
    recordedVersion: _version,
    weaponDamage: BirdRock.baseDamage,
    plan: _level.plan,
  );
  final recorder = FlightRecorder(tape, () => now);
  // the bot's loop with the recorder's clock kept in step
  final sim = recorder.simulation;
  for (var frame = 1; frame <= 300 * 50; frame++) {
    now += 20;
    if (sim.hearts < 2) sim.hearts = 3;
    recorder.apply(
      MovementInput(valid: true, height: .5, flap: rideTheSky(sim)),
      _touch(now),
      now,
    );
    if (sim.canSprint) recorder.command('sprint');
    if (frame % 90 == 0) recorder.command('charge');
    if (frame % 90 == 30 || (frame % 9 == 0 && sim.canShoot)) {
      recorder.command('shoot');
    }
    recorder.tick(.02, now, 2.2);
    if (sim.phase == RunPhase.ended) break;
  }
  if (sim.phase != RunPhase.ended) recorder.command('end', EndReason.quit);
  return tape;
}

/// A replay's digest: the state after every simulated second, then a
/// backward seek and the end.
FrozenResult replayEgypt(ReplayTape tape) {
  final player = ReplayPlayer(tape);
  final digest = EgyptDigest();
  final seconds = (tape.durationMs / 1000).ceil();
  for (var second = 1; second <= seconds; second++) {
    player.seek(second * 1000.0);
    digest.sample(player.simulation, second);
  }
  player.seek(tape.durationMs / 2);
  digest.sample(player.simulation, 0);
  player.seek(tape.durationMs);
  digest.sample(player.simulation, -1);
  return digest.result(player.simulation, 'replay');
}

void _recordFixture() {
  final tape = _recordTape();
  final file = File('$_tapeDir/bot-2-6-w2.2.json')
    ..parent.createSync(recursive: true)
    ..writeAsStringSync(_tapeText(tape));
  _fixture.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert({
      'rulesVersion': _version,
      'catalog': egyptCatalog(),
      'flights': {for (final MapEntry(:key, :value) in _widths.entries) key: botFlight(value).toJson()},
      'pilots': {for (final MapEntry(:key, :value) in _pilots.entries) key: pilotFight(value.$1, value.$2, value.$3).toJson()},
      'tape': {'file': file.path, 'sha': fnvHex(_tapeText(tape)), 'events': tape.events.length, ...replayEgypt(tape).toJson()},
    })}\n',
  );
}

void _matches(Map<String, dynamic> expected, FrozenResult got, String name) {
  expect(got.outcome, expected['outcome'], reason: name);
  expect(got.summary, expected['summary'], reason: name);
  expect(got.checkpoints, expected['checkpoints'], reason: name);
}

void main() {
  if (_record || !_fixture.existsSync()) {
    test('records the frozen Egypt fixture', () {
      _recordFixture();
      expect(_fixture.existsSync(), isTrue);
    });
    return;
  }

  test('2-6 keeps its plan, route, marks, card and his campaign health', () {
    expect(egyptCatalog(), (_stored()['catalog'] as Map).cast<String, dynamic>());
  });

  test('the shared bot flies 2-6 as recorded at 640, 800, 864 px and 2.2', () {
    final stored = (_stored()['flights'] as Map).cast<String, dynamic>();
    expect(stored.keys, _widths.keys);
    for (final MapEntry(:key, :value) in _widths.entries) {
      final got = botFlight(value);
      expect(got.outcome, contains('end=completed'), reason: key);
      _matches((stored[key] as Map).cast<String, dynamic>(), got, 'bot $key');
    }
  });

  test('his pilots fight him as recorded', () {
    final stored = (_stored()['pilots'] as Map).cast<String, dynamic>();
    expect(stored.keys, _pilots.keys);
    for (final MapEntry(:key, :value) in _pilots.entries) {
      final got = pilotFight(value.$1, value.$2, value.$3);
      _matches((stored[key] as Map).cast<String, dynamic>(), got, 'pilot $key');
    }
  });

  test('the saved tape reloads, replays to its digests, and records again the same', () {
    final stored = (_stored()['tape'] as Map).cast<String, dynamic>();
    final text = File(stored['file'] as String).readAsStringSync();
    expect(fnvHex(text), stored['sha']);
    final tape = ReplayTape.fromJson(jsonDecode(text) as Map<String, dynamic>);
    expect(_tapeText(tape), text, reason: 'it re-encodes to the same bytes');
    expect(tape.events, hasLength(stored['events']));
    _matches(stored, replayEgypt(tape), 'replay');
    final again = _recordTape();
    expect(_tapeText(again), text, reason: 'the same flight records the same journal');
  });
}
