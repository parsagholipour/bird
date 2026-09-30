import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/session_replay.dart';
import 'package:push_up_bird/domain/tracking.dart';
import 'package:push_up_bird/game/boss_audio_cues.dart';
import 'package:push_up_bird/game/combat_audio_cues.dart';
import 'boss_fight_test.dart' show arena, step, hitBoss, snapshot;
import 'recorded_flight.dart';

const _birdX = FlightSimulation.birdX,
    _birdRadius = FlightSimulation.birdRadius;

/// A current flight whose dragon has just finished its arrival: by default
/// the second one of the flight (encounter 10), which brings the whole
/// fight; [defeated] 4 meets the first, on its debut.
FlightSimulation dragonArena({
  double width = 2.2,
  FlightCourse course = FlightCourse.starTrail,
  int defeated = 9,
}) {
  final sim = arena(
    version: FlightSimulation.currentRulesVersion,
    course: course,
  )..bossesDefeated = defeated;
  step(sim, .02, width);
  expect(sim.boss!.kind, BossKind.dragon);
  for (var i = 0; i < 235; i++) {
    sim.birdY = .5;
    sim.velocity = 0;
    step(sim, .02, width);
  }
  expect(sim.boss!.phase, BossPhase.attacking);
  return sim;
}

/// Sets the dragon's combat clock to [t] seconds into the fight.
void fightAt(SkyBoss boss, double t) => boss.age = boss.arrivalDuration + t;

/// The dragon's own state on top of the shared boss snapshot.
Object dragonSnapshot(FlightSimulation sim) => [
  snapshot(sim),
  sim.boss?.breathLane,
  sim.boss?.breathsAimed,
  sim.boss?.lastCoreHitAt,
  sim.bossAmmo.map((a) => [a.radius, a.ember, a.splitAfter, a.age]).toList(),
  sim.emberSplits,
  sim.breathBurns,
  sim.boss?.swarmCalls,
  sim.boss?.swarmFollows,
  sim.swarm.map((b) => [b.x, b.y]).toList(),
  sim.swarmSmashed,
];

/// Where a hovering bird should sit to be safe from [lane], nearest to
/// [y]: the lowest point of its flap-when-below bob, which rises about
/// 0.13 above it.
double safeTarget(BreathLane lane, double y) => switch (lane) {
  BreathLane.high => .8,
  BreathLane.low => .38,
  BreathLane.middle => y < .5 ? .25 : .9,
};

/// A player who taps at most [tapsPerSecond] times a second: rising toward
/// [target] they tap whenever the last flap's lift has mostly gone, and
/// hovering they tap as they sink past it.
bool flapToward(
  FlightSimulation sim,
  double target, {
  double tapsPerSecond = 5,
}) {
  if (sim.elapsed - sim.lastFlapAt < 1 / tapsPerSecond) return false;
  return sim.birdY > target && sim.velocity > -.25;
}

/// Breath-aware flight for recorded dragon fights: out of the band when the
/// dragon inhales, otherwise the shared sky-riding bot.
bool breathBot(FlightSimulation sim) {
  final boss = sim.boss;
  if (boss != null &&
      boss.isDragon &&
      (boss.breathWarning > 0 || boss.breathing)) {
    return flapToward(sim, safeTarget(boss.breathLane, sim.birdY));
  }
  return rideTheSky(sim);
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
  test('the dragon joins the cycle as the fifth boss from rules 38', () {
    for (final (version, defeated, kind) in [
      (37, 4, BossKind.baronBat),
      (37, 3, BossKind.pirate),
      (38, 3, BossKind.pirate),
      (38, 4, BossKind.dragon),
      (38, 5, BossKind.baronBat),
      (38, 9, BossKind.dragon),
    ]) {
      final sim = arena(version: version)..bossesDefeated = defeated;
      step(sim);
      expect(sim.boss!.kind, kind, reason: 'rules $version after $defeated');
      expect(sim.supportsDragon, version >= 38);
    }
    final boss = SkyBoss(number: 5, x: 1.5, kind: BossKind.dragon);
    expect(boss.name, 'Ember Dragon');
    expect(boss.title, 'SOVEREIGN OF THE BURNING SKY');
    expect(boss.summonIn, double.infinity, reason: 'It summons no helpers');
    expect(boss.waterLevel, isNull);
    expect(
      SkyBoss(number: 4, x: 1, kind: BossKind.pirate).breathing,
      isFalse,
      reason: 'Only the dragon breathes',
    );
  });

  test('health starts at 360 and climbs by 30 to a cap of 480', () {
    expect(
      [for (var n = 4; n <= 12; n++) SkyBoss.healthFor(BossKind.dragon, n)],
      [360, 360, 390, 420, 450, 480, 480, 480, 480],
    );
    final first = dragonArena(defeated: 4).boss!;
    expect((first.number, first.maxHp), (5, 360));
    final second = dragonArena().boss!;
    expect((second.number, second.maxHp), (10, 480));
  });

  test('the first dragon of a flight is its debut, later ones are not', () {
    final first = dragonArena(defeated: 4).boss!;
    final later = dragonArena().boss!;
    expect(first.debut, isTrue);
    expect(later.debut, isFalse);
    // On its debut it only ever burns one half of the sky ...
    for (var y = .05; y < .96; y += .01) {
      expect(
        DragonBreath.aimAt(y, debut: true),
        y < .5 ? BreathLane.high : BreathLane.low,
      );
    }
    expect(DragonBreath.aimAt(.5), BreathLane.middle);
    expect(DragonBreath.aimAt(.3), BreathLane.high);
    expect(DragonBreath.aimAt(.7), BreathLane.low);
    // ... and its fury fireballs never split into embers.
    first
      ..hp = first.maxHp ~/ 3
      ..volleys = 0;
    later
      ..hp = later.maxHp ~/ 3
      ..volleys = 0;
    expect((first.splitsVolley, later.splitsVolley), (false, true));
  });

  test('the breath warns, burns and ends on a fixed cycle', () {
    final sim = dragonArena();
    final boss = sim.boss!..fireIn = 99;
    void at(double t) {
      fightAt(boss, t - .02);
      step(sim);
    }

    at(DragonBreath.warnAt - .1);
    expect((boss.breathWarning, boss.breaths, boss.breathing), (0, 0, false));
    expect(boss.coreExposed, isFalse);
    expect(boss.breathQuiet, isTrue, reason: 'The jaws are held first');
    at(DragonBreath.warnAt + .75);
    expect(boss.breathWarning, closeTo(.5, .02));
    expect(boss.breaths, 1);
    expect(boss.breathBlasts, 0);
    expect(boss.breathing, isFalse, reason: 'Warnings are fair');
    expect(boss.coreExposed, isTrue);
    at(DragonBreath.blastAt + .1);
    expect(boss.breathing, isTrue);
    expect(boss.breathBlasts, 1);
    expect(boss.breathWarning, 0);
    at(DragonBreath.endAt + .05);
    expect(boss.breathing, isFalse);
    expect(boss.coreExposed, isFalse);
    // Fury never changes the cycle.
    boss.hp = boss.maxHp ~/ 3;
    at(DragonBreath.period + DragonBreath.warnAt + .4);
    expect(boss.breathWarning, greaterThan(0));
    expect(boss.breaths, 2);
    at(DragonBreath.period + DragonBreath.blastAt + .4);
    expect(boss.breathing, isTrue);
    expect(boss.breathHint, startsWith('FIRE'));
    expect(DragonBreath.warnSeconds, 1.5);
    expect(DragonBreath.blastSeconds, closeTo(1.6, 1e-9));
  });

  test('each breath aims where the bird is as the inhale begins', () {
    for (final (y, lane) in [
      (.2, BreathLane.high),
      (.5, BreathLane.middle),
      (.8, BreathLane.low),
    ]) {
      final sim = dragonArena();
      final boss = sim.boss!..fireIn = 99;
      fightAt(boss, DragonBreath.warnAt - .01);
      sim.birdY = y;
      sim.velocity = 0;
      step(sim);
      expect(boss.breaths, 1);
      expect(boss.breathLane, lane);
      // Moving afterwards does not re-aim it.
      sim.birdY = 1 - y;
      step(sim);
      expect(boss.breathLane, lane);
      expect(boss.breathsAimed, 1);
      final (top, bottom) = DragonBreath.band(lane);
      expect(y, inInclusiveRange(top, bottom), reason: 'It aims at the bird');
    }
  });

  test('the flame burns only inside its band and only while it blazes', () {
    final sim = dragonArena();
    final boss = sim.boss!..fireIn = 99;
    boss.breathLane = BreathLane.high;
    boss.breathsAimed = 99;
    fightAt(boss, DragonBreath.blastAt - .3);
    step(sim, 1 / 120);
    sim.birdY = .3;
    step(sim, 1 / 120);
    expect(sim.shield, isTrue, reason: 'No burn before the blast');
    fightAt(boss, DragonBreath.blastAt + .2);
    // Just clear of the band's edge is safe.
    sim.birdY = DragonBreath.split + _birdRadius + .002;
    sim.velocity = 0;
    step(sim, 1 / 120);
    expect((sim.shield, sim.breathBurns), (true, 0));
    // Touching it costs the shield, then a heart after the recovery.
    sim.birdY = DragonBreath.split + _birdRadius - .004;
    sim.velocity = 0;
    step(sim, 1 / 120);
    expect((sim.shield, sim.hearts, sim.breathBurns), (false, 3, 1));
    sim.birdY = .3;
    step(sim, 1 / 120);
    expect(sim.hearts, 3, reason: 'Recovering');
    sim.invulnerableUntil = 0;
    sim.birdY = .3;
    step(sim, 1 / 120);
    expect((sim.hearts, sim.breathBurns), (2, 2));
    fightAt(boss, DragonBreath.endAt + .01);
    sim.invulnerableUntil = 0;
    sim.birdY = .3;
    step(sim, 1 / 120);
    expect(sim.hearts, 2, reason: 'Gone the moment it ends');

    final classic = dragonArena(course: FlightCourse.classic);
    final dragon = classic.boss!
      ..fireIn = 99
      ..breathLane = BreathLane.low
      ..breathsAimed = 99;
    fightAt(dragon, DragonBreath.blastAt + .2);
    classic.birdY = .8;
    step(classic, 1 / 120);
    expect(classic.phase, RunPhase.ended);
    expect(classic.endReason, EndReason.collision);
  });

  test('the cutscenes never burn', () {
    final sim = arena(version: FlightSimulation.currentRulesVersion)
      ..bossesDefeated = 9;
    step(sim);
    final boss = sim.boss!;
    boss.breathLane = BreathLane.middle;
    for (var i = 0; i < 400; i++) {
      step(sim);
      expect(boss.breathing, isFalse);
    }
    fightAt(boss, DragonBreath.blastAt + .1);
    hitBoss(sim, count: boss.hp ~/ BirdRock.baseDamage + 2);
    expect(boss.phase, BossPhase.defeated);
    expect(boss.breathing, isFalse);
    expect(boss.coreExposed, isFalse);
  });

  test('from anywhere in the band, a 5-tap-a-second bird reaches safety in '
      'time and holds it through the flame', () {
    for (final debut in [false, true]) {
      for (var start = .05; start <= .95; start += .015) {
        final sim = dragonArena(defeated: debut ? 4 : 9)..invulnerableUntil = 0;
        final boss = sim.boss!..fireIn = 99;
        fightAt(boss, DragonBreath.warnAt - .004);
        sim.birdY = start;
        sim.velocity = 0;
        _input(sim);
        step(sim, 1 / 120);
        final lane = boss.breathLane;
        final (top, bottom) = DragonBreath.band(lane);
        expect(start, inInclusiveRange(top, bottom));
        final target = safeTarget(lane, start);
        final hearts = sim.hearts;
        var safeBy = double.infinity;
        while (boss.age - boss.arrivalDuration < DragonBreath.endAt + .1) {
          _input(sim, flap: flapToward(sim, target));
          sim.tick(1 / 60, sim.elapsed * 1000 + 17);
          final burning = DragonBreath.scorches(lane, sim.birdY, _birdRadius);
          final t = boss.age - boss.arrivalDuration;
          if (!burning && safeBy == double.infinity) safeBy = t;
          if (burning) safeBy = double.infinity;
        }
        final reason = '${debut ? 'debut ' : ''}$lane from $start';
        expect(safeBy, lessThan(DragonBreath.blastAt), reason: reason);
        expect(sim.hearts, hearts, reason: reason);
        expect(sim.shield, isTrue, reason: reason);
        expect(sim.breathBurns, 0, reason: reason);
      }
    }
  });

  test('fireballs leave the jaws, aimed at the bird, and pause for breath', () {
    final sim = dragonArena();
    final boss = sim.boss!;
    expect(boss.x, closeTo(math.max(_birdX + .76, 2.2 - .5), 1e-9));
    fightAt(boss, 1.25);
    boss.fireIn = .001;
    sim.birdY = .5;
    step(sim, 1 / 120);
    final ball = sim.bossAmmo.single;
    expect(ball.radius, BossAmmo.fireballRadius);
    expect(ball.x, closeTo(boss.x + SkyBoss.dragonMouth.$1, .01));
    expect(ball.y, closeTo(boss.y + SkyBoss.dragonMouth.$2, .01));
    final aim = math.atan2(.5 - ball.y, _birdX - ball.x);
    expect(math.atan2(ball.vy, ball.vx), closeTo(aim, .02));
    expect(
      math.sqrt(ball.vx * ball.vx + ball.vy * ball.vy),
      closeTo(.52, 1e-9),
    );
    expect(boss.fireIn, closeTo(2.0, .01));
    // The pair brackets the bird.
    sim.bossAmmo.clear();
    boss.fireIn = .001;
    step(sim, 1 / 120);
    expect(sim.bossAmmo, hasLength(2));
    // From a second before the inhale to the end of the flame: nothing.
    sim.bossAmmo.clear();
    fightAt(boss, DragonBreath.warnAt - DragonBreath.quietBefore + .01);
    boss.fireIn = .001;
    while (boss.age - boss.arrivalDuration < DragonBreath.endAt - .02) {
      step(sim);
      sim.birdY = .5;
      sim.velocity = 0;
      sim.invulnerableUntil = double.infinity;
    }
    expect(sim.bossAmmo, isEmpty);
    expect(boss.fireIn, greaterThanOrEqualTo(SkyBoss.dragonRefire - .03));
  });

  group('swarm flocks', () {
    /// Runs the fight from just before [t] seconds of combat to just after
    /// it, with the bird held at [y].
    void callAt(FlightSimulation sim, double t, {double y = .5}) {
      fightAt(sim.boss!, t - .02);
      for (var i = 0; i < 4; i++) {
        sim.birdY = y;
        sim.velocity = 0;
        step(sim, 1 / 120);
      }
    }

    test('as each flame gutters out the dragon calls a flock at the bird', () {
      final sim = dragonArena();
      final boss = sim.boss!..fireIn = 99;
      final cues = BossAudioCues()..advance(boss);
      callAt(sim, SkyBoss.swarmCallAt - .1, y: .3);
      expect(sim.swarm, isEmpty);
      callAt(sim, SkyBoss.swarmCallAt, y: .3);
      expect(sim.swarm, hasLength(Rush.flockSize));
      for (final (k, bat) in sim.swarm.indexed) {
        expect(bat.route, isNull);
        expect(bat.lane, 0);
        expect(bat.height, .3);
        expect(bat.y, closeTo(.3, .013));
        expect(bat.x, greaterThan(2.2), reason: 'From behind the dragon');
        if (k > 0) {
          expect(bat.x - sim.swarm[k - 1].x, closeTo(Rush.flockSpacing, 1e-9));
        }
      }
      expect((boss.summons, boss.swarmCalls), (1, 1));
      expect(boss.lastSummonAt, closeTo(boss.age, .02));
      expect(cues.advance(boss), contains('boss_summon'));
      expect(boss.breathHint, startsWith('SWARM'));
      // Out of fury no second flock follows, and each call comes once.
      callAt(sim, SkyBoss.swarmCallAt + SkyBoss.swarmFollowAfter, y: .7);
      expect(boss.summons, 1);
      expect(sim.swarm.every((b) => b.height == .3), isTrue);
      // A flock never flies along an edge.
      callAt(sim, DragonBreath.period + SkyBoss.swarmCallAt, y: .05);
      expect(sim.swarm.last.height, .15);
    });

    test(
      'in fury a second flock follows at the bird, but not on the debut',
      () {
        for (final defeated in [9, 4]) {
          final sim = dragonArena(defeated: defeated);
          final boss = sim.boss!..fireIn = 99;
          boss.hp = boss.maxHp ~/ 2;
          callAt(sim, SkyBoss.swarmCallAt, y: .3);
          callAt(sim, SkyBoss.swarmCallAt + SkyBoss.swarmFollowAfter, y: .7);
          final heights = {for (final bat in sim.swarm) bat.height};
          expect(
            heights,
            defeated == 4 ? {.3} : {.3, .7},
            reason: defeated == 4 ? 'Debut' : 'Later',
          );
        }
      },
    );

    test('both flocks have flown past before the next inhale', () {
      for (final width in [640 / 360, 800 / 360, 2.6]) {
        final sim = dragonArena(width: width);
        final boss = sim.boss!..fireIn = 99;
        boss.hp = boss.maxHp ~/ 2;
        fightAt(boss, SkyBoss.swarmCallAt - .02);
        var calls = 0;
        while (boss.age - boss.arrivalDuration <
            DragonBreath.period + DragonBreath.warnAt) {
          sim.birdY = .1;
          sim.velocity = 0;
          sim.invulnerableUntil = double.infinity;
          step(sim, .02, width);
          calls = math.max(calls, boss.summons);
        }
        expect(calls, 2);
        expect(sim.swarm, isEmpty, reason: 'at ${width.toStringAsFixed(2)}');
      }
    });

    test('a bat hurts like any bat, and a sprint or a rock smashes it', () {
      SwarmBat batAt(FlightSimulation sim, double dx) {
        final bat = SwarmBat(x: _birdX + dx, y: .5, lane: 0, phase: 0);
        sim.swarm.add(bat);
        return bat;
      }

      final sim = dragonArena();
      sim.boss!.fireIn = 99;
      sim.shield = false;
      final hearts = sim.hearts;
      batAt(sim, .01);
      sim.birdY = .5;
      step(sim, 1 / 120);
      expect((sim.hearts, sim.swarm.length), (hearts - 1, 0));

      sim.lastSprintAt = sim.elapsed;
      final score = sim.score;
      batAt(sim, .01);
      sim.birdY = .5;
      step(sim, 1 / 120);
      expect((sim.swarmSmashed, sim.swarm.length), (1, 0));
      expect(sim.score, score + Rush.batPoints);

      sim.lastSprintAt = double.negativeInfinity;
      final bat = batAt(sim, .5);
      sim.rocks.add(BirdRock(x: bat.x - .02, y: .5));
      sim.birdY = .5;
      step(sim, 1 / 120);
      expect((sim.swarmSmashed, sim.swarm.length), (2, 0));
      expect(sim.hearts, hearts - 1);

      final classic = dragonArena(course: FlightCourse.classic);
      classic.boss!.fireIn = 99;
      callAt(classic, SkyBoss.swarmCallAt);
      expect(classic.swarm, hasLength(Rush.flockSize));
      for (var i = 0; i < 400 && classic.phase == RunPhase.playing; i++) {
        classic.birdY = classic.swarm.firstOrNull?.height ?? .5;
        classic.velocity = 0;
        step(classic);
      }
      expect(classic.endReason, EndReason.collision, reason: 'Classic ends');
    });

    test('defeat scatters the swarm, and rules 38 call none', () {
      final sim = dragonArena();
      final boss = sim.boss!..fireIn = 99;
      callAt(sim, SkyBoss.swarmCallAt);
      expect(sim.swarm, isNotEmpty);
      hitBoss(sim, count: boss.hp ~/ BirdRock.baseDamage + 2);
      expect(boss.phase, BossPhase.defeated);
      expect(sim.swarm, isEmpty);

      final old = arena(version: 38)..bossesDefeated = 9;
      step(old);
      expect(old.supportsDragonSwarm, isFalse);
      final dragon = old.boss!;
      expect(dragon.callsSwarm, isFalse);
      for (var i = 0; i < 1200; i++) {
        old.birdY = .5;
        old.velocity = 0;
        old.invulnerableUntil = double.infinity;
        step(old);
      }
      expect(dragon.age - dragon.arrivalDuration, greaterThan(15));
      expect((dragon.summons, old.swarm.length), (0, 0));
    });
  });

  test('hits on the open heart count double', () {
    final sim = dragonArena();
    final boss = sim.boss!..fireIn = 99;
    final full = boss.hp;
    fightAt(boss, 1);
    hitBoss(sim);
    expect(boss.hp, full - BirdRock.baseDamage);
    expect(boss.lastCoreHitAt.isFinite, isFalse);
    fightAt(boss, DragonBreath.warnAt + .5);
    hitBoss(sim);
    expect(boss.hp, full - BirdRock.baseDamage * 3);
    expect(boss.lastCoreHitAt, boss.lastHitAt);
    expect(boss.lastDamage, BirdRock.baseDamage * SkyBoss.coreMultiplier);
    expect(boss.breathHint, contains('heart'));
    // Ordinary bosses never take the bonus.
    final bat = SkyBoss(number: 1, x: 1, kind: BossKind.baronBat)..age = 10;
    expect(bat.strike(10), 10);
  });

  test('in fury the lone fireball bursts into three embers', () {
    final sim = dragonArena();
    final boss = sim.boss!;
    boss.hp = boss.maxHp ~/ 3;
    fightAt(boss, 1);
    boss
      ..volleys = 2
      ..fireIn = .001;
    sim.birdY = .5;
    sim.invulnerableUntil = double.infinity;
    step(sim, 1 / 120);
    expect(boss.fireIn, closeTo(1.55, .01));
    final ball = sim.bossAmmo.single;
    expect(ball.splitAfter, SkyBoss.emberSplitAfter);
    final heading = math.atan2(ball.vy, ball.vx);
    final speed = math.sqrt(ball.vx * ball.vx + ball.vy * ball.vy);
    expect(speed, closeTo(.62, 1e-9));
    boss.fireIn = 99;
    for (var i = 0; i < 60 && sim.emberSplits == 0; i++) {
      step(sim, 1 / 120);
    }
    expect(sim.emberSplits, 1);
    expect(sim.bossAmmo, hasLength(3));
    expect(sim.bossAmmo.every((a) => a.ember), isTrue);
    final headings = [
      for (final e in sim.bossAmmo)
        math.atan2(
          math.sin(math.atan2(e.vy, e.vx) - heading),
          math.cos(math.atan2(e.vy, e.vx) - heading),
        ),
    ];
    expect(headings[0], closeTo(-SkyBoss.emberSpread, 1e-9));
    expect(headings[1], closeTo(0, 1e-9));
    expect(headings[2], closeTo(SkyBoss.emberSpread, 1e-9));
    expect(sim.bossAmmo.first.radius, BossAmmo.emberRadius);
    // Split well short of the bird: it has time to read the embers.
    expect(sim.bossAmmo.first.x - _birdX, greaterThan(.25));
    // Odd volleys stay a pair and never split.
    boss
      ..volleys = 3
      ..fireIn = .001;
    sim.bossAmmo.clear();
    step(sim, 1 / 120);
    expect(sim.bossAmmo.map((a) => a.splitAfter), [null, null]);
  });

  test('pause and resume freeze the breath and the fireballs', () {
    final sim = dragonArena();
    fightAt(sim.boss!, DragonBreath.warnAt + .6);
    step(sim);
    final before = dragonSnapshot(sim);
    sim.takeBreak();
    step(sim, .5);
    sim.resume();
    step(sim, 2);
    step(sim, 1.1);
    expect(dragonSnapshot(sim), before);
  });

  test('the inhale, flame and ember burst have their own cues', () {
    final sim = dragonArena();
    final boss = sim.boss!;
    final bossCues = BossAudioCues(), combatCues = CombatAudioCues();
    bossCues.advance(boss);
    combatCues.advance(sim);
    List<String> at(double t) {
      fightAt(boss, t);
      return bossCues.advance(boss);
    }

    boss.fireIn = .3;
    expect(bossCues.advance(boss), ['boss_charge']);
    boss.volleys++;
    expect(bossCues.advance(boss), ['boss_volley']);
    boss.fireIn = 99;
    expect(at(DragonBreath.warnAt - .1), isEmpty);
    expect(at(DragonBreath.warnAt + .1), ['dragon_inhale']);
    expect(at(DragonBreath.blastAt + .1), ['dragon_breath']);
    expect(at(DragonBreath.endAt + .5), isEmpty);
    sim.emberSplits++;
    expect(combatCues.advance(sim), ['ember_split']);
    // Seeking back and replaying silently never roars twice.
    expect(at(DragonBreath.blastAt + .2), isEmpty);
    bossCues.advance(boss, silent: true);
    expect(at(DragonBreath.blastAt + .3), isEmpty);
  });

  test('identical inputs replay identically, embers and breaths included', () {
    List<Object> run() {
      final sim = dragonArena();
      final states = <Object>[];
      for (var i = 0; i < 1500; i++) {
        _input(sim, flap: breathBot(sim));
        if (sim.canShoot && i % 7 == 0) sim.shoot();
        sim.tick(.02, sim.elapsed * 1000 + 20, viewportWidth: 2.2);
        if (i % 50 == 0) states.add(dragonSnapshot(sim));
        if (i == 400) sim.boss!.hp = sim.boss!.maxHp ~/ 2 + 1;
      }
      return states;
    }

    final a = run();
    expect(run(), a);
  });

  test('a recorded dragon fight survives backward and forward seeks', () {
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
    for (var frame = 1; frame <= 16000; frame++) {
      now = frame * 50.0;
      final flap = breathBot(sim);
      recorder.apply(
        MovementInput(valid: true, flap: flap),
        TrackingSample(
          mode: PlayMode.touch,
          timestampMs: now,
          receivedMs: now,
          joints: const [],
        ),
        now,
      );
      final boss = sim.boss;
      // Let the dragon breathe twice before it is beaten.
      final holdFire =
          boss != null &&
          boss.isDragon &&
          boss.age - boss.arrivalDuration < DragonBreath.period + 3;
      if (sim.canShoot && !holdFire) recorder.command('shoot');
      recorder.tick(.05, now, 2.2);
      if (sim.boss case final dragon? when dragon.isDragon) {
        final state = dragon.phase == BossPhase.defeated
            ? 'defeated'
            : sim.emberSplits > 0 && !seen.contains('split')
            ? 'split'
            : dragon.breathing
            ? 'flame'
            : dragon.breathWarning > 0
            ? 'inhale'
            : 'open';
        if (seen.add(state)) checkpoints[now] = dragonSnapshot(sim);
      }
      if (sim.bossesDefeated >= 5 && sim.boss == null) break;
      if (sim.phase == RunPhase.ended) break;
    }
    expect(sim.phase, isNot(RunPhase.ended));
    expect(seen, containsAll(['inhale', 'flame', 'defeated']));
    final replay = ReplayPlayer(ReplayTape.fromJson(recorder.tape.toJson()));
    final times = checkpoints.keys.toList();
    for (final time in [...times.reversed, ...times]) {
      replay.seek(time);
      expect(dragonSnapshot(replay.simulation), checkpoints[time]);
    }
  });

  for (final (width, defeated) in [
    (640 / 360, 4),
    (800 / 360, 4),
    (640 / 360, 9),
    (800 / 360, 9),
  ]) {
    test(
      'the dragon is beatable with legal flaps and shots at '
      '${width.toStringAsFixed(2)} (${defeated == 4 ? 'debut' : 'later'})',
      () {
        final sim = arena(version: FlightSimulation.currentRulesVersion)
          ..bossesDefeated = defeated;
        var now = sim.elapsed * 1000;
        var sawBreath = false, sawSplit = false, sawSwarm = false;
        final lanes = <BreathLane>{};
        for (var i = 0; i < 9000 && sim.bossesDefeated == defeated; i++) {
          now += 20;
          final flapAt = _dodgeLane(sim);
          final boss = sim.boss;
          final breath =
              boss != null &&
              boss.isDragon &&
              (boss.breathWarning > 0 || boss.breathing);
          sim.apply(
            MovementInput(
              valid: true,
              flap: breath
                  ? flapToward(sim, safeTarget(boss.breathLane, sim.birdY))
                  : sim.birdY > flapAt && sim.velocity > 0,
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
          if (sim.boss case final b? when b.breathing) {
            sawBreath = true;
            lanes.add(b.breathLane);
          }
          sawSplit |= sim.emberSplits > 0;
          sawSwarm |= sim.swarm.isNotEmpty;
        }
        expect(sawBreath, isTrue);
        expect(sawSwarm, isTrue);
        expect(sawSplit, defeated != 4, reason: 'Debut fireballs never split');
        if (defeated == 4) {
          expect(lanes, isNot(contains(BreathLane.middle)));
        }
        expect(sim.bossesDefeated, defeated + 1);
        expect(sim.phase, RunPhase.playing);
        expect(sim.hearts, greaterThan(0));
      },
    );
  }
}

/// A sharp player's hover height between breaths: the lane whose next
/// second, flown with the same flap-when-below rule, stays furthest from
/// every fireball, ember and swarm bat, then as close to the dragon's heart
/// as that allows. It only reads what the screen shows.
double _dodgeLane(FlightSimulation sim) {
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
              ball.radius -
              // A splitting fireball fans out: give it room.
              (ball.splitAfter != null ? .12 : 0),
        );
      }
      for (final bat in sim.swarm) {
        final bx = bat.x - (sim.speed * sim.courseBoost + Rush.swarmSpeed) * t;
        clear = math.min(
          clear,
          math.sqrt((bx - _birdX) * (bx - _birdX) + (bat.y - y) * (bat.y - y)) -
              _birdRadius -
              SwarmBat.radius -
              // The bats bob as they fly.
              .015,
        );
      }
    }
    final score = math.min(clear, .08) * 20 - (target - boss.y).abs();
    if (score > bestScore) (bestScore, best) = (score, target);
  }
  return best;
}
