import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';

import 'campaign_flight.dart' show obstacleSignature;
import 'ny_plans.dart';

/// The Alley Pigeon's scaffold (R0): the enum value, its health and attack,
/// the raid state art and audio read (`SkyEnemy.pigeon`), the pure motion
/// functions of `AlleyPigeon`, and the plan data that lays it. The raid rules
/// themselves (phases, steals, drops) are tested in `alley_pigeon_rules_test`
/// (R1 replaced the scaffold's inert-pigeon tests there).

void main() {
  test('the Alley Pigeon is appended, campaign-only and keeps 0 to 3', () {
    expect(EnemyKind.values.map((k) => k.name), [
      'caveBat',
      'spitterBeetle',
      'duskMoth',
      'simpleBat',
      'alleyPigeon',
    ]);
    expect(EnemyKind.alleyPigeon.index, 4);
    expect(EnemyKind.values.where((k) => k.campaignOnly), [
      EnemyKind.alleyPigeon,
    ]);
    // Appearance indexes wrap over five kinds: 0 to 3 are unchanged.
    for (var i = 0; i < 4; i++) {
      expect(SkyEnemy(x: 1, y: .5, appearance: i).kind, EnemyKind.values[i]);
    }
    expect(SkyEnemy(x: 1, y: .5, appearance: 4).kind, EnemyKind.alleyPigeon);
    expect(SkyEnemy(x: 1, y: .5, appearance: 5).kind, EnemyKind.caveBat);
  });

  test(
    'a pigeon has a bat\'s health, toughened by the chapter, and no shot',
    () {
      expect(SkyEnemy.healthFor(EnemyKind.alleyPigeon.index), 10);
      // Chapter 3's toughness of two: 10 + 5 * 2.
      expect(
        SkyEnemy.healthFor(EnemyKind.alleyPigeon.index, bossesDefeated: 2),
        20,
      );
      final pigeon = SkyEnemy(x: 1, y: .5, appearance: 4, maxHp: 20);
      expect(pigeon.attack, EnemyAttack.none);
      expect(pigeon.maxHp, 20);
      // The health of every older kind is exactly as before.
      expect(SkyEnemy.healthFor(EnemyKind.simpleBat.index), 10);
      expect(SkyEnemy.healthFor(EnemyKind.caveBat.index), 10);
      expect(SkyEnemy.healthFor(EnemyKind.spitterBeetle.index), 20);
      expect(SkyEnemy.healthFor(EnemyKind.duskMoth.index), 30);
    },
  );

  test('only a star-raiding pigeon carries raid state', () {
    final raider = SkyEnemy(x: 1, y: .5, appearance: 4);
    expect(raider.snatches, isTrue);
    expect(raider.squad, isFalse);
    expect(raider.pigeon, isNotNull);
    final squad = SkyEnemy(x: 1, y: .5, appearance: 4, squad: true);
    expect(squad.snatches, isFalse);
    expect(squad.squad, isTrue);
    expect(squad.pigeon, isNull);
    expect(squad.kind, EnemyKind.alleyPigeon);
    for (final kind in EnemyKind.values.where((k) => !k.campaignOnly)) {
      final enemy = SkyEnemy(x: 1, y: .5, appearance: kind.index);
      expect(enemy.snatches, isFalse, reason: kind.name);
      expect(enemy.pigeon, isNull, reason: kind.name);
    }
  });

  test('a pigeon that is not part of a formation glides like a bat', () {
    // A pigeon nobody laid as a formation (a boss helper drawn from a
    // lineup) has no home and no prey: the raid rules leave it alone.
    final pigeon = SkyEnemy(x: 1.2, y: .4, appearance: 4, flightPhase: 1.3);
    final raid = pigeon.pigeon!;
    expect(raid.laid, isFalse);
    expect(raid.phase, PigeonPhase.glide);
    expect(raid.carrying, isFalse);
    expect(raid.hunting, isFalse);
    expect(raid.facingRight, isFalse);
    expect(raid.prey, isNull);
    expect(raid.loot, isNull);
    for (final age in [0.0, .5, 3.0]) {
      pigeon.age = age;
      expect(pigeon.charge, 0);
      expect(raid.warning(age), 0);
      expect(raid.dive(age), 0);
      expect(raid.fleeTime(age), 0);
      expect(raid.kick(age), 0);
      // The idle bob is a small pure function of the clock, like a bat's.
      expect((pigeon.y - .4).abs(), lessThanOrEqualTo(AlleyPigeon.bob));
    }
  });

  test('the raid phases are pure functions of the enemy clock', () {
    final raid = PigeonFlight(slot: 1, flockSize: 3, side: 1)
      ..phase = PigeonPhase.warning
      ..phaseAt = 2;
    expect(raid.warning(2), 0);
    expect(raid.warning(2 + AlleyPigeon.warningSeconds / 2), closeTo(.5, 1e-9));
    expect(raid.warning(2 + AlleyPigeon.warningSeconds), closeTo(1, 1e-9));
    expect(raid.warning(99), 1);
    expect(raid.dive(2.2), 0, reason: 'not diving');
    expect(raid.facingRight, isTrue);
    raid
      ..phase = PigeonPhase.dive
      ..phaseAt = 3;
    expect(raid.dive(3 + AlleyPigeon.diveSeconds / 2), closeTo(.5, 1e-9));
    expect(raid.warning(3.1), 0);
    raid
      ..phase = PigeonPhase.carry
      ..phaseAt = 4
      ..snatchedAt = 4;
    expect(raid.fleeTime(5), closeTo(1, 1e-9));
    expect(raid.kick(4), 1);
    expect(raid.kick(4.12), closeTo(.5, 1e-9));
    expect(raid.kick(4.24), 0);
    expect(raid.kick(9), 0);
    // A pigeon drives its enemy's telegraph.
    final enemy = SkyEnemy(x: 1, y: .5, appearance: 4);
    enemy.pigeon!
      ..phase = PigeonPhase.warning
      ..phaseAt = 0;
    enemy.age = AlleyPigeon.warningSeconds / 4;
    expect(enemy.charge, closeTo(.25, 1e-9));
  });

  test('formations: slots, sides, prey and the hover positions', () {
    expect(AlleyPigeon.sideFor(.6), -1, reason: 'hover above a low lane');
    expect(AlleyPigeon.sideFor(.5), -1);
    expect(AlleyPigeon.sideFor(.4), 1, reason: 'hover below a high lane');
    // One pigeon takes one of the trio, two take the first and another, three
    // take them all.
    expect(
      [for (var d = 0; d < 3; d++) AlleyPigeon.preySlots(1, d)],
      [
        [0],
        [1],
        [2],
      ],
    );
    expect(AlleyPigeon.preySlots(2, 0), [0, 1]);
    expect(AlleyPigeon.preySlots(2, 1), [0, 2]);
    expect(AlleyPigeon.preySlots(3, 0), [0, 1, 2]);
    expect(() => AlleyPigeon.preySlots(0, 0), throwsRangeError);
    expect(() => AlleyPigeon.preySlots(4, 0), throwsRangeError);
    // Hover: above the lane for side -1, x behind the prey.
    final h0 = AlleyPigeon.hover(slot: 0, preyX: 1.5, lane: .6, side: -1);
    expect(h0.x, closeTo(1.5 - .19, 1e-12));
    expect(h0.y, closeTo(.6 - .30, 1e-12));
    final h1 = AlleyPigeon.hover(slot: 1, preyX: 1.5, lane: .6, side: -1);
    expect(h1.y, closeTo(.6 - .44, 1e-12));
    // Room keeps it inside .12 to .88.
    final high = AlleyPigeon.hover(slot: 1, preyX: 1.5, lane: .4, side: 1);
    expect(high.y, closeTo(.4 + .44, 1e-12));
    final squeezed = AlleyPigeon.hover(slot: 1, preyX: 1.5, lane: .3, side: -1);
    expect(squeezed.y, closeTo(.12, 1e-12));
  });

  test('the arrival glide, the dive, the flee and the freed star', () {
    // Gliding in from above-right until the home nears the right edge.
    final far = AlleyPigeon.arrival(homeX: 3, width: 2.2, side: -1);
    expect(far.dx, closeTo(.35, 1e-12));
    expect(far.dy, closeTo(-.35, 1e-12));
    final near = AlleyPigeon.arrival(homeX: 1.9, width: 2.2, side: 1);
    expect(near.dx, 0);
    expect(near.dy, 0);
    final mid = AlleyPigeon.arrival(
      homeX: 2.2 - .30 + .225,
      width: 2.2,
      side: 1,
    );
    expect(mid.dx, closeTo(.35 * .25, 1e-12));
    expect(mid.dy, closeTo(.35 * .25, 1e-12));
    // The dive starts at its hover and ends on the star, accelerating.
    const home = (x: 1.2, y: .3), star = (x: 1.5, y: .55);
    final start = AlleyPigeon.dive(0, home, star);
    final end = AlleyPigeon.dive(1, home, star);
    expect(start.x, closeTo(home.x, 1e-12));
    expect(start.y, closeTo(home.y, 1e-12));
    expect(end.x, closeTo(star.x, 1e-12));
    expect(end.y, closeTo(star.y, 1e-12));
    var lastSpeed = 0.0, previous = start;
    for (var i = 1; i <= 20; i++) {
      final p = AlleyPigeon.dive(i / 20, home, star);
      final speed = math.sqrt(
        math.pow(p.x - previous.x, 2) + math.pow(p.y - previous.y, 2),
      );
      if (i > 1) expect(speed, greaterThan(lastSpeed * .999), reason: '$i');
      lastSpeed = speed;
      previous = p;
    }
    expect(AlleyPigeon.dive(-1, home, star).x, closeTo(home.x, 1e-12));
    expect(AlleyPigeon.dive(2, home, star).x, closeTo(star.x, 1e-12));
    // The thief drifts right, then climbs away on its side.
    expect(AlleyPigeon.flee(0, -1), (dx: 0, dy: 0));
    expect(
      AlleyPigeon.flee(.5, -1).dy,
      0,
      reason: 'the gloat stays in the lane',
    );
    expect(AlleyPigeon.flee(1.65, -1).dy, closeTo(-.30, 1e-9));
    expect(AlleyPigeon.flee(1.65, 1).dy, closeTo(.30, 1e-9));
    expect(AlleyPigeon.flee(1, 1).dx, closeTo(.70, 1e-12));
    // A freed star hops and settles on its gate line.
    expect(AlleyPigeon.floatY(0, .2, .5), closeTo(.2, 1e-12));
    expect(AlleyPigeon.floatY(5, .2, .5), closeTo(.5, 1e-3));
    expect(AlleyPigeon.floatY(.15, .5, .5), lessThan(.5), reason: 'the hop');
  });

  test('a pigeon may warn only with prey ahead and room for a fair dive', () {
    bool warns(double preyX, {double width = 2.2, double speed = .55}) =>
        AlleyPigeon.mayWarn(
          preyX: preyX,
          birdX: FlightSimulation.birdX,
          width: width,
          speed: speed,
        );
    // The bird's column is at .47: the prey must be .40 beyond it after the
    // 1.3 s lead at the course speed.
    expect(warns(1.7), isTrue);
    expect(warns(1.85), isFalse, reason: 'beyond the warn reach');
    expect(warns(FlightSimulation.birdX + .5), isFalse, reason: 'too close');
    expect(warns(1.7, width: 1.75), isFalse, reason: 'beyond the screen edge');
    // The 1.3 s lead needs more room at speed.
    expect(warns(1.4, speed: .35), isTrue);
    expect(warns(1.4, speed: .6), isFalse);
  });

  test('flocks cycle through a plan, and its random is its own', () {
    final plan = nyPlan(flocks: [1, 2, 3]);
    expect(
      [for (var i = 0; i < 7; i++) plan.flockSizeFor(i)],
      [1, 2, 3, 1, 2, 3, 1],
    );
    expect(nyPlan().flockSizeFor(5), 1);
    final shared = math.Random(1);
    // A pure seed per entry, different for each entry.
    expect(
      plan.flockRandom(2, shared).nextInt(1 << 30),
      plan.flockRandom(2, shared).nextInt(1 << 30),
    );
    expect({
      for (var i = 0; i < 6; i++) plan.flockRandom(i, shared).nextInt(1 << 30),
    }, hasLength(6));
    // The flight's shared random is never consumed by a pigeon draw.
    final flight = math.Random(9);
    plan.flockRandom(3, flight).nextInt(9);
    expect(flight.nextInt(1000), math.Random(9).nextInt(1000));
    // Endless shares the flight's random (it never lays pigeons).
    expect(
      identical(FlightPlan.endless.flockRandom(0, shared), shared),
      isTrue,
    );
    expect(nyPlan(flocks: [4]).problem, 'flocks');
    expect(nyPlan(flocks: [0]).problem, 'flocks');
  });

  test('a pigeon lineup does not move a level\'s passages', () {
    // Pigeons draw nothing from the shared random: the same seed lays the
    // same passages, openings and panels with pigeons as with bats.
    Set<String> laid(LevelPlan plan) {
      final signatures = <String>{};
      final sim = flyNy(
        plan,
        watch: (sim) {
          for (final o in sim.obstacles) {
            signatures.add(obstacleSignature(sim, o));
          }
        },
      );
      expect(sim.endReason, EndReason.completed);
      return signatures;
    }

    final withPigeons = laid(nyPlan(length: 40));
    final withBats = laid(
      nyPlan(
        length: 40,
        lineup: const [EnemyKind.simpleBat, EnemyKind.caveBat],
      ),
    );
    expect(withPigeons, isNotEmpty);
    expect(withPigeons, withBats);
  });
}
