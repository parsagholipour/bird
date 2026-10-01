import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/session_replay.dart';
import 'package:push_up_bird/domain/tracking.dart';

import 'coop_flight_test.dart' show clearSky, step;

/// A random whose next coin flips and picks a test can script; everything
/// else, and anything unscripted, comes from a seeded random.
class RiggedRandom implements Random {
  RiggedRandom(int seed) : _inner = Random(seed);
  final Random _inner;
  final bools = <bool>[], ints = <int>[];

  @override
  bool nextBool() => bools.isEmpty ? _inner.nextBool() : bools.removeAt(0);
  @override
  int nextInt(int max) => ints.isEmpty ? _inner.nextInt(max) : ints.removeAt(0);
  @override
  double nextDouble() => _inner.nextDouble();

  /// The next box rolls [prize].
  void rig(BoxPrize prize) {
    bools.add(prize.attack);
    ints.add(prize.index % 3);
  }
}

/// A duel past its countdown with an empty sky, so a test chooses what the
/// birds meet.
FlightSimulation duel({RiggedRandom? random}) {
  final sim = FlightSimulation(
    rules: TapFlyMode(),
    practice: false,
    course: FlightCourse.starTrail,
    coop: CoopMode.duel,
    random: random ?? RiggedRandom(9),
  );
  step(sim, 3);
  clearDuel(sim);
  return sim;
}

void clearDuel(FlightSimulation sim) {
  clearSky(sim);
  sim.boxes.clear();
  sim.swarm.clear();
  sim.meteors.clear();
  sim.enemyAmmo.clear();
  sim.rocks.clear();
}

/// Holds both birds still at [heights], in their column.
void hold(FlightSimulation sim, List<double> heights) {
  for (final (player, bird) in sim.flock.indexed) {
    bird
      ..y = heights[player]
      ..velocity = 0
      ..x = bird.homeX
      ..vx = 0;
  }
}

/// Steps [seconds], holding both birds at [heights] all the while, in an
/// empty sky but for what the test put there.
void hover(FlightSimulation sim, double seconds, List<double> heights) {
  for (var i = 0; i < (seconds / .02).round(); i++) {
    clearCourse(sim);
    hold(sim, heights);
    step(sim, .02);
  }
}

/// Takes away the passages, their stars and boxes, which keep coming.
void clearCourse(FlightSimulation sim) {
  sim.obstacles.clear();
  sim.stars.clear();
  sim.starTrios.clear();
  // A test's own boxes start their bob at 0.
  sim.boxes.removeWhere((box) => box.phase != 0);
}

/// Opens a box in front of [player]'s bird and returns it.
MysteryBox openFor(FlightSimulation sim, int player, BoxPrize prize) {
  clearCourse(sim);
  (sim.random as RiggedRandom).rig(prize);
  final bird = sim.flock[player];
  final box = MysteryBox(x: bird.x + .01, y: bird.y, phase: 0);
  sim.boxes.add(box);
  step(sim, .02);
  expect(box.opened, isTrue);
  expect(box.opener, player);
  expect(box.prize, prize);
  return box;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('a duel', () {
    test('flies two rivals in one column on a Star Trail', () {
      expect(
        () => FlightSimulation(
          rules: TapFlyMode(),
          practice: false,
          course: FlightCourse.classic,
          coop: CoopMode.duel,
        ),
        throwsArgumentError,
      );
      final sim = FlightSimulation(
        rules: TapFlyMode(),
        practice: false,
        course: FlightCourse.starTrail,
        coop: CoopMode.duel,
        random: Random(1),
      );
      expect(sim.duel, isTrue);
      expect(sim.paired, isTrue);
      expect(sim.roped, isFalse);
      expect(sim.plan, isA<DuelPlan>());
      expect(sim.supportsMagnet, isFalse);
      expect(
        [for (final b in sim.flock) b.homeX],
        [FlightSimulation.birdX, FlightSimulation.birdX],
      );
      expect([for (final b in sim.flock) b.y], Duel.startHeights);
      for (final bird in sim.flock) {
        expect(bird.hearts, 3);
        expect(bird.shield, isTrue);
      }
      expect(CoopMode.duel.team, isFalse);
      expect(CoopMode.free.team, isTrue);
    });

    test('each bird has its own hearts, shield and recovery', () {
      final sim = duel();
      final [one, two] = sim.flock;
      // Player 2 dives into the ground: its shield takes the first hit.
      two.y = 1;
      step(sim, .02);
      expect(two.shield, isFalse);
      expect(one.shield, isTrue);
      expect(sim.viewing(two, () => sim.recoveryRemaining), greaterThan(0));
      expect(sim.viewing(one, () => sim.recoveryRemaining), 0);
      hover(sim, 1.6, [.3, .7]);
      two.y = 1;
      step(sim, .02);
      expect((one.hearts, two.hearts), (3, 2));
      expect(sim.viewing(two, () => sim.hearts), 2);
      expect(sim.phase, RunPhase.playing);
    });

    test('a wall hurts each bird that touches it', () {
      final sim = duel();
      final [one, two] = sim.flock;
      for (final bird in sim.flock) {
        bird.shield = false;
      }
      // A wall with its gap far above both birds.
      sim.obstacles.add(
        Obstacle(
          x: FlightSimulation.birdX - .02,
          center: .15,
          gap: .1,
          target: .15,
          width: .1,
        ),
      );
      for (var i = 0; i < 5; i++) {
        hold(sim, [.5, .62]);
        step(sim, .02);
      }
      expect((one.hearts, two.hearts), (2, 2));
    });

    test('boxes ride every other passage off its star line; '
        'nothing else attacks', () {
      final sim = FlightSimulation(
        rules: TapFlyMode(),
        practice: false,
        course: FlightCourse.starTrail,
        coop: CoopMode.duel,
        random: Random(3),
      );
      var laid = 0;
      for (var i = 0; i < 90 * 50 && sim.phase != RunPhase.ended; i++) {
        // Both birds hover safely out of the way of every box.
        for (final bird in sim.flock) {
          bird
            ..invulnerableUntil = double.infinity
            ..velocity = 0
            ..y = bird == sim.lead ? .05 : .95;
        }
        final before = sim.boxes.length;
        step(sim, .02);
        if (sim.boxes.length > before) {
          laid++;
          final box = sim.boxes.last;
          final passage = sim.obstacles.last;
          expect(box.x, closeTo(passage.x - Duel.boxLead, .05));
          expect(
            (box.y - passage.baseCenter).abs(),
            greaterThanOrEqualTo(Duel.boxOffset - 1e-9),
          );
          expect(box.y, inInclusiveRange(Duel.boxTop, Duel.boxBottom));
        }
        expect(sim.boss, isNull);
        expect(sim.rushPath, isNull);
        expect(sim.gale, isNull);
        expect(sim.enemies.where((e) => e.sender == null), isEmpty);
        expect(sim.heartPickups, isEmpty);
      }
      expect(sim.elapsed, greaterThan(80));
      expect(laid, greaterThan(15));
      expect(sim.boxesOpened, 0);
    });

    test('flying into a box opens it for that bird', () {
      final sim = duel();
      sim.flock[1].shield = false;
      final box = openFor(sim, 1, BoxPrize.shield);
      expect(sim.flock[1].shield, isTrue);
      expect(sim.flock[1].boxesOpened, 1);
      expect(sim.flock[0].boxesOpened, 0);
      // It bursts for a moment, then goes.
      hover(sim, MysteryBox.burstSeconds + .1, [.3, .7]);
      expect(sim.boxes, isNot(contains(box)));
    });

    test('a rock opens a box for its thrower', () {
      final sim = duel(random: RiggedRandom(2)..rig(BoxPrize.heart));
      hold(sim, [.3, .7]);
      final box = MysteryBox(x: 1.2, y: .7, phase: 0);
      sim.boxes.add(box);
      expect(sim.shoot(player: 1), isTrue);
      expect(sim.rocks.single.owner, 1);
      hover(sim, .6, [.3, .7]);
      expect(box.opener, 1);
      expect(box.prize, BoxPrize.heart);
      expect(sim.flock[1].hearts, 4);
      expect(sim.rocks, isEmpty);
    });

    test('a heart heals up to five and a shield takes the next hit', () {
      final sim = duel();
      final one = sim.lead;
      one
        ..hearts = 4
        ..shield = false;
      openFor(sim, 0, BoxPrize.heart);
      expect(one.hearts, 5);
      openFor(sim, 0, BoxPrize.shield);
      expect(one.shield, isTrue);
    });

    test('a bat swarm flies at the rival and through its sender', () {
      final sim = duel();
      final [one, two] = sim.flock;
      hold(sim, [.3, .7]);
      openFor(sim, 0, BoxPrize.batSwarm);
      expect(sim.swarm, hasLength(Duel.swarmSize));
      for (final bat in sim.swarm) {
        expect(bat.sender, 0);
        expect(bat.height, closeTo(.7, .01));
      }
      hover(sim, 4, [.3, .7]);
      expect(two.shield, isFalse, reason: 'the swarm caught player 2');
      expect(one.hitsLanded, 1);

      // A swarm player 2 sends flies straight through player 2.
      hover(sim, 1.6, [.3, .7]);
      openFor(sim, 1, BoxPrize.batSwarm);
      final bats = [...sim.swarm.where((b) => b.sender == 1)];
      expect(bats, hasLength(Duel.swarmSize));
      for (final bat in bats) {
        expect(bat.height, closeTo(.3, .01));
      }
      // Player 1 slips up out of the way; player 2 flies at the bats.
      hover(sim, 4, [.12, .3]);
      expect(two.hearts, 3);
      expect(one.shield, isTrue);
      expect(sim.swarmSmashed, 0);
    });

    test('a rival rock smashes a sent bat, its sender\'s does not', () {
      final sim = duel();
      hold(sim, [.3, .7]);
      openFor(sim, 0, BoxPrize.batSwarm);
      // Player 1 flies at the bats' height, in front of player 2.
      hold(sim, [.55, .7]);
      expect(sim.shoot(player: 0), isTrue);
      hover(sim, 1, [.55, .7]);
      expect(sim.swarmSmashed, 0);
      hover(sim, .3, [.3, .7]);
      expect(sim.shoot(player: 1), isTrue);
      hover(sim, .5, [.3, .7]);
      expect(sim.swarmSmashed, 1);
    });

    test('a sent spitter spits only at the rival', () {
      final sim = duel();
      final [one, two] = sim.flock;
      hold(sim, [.25, .7]);
      openFor(sim, 1, BoxPrize.spitter);
      final spitter = sim.enemies.single;
      expect(spitter.sender, 1);
      expect(spitter.kind, EnemyKind.spitterBeetle);
      expect(spitter.drift, Duel.spitterDrift);
      for (var i = 0; i < 6 * 50; i++) {
        clearCourse(sim);
        hold(sim, [.25, .7]);
        step(sim, .02);
        for (final ammo in sim.enemyAmmo) {
          expect(ammo.sender, 1);
          // Every pellet is aimed at player 1, never at player 2.
          final atColumn = ammo.y + ammo.vy * (one.x - ammo.x) / ammo.vx;
          expect(atColumn, closeTo(.25, .05));
        }
      }
      expect(sim.enemyShots, greaterThan(1));
      expect(one.shield, isFalse);
      expect(two.hitsLanded, greaterThanOrEqualTo(1));
      expect((two.hearts, two.shield), (3, true));
    });

    test('a meteor shower drops its meteors on the rival', () {
      final sim = duel();
      hold(sim, [.3, .7]);
      openFor(sim, 0, BoxPrize.meteorShower);
      var dropped = 0;
      for (var i = 0; i < 3 * 50; i++) {
        final before = sim.meteors.length;
        hold(sim, [.3, .7]);
        step(sim, .02);
        if (sim.meteors.length > before) dropped++;
      }
      expect(dropped, Duel.showerMeteors);
      expect(sim.meteorShowers, isEmpty);
      expect(sim.flock[1].shield, isFalse);
      expect(sim.flock[0].shield, isTrue);
      expect(sim.flock[0].hitsLanded, greaterThanOrEqualTo(1));
    });

    test('star power shields its bird, rams, and hurts the rival it '
        'touches', () {
      final sim = duel();
      final [one, two] = sim.flock;
      hold(sim, [.3, .7]);
      openFor(sim, 0, BoxPrize.starPower);
      expect(sim.viewing(one, () => sim.starPowered), isTrue);
      expect(sim.viewing(two, () => sim.starPowered), isFalse);
      expect(sim.viewing(one, () => sim.ramming), isTrue);
      // Nothing hurts it: not even the ground.
      one.y = 1;
      step(sim, .02);
      expect((one.hearts, one.shield), (3, true));
      // Flying into its rival hurts the rival.
      hold(sim, [.5, .5 + Tether.contact]);
      step(sim, .02);
      expect(two.shield, isFalse);
      expect(one.hitsLanded, 1);
      hover(sim, Duel.starPowerSeconds, [.3, .7]);
      expect(sim.viewing(one, () => sim.starPowered), isFalse);
    });

    test('a rock hurts the rival only when it flies into it', () {
      final sim = duel();
      final [one, two] = sim.flock;
      // Level in the column, neither can hit the other.
      hold(sim, [.45, .55]);
      expect(sim.shoot(player: 0), isTrue);
      expect(sim.shoot(player: 1), isTrue);
      hover(sim, .8, [.45, .55]);
      expect(sim.rivalStrikes, 0);
      // Player 2 surges ahead at player 1's height: player 1 hits it.
      for (var i = 0; i < 40; i++) {
        one
          ..y = .5
          ..velocity = 0;
        two
          ..x = FlightSimulation.birdX + .35
          ..vx = 0
          ..y = .5
          ..velocity = 0;
        if (i == 0) expect(sim.shoot(player: 0), isTrue);
        step(sim, .02);
      }
      expect(sim.rivalStrikes, 1);
      expect(two.shield, isFalse);
      expect(one.hitsLanded, 1);
    });

    test('the first bird down loses', () {
      final sim = duel();
      final two = sim.flock[1];
      two
        ..hearts = 1
        ..shield = false
        ..y = 1;
      step(sim, .02);
      expect(sim.phase, RunPhase.ended);
      expect(sim.endReason, EndReason.collision);
      expect(two.downAt, isNotNull);
      expect(sim.duelWinner, 0);
    });

    test('two birds down on the same step draw', () {
      final sim = duel();
      for (final bird in sim.flock) {
        bird
          ..hearts = 1
          ..shield = false;
      }
      sim.lead.y = 0;
      sim.flock[1].y = 1;
      step(sim, .02);
      expect(sim.phase, RunPhase.ended);
      expect(sim.duelWinner, isNull);
      expect(sim.flock.every((b) => b.downAt != null), isTrue);
    });

    test('a bird\'s own stars charge its own shield', () {
      final sim = duel();
      final [one, two] = sim.flock;
      one.shield = two.shield = false;
      for (var i = 0; i < 9; i++) {
        sim.stars.add(SkyStar(x: one.x + .03, y: .3));
        for (var k = 0; k < 5; k++) {
          hold(sim, [.3, .7]);
          step(sim, .02);
        }
      }
      expect(one.stars, 9);
      expect(one.shield, isTrue);
      expect(two.shield, isFalse);
      expect(sim.viewing(one, () => sim.shieldCharge), 0);
    });

    test('a box never holds a help its bird cannot use', () {
      final random = Random(11);
      final seen = <BoxPrize>{};
      for (var i = 0; i < 400; i++) {
        final hearts = 1 + random.nextInt(5);
        final shield = random.nextBool();
        final prize = Duel.roll(random, hearts: hearts, shield: shield);
        seen.add(prize);
        if (prize == BoxPrize.heart) expect(hearts, lessThan(Duel.maxHearts));
        if (prize == BoxPrize.shield) expect(shield, isFalse);
      }
      expect(seen, BoxPrize.values.toSet());
    });
  });

  test('a duel replays exactly from its JSON', () {
    final tape = ReplayTape(
      mode: PlayMode.touch,
      course: FlightCourse.starTrail,
      practice: false,
      seed: 31,
      cycleSeconds: 3,
      bird: 0,
      partner: 1,
      coop: CoopMode.duel,
      reducedMotion: false,
      originMs: 0,
    );
    var now = 0.0;
    final recorder = FlightRecorder(tape, () => now);
    final sim = recorder.simulation;
    final random = Random(8);
    for (var i = 0; i < 60 * 50 && sim.phase != RunPhase.ended; i++) {
      now += 20;
      if (sim.phase == RunPhase.playing) {
        for (final (player, bird) in sim.flock.indexed) {
          // Each bird chases the next box, or else its passage's gap.
          final box = sim.boxes.where((b) => !b.opened).firstOrNull;
          final passage = sim.obstacles
              .where((o) => o.x + o.width > bird.x)
              .firstOrNull;
          final goal = box?.y ?? passage?.target ?? .5;
          if (bird.y > goal + .03 && random.nextDouble() < .4) {
            recorder.command('flap', null, player);
          }
          if (random.nextDouble() < .04) {
            recorder.command('shoot', null, player);
          }
          if (random.nextDouble() < .01) {
            recorder.command('sprint', null, player);
          }
        }
      }
      recorder.apply(
        const MovementInput(valid: true),
        TrackingSample(
          mode: PlayMode.touch,
          timestampMs: now,
          receivedMs: now,
          joints: const [],
        ),
        now,
      );
      recorder.tick(.02, now, 2.2);
    }
    expect(sim.boxesOpened, greaterThan(0));
    final json = jsonDecode(jsonEncode(tape.toJson())) as Map<String, dynamic>;
    expect(json['coop'], 'duel');
    final loaded = ReplayTape.fromJson(json);
    expect(loaded.coop, CoopMode.duel);
    final replayed = (ReplayPlayer(loaded)..seek(loaded.durationMs)).simulation;
    expect(replayed.duel, isTrue);
    expect(replayed.elapsed, sim.elapsed);
    expect(replayed.boxesOpened, sim.boxesOpened);
    expect(replayed.phase, sim.phase);
    expect(replayed.duelWinner, sim.duelWinner);
    for (final (player, bird) in sim.flock.indexed) {
      final twin = replayed.flock[player];
      expect(twin.y, bird.y);
      expect(twin.hearts, bird.hearts);
      expect(twin.shield, bird.shield);
      expect(twin.boxesOpened, bird.boxesOpened);
      expect(twin.hitsLanded, bird.hitsLanded);
    }
  });
}
