import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/session_replay.dart';
import 'package:push_up_bird/domain/tracking.dart';
import 'boss_fight_test.dart' show arena, step, hover, hitBoss, snapshot;
import 'recorded_flight.dart';

FlightSimulation mothArena({double width = 2.2}) {
  final sim = arena(version: 22, course: FlightCourse.starTrail)
    ..bossesDefeated = 2;
  step(sim, .02, width);
  for (var i = 0; i < 235; i++) {
    sim.birdY = .5;
    sim.velocity = 0;
    step(sim, .02, width);
  }
  return sim;
}

void main() {
  test(
    'new flights cycle bat, beetle, moth, pirate, dragon with intervals and '
    'rewards',
    () {
      final sim = arena(version: FlightSimulation.currentRulesVersion);
      step(sim);
      for (final (number, kind, hp) in [
        (1, BossKind.baronBat, 12),
        (2, BossKind.spitterBeetle, 21),
        (3, BossKind.duskMoth, 24),
        (4, BossKind.pirate, 30),
        (5, BossKind.dragon, 36),
        // The returning Baron has twice the health from rules 48.
        (6, BossKind.baronBat, 48),
        (7, BossKind.spitterBeetle, 33),
        (8, BossKind.duskMoth, 36),
        (9, BossKind.pirate, 42),
        (10, BossKind.dragon, 48),
        (11, BossKind.baronBat, 48),
      ]) {
        final boss = sim.boss!;
        expect((boss.number, boss.kind, boss.hp), (number, kind, hp * 10));
        expect(sim.shoot(), isFalse);
        expect(boss.shielded, isFalse);
        hover(sim, boss.arrivalDuration + .1);
        hitBoss(sim, count: hp + 2);
        expect(boss.hp, 0);
        expect(boss.phase, BossPhase.defeated);
        expect(sim.bossesDefeated, number);
        expect(sim.score, number * FlightSimulation.bossBonus);
        expect(sim.shield, isTrue);
        expect(sim.bossAmmo, isEmpty);
        expect(sim.enemyAmmo, isEmpty);
        expect(sim.enemies, isEmpty);
        hover(sim, boss.departureDuration + .1);
        expect(sim.boss, isNull);
        expect(sim.obstacles, isNotEmpty);
        if (kind == BossKind.duskMoth) {
          // A gale follows the Dusk Empress, and the next boss waits for it.
          // gale_test.dart flies one through.
          sim.elapsed += Gale.afterBoss;
          step(sim);
          expect(sim.gale, isNotNull);
          sim.elapsed += FlightSimulation.bossInterval;
          step(sim);
          expect(sim.boss, isNull);
          sim.gale = null;
          step(sim);
          expect(sim.boss!.phase, BossPhase.arriving);
          continue;
        }
        sim.elapsed += FlightSimulation.bossInterval - .3;
        step(sim);
        expect(sim.boss, isNull);
        sim.elapsed += .3;
        step(sim);
        expect(sim.boss!.phase, BossPhase.arriving);
      }
    },
  );

  test('moth fans aim at the bird, widen, and accelerate in fury', () {
    final sim = mothArena();
    final boss = sim.boss!;
    expect(boss.name, 'Dusk Empress');
    expect(boss.hp, 24);
    for (final (hp, count, speed, interval) in [
      (24, 5, .62, 1.65),
      (24, 7, .62, 1.65),
      (12, 7, .72, 1.2),
    ]) {
      boss.hp = hp;
      boss.fireIn = .001;
      sim.bossAmmo.clear();
      sim.birdY = .3;
      sim.velocity = 0;
      step(sim, 1 / 120);
      expect(sim.bossAmmo, hasLength(count));
      final middle = sim.bossAmmo[count ~/ 2];
      final aim = math.atan2(
        .3 - boss.y,
        FlightSimulation.birdX - boss.muzzleX,
      );
      expect(math.atan2(middle.vy, middle.vx), closeTo(aim, .001));
      expect(boss.fireIn, closeTo(interval, .01));
      for (final shot in sim.bossAmmo) {
        expect(
          math.sqrt(shot.vx * shot.vx + shot.vy * shot.vy),
          closeTo(speed, 1e-9),
        );
        expect(shot.x, closeTo(boss.muzzleX + shot.vx / 120, 1e-9));
      }
    }
  });

  test(
    'veil warns, blocks at its drawn edge, and leaves long damage windows',
    () {
      final sim = mothArena();
      final boss = sim.boss!;
      hitBoss(sim);
      expect(boss.hp, 23);
      boss.age = boss.arrivalDuration + 4.4;
      expect(boss.shieldWarning, closeTo(.25, 1e-9));
      expect(boss.shielded, isFalse);
      step(sim);
      hitBoss(sim);
      expect(boss.hp, 22, reason: 'The warning is still a damage window');
      boss.age = boss.arrivalDuration + 5.1;
      expect(boss.shielded, isTrue);
      expect(boss.shieldWarning, 0);
      final lastHit = boss.lastHitAt;
      final score = sim.score;
      sim.rocks.add(BirdRock(x: boss.x - SkyBoss.shieldRadius, y: boss.y));
      step(sim);
      expect(sim.rocks, isEmpty);
      expect(boss.hp, 22);
      expect(boss.lastHitAt, lastHit);
      expect(boss.lastShieldHitAt, closeTo(boss.age, .02));
      expect(sim.score, score);
      hitBoss(sim, count: 40);
      expect(boss.hp, 22);
      expect(sim.bossesDefeated, 2);
      boss.hp = 12;
      expect(
        boss.shielded,
        isTrue,
        reason: 'Fury does not reset the veil cycle',
      );
      final volleys = boss.volleys;
      boss.fireIn = .001;
      step(sim);
      expect(
        boss.volleys,
        volleys + 1,
        reason: 'The shield does not stop attacks',
      );
      boss.age = boss.arrivalDuration + 6.61;
      expect(boss.shielded, isFalse);
      step(sim);
      hitBoss(sim);
      expect(boss.hp, 11);
      boss.age = boss.arrivalDuration + 12.4;
      expect(boss.shieldWarning, greaterThan(0));
      boss.age = boss.arrivalDuration + 13.1;
      expect(
        boss.shielded,
        isTrue,
        reason: 'The shield repeats every eight seconds',
      );
      boss.age = boss.arrivalDuration + 14.61;
      step(sim);
      hitBoss(sim, count: 11);
      expect(boss.phase, BossPhase.defeated);
      expect(boss.shielded, isFalse);
      expect(boss.shieldWarning, 0);
    },
  );

  test('moth helpers get warning room and long fights keep bounded ammo', () {
    final sim = mothArena(width: 640 / 360);
    final boss = sim.boss!;
    boss.summonIn = .001;
    step(sim, .02, 640 / 360);
    expect(sim.enemies.single.kind, EnemyKind.duskMoth);
    expect(sim.enemies.single.x, greaterThan(FlightSimulation.birdX + .9));
    expect(sim.enemies.single.fireIn, greaterThan(.7));
    expect(sim.enemyAmmo, isEmpty);
    final normalInterval = boss.summonIn;
    boss.hp = 12;
    sim.enemies.clear();
    boss.summonIn = .001;
    step(sim, .02, 640 / 360);
    expect(boss.summonIn, lessThan(normalInterval));
    var maxAmmo = 0, maxHelpers = 0;
    for (var i = 0; i < 1200; i++) {
      sim.birdY = .5;
      sim.velocity = 0;
      step(sim, .1, 640 / 360);
      maxAmmo = math.max(maxAmmo, sim.bossAmmo.length);
      maxHelpers = math.max(maxHelpers, sim.enemies.length);
      expect(sim.enemyAmmo.length, lessThanOrEqualTo(12));
    }
    expect(maxAmmo, lessThan(45));
    expect(maxHelpers, lessThan(5));
  });

  group('debut encounter (rules version 37)', () {
    // The moth first appears after two bosses fall and returns every fifth
    // (every fourth before the Ember Dragon joined in rules version 38).
    FlightSimulation moth(int version, int bossesDefeated) {
      final sim = arena(version: version, course: FlightCourse.starTrail)
        ..bossesDefeated = bossesDefeated;
      step(sim);
      hover(sim, sim.boss!.arrivalDuration + .1);
      expect(sim.boss!.isMoth, isTrue);
      return sim;
    }

    test('the first moth fights without a shield', () {
      final sim = moth(FlightSimulation.currentRulesVersion, 2);
      final boss = sim.boss!;
      expect((boss.number, boss.debut, boss.hasShield), (3, true, false));
      // Sample two whole 8-second cycles: no warning, no shield.
      for (var i = 0; i < 160; i++) {
        boss.age = boss.arrivalDuration + i * .1;
        expect(boss.shieldWarning, 0);
        expect(boss.shielded, isFalse);
      }
      // Right where later moths raise the shield, a rock still lands.
      boss.age = boss.arrivalDuration + SkyBoss.shieldStartsAt + .1;
      final before = boss.hp;
      hitBoss(sim);
      expect(boss.hp, lessThan(before));
      expect(boss.lastShieldHitAt.isFinite, isFalse);
      expect(boss.shieldHint, startsWith('No veil yet'));
    });

    test('later moths bring the shield back', () {
      for (final defeated in [7, 12]) {
        final sim = moth(FlightSimulation.currentRulesVersion, defeated);
        final boss = sim.boss!;
        expect((boss.debut, boss.hasShield), (false, true));
        boss.age = boss.arrivalDuration + SkyBoss.shieldStartsAt - .4;
        expect(boss.shieldWarning, greaterThan(0));
        boss.age = boss.arrivalDuration + SkyBoss.shieldStartsAt + .1;
        expect(boss.shielded, isTrue);
        final before = boss.hp;
        hitBoss(sim);
        expect(boss.hp, before);
        expect(boss.lastShieldHitAt, closeTo(boss.age, .02));
      }
    });

    test('helpers of the first moth drift slower than later ones', () {
      double travel(int defeated) {
        final sim = moth(FlightSimulation.currentRulesVersion, defeated);
        sim.boss!.summonIn = .001;
        step(sim);
        final helper = sim.enemies.single;
        final expected = defeated == 2 ? SkyEnemy.debutDrift : 1;
        expect(helper.drift, expected);
        final from = helper.x;
        hover(sim, 1);
        return from - helper.x;
      }

      // Same score, same course speed: only the drift differs.
      expect(travel(2) / travel(7), closeTo(SkyEnemy.debutDrift, .01));
    });

    test('earlier rules keep the shield and the pace of the first moth', () {
      for (final version in [22, 34, 36]) {
        final sim = moth(version, 2);
        final boss = sim.boss!;
        expect((boss.debut, boss.hasShield), (false, true));
        boss.age = boss.arrivalDuration + SkyBoss.shieldStartsAt + .1;
        expect(boss.shielded, isTrue);
        boss.summonIn = .001;
        step(sim);
        expect(sim.enemies.single.drift, 1);
      }
    });
  });

  test(
    'pause and resume countdown freeze active shields and attack clocks',
    () {
      final sim = mothArena();
      sim.boss!.age = sim.boss!.arrivalDuration + 5.1;
      hitBoss(sim);
      final before = snapshot(sim);
      sim.takeBreak();
      step(sim, .5);
      sim.resume();
      step(sim, 2);
      step(sim, 1.1);
      expect(snapshot(sim), before);
      expect(sim.boss!.shielded, isTrue);
    },
  );

  for (final width in [640 / 360, 800 / 360]) {
    test(
      'third boss is beatable with legal flaps and shots at width $width',
      () {
        final sim = arena(version: 22)..bossesDefeated = 2;
        var now = sim.elapsed * 1000;
        var sawShield = false;
        for (var i = 0; i < 4000 && sim.bossesDefeated == 2; i++) {
          now += 20;
          // Sweep gently above and below the middle lane instead of sitting
          // in the center of every aimed fan. No position/health overrides.
          final fight = (sim.boss?.age ?? 0) - 4.6;
          final flapAt = .56 + math.sin(fight * .85 + 2.4) * .08;
          sim.apply(
            MovementInput(
              valid: true,
              flap: sim.birdY > flapAt && sim.velocity > 0,
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
          sawShield |= sim.boss?.shielded == true;
        }
        expect(sawShield, isTrue);
        expect(sim.bossesDefeated, 3);
        expect(sim.phase, RunPhase.playing);
        expect(sim.hearts, greaterThan(0));
        expect(sim.flaps, greaterThan(0));
        expect(sim.shots, greaterThanOrEqualTo(24));
      },
    );
  }

  test(
    'recorded shield, warning, blocked shots and defeat survive backward seeks',
    () {
      var now = 0.0;
      final recorder = FlightRecorder(
        ReplayTape(
          mode: PlayMode.touch,
          course: FlightCourse.starTrail,
          practice: true,
          seed: 7,
          cycleSeconds: 3,
          bird: 0,
          reducedMotion: true,
          originMs: 0,
          weaponDamage: 22,
          // From version 37 the first moth has no shield to replay; this
          // journal keeps the original shielded debut.
          recordedVersion: 36,
        ),
        () => now,
      );
      final sim = recorder.simulation;
      final checkpoints = <double, Object>{};
      final seen = <String>{};
      for (var frame = 1; frame <= 6500; frame++) {
        now = frame * 50.0;
        recorder.apply(
          MovementInput(valid: true, flap: rideTheSky(sim)),
          TrackingSample(
            mode: PlayMode.touch,
            timestampMs: now,
            receivedMs: now,
            joints: const [],
          ),
          now,
        );
        if (sim.canShoot) recorder.command('shoot');
        recorder.tick(.05, now, 2.2);
        if (sim.boss case final boss? when boss.isMoth) {
          final state = boss.phase == BossPhase.defeated
              ? 'defeated'
              : boss.shielded
              ? (boss.lastShieldHitAt.isFinite ? 'blocked' : 'shield')
              : boss.shieldWarning > 0
              ? 'warning'
              : 'open';
          if (seen.add(state)) checkpoints[now] = snapshot(sim);
        }
        if (sim.bossesDefeated >= 3 && sim.boss == null) break;
      }
      expect(seen, containsAll(['warning', 'blocked', 'defeated']));
      final replay = ReplayPlayer(ReplayTape.fromJson(recorder.tape.toJson()));
      final times = checkpoints.keys.toList();
      for (final time in [...times.reversed, ...times]) {
        replay.seek(time);
        expect(snapshot(replay.simulation), checkpoints[time]);
      }
    },
  );
}
