import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/session_replay.dart';
import 'package:push_up_bird/domain/tracking.dart';
import 'package:push_up_bird/game/boss_audio_cues.dart';
import 'boss_fight_test.dart' show arena, step, hitBoss, snapshot;
import 'dragon_boss_test.dart' show flapToward, breathBot;

const _birdX = FlightSimulation.birdX,
    _birdRadius = FlightSimulation.birdRadius;

/// A current flight whose Baron Bat has just finished his arrival: by
/// default the second one of the flight (encounter 6), which comes back
/// upgraded; [defeated] 0 meets the first, on his debut.
FlightSimulation baronArena({
  double width = 2.2,
  FlightCourse course = FlightCourse.starTrail,
  int defeated = 5,
  int version = FlightSimulation.currentRulesVersion,
}) {
  final sim = arena(version: version, course: course)
    ..bossesDefeated = defeated;
  step(sim, .02, width);
  expect(sim.boss!.kind, BossKind.baronBat);
  for (var i = 0; i < 235; i++) {
    sim.birdY = .5;
    sim.velocity = 0;
    step(sim, .02, width);
  }
  expect(sim.boss!.phase, BossPhase.attacking);
  return sim;
}

/// Sets the Baron's combat clock to [t] seconds into the fight.
void fightAt(SkyBoss boss, double t) => boss.age = boss.arrivalDuration + t;

/// The upgraded Baron's own state on top of the shared boss snapshot.
Object baronSnapshot(FlightSimulation sim) => [
  snapshot(sim),
  sim.boss?.screechGap,
  sim.boss?.screechesAimed,
  sim.boss?.batPairs,
  sim.boss?.furyPairs,
  sim.screechHits,
  sim.enemies.map((e) => [e.x, e.y, e.hp, e.appearance]).toList(),
];

/// Where a hovering bird should sit to hold [gap]: its flap-when-below bob
/// rises about 0.13 above this point, so it sits just above the gap's floor.
double gapTarget(ScreechGap gap, {bool fury = false}) {
  final (_, bottom) = BaronScreech.opening(gap, fury: fury);
  return bottom - _birdRadius - .015;
}

/// Screech-aware flight: into the gap when the Baron screeches, otherwise
/// the dragon tests' breath-aware bot (which rides the sky).
bool screechBot(FlightSimulation sim) {
  final boss = sim.boss;
  if (boss != null &&
      boss.screeches &&
      (boss.screechWarning > 0 || boss.screeching)) {
    return flapToward(sim, gapTarget(boss.screechGap, fury: boss.enraged));
  }
  return breathBot(sim);
}

void _input(FlightSimulation sim, {bool flap = false}) {
  final now = sim.elapsed * 1000 + 1;
  sim.apply(
    MovementInput(valid: true, flap: flap),
    TrackingSample(
      mode: PlayMode.touch,
      timestampMs: now,
      receivedMs: now,
      joints: const [],
    ),
    now,
  );
}

void main() {
  test('Baron Bat comes back upgraded after his debut, from rules 40', () {
    for (final (version, defeated, upgraded) in [
      (39, 0, false),
      (39, 5, false),
      (40, 0, false),
      (40, 5, true),
      (40, 10, true),
    ]) {
      final sim = arena(version: version)..bossesDefeated = defeated;
      step(sim);
      final boss = sim.boss!;
      expect(boss.kind, BossKind.baronBat);
      expect(boss.screeches, upgraded, reason: 'rules $version, $defeated');
      expect(sim.supportsUpgradedBaron, version >= 40);
      expect(boss.name, 'Baron Bat');
      expect(boss.title, upgraded ? 'THE STORM RETURNS' : 'LORD OF THE STORM');
      expect(boss.summonIn == double.infinity, upgraded);
    }
    // Only a Baron Bat is ever upgraded.
    for (final kind in BossKind.values.skip(1)) {
      expect(
        // A mini-boss (rules 43) is cinematic only, so every kind is.
        SkyBoss(
          number: 6,
          x: 1,
          kind: kind,
          upgraded: true,
          cinematic: true,
        ).screeches,
        isFalse,
        reason: kind.name,
      );
    }
    expect(SkyBoss(number: 6, x: 1).screeches, isFalse);
  });

  test('the debut Baron keeps his original fight', () {
    final sim = baronArena(defeated: 0);
    final boss = sim.boss!..fireIn = 99;
    expect((boss.debut, boss.screeches), (true, false));
    final kinds = <EnemyKind>{};
    var most = 0;
    for (var i = 0; i < 600; i++) {
      sim.birdY = .5;
      sim.velocity = 0;
      step(sim);
      expect(boss.screechWarning, 0);
      expect(boss.screeching, isFalse);
      kinds.addAll(sim.enemies.map((e) => e.kind));
      most = math.max(most, sim.enemies.length);
    }
    // One helper at a time, from the mixed lineup.
    expect(boss.summons, 2);
    expect(boss.batPairs, 0);
    expect(kinds, {EnemyKind.simpleBat, EnemyKind.spitterBeetle});
    expect(most, lessThanOrEqualTo(2));
  });

  test('the screech warns, sweeps and ends on a fixed cycle', () {
    final sim = baronArena();
    final boss = sim.boss!..fireIn = 99;
    void at(double t) {
      fightAt(boss, t - .02);
      step(sim);
    }

    at(BaronScreech.warnAt - .1);
    expect((boss.screechWarning, boss.screechWarnings), (0, 0));
    expect(boss.screeching, isFalse);
    expect(boss.screechQuiet, isTrue, reason: 'The fireballs are held first');
    at(BaronScreech.warnAt + .75);
    expect(boss.screechWarning, closeTo(.5, .02));
    expect((boss.screechWarnings, boss.screechBlasts), (1, 0));
    expect(boss.screeching, isFalse, reason: 'Warnings are fair');
    expect(boss.screechHint, startsWith('SONIC SCREECH'));
    at(BaronScreech.screechAt + .1);
    expect(boss.screeching, isTrue);
    expect(boss.screechBlasts, 1);
    expect(boss.screechWarning, 0);
    expect(
      boss.screechFront,
      closeTo(boss.muzzleX - BaronScreech.speed * .1, 1e-9),
    );
    expect(boss.screechHint, startsWith('SCREECH'));
    at(BaronScreech.endAt + .05);
    expect(boss.screeching, isFalse);
    expect(boss.screechFront, isNull);
    expect(boss.screechQuiet, isFalse);
    // Fury never changes the cycle; it only narrows the gap.
    boss.hp = boss.maxHp ~/ 3;
    at(BaronScreech.period + BaronScreech.warnAt + .4);
    expect(boss.screechWarning, greaterThan(0));
    expect(boss.screechWarnings, 2);
    at(BaronScreech.period + BaronScreech.screechAt + .4);
    expect(boss.screeching, isTrue);
    final (top, bottom) = boss.screechOpening;
    expect(bottom - top, closeTo(BaronScreech.furyGapHeight, 1e-9));
    expect(BaronScreech.warnSeconds, 1.5);
    expect(BaronScreech.sweepSeconds, 1.5);
  });

  test('the gap never opens around the bird and alternates', () {
    for (var y = .04; y < .97; y += .01) {
      for (final index in [0, 1, 2, 3]) {
        final gap = BaronScreech.aimAt(y, index);
        final own = y < BaronScreech.highBelow
            ? ScreechGap.high
            : y > BaronScreech.lowAbove
            ? ScreechGap.low
            : ScreechGap.middle;
        expect(gap, isNot(own), reason: '$y #$index');
        expect(gap, BaronScreech.aimAt(y, index + 2), reason: 'Two in turn');
        expect(gap, isNot(BaronScreech.aimAt(y, index + 1)));
      }
    }
    // Every gap is used.
    expect({
      for (final y in [.2, .5, .8])
        for (final i in [0, 1]) BaronScreech.aimAt(y, i),
    }, ScreechGap.values.toSet());
  });

  test('each screech aims once, from where the bird is as the warning '
      'begins', () {
    for (final (y, index, gap) in [
      (.2, 0, ScreechGap.low),
      (.5, 0, ScreechGap.high),
      (.8, 0, ScreechGap.high),
      (.2, 1, ScreechGap.middle),
      (.5, 1, ScreechGap.low),
      (.8, 1, ScreechGap.middle),
    ]) {
      final sim = baronArena();
      final boss = sim.boss!..fireIn = 99;
      // Catch up on earlier screeches first.
      fightAt(boss, index * BaronScreech.period + BaronScreech.warnAt - .05);
      step(sim);
      expect(boss.screechesAimed, index);
      sim.birdY = y;
      sim.velocity = 0;
      fightAt(boss, index * BaronScreech.period + BaronScreech.warnAt - .01);
      step(sim);
      expect(boss.screechWarnings, index + 1);
      expect(boss.screechGap, gap, reason: '$y #$index');
      // Moving afterwards does not re-aim it.
      sim.birdY = 1 - y;
      step(sim);
      expect(boss.screechGap, gap);
      expect(boss.screechesAimed, index + 1);
    }
  });

  test('the wall hurts only outside the gap, only as it crosses the bird', () {
    final sim = baronArena();
    final boss = sim.boss!..fireIn = 99;
    boss
      ..screechGap = ScreechGap.high
      ..screechesAimed = 99;
    final (top, bottom) = BaronScreech.opening(ScreechGap.high);
    // Where the wall's leading edge first reaches the bird.
    final reach =
        BaronScreech.screechAt +
        (boss.muzzleX - _birdX - _birdRadius) / BaronScreech.speed;
    fightAt(boss, reach - .05);
    sim.birdY = .8;
    step(sim, 1 / 120);
    expect((sim.shield, sim.screechHits), (true, 0), reason: 'Not there yet');
    // Inside the gap, the wall goes by harmlessly.
    for (final y in [top + _birdRadius + .002, bottom - _birdRadius - .002]) {
      fightAt(boss, reach + .01);
      sim.birdY = y;
      sim.velocity = 0;
      step(sim, 1 / 120);
      expect((sim.shield, sim.screechHits), (true, 0), reason: '$y');
    }
    // Poking out of the gap costs the shield, then a heart after recovery.
    fightAt(boss, reach + .01);
    sim.birdY = bottom - _birdRadius + .004;
    sim.velocity = 0;
    step(sim, 1 / 120);
    expect((sim.shield, sim.hearts, sim.screechHits), (false, 3, 1));
    sim.birdY = .8;
    step(sim, 1 / 120);
    expect(sim.hearts, 3, reason: 'Recovering');
    sim.invulnerableUntil = 0;
    fightAt(boss, reach + .02);
    sim.birdY = .8;
    step(sim, 1 / 120);
    expect((sim.hearts, sim.screechHits), (2, 2));
    // Once the wall has passed, the sky is safe again.
    sim.invulnerableUntil = 0;
    fightAt(
      boss,
      reach +
          (2 * _birdRadius + BaronScreech.thickness) / BaronScreech.speed +
          .02,
    );
    sim.birdY = .8;
    step(sim, 1 / 120);
    expect(sim.hearts, 2, reason: 'The wall has gone by');

    final classic = baronArena(course: FlightCourse.classic);
    final baron = classic.boss!
      ..fireIn = 99
      ..screechGap = ScreechGap.low
      ..screechesAimed = 99;
    fightAt(baron, reach + .01);
    classic.birdY = .2;
    step(classic, 1 / 120);
    expect(classic.phase, RunPhase.ended);
    expect(classic.endReason, EndReason.collision);
  });

  test('the cutscenes never screech', () {
    final sim = arena(version: FlightSimulation.currentRulesVersion)
      ..bossesDefeated = 5;
    step(sim);
    final boss = sim.boss!;
    expect(boss.screeches, isTrue);
    for (var i = 0; i < 400; i++) {
      step(sim);
      expect(boss.screeching, isFalse);
      expect(boss.screechWarning, 0);
    }
    fightAt(boss, BaronScreech.screechAt + .1);
    hitBoss(sim, count: boss.hp ~/ BirdRock.baseDamage + 2);
    expect(boss.phase, BossPhase.defeated);
    expect(boss.screeching, isFalse);
    expect(boss.screechFront, isNull);
  });

  test('from anywhere in the sky, a 5-tap-a-second bird reaches the gap in '
      'time and holds it as the wall goes by', () {
    for (final width in [640 / 360, 2.4]) {
      for (final fury in [false, true]) {
        for (final index in [0, 1]) {
          for (var start = .05; start <= .95; start += .015) {
            final sim = baronArena(width: width)..invulnerableUntil = 0;
            final boss = sim.boss!..fireIn = 99;
            if (fury) boss.hp = boss.maxHp ~/ 3;
            fightAt(
              boss,
              index * BaronScreech.period + BaronScreech.warnAt - .004,
            );
            sim.birdY = start;
            sim.velocity = 0;
            sim.enemies.clear();
            boss
              ..batPairs = 99
              ..furyPairs = 99;
            _input(sim);
            sim.tick(1 / 120, sim.elapsed * 1000 + 8, viewportWidth: width);
            final gap = boss.screechGap;
            expect(boss.screechesAimed, index + 1);
            final target = gapTarget(gap, fury: fury);
            final hearts = sim.hearts;
            var crossed = false;
            while (boss.age - boss.arrivalDuration <
                index * BaronScreech.period + BaronScreech.endAt) {
              _input(sim, flap: flapToward(sim, target));
              sim.tick(1 / 60, sim.elapsed * 1000 + 17, viewportWidth: width);
              if (boss.screechFront case final front?
                  when BaronScreech.reaches(front, _birdX, _birdRadius)) {
                crossed = true;
              }
            }
            final reason =
                '${width.toStringAsFixed(2)} ${fury ? 'fury ' : ''}'
                '#$index $gap from ${start.toStringAsFixed(3)}';
            expect(crossed, isTrue, reason: reason);
            expect(sim.hearts, hearts, reason: reason);
            expect(sim.shield, isTrue, reason: reason);
            expect(sim.screechHits, 0, reason: reason);
          }
        }
      }
    }
  });

  test('fireballs hold for the screech', () {
    final sim = baronArena();
    final boss = sim.boss!;
    fightAt(boss, BaronScreech.warnAt - BaronScreech.quietBefore + .01);
    boss.fireIn = .001;
    final volleys = boss.volleys;
    while (boss.age - boss.arrivalDuration < BaronScreech.endAt) {
      step(sim, 1 / 60);
      expect(boss.volleys, volleys, reason: 'Held through the screech');
    }
    expect(boss.fireIn, greaterThanOrEqualTo(BaronScreech.refire - 2 / 60));
    for (var i = 0; i < 60 && boss.volleys == volleys; i++) {
      step(sim, 1 / 60);
    }
    expect(boss.volleys, volleys + 1, reason: 'Then it fires again');
  });

  test('small bats come two at a time, and twice a cycle in fury', () {
    final sim = baronArena();
    final boss = sim.boss!..fireIn = 99;
    sim.enemies.clear();
    void until(double t) {
      while (boss.age - boss.arrivalDuration < t) {
        sim.birdY = .5;
        sim.velocity = 0;
        step(sim);
      }
    }

    until(BaronScreech.pairAt - .05);
    expect(sim.enemies, isEmpty, reason: 'No bats before the first screech');
    until(BaronScreech.pairAt + .05);
    expect(sim.enemies, hasLength(2));
    expect((boss.summons, boss.batPairs), (2, 1));
    expect(boss.age - boss.lastSummonAt, lessThan(.1));
    final (high, low) = BaronScreech.pairHeights;
    expect(sim.enemies.map((e) => e.kind).toSet(), {
      EnemyKind.simpleBat,
    }, reason: 'Small bats only');
    expect(sim.enemies[0].y, closeTo(high, .02));
    expect(sim.enemies[1].y, closeTo(low, .02));
    for (final bat in sim.enemies) {
      expect(bat.x, greaterThan(2.2), reason: 'They enter from the right');
    }
    // Calm: no second pair.
    until(BaronScreech.furyPairAt + .05);
    expect((boss.summons, boss.furyPairs), (2, 1));
    // Fury: another pair a second later.
    boss.hp = boss.maxHp ~/ 3;
    until(BaronScreech.period + BaronScreech.pairAt + .05);
    expect(boss.summons, 4);
    until(BaronScreech.period + BaronScreech.furyPairAt + .05);
    expect((boss.summons, boss.furyPairs), (6, 2));
  });

  test('every pair has flown past the bird before the next warning', () {
    // At the slowest pace on the widest phone ...
    const slowest = .40 * .9, widest = 2.4;
    const past = _birdX - _birdRadius - SkyEnemy.radius;
    final flight = (widest + .15 - past) / slowest;
    expect(
      BaronScreech.furyPairAt + flight,
      lessThan(BaronScreech.period + BaronScreech.warnAt),
    );
    // ... and in a flight.
    final sim = baronArena(width: widest);
    final boss = sim.boss!
      ..fireIn = 99
      ..hp = 1;
    expect(sim.speed, lessThan(.41));
    sim.enemies.clear();
    while (boss.age - boss.arrivalDuration <
        BaronScreech.period + BaronScreech.warnAt) {
      sim.birdY = .5;
      sim.velocity = 0;
      step(sim, .02, widest);
      for (final bat in sim.enemies) {
        expect(
          (bat.y - .5).abs(),
          greaterThan(_birdRadius + SkyEnemy.radius),
          reason: 'The test bird hovers between the pair',
        );
      }
    }
    expect(boss.summons, 4);
    expect(
      sim.enemies.every((bat) => bat.x < past),
      isTrue,
      reason: 'All past the bird as the warning begins',
    );
  });

  test('pause and resume freeze the screech', () {
    final sim = baronArena();
    fightAt(sim.boss!, BaronScreech.screechAt + .2);
    step(sim);
    final before = baronSnapshot(sim);
    sim.takeBreak();
    step(sim, .5);
    sim.resume();
    step(sim, 2);
    step(sim, 1.1);
    expect(baronSnapshot(sim), before);
  });

  test('the warning and the screech have their own cues', () {
    final sim = baronArena();
    final boss = sim.boss!..fireIn = 99;
    final cues = BossAudioCues()..advance(boss);
    List<String> at(double t) {
      fightAt(boss, t);
      return cues.advance(boss);
    }

    expect(at(BaronScreech.warnAt - .1), isEmpty);
    expect(at(BaronScreech.warnAt + .1), ['screech_warning']);
    expect(at(BaronScreech.screechAt + .1), ['sonic_screech']);
    expect(at(BaronScreech.endAt - .1), isEmpty);
    boss.summons += 2;
    expect(cues.advance(boss), ['boss_summon'], reason: 'One call per pair');
    // Seeking back and replaying silently never screeches twice.
    expect(at(BaronScreech.screechAt + .2), isEmpty);
    cues.advance(boss, silent: true);
    expect(at(BaronScreech.screechAt + .3), isEmpty);
  });

  test('identical inputs replay identically, screeches and pairs included', () {
    List<Object> run() {
      final sim = baronArena();
      final states = <Object>[];
      for (var i = 0; i < 1500; i++) {
        _input(sim, flap: screechBot(sim));
        if (sim.canShoot && i % 7 == 0) sim.shoot();
        sim.tick(.02, sim.elapsed * 1000 + 20, viewportWidth: 2.2);
        if (i % 50 == 0) states.add(baronSnapshot(sim));
        if (i == 400) sim.boss!.hp = sim.boss!.maxHp ~/ 2 + 1;
      }
      return states;
    }

    final a = run();
    expect(run(), a);
  });

  test('a recorded flight to the upgraded Baron survives seeks', () {
    var now = 0.0;
    final recorder = FlightRecorder(
      ReplayTape(
        mode: PlayMode.touch,
        course: FlightCourse.starTrail,
        practice: true,
        seed: 11,
        cycleSeconds: 3,
        bird: 0,
        reducedMotion: true,
        originMs: 0,
        weaponDamage: 60,
      ),
      () => now,
    );
    final sim = recorder.simulation;
    final checkpoints = <double, Object>{};
    final seen = <String>{};
    for (var frame = 1; frame <= 24000; frame++) {
      now = frame * 50.0;
      recorder.apply(
        MovementInput(valid: true, flap: screechBot(sim)),
        TrackingSample(
          mode: PlayMode.touch,
          timestampMs: now,
          receivedMs: now,
          joints: const [],
        ),
        now,
      );
      final boss = sim.boss;
      // Let the dragon breathe and the Baron screech before they are beaten.
      final holdFire =
          boss != null &&
          (boss.isDragon || boss.screeches) &&
          boss.age - boss.arrivalDuration < BaronScreech.period + 3;
      if (sim.canShoot && !holdFire) recorder.command('shoot');
      recorder.tick(.05, now, 2.2);
      if (sim.boss case final baron? when baron.screeches) {
        final state = baron.phase == BossPhase.defeated
            ? 'defeated'
            : baron.screeching
            ? 'screech'
            : baron.screechWarning > 0
            ? 'warning'
            : sim.enemies.length >= 2
            ? 'pair'
            : 'open';
        if (seen.add(state)) checkpoints[now] = baronSnapshot(sim);
      }
      if (sim.bossesDefeated >= 6 && sim.boss == null) break;
      if (sim.phase == RunPhase.ended) break;
    }
    expect(sim.phase, isNot(RunPhase.ended));
    expect(seen, containsAll(['warning', 'screech', 'pair', 'defeated']));
    final replay = ReplayPlayer(ReplayTape.fromJson(recorder.tape.toJson()));
    final times = checkpoints.keys.toList();
    for (final time in [...times.reversed, ...times]) {
      replay.seek(time);
      expect(baronSnapshot(replay.simulation), checkpoints[time]);
    }
  });

  for (final width in [640 / 360, 800 / 360]) {
    test('the upgraded Baron is beatable with legal flaps and shots at '
        '${width.toStringAsFixed(2)}', () {
      final sim = arena(version: FlightSimulation.currentRulesVersion)
        ..bossesDefeated = 5;
      var now = sim.elapsed * 1000;
      var sawScreech = false, sawFuryPair = false;
      final gaps = <ScreechGap>{};
      for (var i = 0; i < 9000 && sim.bossesDefeated == 5; i++) {
        now += 20;
        final boss = sim.boss;
        final screech =
            boss != null &&
            boss.screeches &&
            (boss.screechWarning > 0 || boss.screeching);
        sim.apply(
          MovementInput(
            valid: true,
            flap: screech
                ? flapToward(
                    sim,
                    gapTarget(boss.screechGap, fury: boss.enraged),
                  )
                : sim.birdY > _dodge(sim) && sim.velocity > 0,
          ),
          TrackingSample(
            mode: PlayMode.touch,
            timestampMs: now,
            receivedMs: now,
            joints: const [],
          ),
          now,
        );
        if (sim.canShoot) sim.shoot();
        sim.tick(.02, now, viewportWidth: width);
        if (sim.boss case final b? when b.screeching) {
          sawScreech = true;
          gaps.add(b.screechGap);
        }
        if (sim.boss case final b? when b.furyPairs > 0 && b.enraged) {
          sawFuryPair |= b.summons > 2 * b.batPairs;
        }
      }
      expect(sawScreech, isTrue);
      expect(gaps.length, greaterThan(1));
      expect(sawFuryPair, isTrue);
      expect(sim.bossesDefeated, 6);
      expect(sim.phase, RunPhase.playing);
      expect(sim.hearts, greaterThan(0));
    });
  }
}

/// A sharp player's hover height between screeches: the lane whose next
/// second, flown with the same flap-when-below rule, stays furthest from
/// every fireball and bat, then as close to the Baron as that allows. It
/// only reads what the screen shows.
double _dodge(FlightSimulation sim) {
  final boss = sim.boss;
  if (boss == null || boss.phase != BossPhase.attacking) return .5;
  var best = sim.birdY, bestScore = double.negativeInfinity;
  for (var target = .1; target <= .92; target += .02) {
    var y = sim.birdY, v = sim.velocity, clear = .2;
    for (var i = 1; i <= 50; i++) {
      final t = i * .02;
      if (y > target && v > 0) v = sim.rules.flapImpulse;
      v += sim.rules.gravity * .02;
      y += v * .02;
      clear = math.min(clear, math.min(1 - y, y) - _birdRadius);
      for (final ball in sim.bossAmmo) {
        final bx = ball.x + ball.vx * t;
        final by = ball.y + ball.vy * t;
        clear = math.min(
          clear,
          math.sqrt((bx - _birdX) * (bx - _birdX) + (by - y) * (by - y)) -
              _birdRadius -
              ball.radius,
        );
      }
      for (final bat in sim.enemies) {
        final bx = bat.x - sim.speed * sim.courseBoost * bat.drift * t;
        clear = math.min(
          clear,
          math.sqrt((bx - _birdX) * (bx - _birdX) + (bat.y - y) * (bat.y - y)) -
              _birdRadius -
              SkyEnemy.radius -
              .015,
        );
      }
    }
    final score = math.min(clear, .08) * 20 - (target - boss.y).abs();
    if (score > bestScore) (bestScore, best) = (score, target);
  }
  return best;
}
