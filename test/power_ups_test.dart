import 'dart:convert';
import 'dart:math';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/data/progress_repository.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/session_replay.dart';
import 'package:push_up_bird/domain/tracking.dart';
import 'touch_combat_test.dart' show tick;

/// A touch Star Trail flown with [upgrades], cleared of everything laid.
FlightSimulation flight(
  PowerUps upgrades, {
  int version = FlightSimulation.currentRulesVersion,
}) {
  final sim = FlightSimulation(
    rules: TapFlyMode(rulesVersion: version),
    practice: true,
    course: FlightCourse.starTrail,
    rulesVersion: version,
    upgrades: upgrades,
    random: Random(4),
  );
  tick(sim, 3);
  sim.obstacles.clear();
  sim.stars.clear();
  sim.starTrios.clear();
  sim.enemies.clear();
  return sim;
}

/// Hovers in place so nothing but the test touches the bird.
void hover(FlightSimulation sim, double seconds) {
  for (var i = 0; i < (seconds / .02).round(); i++) {
    sim.birdY = .5;
    sim.velocity = 0;
    tick(sim, .02);
  }
}

void collect(FlightSimulation sim, int count) {
  for (var i = 0; i < count; i++) {
    sim.stars.add(SkyStar(x: FlightSimulation.birdX, y: .5));
    hover(sim, .02);
  }
}

void perfectGate(FlightSimulation sim) {
  sim.obstacles
    ..clear()
    ..add(
      Obstacle(
        x: FlightSimulation.birdX - FlightSimulation.birdRadius - .141,
        center: .5,
        gap: .45,
      )..maxDeviation = 0,
    );
  hover(sim, .02);
}

RunResult trail(String id, int stars, {bool practice = false, int? score}) =>
    RunResult(
      id: id,
      mode: PlayMode.touch,
      practice: practice,
      course: FlightCourse.starTrail,
      score: score ?? stars,
      stars: stars,
      repetitions: 0,
      flaps: 10,
      durationSeconds: 30,
      reason: EndReason.collision,
      finishedAt: DateTime(2026, 10, 4),
    );

void main() {
  test('the top levels keep shot, sprint and shield as they always were; '
      'the magnet flew one below its top', () {
    expect(ShotPower.maxCharge(4), 1);
    expect(SprintPower.seconds(4), Sprint.seconds);
    expect(SprintPower.cooldown(4), Sprint.cooldown);
    expect(ShieldPower.stars(4), 9);
    expect(ShieldPower.cover(4), 1.5);
    expect(MagnetPower.gates(3), 3);
    expect(MagnetPower.seconds(3), 8);
    expect(MagnetPower.radius(3), .20);
    expect(MagnetPower.seconds(4), greaterThan(8));
    expect(MagnetPower.radius(4), closeTo(.22, 1e-12));
    for (final p in PowerUp.values) {
      for (var level = 1; level <= PowerUp.maxLevel; level++) {
        expect(
          PowerUp.costFrom(level - 1),
          isPositive,
          reason: '${p.name} $level',
        );
      }
      expect(PowerUp.costFrom(PowerUp.maxLevel), isNull);
    }
    // Every level is at least as good as the one below it.
    for (var l = 1; l <= PowerUp.maxLevel; l++) {
      expect(ShotPower.maxCharge(l), greaterThan(ShotPower.maxCharge(l - 1)));
      expect(SprintPower.seconds(l), greaterThan(SprintPower.seconds(l - 1)));
      expect(SprintPower.cooldown(l), lessThan(SprintPower.cooldown(l - 1)));
      expect(ShieldPower.stars(l), lessThanOrEqualTo(ShieldPower.stars(l - 1)));
      expect(ShieldPower.cover(l), greaterThan(ShieldPower.cover(l - 1)));
      expect(MagnetPower.gates(l), lessThanOrEqualTo(MagnetPower.gates(l - 1)));
      expect(MagnetPower.seconds(l), greaterThan(MagnetPower.seconds(l - 1)));
      expect(MagnetPower.radius(l), greaterThan(MagnetPower.radius(l - 1)));
    }
  });

  test('flights default to the legacy levels; older rules ignore upgrades', () {
    expect(flight(PowerUps.legacy).upgrades, PowerUps.legacy);
    final old = flight(
      const PowerUps(),
      version: FlightSimulation.upgradesRulesVersion - 1,
    );
    expect(old.upgrades, PowerUps.legacy);
    expect(old.maxCharge, 1);
    expect(old.shieldStars, 9);
    expect(old.magnetGates, 3);
    expect(
      () => flight(const PowerUps(shot: 5)),
      throwsArgumentError,
      reason: 'Levels stop at the top',
    );
  });

  test('a level-0 shot charges enough to see, shatter, and release itself', () {
    final sim = flight(const PowerUps());
    expect(sim.maxCharge, .40);
    expect(
      PowerShot.shatters(sim.maxCharge),
      isTrue,
      reason: 'Even level 0 can show what a charged rock does',
    );
    expect(sim.startCharge(), isTrue);
    hover(sim, .3);
    expect(sim.shotCharge, closeTo(.3, 1e-9));
    expect(sim.shotChargeFull, isFalse);
    hover(sim, .12);
    expect(sim.shotCharge, closeTo(.40, 1e-9));
    expect(sim.shotChargeFull, isTrue);
    expect(sim.shots, 0);
    hover(sim, PowerShot.maxFullHoldSeconds);
    expect(sim.shots, 1, reason: 'The capped charge fires on its own');
    expect(sim.rocks.single.charge, closeTo(.40, 1e-9));
    expect(sim.rocks.single.damage, PowerShot.damage(BirdRock.baseDamage, .40));
    expect(sim.ammo, closeTo(1 - PowerShot.cost(.40), 1e-9));
  });

  test('each shot level charges further, up to a full second at the top', () {
    for (var level = 0; level <= PowerUp.maxLevel; level++) {
      final sim = flight(PowerUps.legacy.withLevel(PowerUp.shot, level))
        ..startCharge();
      final top = ShotPower.maxCharge(level);
      hover(sim, top + .1);
      expect(sim.shotCharge, closeTo(top, 1e-9));
      expect(sim.shotChargeFull, isTrue);
      sim.shoot();
      expect(sim.rocks.single.charge, closeTo(top, 1e-9));
    }
  });

  test('a level-0 sprint is shorter and comes back later', () {
    final sim = flight(const PowerUps())..invulnerableUntil = double.infinity;
    expect(sim.sprint(), isTrue);
    expect(sim.sprintRemaining, closeTo(.9, 1e-9));
    expect(sim.sprintCooldownRemaining, closeTo(25, 1e-9));
    hover(sim, .92);
    expect(sim.sprinting, isFalse);
    expect(sim.sprintBoost, 1);
    hover(sim, 25 - .92 - .1);
    expect(sim.canSprint, isFalse);
    hover(sim, .12);
    expect(sim.canSprint, isTrue);
  });

  test('the sprint burst eases out before its shorter end', () {
    double boostAt(double age) => Sprint.boost(age, length: .9);
    expect(boostAt(.3), Sprint.peakBoost);
    expect(boostAt(.9 - .2), closeTo(1.75, 1e-9));
    expect(boostAt(.9), 1);
    expect(Sprint.boost(.5), Sprint.boost(.5, length: Sprint.seconds));
  });

  test('a level-0 shield needs 15 stars and covers briefly once broken', () {
    final sim = flight(const PowerUps());
    expect(sim.shield, isTrue);
    sim.obstacles.add(Obstacle(x: FlightSimulation.birdX, center: .2, gap: .3));
    hover(sim, .02);
    expect(sim.shield, isFalse);
    expect(sim.hearts, 3);
    expect(sim.recoverySeconds, .6);
    expect(sim.recoveryRemaining, closeTo(.6 - .02, .021));
    sim.obstacles.clear();
    hover(sim, .7);
    expect(sim.recoveryRemaining, 0);
    collect(sim, 9);
    expect(sim.shield, isFalse, reason: 'Nine stars are not enough at 0');
    expect(sim.shieldCharge, 9);
    expect(sim.shieldStars, 15);
    collect(sim, 6);
    expect(sim.shield, isTrue);
    // A lost heart still recovers for the full 1.5 s.
    sim.shield = false;
    sim.obstacles.add(Obstacle(x: FlightSimulation.birdX, center: .2, gap: .3));
    hover(sim, .02);
    expect(sim.hearts, 2);
    expect(sim.recoverySeconds, 1.5);
  });

  test('the top magnet lasts 10 s and reaches 10% further', () {
    final sim = flight(PowerUps.max);
    for (var i = 0; i < 2; i++) {
      perfectGate(sim);
    }
    expect(sim.magnetActive, isFalse);
    perfectGate(sim);
    expect(sim.magnetActive, isTrue);
    expect(sim.magnetRemaining, closeTo(10, .03));
    expect(sim.pickupRadius, closeTo(.22, 1e-12));
  });

  test('a level-0 magnet takes five perfect gates and is shorter', () {
    final sim = flight(const PowerUps());
    for (var i = 0; i < 4; i++) {
      perfectGate(sim);
    }
    expect(sim.magnetActive, isFalse);
    expect(sim.magnetCharge, 4);
    perfectGate(sim);
    expect(sim.magnetActive, isTrue);
    expect(sim.magnetRemaining, closeTo(5, .03));
    expect(sim.pickupRadius, .16);
  });

  test('journals record their upgrades and replay with them', () {
    const upgrades = PowerUps(shot: 1, sprint: 2, shield: 3, magnet: 4);
    final tape = ReplayTape(
      mode: PlayMode.touch,
      course: FlightCourse.starTrail,
      practice: false,
      seed: 9,
      cycleSeconds: 3,
      bird: 0,
      reducedMotion: false,
      originMs: 0,
      upgrades: upgrades,
    );
    expect(tape.createSimulation().upgrades, upgrades);
    final json = jsonDecode(jsonEncode(tape.toJson())) as Map<String, dynamic>;
    expect(json['upgrades'], upgrades.toJson());
    expect(ReplayTape.fromJson(json).upgrades, upgrades);
    expect(
      () => ReplayTape.fromJson({...json, 'upgrades': null}),
      throwsFormatException,
    );
    expect(
      () => ReplayTape.fromJson({
        ...json,
        'upgrades': {...upgrades.toJson(), 'magnet': 5},
      }),
      throwsFormatException,
    );
    // An older journal never carried upgrades and flies the legacy levels.
    final old = ReplayTape.fromJson({
      ...json..remove('upgrades'),
      'version': FlightSimulation.upgradesRulesVersion - 1,
    });
    expect(old.upgrades, PowerUps.legacy);
    expect(old.toJson().containsKey('upgrades'), isFalse);
  });

  test('stars collected on scored flights buy upgrades', () async {
    final repo = SqliteProgressRepository(
      ProgressDatabase(NativeDatabase.memory()),
    );
    addTearDown(repo.close);
    var p = await repo.load();
    expect(p.upgrades, const PowerUps());
    expect(p.starWallet, 0);
    expect(p.canBuy(PowerUp.shot), isFalse);
    await expectLater(repo.buyUpgrade(PowerUp.shot), throwsStateError);

    await repo.saveRun(trail('a', 100, score: 900));
    await repo.saveRun(trail('practice', 500, practice: true));
    p = await repo.load();
    expect(p.starsEarned, 100, reason: 'Stars picked up, never the score');
    expect(p.starWallet, 100);
    expect(p.canBuy(PowerUp.magnet), isTrue);
    await repo.buyUpgrade(PowerUp.magnet);
    p = await repo.load();
    expect(p.upgrades.magnet, 1);
    expect(p.starsSpent, PowerUp.costs[0]);
    expect(p.starWallet, 100 - PowerUp.costs[0]);
    expect(p.canBuy(PowerUp.magnet), isFalse, reason: '120 for level 2');
    await expectLater(repo.buyUpgrade(PowerUp.magnet), throwsStateError);
    p = await repo.load();
    expect(p.upgrades.magnet, 1, reason: 'A refused purchase changes nothing');
    expect(p.starsSpent, PowerUp.costs[0]);

    await repo.saveRun(trail('b', 2000));
    for (var i = 1; i < PowerUp.maxLevel; i++) {
      await repo.buyUpgrade(PowerUp.magnet);
    }
    p = await repo.load();
    expect(p.upgrades.magnet, PowerUp.maxLevel);
    expect(p.starsSpent, PowerUp.costs.fold(0, (a, b) => a + b));
    expect(p.canBuy(PowerUp.magnet), isFalse);
    await expectLater(repo.buyUpgrade(PowerUp.magnet), throwsStateError);

    await repo.reset();
    p = await repo.load();
    expect(p.upgrades, const PowerUps());
    expect(p.starsSpent, 0);
  });
}
