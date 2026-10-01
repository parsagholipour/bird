import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/session_replay.dart';
import 'package:push_up_bird/domain/tracking.dart';

import 'recorded_flight.dart';

/// Endless flights, and every rules version they can be replayed with, are
/// locked to digests recorded before the campaign's flight plans existed.
/// Every flight is seeded and scripted, so a digest changes only when a rule,
/// a random draw or its order does.
///
/// The fixture is written when it is missing, or with
/// `--dart-define=RECORD_ENDLESS_BASELINE=true`. With
/// `--dart-define=DUMP_ENDLESS_BASELINE=true` every sampled state is also
/// written to build/endless-baseline/ as text, to diff a changed flight.
const _record = bool.fromEnvironment('RECORD_ENDLESS_BASELINE');
const _dump = bool.fromEnvironment('DUMP_ENDLESS_BASELINE');
final _fixture = File('test/fixtures/endless_plan_baseline.json');

/// Counts every draw, so a draw added, lost or moved changes the digest even
/// when its value happens to change nothing else.
class CountingRandom implements Random {
  CountingRandom(int seed) : _random = Random(seed);
  final Random _random;
  int draws = 0;

  @override
  bool nextBool() {
    draws++;
    return _random.nextBool();
  }

  @override
  double nextDouble() {
    draws++;
    return _random.nextDouble();
  }

  @override
  int nextInt(int max) {
    draws++;
    return _random.nextInt(max);
  }
}

/// 64-bit FNV-1a over the UTF-16 code units, stable across runs.
int _fnv(int hash, String text) {
  for (final unit in text.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x100000001b3) & 0xFFFFFFFFFFFFFFFF;
  }
  return hash;
}

const _fnvOffset = 0xcbf29ce484222325;

String _n(double value) => value.toString();

/// Everything the rules own that can differ between two flights, written
/// with full precision.
String stateOf(FlightSimulation sim, {int? draws}) {
  final b = StringBuffer()
    ..write('t=${_n(sim.elapsed)} d=${_n(sim.distance)} ')
    ..write('y=${_n(sim.birdY)} v=${_n(sim.velocity)} ')
    ..write('ph=${sim.phase.name} end=${sim.endReason?.name} ')
    ..write('cd=${_n(sim.countdown)} st=${sim.started}\n')
    ..write('score=${sim.score} gates=${sim.gates} reps=${sim.repetitions} ')
    ..write('flaps=${sim.flaps} stars=${sim.collectedStars} ')
    ..write('combo=${sim.combo}/${sim.bestCombo} trios=${sim.completedTrios} ')
    ..write('perfect=${sim.perfectPasses}/${sim.perfectStreak}\n')
    ..write('hearts=${sim.hearts} shield=${sim.shield} ')
    ..write('inv=${_n(sim.invulnerableUntil)} ')
    ..write('magnet=${sim.magnetCharge}/${_n(sim.magnetUntil)}/')
    ..write('${sim.magnetActivations} glide=${_n(sim.glideRemaining)}\n')
    ..write('speed=${_n(sim.speed)} gap=${_n(sim.gap)} ')
    ..write('interval=${_n(sim.spawnInterval)} pace=${_n(sim.paceMultiplier)} ')
    ..write('boost=${_n(sim.courseBoost)}\n')
    ..write('ammo=${_n(sim.ammo)} shots=${sim.shots} dry=${sim.dryFires} ')
    ..write('lastShot=${_n(sim.lastShotAt)}/${_n(sim.lastShotCharge)} ')
    ..write('charge=${sim.chargeStartedAt} sprints=${sim.sprints} ')
    ..write('lastSprint=${_n(sim.lastSprintAt)} ')
    ..write('ring=${_n(sim.ringSprintFrom)}/${_n(sim.ringSprintUntil)}\n')
    ..write('defeated=${sim.bossesDefeated} enemies=${sim.enemiesDefeated} ')
    ..write('doors=${sim.doorsDestroyed} impacts=${sim.rockImpacts} ')
    ..write('deflected=${sim.projectilesDeflected} ')
    ..write('enemyShots=${sim.enemyShots} shattered=${sim.ammoShattered} ')
    ..write('splashes=${sim.cannonSplashes}/${sim.birdSplashes} ')
    ..write('embers=${sim.emberSplits} burns=${sim.breathBurns} ')
    ..write('screeched=${sim.screechHits}\n')
    ..write('rush=${sim.rushPathsRun}/${sim.rushWarnings}/')
    ..write('${sim.rushPathsEscaped} rings=${sim.ringSprints}/')
    ..write('${sim.ringChain} smash=${sim.smashes}/${sim.smashChain}/')
    ..write('${sim.meteorsSmashed} vents=${sim.ventsErupted} ')
    ..write('swarm=${sim.swarmSmashed} last=${sim.lastRushKind?.name} ')
    ..write('bag=${sim.rushKinds.map((k) => k.name).join(',')}\n')
    ..write('gales=${sim.galesBlown}/${sim.galeWarnings}/')
    ..write('${sim.galesWeathered} gusts=${sim.gusts} ')
    ..write('dodges=${sim.galeDodges}\n');
  if (draws != null) b.write('draws=$draws\n');
  final boss = sim.boss;
  if (boss != null) {
    b
      ..write('boss ${boss.kind.name} #${boss.number} hp=${boss.hp}/')
      ..write('${boss.maxHp} ${boss.phase.name} x=${_n(boss.x)} ')
      ..write('y=${_n(boss.y)} age=${_n(boss.age)} fire=${_n(boss.fireIn)} ')
      ..write('summon=${_n(boss.summonIn)} volleys=${boss.volleys} ')
      ..write('summons=${boss.summons} debut=${boss.debut} ')
      ..write('upgraded=${boss.upgraded} slot=${boss.openSlot} ')
      ..write('breath=${boss.breathLane.name}/${boss.breathsAimed} ')
      ..write('screech=${boss.screechGap.name}/${boss.screechesAimed}\n');
  }
  for (final o in sim.obstacles) {
    b
      ..write('o ${o.kind.name} x=${_n(o.x)} c=${_n(o.baseCenter)} ')
      ..write('g=${_n(o.baseGap)} t=${_n(o.target)} w=${_n(o.width)} ')
      ..write('a=${_n(o.amplitude)} p=${_n(o.period)} ')
      ..write('ph=${_n(o.phaseOffset)} born=${_n(o.bornAt)} ')
      ..write('look=${o.appearance} rubble=${o.rubble} ')
      ..write('door=${o.door?.hp} smashed=${o.smashedAt} ')
      ..write('scored=${o.scored} hit=${o.hit} dev=${_n(o.maxDeviation)}\n');
  }
  for (final e in sim.enemies) {
    b
      ..write('e ${e.appearance} x=${_n(e.x)} y=${_n(e.y)} ')
      ..write('hp=${e.hp}/${e.maxHp} fire=${_n(e.fireIn)} ')
      ..write('volleys=${e.volleys} drift=${_n(e.drift)}\n');
  }
  for (final s in sim.stars) {
    b.write('s ${_n(s.x)} ${_n(s.y)} ${s.collected} ${s.missed}\n');
  }
  b.write('trios=${sim.starTrios.length} ');
  for (final h in sim.heartPickups) {
    b.write('heart ${_n(h.x)} ${_n(h.y)} ');
  }
  b.write('\n');
  for (final r in sim.rocks) {
    b.write('r ${_n(r.x)} ${_n(r.y)} ${r.damage} ${_n(r.charge)}\n');
  }
  for (final a in sim.enemyAmmo) {
    b.write('ea ${_n(a.x)} ${_n(a.y)}\n');
  }
  for (final a in sim.bossAmmo) {
    b.write('ba ${_n(a.x)} ${_n(a.y)} ${_n(a.vy)}\n');
  }
  final path = sim.rushPath;
  if (path != null) {
    b
      ..write('path ${path.kind.name} ${path.phase.name} ')
      ..write('${_n(path.startDistance)} ${_n(path.endDistance)} ')
      ..write('${_n(path.resumeDistance)} resumed=${path.resumed} ')
      ..write('fire=${_n(path.fireDistance)} meteors=${path.meteors} ')
      ..write('flocks=${path.flocks} catches=${path.catches} ')
      ..write('heights=${path.heights.map(_n).join(',')}\n');
  }
  for (final ring in sim.sprintRings) {
    b.write('ring ${_n(ring.x)} ${_n(ring.y)} ${ring.collected}\n');
  }
  for (final m in sim.meteors) {
    b.write('m ${_n(m.x)} ${_n(m.y)}\n');
  }
  for (final vent in sim.lavaVents) {
    b.write('vent ${_n(vent.x)} ${vent.rumbledAt} ${vent.eruptedAt}\n');
  }
  for (final bat in sim.swarm) {
    b.write('bat ${_n(bat.x)} ${_n(bat.y)}\n');
  }
  final gale = sim.gale;
  if (gale != null) {
    b
      ..write('gale ${gale.phase.name} ${_n(gale.startDistance)} ')
      ..write('gusts=${gale.gusts} hits=${gale.hits}\n');
  }
  for (final d in sim.galeDebris) {
    b.write('debris ${_n(d.x)} ${_n(d.y)} ${d.hitAt} ${d.dodged}\n');
  }
  for (final e in sim.events) {
    b.write('ev ${e.kind.name} ${_n(e.at)} ${e.value}\n');
  }
  return b.toString();
}

/// A flight's digest: the running hash of its state after every simulated
/// second, checkpointed every ten seconds, plus a readable summary.
class FlightDigest {
  final List<String> checkpoints = [];
  final StringBuffer dump = StringBuffer();
  int _hash = _fnvOffset;
  void sample(FlightSimulation sim, int second, {int? draws}) {
    final state = stateOf(sim, draws: draws);
    _hash = _fnv(_hash, state);
    if (_dump) dump.write('--- $second\n$state');
    if (second % 10 == 0 || second < 0) {
      checkpoints.add(_hash.toRadixString(16));
    }
  }

  String summary(FlightSimulation sim, {int? draws}) =>
      't=${sim.elapsed.toStringAsFixed(2)} ${sim.phase.name} '
      '${sim.endReason?.name} score=${sim.score} gates=${sim.gates} '
      'stars=${sim.collectedStars} hearts=${sim.hearts} '
      'bosses=${sim.bossesDefeated} rush=${sim.rushPathsRun} '
      'gales=${sim.galesBlown} doors=${sim.doorsDestroyed} '
      'enemies=${sim.enemiesDefeated} draws=$draws';

  Map<String, Object> toJson(String summary) => {
    'summary': summary,
    'checkpoints': checkpoints,
  };
}

/// A touch pilot: the shared sky-riding bot flaps, a charged shot goes off
/// every 1.8 seconds with tapped shots between, and Sprint fires whenever it
/// is ready. [keepAlive] tops the hearts up so a long flight meets every boss.
void touchPilot(
  FlightSimulation sim,
  int frame,
  double now, {
  required bool keepAlive,
}) {
  if (keepAlive && sim.hearts < 2) sim.hearts = 3;
  sim.apply(
    MovementInput(valid: true, height: .5, flap: rideTheSky(sim)),
    TrackingSample(
      mode: PlayMode.touch,
      timestampMs: now,
      receivedMs: now,
      joints: const [],
    ),
    now,
  );
  if (sim.canSprint) sim.sprint();
  switch (frame % 90) {
    case 0:
      sim.startCharge();
    case 30:
      sim.shoot();
    default:
      if (frame % 9 == 0 && !sim.charging && sim.canShoot) sim.shoot();
  }
}

/// A height pilot for camera modes: it eases toward the next opening at
/// the calibrated cadence, and jump modes hop when they drop below it.
void heightPilot(FlightSimulation sim, double now, {double cycle = 3}) {
  final ahead = sim.obstacles.where((o) => !o.scored);
  final target = ahead.isEmpty ? .5 : ahead.first.target;
  final maxStep = .7 / (cycle / 2) * .02;
  final y = sim.birdY + (target - sim.birdY).clamp(-maxStep, maxStep);
  final mode = sim.rules.mode;
  sim.apply(
    MovementInput(
      valid: true,
      height: (.85 - y) / .7,
      flap: !mode.controlsHeight && sim.birdY > target && sim.velocity >= 0,
    ),
    TrackingSample(
      mode: mode,
      timestampMs: now,
      receivedMs: now,
      joints: const [],
    ),
    now,
  );
}

class Flight {
  const Flight(
    this.name, {
    required this.rules,
    this.version = 40,
    this.course = FlightCourse.starTrail,
    this.seconds = 300,
    this.width = 2.2,
    this.damage = 60,
    this.seed = 7,
    this.keepAlive = true,
    this.reducedMotion = false,
    this.practice = false,
  });
  final String name;
  final GameMode Function(int version) rules;
  final int version, seconds, damage, seed;
  final FlightCourse course;
  final double width;
  final bool keepAlive, reducedMotion, practice;

  (FlightDigest, String) fly() {
    final random = CountingRandom(seed);
    final sim = FlightSimulation(
      rules: rules(version),
      practice: practice,
      course: course,
      rulesVersion: version,
      weaponDamage: damage,
      random: random,
    );
    final digest = FlightDigest();
    var now = 0.0;
    for (var frame = 1; frame <= seconds * 50; frame++) {
      now += 20;
      if (sim.rules.mode == PlayMode.touch) {
        touchPilot(sim, frame, now, keepAlive: keepAlive);
      } else {
        heightPilot(sim, now);
      }
      sim.tick(.02, now, viewportWidth: width, reducedMotion: reducedMotion);
      if (frame % 50 == 0) digest.sample(sim, frame ~/ 50, draws: random.draws);
      if (sim.phase == RunPhase.ended) break;
    }
    digest.sample(sim, -1, draws: random.draws);
    return (digest, digest.summary(sim, draws: random.draws));
  }
}

GameMode _tap(int version) => TapFlyMode(rulesVersion: version);

final flights = [
  // Long touch Star Trails: five bosses, the upgraded Baron's return, every
  // rush path, a gale, stone panels and heart pickups.
  const Flight('touch-v40-long', rules: _tap, seconds: 560),
  const Flight('touch-v40-narrow', rules: _tap, seconds: 420, width: 1.6),
  const Flight('touch-v40-wide', rules: _tap, seconds: 420, width: 2.4),
  const Flight(
    'touch-v40-reduced',
    rules: _tap,
    seconds: 240,
    seed: 11,
    reducedMotion: true,
  ),
  // The base weapon: long fights, and no top-ups, so the flight ends.
  const Flight(
    'touch-v40-base-weapon',
    rules: _tap,
    seconds: 400,
    damage: 10,
    keepAlive: false,
  ),
  const Flight(
    'touch-v40-base-kept',
    rules: _tap,
    seconds: 360,
    damage: 10,
    seed: 23,
  ),
  for (final version in [
    5,
    7,
    12,
    13,
    15,
    16,
    18,
    19,
    20,
    21,
    22,
    23,
    24,
    25,
    26,
    27,
    28,
    29,
    31,
    32,
    33,
    34,
    35,
    36,
    37,
    38,
    39,
  ])
    Flight('touch-v$version', rules: _tap, version: version, seconds: 330),
  const Flight(
    'touch-classic-v40',
    rules: _tap,
    course: FlightCourse.classic,
    seconds: 200,
  ),
  const Flight(
    'touch-classic-v40-practice',
    rules: _tap,
    course: FlightCourse.classic,
    seconds: 200,
    practice: true,
  ),
  Flight(
    'push-up-trail-v40',
    rules: (_) => PushUpFlightMode(cycleSeconds: 3),
    seconds: 240,
  ),
  Flight(
    'squat-classic-v40',
    rules: (_) => SquatFlyMode(cycleSeconds: 2),
    course: FlightCourse.classic,
    seconds: 240,
  ),
  Flight('jump-trail-v40', rules: (_) => JumpFlyMode(), seconds: 240),
  Flight(
    'jump-trail-v10',
    rules: (_) => JumpFlyMode(),
    version: 10,
    seconds: 120,
  ),
  Flight(
    'push-up-trail-v4',
    rules: (_) => PushUpFlightMode(cycleSeconds: 3),
    version: 4,
    seconds: 90,
  ),
];

/// A scored touch flight through [FlightRecorder], saved as JSON and
/// replayed from the tape.
ReplayTape recordTouch({required int version, int seed = 31}) {
  var now = 0.0;
  final tape = ReplayTape(
    mode: PlayMode.touch,
    practice: false,
    seed: seed,
    cycleSeconds: 3,
    bird: 1,
    reducedMotion: false,
    originMs: 0,
    course: FlightCourse.starTrail,
    recordedVersion: version,
  );
  final recorder = FlightRecorder(tape, () => now);
  final sim = recorder.simulation;
  for (var frame = 1; frame <= 300 * 50; frame++) {
    now += 20;
    recorder.apply(
      MovementInput(valid: true, height: .5, flap: rideTheSky(sim)),
      TrackingSample(
        mode: PlayMode.touch,
        timestampMs: now,
        receivedMs: now,
        joints: const [],
      ),
      now,
    );
    if (version >= 29 && sim.canSprint) recorder.command('sprint');
    if (version >= 28 && frame % 90 == 0) recorder.command('charge');
    if (frame % 90 == 30) recorder.command('shoot');
    if (frame == 1000 && sim.supportsWeaponDamage) recorder.setWeaponDamage(30);
    recorder.tick(.02, now, 2.2);
    if (sim.phase == RunPhase.ended) break;
  }
  if (sim.phase != RunPhase.ended) recorder.command('end', EndReason.quit);
  return ReplayTape.fromJson(
    jsonDecode(jsonEncode(tape.toJson())) as Map<String, dynamic>,
  );
}

FlightDigest replayDigest(ReplayTape tape) {
  final player = ReplayPlayer(tape);
  final digest = FlightDigest();
  final seconds = (tape.durationMs / 1000).ceil();
  for (var second = 1; second <= seconds; second++) {
    player.seek(second * 1000.0);
    digest.sample(player.simulation, second);
  }
  // A backward seek reruns the journal from the start.
  player.seek(tape.durationMs / 2);
  digest.sample(player.simulation, 0);
  player.seek(tape.durationMs);
  digest.sample(player.simulation, -1);
  return digest;
}

void main() {
  test('endless flights match the recorded baseline, for every version', () {
    final results = <String, Object>{};
    final dumps = <String, String>{};
    for (final flight in flights) {
      final (digest, summary) = flight.fly();
      results[flight.name] = digest.toJson(summary);
      dumps[flight.name] = digest.dump.toString();
    }
    for (final version in [27, 33, 38, 40]) {
      final tape = recordTouch(version: version);
      final digest = replayDigest(tape);
      final sim = tape.createSimulation();
      for (final event in tape.events) {
        applyReplayEvent(sim, event);
      }
      final name = 'replay-v$version';
      results[name] = digest.toJson(digest.summary(sim));
      dumps[name] = digest.dump.toString();
    }
    if (_dump) {
      final folder = Directory('build/endless-baseline')
        ..createSync(recursive: true);
      for (final MapEntry(:key, :value) in dumps.entries) {
        File('${folder.path}/$key.txt').writeAsStringSync(value);
      }
    }
    if (_record || !_fixture.existsSync()) {
      _fixture.writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert(results),
      );
      return;
    }
    final baseline = (jsonDecode(_fixture.readAsStringSync()) as Map)
        .cast<String, dynamic>();
    expect(results.keys.toSet(), baseline.keys.toSet());
    for (final name in baseline.keys) {
      final expected = baseline[name] as Map;
      final actual = results[name] as Map;
      expect(actual['summary'], expected['summary'], reason: name);
      expect(actual['checkpoints'], expected['checkpoints'], reason: name);
    }
  });

  test('rules version 42 flies solo endless exactly like 41', () {
    expect(FlightSimulation.coopRulesVersion, 42);
    for (final width in [1.6, 2.4]) {
      final (v41, _) = Flight(
        'v41',
        rules: _tap,
        version: 41,
        seconds: 400,
        width: width,
      ).fly();
      final (v42, _) = Flight(
        'v42',
        rules: _tap,
        version: 42,
        seconds: 400,
        width: width,
      ).fly();
      expect(v42.checkpoints, v41.checkpoints);
    }
  });

  test('rules version 43 flies solo endless exactly like 42 and like 41', () {
    // 43 is New York (data only); 42 is Fly Together. A solo endless flight
    // meets neither, so all three versions fly the same flight.
    expect(FlightSimulation.currentRulesVersion, 43);
    for (final width in [1.6, 2.4]) {
      final (v41, _) = Flight(
        'v41',
        rules: _tap,
        version: 41,
        seconds: 400,
        width: width,
      ).fly();
      final (v42, _) = Flight(
        'v42',
        rules: _tap,
        version: 42,
        seconds: 400,
        width: width,
      ).fly();
      final (v43, _) = Flight(
        'v43',
        rules: _tap,
        version: 43,
        seconds: 400,
        width: width,
      ).fly();
      expect(v43.checkpoints, v42.checkpoints, reason: 'width $width vs 42');
      expect(v43.checkpoints, v41.checkpoints, reason: 'width $width vs 41');
    }
  });

  test('rules version 41 flies endless exactly like 40', () {
    // The current version moved on (42 co-op, 43 New York); 41 still flies as
    // it did.
    expect(FlightSimulation.currentRulesVersion, greaterThanOrEqualTo(41));
    for (final width in [1.6, 2.4]) {
      final (v40, _) = Flight(
        'v40',
        rules: _tap,
        seconds: 400,
        width: width,
      ).fly();
      final (v41, _) = Flight(
        'v41',
        rules: _tap,
        version: 41,
        seconds: 400,
        width: width,
      ).fly();
      expect(v41.checkpoints, v40.checkpoints);
    }
  });

  test('rules version 43 flies endless exactly like 41 (New York is data)', () {
    // Rules 43 adds the Alley Pigeon, steam geysers and two mini-bosses, all
    // reachable only through a campaign level plan: endless never meets them.
    expect(FlightSimulation.currentRulesVersion, 43);
    for (final width in [1.6, 2.2, 2.4]) {
      final (v41, _) = Flight(
        'v41',
        rules: _tap,
        version: 41,
        seconds: 560,
        width: width,
      ).fly();
      final (v43, summary) = Flight(
        'v43',
        rules: _tap,
        version: 43,
        seconds: 560,
        width: width,
      ).fly();
      expect(v43.checkpoints, v41.checkpoints, reason: 'width $width');
      expect(summary, contains('bosses='));
    }
  });

  test('no endless flight, at any version, meets a campaign-only kind', () {
    final bosses = <BossKind>{};
    final enemies = <EnemyKind>{};
    for (final version in [34, 38, 40, 41, 42, 43]) {
      final random = CountingRandom(7);
      final sim = FlightSimulation(
        rules: TapFlyMode(rulesVersion: version),
        practice: false,
        course: FlightCourse.starTrail,
        rulesVersion: version,
        weaponDamage: 60,
        random: random,
      );
      var now = 0.0;
      for (var frame = 1; frame <= 560 * 50; frame++) {
        now += 20;
        touchPilot(sim, frame, now, keepAlive: true);
        sim.tick(.02, now);
        if (sim.boss case final boss?) bosses.add(boss.kind);
        enemies.addAll(sim.enemies.map((e) => e.kind));
      }
    }
    expect(bosses.where((kind) => kind.campaignOnly), isEmpty);
    expect(enemies.where((kind) => kind.campaignOnly), isEmpty);
    // The endless cycle never indexes past the first five kinds.
    for (final version in [38, 40, 42, 43]) {
      for (var defeated = 0; defeated < 200; defeated++) {
        final encounter = FlightPlan.endless.bossEncounter(defeated, version);
        expect(encounter.kind.campaignOnly, isFalse);
        expect(encounter.kind.index, lessThan(BossKind.endlessCycle));
      }
    }
    for (final index in EndlessPlan.enemyLineup) {
      expect(EnemyKind.values[index].campaignOnly, isFalse);
    }
  });

  test('the baseline flights reach every endless set piece', () {
    final random = CountingRandom(7);
    final sim = FlightSimulation(
      rules: TapFlyMode(),
      practice: false,
      course: FlightCourse.starTrail,
      rulesVersion: 40,
      weaponDamage: 60,
      random: random,
    );
    final kinds = <RushPathKind>{};
    final bosses = <BossKind>{};
    var upgraded = false, panels = false, hearts = false;
    var now = 0.0;
    for (var frame = 1; frame <= 560 * 50; frame++) {
      now += 20;
      touchPilot(sim, frame, now, keepAlive: true);
      sim.tick(.02, now);
      if (sim.rushPath case final path?) kinds.add(path.kind);
      if (sim.boss case final boss?) {
        bosses.add(boss.kind);
        upgraded |= boss.upgraded;
      }
      panels |= sim.obstacles.any((o) => o.door != null);
      hearts |= sim.heartPickups.isNotEmpty;
    }
    expect(sim.phase, RunPhase.playing);
    // Every endless boss, and never a campaign-only mini-boss (New York).
    expect(bosses, {
      for (final kind in BossKind.values)
        if (!kind.campaignOnly) kind,
    });
    expect(upgraded, isTrue);
    expect(kinds, RushPathKind.values.toSet());
    expect(sim.galesBlown, greaterThan(0));
    expect(panels, isTrue);
    expect(hearts, isTrue);
  });
}
