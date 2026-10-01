import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';

import 'campaign_flight.dart' show flyLevel, obstacleSignature;
import 'ny_arena.dart';

/// The Alley Pigeon's rules (spec `reports/02-alley-pigeon.md` section 2):
/// formations and star binding, the telegraph, the dive, the snatch, the
/// gloat and flight, the hits that spook, free and kill, rams and touches,
/// the edge cases, and the economy. Replay and seek are in
/// `alley_pigeon_replay_test`, the star economy in
/// `alley_pigeon_economy_test`.

SkyEnemy firstRaider(FlightSimulation sim) => raiders(sim).first;

/// A rock fired straight into [target] that does [damage].
void shootAt(FlightSimulation sim, SkyEnemy target, {int damage = 10}) {
  sim.rocks.add(BirdRock(x: target.x - .03, y: target.y, damage: damage));
}

/// Runs a fresh single-pigeon level until its first pigeon is in [phase].
({FlightSimulation sim, SkyEnemy pigeon, SkyStar prey}) until(
  PigeonPhase phase, {
  double width = 2.2,
  LevelPlan? plan,
}) {
  final sim = arenaOf(plan ?? rulesPlan());
  runUntil(
    sim,
    (s) => raiders(s).isNotEmpty && firstRaider(s).pigeon!.phase == phase,
    width: width,
    holdY: .5,
    immortal: true,
  );
  final pigeon = firstRaider(sim);
  return (
    sim: sim,
    pigeon: pigeon,
    prey: pigeon.pigeon!.loot ?? pigeon.pigeon!.prey!,
  );
}

void main() {
  group('formations', () {
    test('one, two or three pigeons hover over stars of the passage trio', () {
      for (final size in [1, 2, 3]) {
        final plan = rulesPlan(flocks: [size]);
        final sim = arenaOf(plan);
        runUntil(sim, (s) => raiders(s).isNotEmpty, holdY: .5, immortal: true);
        final birds = raiders(sim);
        expect(birds, hasLength(size), reason: 'flock of $size');
        final trio = sim.stars.take(3).toList();
        final lane = sim.obstacles.last.baseCenter;
        final side = AlleyPigeon.sideFor(lane);
        final draw = switch (size) {
          1 => plan.flockRandom(0, math.Random(0)).nextInt(3),
          2 => plan.flockRandom(0, math.Random(0)).nextInt(2),
          _ => 0,
        };
        final slots = AlleyPigeon.preySlots(size, draw);
        for (final (j, bird) in birds.indexed) {
          final raid = bird.pigeon!;
          expect(raid.laid, isTrue);
          expect(raid.slot, j);
          expect(raid.flockSize, size);
          expect(raid.side, side);
          expect(raid.phase, PigeonPhase.glide);
          // Bound at lay time: the star belongs to this pigeon.
          expect(raid.prey, same(trio[slots[j]]), reason: '$size: $j');
          expect(raid.prey!.thief, same(bird));
          // Hovering over it: x from its prey, above or below the lane.
          final hover = AlleyPigeon.hover(
            slot: j,
            preyX: raid.prey!.x,
            lane: lane,
            side: side,
          );
          expect(raid.homeX, closeTo(hover.x, 1e-9));
          expect(raid.homeY, closeTo(hover.y, 1e-9));
          expect(bird.maxHp, 20, reason: 'chapter 3: 10 + 5 x 2');
          expect(bird.attack, EnemyAttack.none);
        }
        // The other stars of the trio belong to nobody.
        for (final (i, star) in trio.indexed) {
          expect(
            star.thief != null,
            slots.contains(i),
            reason: 'flock of $size, star $i',
          );
        }
        if (size == 2) {
          expect(slots[0], 0);
          expect(slots[1], anyOf(1, 2));
        }
        if (size == 3) expect(slots, [0, 1, 2]);
      }
    });

    test(
      'health is ten plus five per toughness, and a pigeon fires nothing',
      () {
        for (var toughness = 0; toughness <= 4; toughness++) {
          final sim = arenaOf(rulesPlan(toughness: toughness));
          runUntil(
            sim,
            (s) => raiders(s).isNotEmpty,
            holdY: .5,
            immortal: true,
          );
          expect(firstRaider(sim).maxHp, 10 + 5 * toughness);
        }
      },
    );

    test('a high lane hovers its flock below, a low lane above', () {
      final sides = <int>{};
      for (var seed = 3100; seed < 3130; seed++) {
        final sim = arenaOf(rulesPlan(seed: seed));
        runUntil(sim, (s) => raiders(s).isNotEmpty, holdY: .5, immortal: true);
        final lane = sim.obstacles.last.baseCenter;
        final raid = firstRaider(sim).pigeon!;
        expect(raid.side, lane >= .5 ? -1 : 1);
        // The hover keeps inside the screen.
        expect(
          raid.homeY,
          inInclusiveRange(AlleyPigeon.hoverMin, AlleyPigeon.hoverMax),
        );
        sides.add(raid.side);
      }
      expect(sides, {-1, 1});
    });

    test('a pigeon glides in from above the right edge and never pops in', () {
      for (final width in [1.6, 2.2, 2.4]) {
        final sim = arenaOf(rulesPlan(flocks: [3]));
        SkyEnemy? bird;
        var seenOnScreen = false;
        runUntil(
          sim,
          (s) {
            if (raiders(s).isEmpty) return false;
            bird = raiders(s).first;
            if (bird!.x <= width + .05) seenOnScreen = true;
            // Off screen until it has come in over the top right.
            if (!seenOnScreen) {
              expect(
                bird!.x > width + .05 || bird!.y < 0 || bird!.y > 1,
                isTrue,
                reason: 'w=$width popped in at (${bird!.x}, ${bird!.y})',
              );
            }
            return bird!.pigeon!.phase == PigeonPhase.warning;
          },
          width: width,
          holdY: .5,
          immortal: true,
        );
        expect(seenOnScreen, isTrue);
      }
    });
  });

  group('the raid', () {
    for (final width in [1.6, 1.78, 2.2, 2.4]) {
      test(
        'the timeline at width $width: warning .80 s, dive .44 s, snatch',
        () {
          final sim = arenaOf(rulesPlan());
          final times = <PigeonPhase, double>{};
          double? preyXAtWarning, enteredAt;
          SkyEnemy? bird;
          SkyStar? prey;
          runUntil(
            sim,
            (s) {
              if (raiders(s).isEmpty) return false;
              bird ??= raiders(s).first;
              final raid = bird!.pigeon!;
              prey ??= raid.prey;
              // In view: inside the right edge and below the top, as it
              // glides in from above-right.
              if (enteredAt == null && bird!.x <= width && bird!.y >= 0) {
                enteredAt = s.elapsed;
              }
              if (times[raid.phase] == null) {
                times[raid.phase] = s.elapsed;
                if (raid.phase == PigeonPhase.warning) {
                  preyXAtWarning = raid.prey!.x;
                }
              }
              return raid.phase == PigeonPhase.carry;
            },
            width: width,
            holdY: .5,
            immortal: true,
          );
          // The warning starts as the prey comes within reach and far enough.
          final reach = math.min(
            width - AlleyPigeon.warnEdge,
            AlleyPigeon.warnReach,
          );
          expect(preyXAtWarning!, lessThanOrEqualTo(reach + 1e-9));
          expect(preyXAtWarning!, greaterThan(reach - .02));
          // Its clocks.
          final warn = times[PigeonPhase.warning]!;
          final dive = times[PigeonPhase.dive]!;
          final carry = times[PigeonPhase.carry]!;
          expect(dive - warn, closeTo(AlleyPigeon.warningSeconds, .02));
          expect(carry - dive, closeTo(AlleyPigeon.diveSeconds, .02));
          expect(sim.pigeonWarnings, 1);
          expect(sim.pigeonDives, 1);
          expect(sim.starsSnatched, 1);
          // The leader is in view well before it dives: 1.4 s and more on a
          // wide phone, 1.3 s at 640 (the report's 1.4 is the wide figure),
          // and at every width the whole 0.80 s warning is in view.
          expect(
            dive - enteredAt!,
            greaterThanOrEqualTo(width >= 2.0 ? 1.4 : 1.25),
            reason: 'in view ${dive - enteredAt!} s before the dive at $width',
          );
          expect(warn - enteredAt!, greaterThan(0));
          // The snatch is well ahead of the bird: fair at every width.
          final raid = bird!.pigeon!;
          expect(raid.snatchedAt, closeTo(bird!.age, .03));
          expect(bird!.x - birdX, inInclusiveRange(.45, .95));
          expect(raid.loot, same(prey));
          expect(prey!.carried, isTrue);
          expect(prey!.collected, isFalse);
        },
      );
    }

    test('a screen narrower than 1.6 gives no dive at all', () {
      final sim = arenaOf(rulesPlan());
      SkyEnemy? bird;
      runUntil(
        sim,
        (s) {
          if (raiders(s).isNotEmpty) bird ??= raiders(s).first;
          // Until the flock has gone by.
          return bird != null && !s.enemies.contains(bird);
        },
        width: 1.5,
        holdY: .5,
        immortal: true,
      );
      expect(sim.pigeonWarnings, 0);
      expect(sim.pigeonDives, 0);
      expect(sim.starsSnatched, 0);
    });

    test('the telegraph is 0.80 s and drives the pigeon\'s charge', () {
      final (:sim, :pigeon, :prey) = until(PigeonPhase.warning);
      final raid = pigeon.pigeon!;
      expect(pigeon.charge, lessThan(.1));
      final start = pigeon.age;
      while (raid.phase == PigeonPhase.warning) {
        final before = pigeon.charge;
        frame(sim);
        sim.birdY = .5;
        sim.velocity = 0;
        sim.invulnerableUntil = 1e9;
        if (raid.phase == PigeonPhase.warning) {
          expect(pigeon.charge, greaterThanOrEqualTo(before));
        }
      }
      expect(pigeon.age - start, closeTo(.8, .02));
      expect(raid.facingRight, isTrue);
      expect(raid.phase, PigeonPhase.dive);
      expect(pigeon.charge, 0, reason: 'the dive is not a telegraph');
    });

    test('the dive is a quarter ellipse that ends on the live star', () {
      final (:sim, :pigeon, :prey) = until(PigeonPhase.dive);
      final raid = pigeon.pigeon!;
      final home = (x: raid.homeX, y: raid.homeY);
      var lastGap = double.infinity;
      while (raid.phase == PigeonPhase.dive) {
        final u = raid.dive(pigeon.age);
        final at = AlleyPigeon.dive(
          u,
          (x: raid.homeX, y: raid.homeY),
          (x: prey.x, y: prey.y),
        );
        // The drawn position is on the path (plus a small flight bob).
        expect((pigeon.x - at.x).abs(), lessThan(.05));
        final gap = math.sqrt(
          math.pow(pigeon.x - prey.x, 2) + math.pow(pigeon.y - prey.y, 2),
        );
        expect(
          gap,
          lessThan(lastGap + .02),
          reason: 'it closes in on the star',
        );
        lastGap = gap;
        frame(sim);
        sim.birdY = .5;
        sim.velocity = 0;
        sim.invulnerableUntil = 1e9;
      }
      expect(raid.phase, PigeonPhase.carry);
      expect(pigeon.x, closeTo(prey.x, .02), reason: 'at the star\'s centre');
      expect(home.x, greaterThan(pigeon.x - .5));
    });

    test('the snatch: the star rides on the thief and cannot be collected', () {
      final (:sim, :pigeon, :prey) = until(PigeonPhase.carry);
      final raid = pigeon.pigeon!;
      expect(raid.carrying, isTrue);
      expect(raid.loot, same(prey));
      expect(prey.carried, isTrue);
      expect(sim.stars, contains(prey), reason: 'the star stays in the list');
      expect(sim.starsSnatched, 1);
      expect(pigeon.recoil, greaterThan(.5), reason: 'the beak kicks');
      expect(raid.kick(pigeon.age), greaterThan(.5));
      // It follows the thief.
      for (var i = 0; i < 30; i++) {
        frame(sim);
        sim.birdY = .5;
        sim.velocity = 0;
        sim.invulnerableUntil = 1e9;
        expect(prey.x, closeTo(pigeon.x, 1e-9));
        expect(prey.y, closeTo(pigeon.y, 1e-9));
      }
      // Even in the bird's own beak it is out of reach.
      final stars = sim.collectedStars;
      prey.x = birdX;
      sim.birdY = prey.y;
      frame(sim);
      expect(prey.collected, isFalse);
      expect(sim.collectedStars, stars);
      // A thief is no hazard: flying at it costs a shield, nothing else.
      expect(sim.hearts, 3);
    });

    test(
      'a thief that gets away takes the star for good and forfeits its trio',
      () {
        final (:sim, :pigeon, :prey) = until(PigeonPhase.carry);
        final trio = prey.trio!;
        final snatched = sim.elapsed;
        sim
          ..combo = 7
          ..bestCombo = 7;
        final score = sim.score, hearts = sim.hearts, shield = sim.shield;
        runUntil(
          sim,
          (s) => !s.enemies.contains(pigeon),
          holdY: .5,
          immortal: true,
        );
        // About two seconds after the snatch, and nothing else happened.
        expect(sim.elapsed - snatched, inInclusiveRange(1.9, 2.6));
        expect(sim.starsLost, 1);
        expect(prey.carried, isFalse);
        expect(prey.missed, isTrue);
        expect(trio.missed, isTrue);
        expect(sim.stars, isNot(contains(prey)));
        expect(pigeon.pigeon!.loot, isNull);
        expect(sim.combo, 7, reason: 'a theft never resets the streak');
        expect(sim.score, score);
        expect((sim.hearts, sim.shield), (hearts, shield));
        expect(sim.pigeonsDefeated, 0);
        expect(sim.starsFreed, 0);
      },
    );

    test('a thief never hurts the bird: thefts are not damage', () {
      final sim = arenaOf(rulesPlan(flocks: [3]));
      // No immortality: a hover-held bird must lose nothing to the pigeons.
      runUntil(sim, (s) => s.starsSnatched >= 1, holdY: .5, seconds: 40);
      expect(sim.shield, isTrue);
      expect(sim.hearts, 3);
    });
  });

  group('hits', () {
    for (final phase in [
      PigeonPhase.glide,
      PigeonPhase.warning,
      PigeonPhase.dive,
    ]) {
      test(
        'a hit in the ${phase.name} spooks the pigeon; the star is untouched',
        () {
          final (:sim, :pigeon, :prey) = until(phase);
          final raid = pigeon.pigeon!;
          shootAt(sim, pigeon);
          frame(sim);
          sim.birdY = .5;
          sim.velocity = 0;
          sim.invulnerableUntil = 1e9;
          expect(pigeon.hp, 10);
          expect(raid.spooked, isTrue);
          expect(raid.phase, PigeonPhase.flee);
          expect(raid.prey, isNull);
          expect(prey.thief, isNull);
          expect(prey.carried, isFalse);
          expect(sim.starsSnatched, 0);
          // It leaves from where it is, and the star goes on as a normal star.
          runUntil(
            sim,
            (s) => !s.enemies.contains(pigeon),
            holdY: .5,
            immortal: true,
          );
          expect(sim.starsSnatched, 0);
          expect(sim.starsLost, 0);
          expect(prey.missed, isFalse);
          expect(sim.stars, contains(prey));
          expect(sim.pigeonsDefeated, 0);
        },
      );
    }

    test(
      'a hit on a thief frees the star, which floats back to its gate line',
      () {
        final (:sim, :pigeon, :prey) = until(PigeonPhase.carry);
        final raid = pigeon.pigeon!;
        for (var i = 0; i < 20; i++) {
          frame(sim);
          sim.birdY = .5;
          sim.velocity = 0;
          sim.invulnerableUntil = 1e9;
        }
        final fleeAt = raid.phaseAt, y0 = prey.y;
        shootAt(sim, pigeon);
        frame(sim);
        expect(pigeon.hp, 10);
        expect(sim.enemies, contains(pigeon), reason: 'one hit does not kill');
        expect(raid.phase, PigeonPhase.flee);
        expect(raid.phaseAt, fleeAt, reason: 'the climb away carries on');
        expect(raid.loot, isNull);
        expect(prey.carried, isFalse);
        expect(prey.rescued, isTrue);
        expect(prey.freedAt, isNotNull);
        expect(prey.thief, isNull);
        expect(sim.starsFreed, 1);
        expect(sim.starsLost, 0);
        expect(prey.y, closeTo(y0, .05), reason: 'it appears at the pigeon');
        // It hops, then floats back to the line of its gate, staying with the
        // scenery.
        final world = prey.x + sim.distance;
        var highest = prey.y;
        for (var i = 0; i < 120; i++) {
          frame(sim);
          sim.birdY = .5;
          sim.velocity = 0;
          sim.invulnerableUntil = 1e9;
          highest = math.min(highest, prey.y);
        }
        expect(prey.x + sim.distance, closeTo(world, 1e-6));
        expect(prey.y, closeTo(prey.gateY, .02));
        expect(highest, lessThan(y0 - .01), reason: 'the hop');
        expect(prey.collected, isFalse);
        expect(sim.stars, contains(prey));
      },
    );

    test('a freed star can be caught: a streak star and a trio star again', () {
      final (:sim, :pigeon, :prey) = until(PigeonPhase.carry);
      shootAt(sim, pigeon);
      frame(sim);
      expect(prey.rescued, isTrue);
      final combo = sim.combo, stars = sim.collectedStars;
      // Catch it: hold the bird at its gate line as it arrives.
      runUntil(
        sim,
        (s) => prey.collected || prey.missed,
        holdY: prey.gateY,
        immortal: true,
      );
      expect(prey.collected, isTrue);
      expect(sim.collectedStars, stars + 1);
      expect(sim.combo, greaterThan(combo - 1));
    });

    test('a freed star the bird misses does not reset the streak', () {
      final (:sim, :pigeon, :prey) = until(PigeonPhase.carry);
      shootAt(sim, pigeon);
      frame(sim);
      expect(prey.rescued, isTrue);
      // Only this star can be missed: the rest of the passage is taken.
      for (final star in sim.stars) {
        if (star != prey) star.collected = true;
      }
      sim
        ..combo = 5
        ..bestCombo = 5;
      runUntil(
        sim,
        (s) => prey.missed,
        holdY: math.min(.9, prey.gateY + .35),
        immortal: true,
      );
      expect(sim.combo, 5);
      // The same star, had the course laid it, would have cost the streak.
    });

    test(
      'a star the course laid that the bird misses still resets the streak',
      () {
        final sim = arenaOf(rulesPlan(lineup: const [EnemyKind.simpleBat]));
        runUntil(sim, (s) => s.stars.isNotEmpty, holdY: .5, immortal: true);
        sim.combo = 5;
        final star = sim.stars.first;
        runUntil(
          sim,
          (s) => star.missed || star.collected,
          holdY: math.min(.9, star.gateY + .35),
          immortal: true,
        );
        expect(star.missed, isTrue);
        expect(sim.combo, 0);
      },
    );

    test('the kill: two base shots, +3, and the star is won back too', () {
      final (:sim, :pigeon, :prey) = until(PigeonPhase.carry);
      final score = sim.score;
      shootAt(sim, pigeon);
      frame(sim);
      expect(sim.enemies, contains(pigeon));
      expect(sim.starsFreed, 1);
      shootAt(sim, pigeon);
      frame(sim);
      expect(pigeon.hp, 0);
      expect(sim.enemies, isNot(contains(pigeon)));
      expect(sim.pigeonsDefeated, 1);
      expect(sim.enemiesDefeated, 1);
      expect(sim.score, score + 3, reason: 'only the usual reward');
      expect(sim.starsFreed, 1, reason: 'freed once, not twice');
      expect(prey.carried, isFalse);
      expect(
        sim.events.any(
          (e) =>
              e.kind == FlightEventKind.enemyHit &&
              e.enemyKind == EnemyKind.alleyPigeon,
        ),
        isTrue,
      );
    });

    test('one charged shot kills a thief and frees its star in one blow', () {
      final (:sim, :pigeon, :prey) = until(PigeonPhase.carry);
      // A third of a charge doubles a base shot: 20 damage, a pigeon's health.
      shootAt(sim, pigeon, damage: PowerShot.damage(10, 1 / 3));
      frame(sim);
      expect(sim.enemies, isNot(contains(pigeon)));
      expect(sim.pigeonsDefeated, 1);
      expect(sim.starsFreed, 1);
      expect(prey.carried, isFalse);
      expect(prey.rescued, isTrue);
      expect(prey.freedAt, isNotNull);
    });

    test('a shatter blast spooks a hunting pigeon like a rock does', () {
      final (:sim, :pigeon, :prey) = until(PigeonPhase.warning);
      // An enemy pellet a little way off, and a charged rock that breaks it:
      // the blast (half the rock's damage) reaches the pigeon.
      final pellet = EnemyAmmo(
        x: pigeon.x + .12,
        y: pigeon.y,
        vx: 0,
        vy: 0,
        attack: EnemyAttack.aimed,
      );
      sim.enemyAmmo.add(pellet);
      sim.rocks.add(
        BirdRock(x: pellet.x - .02, y: pigeon.y, damage: 10, charge: 1),
      );
      frame(sim);
      expect(sim.ammoShattered, 1);
      expect(pigeon.hp, 15);
      // The hit is seen on the pigeon's next step.
      frame(sim);
      expect(pigeon.pigeon!.spooked, isTrue);
      expect(pigeon.pigeon!.phase, PigeonPhase.flee);
      expect(sim.starsSnatched, 0);
      expect(prey.thief, isNull);
    });
  });

  group('the bird and the pigeon', () {
    test('a Sprint ram smashes a thief and the star drops into the beak', () {
      final (:sim, :pigeon, :prey) = until(PigeonPhase.carry);
      final stars = sim.collectedStars, hearts = sim.hearts;
      sim.lastSprintAt = sim.elapsed;
      pigeon.placeAt(birdX + .03, sim.birdY);
      frame(sim);
      sim.birdY = .5;
      expect(sim.enemies, isNot(contains(pigeon)));
      expect(sim.pigeonsDefeated, 1);
      expect(sim.starsFreed, 1);
      expect(
        sim.events.where((e) => e.kind == FlightEventKind.enemyRammed),
        hasLength(1),
      );
      expect(prey.carried, isFalse);
      // Collected on the next step, like any star the bird touches.
      sim.birdY = prey.y;
      frame(sim);
      expect(prey.collected, isTrue);
      expect(sim.collectedStars, stars + 1);
      expect(sim.hearts, hearts);
      expect(sim.shield, isTrue, reason: 'a ram costs nothing');
    });

    test('flying into a thief costs the shield, and the star comes home', () {
      final (:sim, :pigeon, :prey) = until(PigeonPhase.carry);
      final stars = sim.collectedStars;
      sim.invulnerableUntil = 0;
      pigeon.placeAt(birdX + .03, sim.birdY);
      frame(sim);
      expect(sim.shield, isFalse, reason: 'like any enemy: the shield first');
      expect(sim.hearts, 3);
      expect(sim.enemies, isNot(contains(pigeon)));
      expect(sim.pigeonsDefeated, 0, reason: 'flown into, not defeated');
      expect(sim.starsFreed, 1);
      expect(prey.carried, isFalse);
      sim.birdY = prey.y;
      frame(sim);
      expect(prey.collected, isTrue);
      expect(sim.collectedStars, stars + 1);
    });

    test('flying into a hunter: shield, then a heart, then recovery', () {
      final (:sim, :pigeon, :prey) = until(PigeonPhase.warning);
      sim.invulnerableUntil = 0;
      pigeon.placeAt(birdX + .03, sim.birdY);
      frame(sim);
      expect(sim.shield, isFalse);
      expect(prey.thief, isNull, reason: 'its reservation is released');
      expect(sim.starsSnatched, 0);
      // Another one during the recovery costs nothing; after it, a heart.
      final other = SkyEnemy(
        x: birdX + .03,
        y: sim.birdY,
        appearance: 4,
        maxHp: 20,
      );
      sim.enemies.add(other);
      frame(sim);
      expect(sim.hearts, 3, reason: '1.5 s of recovery');
      sim.invulnerableUntil = 0;
      sim.enemies.add(
        SkyEnemy(x: birdX + .03, y: sim.birdY, appearance: 4, maxHp: 20),
      );
      frame(sim);
      expect(sim.hearts, 2);
    });

    test(
      'a dive whiffs into a flee when its prey is collected or too close',
      () {
        for (final reason in ['collected', 'missed', 'close']) {
          final (:sim, :pigeon, :prey) = until(PigeonPhase.dive);
          switch (reason) {
            case 'collected':
              prey.collected = true;
            case 'missed':
              prey.missed = true;
            default:
              prey.x = birdX + AlleyPigeon.whiffGuard - .01;
          }
          frame(sim);
          final raid = pigeon.pigeon!;
          expect(raid.phase, PigeonPhase.flee, reason: reason);
          expect(raid.spooked, isFalse);
          expect(raid.prey, isNull);
          expect(raid.loot, isNull);
          expect(sim.starsSnatched, 0, reason: reason);
          expect(prey.carried, isFalse);
        }
      },
    );

    test('a sprint speeds the world, not the pigeon: the clocks hold', () {
      // Sprint from 0 to 1 s into the warning: the star rushes at the bird,
      // but the warning stays .80 s, the dive .44 s, and it never snatches
      // from closer than the whiff guard.
      for (final delay in [0.0, .3, .6, .8, 1.0]) {
        final (:sim, :pigeon, :prey) = until(PigeonPhase.warning);
        final raid = pigeon.pigeon!;
        final warnAt = pigeon.age;
        runUntil(
          sim,
          (s) => pigeon.age - warnAt >= delay,
          holdY: .5,
          immortal: true,
        );
        sim.lastSprintAt = sim.elapsed;
        runUntil(
          sim,
          (s) =>
              raid.phase == PigeonPhase.carry || raid.phase == PigeonPhase.flee,
          holdY: .5,
          immortal: true,
        );
        reason(String what) => '$what (sprint after $delay s)';
        expect(
          raid.phaseAt - warnAt,
          closeTo(1.24, .03),
          reason: reason('whole raid'),
        );
        if (raid.phase == PigeonPhase.carry) {
          expect(
            prey.x,
            greaterThan(birdX + AlleyPigeon.whiffGuard),
            reason: reason('snatch'),
          );
        } else {
          expect(sim.starsSnatched, 0, reason: reason('whiff'));
        }
      }
    });
  });

  group('edge cases', () {
    test('two pigeons on one star: the second is preyless', () {
      final sim = arenaOf(rulesPlan());
      runUntil(sim, (s) => raiders(s).isNotEmpty, holdY: .5, immortal: true);
      final first = firstRaider(sim);
      final star = first.pigeon!.prey!;
      final second = SkyEnemy(
        x: 2.4,
        y: .2,
        appearance: 4,
        maxHp: 20,
        flightPhase: 0,
      );
      second.pigeon!
        ..laid = true
        ..prey = star
        ..homeX = 2.4
        ..homeY = .2;
      sim.enemies.add(second);
      frame(sim);
      expect(
        second.pigeon!.prey,
        isNull,
        reason: 'the reservation is the first\'s',
      );
      expect(star.thief, same(first));
      // It glides on and never dives.
      runUntil(
        sim,
        (s) => !s.enemies.contains(second) || s.starsSnatched > 0,
        holdY: .5,
        immortal: true,
      );
      expect(
        second.pigeon!.phase == PigeonPhase.glide ||
            !sim.enemies.contains(second),
        isTrue,
      );
    });

    test('a pigeon with no stars to take glides like a bat', () {
      final sim = arenaOf(rulesPlan(lineup: const [EnemyKind.simpleBat]));
      runUntil(sim, (s) => s.stars.isNotEmpty, holdY: .5, immortal: true);
      // A boss helper, say: nobody laid it, nothing is reserved for it.
      final helper = SkyEnemy(
        x: 2.4,
        y: .3,
        appearance: 4,
        maxHp: 20,
        flightPhase: 0.4,
      );
      sim.enemies.add(helper);
      runUntil(
        sim,
        (s) => !s.enemies.contains(helper),
        holdY: .9,
        immortal: true,
      );
      expect(helper.pigeon!.phase, PigeonPhase.glide);
      expect(sim.pigeonWarnings, 0);
      expect(sim.starsSnatched, 0);
      expect(sim.stars.where((s) => s.carried || s.thief != null), isEmpty);
    });

    test('a level whose stars are all gone leaves its pigeons preyless', () {
      final sim = arenaOf(rulesPlan());
      runUntil(sim, (s) => raiders(s).isNotEmpty, holdY: .5, immortal: true);
      final bird = firstRaider(sim);
      // The star it was bound to is collected before it can warn.
      bird.pigeon!.prey!.collected = true;
      runUntil(
        sim,
        (s) => !s.enemies.contains(bird),
        holdY: .9,
        immortal: true,
      );
      expect(sim.pigeonWarnings, 0);
      expect(bird.pigeon!.prey, isNull);
      expect(sim.starsSnatched, 0);
    });

    test('King Coo\'s squadron pigeons are gliders: they never snatch', () {
      final sim = arenaOf(rulesPlan(lineup: const [EnemyKind.simpleBat]));
      runUntil(sim, (s) => s.stars.length >= 3, holdY: .5, immortal: true);
      final squad = SkyEnemy(
        x: 1.5,
        y: .4,
        appearance: 4,
        maxHp: 20,
        flightPhase: .7,
        squad: true,
      );
      expect(squad.pigeon, isNull);
      sim.enemies.add(squad);
      for (var i = 0; i < 180; i++) {
        frame(sim);
        sim.birdY = .9;
        sim.velocity = 0;
        sim.invulnerableUntil = 1e9;
        if (!sim.enemies.contains(squad)) break;
      }
      expect(sim.pigeonWarnings + sim.pigeonDives + sim.starsSnatched, 0);
      expect(sim.stars.where((s) => s.carried || s.thief != null), isEmpty);
      // Shooting one is an ordinary pigeon defeat (the audio's cue).
      final another = SkyEnemy(
        x: 1.6,
        y: .3,
        appearance: 4,
        maxHp: 10,
        squad: true,
      );
      sim.enemies.add(another);
      shootAt(sim, another);
      frame(sim);
      expect(sim.enemies, isNot(contains(another)));
      expect(sim.pigeonsDefeated, 1);
    });

    test('a boss arrival clears pigeons and stars with nothing left behind', () {
      final plan = rulesPlan(
        boss: BossKind.baronBat,
        lineup: const [EnemyKind.alleyPigeon],
        length: 20,
      );
      final sim = arenaOf(plan);
      runUntil(
        sim,
        (s) => s.boss != null,
        holdY: .5,
        immortal: true,
        seconds: 60,
      );
      expect(sim.boss!.kind, BossKind.baronBat);
      expect(raiders(sim), isEmpty);
      expect(sim.stars.where((s) => s.carried || s.thief != null), isEmpty);
      // Whatever the Baron calls from the lineup is a bat that steals nothing.
      final before = sim.starsSnatched;
      runUntil(
        sim,
        (s) => s.enemies.any((e) => e.kind == EnemyKind.alleyPigeon),
        holdY: .5,
        immortal: true,
        seconds: 30,
      );
      final helper = sim.enemies.firstWhere(
        (e) => e.kind == EnemyKind.alleyPigeon,
      );
      expect(helper.pigeon!.laid, isFalse);
      for (var i = 0; i < 120; i++) {
        frame(sim);
        sim.birdY = .5;
        sim.velocity = 0;
        sim.invulnerableUntil = 1e9;
      }
      expect(sim.starsSnatched, before);
      expect(sim.pigeonWarnings, 0);
    });

    test('a level without stars to give still lays its pigeons, preyless', () {
      // Every trio star of the passage is taken before the formation's first
      // look: the pigeons glide.
      final sim = arenaOf(rulesPlan(flocks: [3]));
      runUntil(sim, (s) => raiders(s).length == 3, holdY: .5, immortal: true);
      for (final star in sim.stars) {
        star.collected = true;
      }
      runUntil(sim, (s) => raiders(s).isEmpty, holdY: .9, immortal: true);
      expect(sim.pigeonWarnings, 0);
      expect(sim.starsSnatched, 0);
    });
  });

  group('determinism and isolation', () {
    test('pigeons never draw from the shared random', () {
      Set<String> laid(LevelPlan plan) {
        final signatures = <String>{};
        final sim = arenaOf(plan);
        runUntil(
          sim,
          (s) => s.distance > 12,
          holdY: .5,
          immortal: true,
          watch: (s) {
            for (final o in s.obstacles) {
              signatures.add(obstacleSignature(s, o));
            }
          },
        );
        // The next draw of the shared random is the same too.
        signatures.add('next ${sim.random.nextInt(1 << 30)}');
        return signatures;
      }

      for (final flocks in [
        const <int>[],
        [2],
        [1, 2, 3],
      ]) {
        final withPigeons = laid(rulesPlan(flocks: flocks, panels: .25));
        final withBats = laid(
          rulesPlan(
            panels: .25,
            lineup: const [EnemyKind.simpleBat, EnemyKind.caveBat],
          ),
        );
        expect(withPigeons, withBats, reason: 'flocks $flocks');
      }
    });

    test('every width steals the same stars, only the timing differs', () {
      final stolen = <double, List<String>>{};
      for (final width in [1.78, 2.2, 2.4]) {
        final sim = arenaOf(
          rulesPlan(flocks: [3], length: 20, marks: const StarMarks(5, 6)),
        );
        final worlds = <String>[];
        final seen = <SkyStar>{};
        runUntil(
          sim,
          (s) {
            for (final e in s.enemies) {
              final loot = e.pigeon?.loot;
              if (loot != null && seen.add(loot)) {
                // Which star of which passage: slot and the passage's place.
                worlds.add('${loot.trioSlot}@${(loot.x + s.distance).round()}');
              }
            }
            return s.distance > 6;
          },
          width: width,
          holdY: .5,
          immortal: true,
        );
        stolen[width] = worlds..sort();
      }
      // Two flocks of three within the first six course units: all six
      // stars are taken at every width that is wide enough to see the dive,
      // and they are the same six.
      expect(stolen[2.2], hasLength(6));
      expect(stolen[2.4], stolen[2.2]);
      expect(stolen[1.78], stolen[2.2]);
    });

    test('a pigeon plan cannot be flown under rules 41 or 42', () {
      for (final older in [41, 42]) {
        expect(
          () => arenaOf(rulesPlan(), version: older),
          throwsArgumentError,
          reason: 'minRulesVersion 43, not $older',
        );
      }
    });

    test('raids run only where rules 43 and combat are on', () {
      final sim = arenaOf(rulesPlan());
      expect(sim.supportsAlleyPigeon, isTrue);
      expect(arenaOf(rulesPlan()).supportsSteamGeysers, isTrue);
      final endless = FlightSimulation(
        rules: TapFlyMode(),
        practice: false,
        course: FlightCourse.starTrail,
        random: math.Random(1),
      );
      expect(endless.supportsAlleyPigeon, isTrue);
      expect(
        endless.thiefBudget,
        greaterThan(1000),
        reason: 'no route, no cap',
      );
    });

    test('the shared bot flies a pigeon level to its end at every width', () {
      for (final width in [1.6, 1.78, 2.2, 2.4]) {
        final sim = arenaOf(
          rulesPlan(flocks: [1, 2, 3], length: 40),
          weaponDamage: 30,
        );
        flyLevel(sim, viewportWidth: width);
        expect(sim.endReason, EndReason.completed, reason: 'width $width');
        // Every star is accounted for: collected, missed, lost, or laid.
        expect(sim.starsLost, lessThanOrEqualTo(sim.thiefBudget));
        expect(sim.stars.where((s) => s.carried), isEmpty);
      }
    });
  });
}
