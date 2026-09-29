import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/tracking.dart';
import 'package:push_up_bird/game/boss_audio_cues.dart';
import 'package:push_up_bird/game/combat_audio_cues.dart';
import 'boss_fight_test.dart' show arena, step, hover, hitBoss, snapshot;

const _birdX = FlightSimulation.birdX,
    _birdRadius = FlightSimulation.birdRadius;

/// A current flight whose fourth boss, the Pirate Captain, has just finished
/// sailing in.
FlightSimulation pirateArena({
  double width = 2.2,
  FlightCourse course = FlightCourse.starTrail,
}) {
  final sim = arena(
    version: FlightSimulation.currentRulesVersion,
    course: course,
  )..bossesDefeated = 3;
  step(sim, .02, width);
  expect(sim.boss!.kind, BossKind.pirate);
  for (var i = 0; i < 235; i++) {
    sim.birdY = .5;
    sim.velocity = 0;
    step(sim, .02, width);
  }
  expect(sim.boss!.phase, BossPhase.attacking);
  return sim;
}

double _hypot(double x, double y) => math.sqrt(x * x + y * y);

/// Sets the Pirate Captain's combat clock to [t] seconds into the fight.
void fightAt(SkyBoss boss, double t) => boss.age = boss.arrivalDuration + t;

void main() {
  test('the pirate joins the cycle as the fourth boss from rules 34', () {
    for (final (version, fourth) in [
      (33, BossKind.baronBat),
      (34, BossKind.pirate),
    ]) {
      final sim = arena(version: version)..bossesDefeated = 3;
      step(sim);
      expect(sim.boss!.kind, fourth, reason: 'rules $version');
    }
    final boss = SkyBoss(number: 4, x: 1.5, kind: BossKind.pirate);
    expect(boss.name, 'Pirate Captain');
    expect(boss.title, 'TERROR OF THE HIGH TIDE');
    expect(boss.maxHp, 300);
    expect(SkyBoss.healthFor(BossKind.pirate, 8), 420);
    expect(
      SkyBoss(number: 1, x: 1, kind: BossKind.duskMoth).waterLevel,
      isNull,
      reason: 'Only the pirate brings a sea',
    );
  });

  test('the sea rolls in with the ship and the ship rides it', () {
    final sim = arena(version: FlightSimulation.currentRulesVersion)
      ..bossesDefeated = 3;
    step(sim);
    final boss = sim.boss!;
    expect(boss.waterLevel, closeTo(SkyBoss.seaHidden, .01));
    hover(sim, boss.arrivalDuration * .6);
    expect(boss.waterLevel, closeTo(SkyBoss.seaLevel, 1e-9));
    expect(boss.y, closeTo(SkyBoss.seaLevel - SkyBoss.shipRide, .009));
    hover(sim, boss.arrivalDuration * .4 + .1);
    expect(boss.phase, BossPhase.attacking);
    expect(boss.x, closeTo(math.max(_birdX + .72, 2.2 - .5), 1e-9));
    expect(boss.summonIn, double.infinity);
  });

  test('the tide warns, surges, holds and falls on a fixed cycle', () {
    final sim = pirateArena();
    final boss = sim.boss!;
    void at(double t) {
      fightAt(boss, t - .02);
      step(sim);
    }

    at(2.9);
    expect((boss.tide, boss.tideWarning, boss.tideSurges), (0, 0, 0));
    expect(boss.waterLevel, SkyBoss.seaLevel);
    at(3.65);
    expect(boss.tideWarning, closeTo(.5, .02));
    expect(boss.tideSurges, 1);
    expect(boss.tideRises, 0);
    expect(boss.waterLevel, SkyBoss.seaLevel, reason: 'Warnings are fair');
    at(4.75);
    expect(boss.tideWarning, 0);
    expect(boss.tideRises, 1);
    expect(boss.tide, inExclusiveRange(0, 1));
    at(6);
    expect(boss.tide, 1);
    expect(boss.waterLevel, SkyBoss.tidePeak);
    expect(boss.y, closeTo(SkyBoss.tidePeak - SkyBoss.shipRide, .009));
    at(8);
    expect(boss.tide, inExclusiveRange(0, 1));
    at(9);
    expect(boss.tide, 0);
    boss.hp = boss.maxHp ~/ 3;
    at(13.5);
    expect(
      boss.tideWarning,
      greaterThan(0),
      reason: 'Fury never changes the cycle',
    );
    expect(boss.tideSurges, 2);
    at(16);
    expect(boss.waterLevel, SkyBoss.tidePeak);
    expect(boss.tideHint, contains('HIGH TIDE'));
  });

  test('the water hurts, splashes and throws the bird back out', () {
    final sim = pirateArena();
    final boss = sim.boss!;
    fightAt(boss, 6);
    boss.fireIn = 99;
    step(sim);
    expect(boss.waterLevel, SkyBoss.tidePeak);
    expect(sim.shield, isTrue);
    sim.birdY = SkyBoss.tidePeak;
    sim.velocity = .2;
    step(sim, 1 / 120);
    expect(sim.shield, isFalse);
    expect(sim.hearts, 3);
    expect(sim.birdY + _birdRadius, lessThan(SkyBoss.tidePeak));
    expect(sim.velocity, lessThan(0));
    expect(sim.seaSplashes.single.bird, isTrue);
    // Still recovering: no second splash and no second hit.
    sim.birdY = SkyBoss.tidePeak;
    step(sim, 1 / 120);
    expect(sim.seaSplashes, hasLength(1));
    expect(sim.hearts, 3);
    // Above the surface is always safe.
    sim.invulnerableUntil = 0;
    sim.birdY = SkyBoss.tidePeak - _birdRadius - .01;
    sim.velocity = 0;
    step(sim, 1 / 120);
    expect(sim.hearts, 3);

    final classic = pirateArena(course: FlightCourse.classic);
    classic.birdY = SkyBoss.seaLevel;
    step(classic, 1 / 120);
    expect(classic.phase, RunPhase.ended);
    expect(classic.endReason, EndReason.collision);
  });

  test('cannonballs arc through the bird, bracket it, and broadside', () {
    final sim = pirateArena();
    final boss = sim.boss!;
    for (final (t, hp, volley, offsets, interval) in [
      (.5, boss.maxHp, 0, [0.0], 2.1),
      (.5, boss.maxHp, 1, [-.16, .16], 2.1),
      (.5, boss.maxHp, 2, [0.0], 2.1),
      (.5, boss.maxHp ~/ 3, 1, [-.16, .16], 1.5),
      (.5, boss.maxHp ~/ 3, 2, [-.26, 0.0, .26], 1.5),
      (.5, boss.maxHp ~/ 3, 3, [0.0], 1.5),
      // High tide: the broadside becomes a pair.
      (6.0, boss.maxHp ~/ 3, 2, [-.16, .16], 1.5),
    ]) {
      fightAt(boss, t);
      boss
        ..hp = hp
        ..volleys = volley
        ..fireIn = .001;
      sim.bossAmmo.clear();
      sim.birdY = .45;
      sim.velocity = 0;
      sim.invulnerableUntil = double.infinity;
      step(sim, 1 / 120);
      expect(sim.bossAmmo, hasLength(offsets.length));
      expect(boss.fireIn, closeTo(interval, .01));
      for (final (i, ball) in sim.bossAmmo.indexed) {
        expect(ball.cannonball, isTrue);
        expect(ball.radius, BossAmmo.cannonballRadius);
        expect(ball.vy, lessThan(0), reason: 'Lobbed upward first');
        // Fly the ball on alone: it passes where it was aimed.
        final target = .45 + offsets[i];
        var (x, y, vy) = (ball.x, ball.y, ball.vy);
        var closest = double.infinity;
        for (var t = 0; t < 600 && x > _birdX - .2; t++) {
          x += ball.vx / 120;
          vy += ball.gravity / 120;
          y += vy / 120;
          closest = math.min(closest, _hypot(x - _birdX, y - target));
        }
        expect(closest, lessThan(.012));
      }
    }
  });

  test('the barrel points along the launch and balls leave its muzzle', () {
    final boss = SkyBoss(number: 4, x: 1.5, kind: BossKind.pirate)..y = .7;
    for (final target in [.15, .45, .8]) {
      final shot = boss.cannonShot(_birdX, target);
      expect(shot.angle, closeTo(math.atan2(shot.vy, shot.vx), 1e-9));
      expect(shot.angle.abs(), greaterThan(math.pi / 2), reason: 'Faces left');
      final (px, py) = (
        boss.x + SkyBoss.cannonPivot.$1,
        boss.y + SkyBoss.cannonPivot.$2,
      );
      expect(
        _hypot(shot.x - px, shot.y - py),
        closeTo(SkyBoss.cannonLength, 1e-9),
      );
    }
  });

  test('shots below the rail glance off the hull; the captain takes hits', () {
    final sim = pirateArena();
    final boss = sim.boss!;
    boss.fireIn = 99;
    final hp = boss.hp;
    sim.rocks.add(
      BirdRock(x: boss.x + SkyBoss.hullLeft - .03, y: boss.y + .15),
    );
    step(sim);
    expect(sim.rocks.single.rebounding, isTrue);
    expect(boss.hp, hp);
    expect(boss.lastHullHitAt, closeTo(boss.age, .02));
    sim.rocks.clear();
    hitBoss(sim);
    expect(boss.hp, hp - BirdRock.baseDamage);
    expect(
      SkyBoss(number: 1, x: 1, kind: BossKind.baronBat).hullBlocks(1, 1),
      isFalse,
    );
  });

  test('missed cannonballs splash into the sea; high lobs come back', () {
    final sim = pirateArena();
    final boss = sim.boss!;
    fightAt(boss, .5);
    boss.fireIn = 99;
    sim.invulnerableUntil = double.infinity;
    sim.bossAmmo.add(
      BossAmmo(
        x: 1.2,
        y: -.3,
        vx: -.5,
        vy: -.2,
        gravity: SkyBoss.cannonGravity,
        radius: BossAmmo.cannonballRadius,
      ),
    );
    step(sim);
    expect(sim.bossAmmo, hasLength(1), reason: 'Above the screen, still live');
    for (var i = 0; i < 200 && sim.bossAmmo.isNotEmpty; i++) {
      sim.birdY = .6;
      sim.velocity = 0;
      step(sim);
    }
    expect(sim.bossAmmo, isEmpty);
    final splash = sim.seaSplashes.single;
    expect(splash.bird, isFalse);
    final x = splash.x;
    step(sim);
    expect(splash.x, lessThan(x), reason: 'Drifts with the course');
    hover(sim, 1.3);
    expect(sim.seaSplashes, isEmpty);
  });

  test('the sea drains after the defeat and never hurts the cutscene', () {
    final sim = pirateArena();
    final boss = sim.boss!;
    fightAt(boss, 6);
    step(sim);
    expect(boss.waterLevel, SkyBoss.tidePeak);
    hitBoss(sim, count: boss.hp ~/ BirdRock.baseDamage + 2);
    expect(boss.phase, BossPhase.defeated);
    expect(boss.waterLevel, closeTo(SkyBoss.tidePeak, .01));
    final hearts = sim.hearts;
    final shield = sim.shield;
    for (var i = 0; i < 400 && sim.boss != null; i++) {
      step(sim);
      if (sim.boss?.waterLevel case final sea?) {
        expect(sea, greaterThanOrEqualTo(SkyBoss.tidePeak - 1e-9));
      }
    }
    expect(sim.boss, isNull);
    expect((sim.hearts, sim.shield), (hearts, shield));
    expect(sim.bossesDefeated, 4);
  });

  test('pause and resume freeze the tide and the cannon', () {
    final sim = pirateArena();
    fightAt(sim.boss!, 4.8);
    step(sim);
    final before = snapshot(sim);
    final level = sim.boss!.waterLevel;
    sim.takeBreak();
    step(sim, .5);
    sim.resume();
    step(sim, 2);
    step(sim, 1.1);
    expect(snapshot(sim), before);
    expect(sim.boss!.waterLevel, level);
  });

  test('the fuse, cannon, bell, surge and splashes have their own cues', () {
    final sim = pirateArena();
    final boss = sim.boss!;
    final bossCues = BossAudioCues(), combatCues = CombatAudioCues();
    bossCues.advance(boss);
    combatCues.advance(sim);
    List<String> at(double t) {
      fightAt(boss, t);
      return bossCues.advance(boss);
    }

    boss.fireIn = .3;
    expect(bossCues.advance(boss), ['cannon_fuse']);
    boss.volleys++;
    expect(bossCues.advance(boss), ['cannon_fire']);
    expect(at(2.9), isEmpty);
    expect(at(3.1), ['tide_warning']);
    expect(at(4.4), ['tide_surge']);
    expect(at(8), isEmpty);
    sim.cannonSplashes++;
    expect(combatCues.advance(sim), ['sea_splash']);
    sim.birdSplashes++;
    expect(combatCues.advance(sim), ['sea_splash']);
    // Seeking back and replaying silently never rings the bell twice.
    expect(at(3.2), isEmpty);
    bossCues.advance(boss, silent: true);
    expect(at(3.25), isEmpty);
  });

  for (final width in [640 / 360, 800 / 360]) {
    test('the pirate is beatable with legal flaps and shots at $width', () {
      final sim = arena(version: FlightSimulation.currentRulesVersion)
        ..bossesDefeated = 3;
      var now = sim.elapsed * 1000;
      var sawSurge = false, sawBroadside = false;
      for (var i = 0; i < 6000 && sim.bossesDefeated == 3; i++) {
        now += 20;
        final flapAt = _dodgeLane(sim);
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
        sawSurge |= sim.boss?.tide == 1;
        sawBroadside |= sim.bossAmmo.length >= 3;
      }
      expect(sawSurge, isTrue);
      expect(sawBroadside, isTrue);
      expect(sim.bossesDefeated, 4);
      expect(sim.phase, RunPhase.playing);
      expect(sim.hearts, greaterThan(0));
    });
  }
}

/// A sharp player's hover height: the lane whose next second, flown with
/// the same flap-when-below rule, stays furthest from every cannonball in
/// the air and from the water, then as close to the captain as that allows.
/// It only reads what the screen shows.
double _dodgeLane(FlightSimulation sim) {
  final boss = sim.boss;
  if (boss == null || boss.phase != BossPhase.attacking) return .5;
  final surging = boss.tideWarning > 0 || boss.tide > 0;
  final sea = surging ? SkyBoss.tidePeak : boss.waterLevel!;
  var best = sim.birdY, bestScore = double.negativeInfinity;
  for (var target = .08; target <= sea - .09; target += .02) {
    var y = sim.birdY, v = sim.velocity, clear = .2;
    for (var i = 1; i <= 50; i++) {
      final t = i * .02;
      if (y > target && v > 0) v = sim.rules.flapImpulse;
      v += sim.rules.gravity * .02;
      y += v * .02;
      clear = math.min(clear, math.min(sea - y, y) - _birdRadius);
      for (final ball in sim.bossAmmo) {
        final bx = ball.x + ball.vx * t;
        final by = ball.y + ball.vy * t + ball.gravity * t * t / 2;
        clear = math.min(
          clear,
          _hypot(bx - _birdX, by - y) - _birdRadius - ball.radius,
        );
      }
    }
    final score = math.min(clear, .08) * 20 - (target - boss.y).abs();
    if (score > bestScore) (bestScore, best) = (score, target);
  }
  return best;
}
