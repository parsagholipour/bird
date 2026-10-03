import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/bird_motion.dart';
import 'package:push_up_bird/domain/campaign.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/session_replay.dart';

import 'campaign_flight.dart';
import 'gargoyle_pilot.dart' show frame;
import 'neferhoo_pilot.dart' show neferhooArena;

/// Neferhoo's rules (rules version 50, level 2-6), on the REAL simulation:
/// the mail call, return to sender, the padded wraps, the boomerang ankh,
/// the three stages with the ankh armed by stage, the hints, and a defeat
/// that clears everything. Spec: `egypt-ws/reports/01-egypt-guardian.md` §3,
/// staged by `egypt-int/MASTER-PLAN.md` §2.
///
/// Every flight here starts as he begins to fight ([neferhooArena]: 640 px
/// wide, the bird at mid-height with its shield, three hearts and a full
/// reserve) and is stepped at 60 Hz with the bird held where each test puts
/// it. Every loop is bounded and stops when the flight ends.
///
/// They fly his rules 50 fight ([v50]), which every saved 2-6 tape of rules
/// 50 replays; what rules 52 changes (twice the health, faster letters, his
/// mummy bats) is `neferhoo_tougher_rules_test.dart`, on the same arena.

const w640 = 640 / 360;

/// The rules these tests fly: Neferhoo's own version, 50.
const v50 = FlightSimulation.neferhooRulesVersion;

/// Steps [sim] at 60 Hz, the bird held at [y] (no taps), until the boss's
/// combat time reaches [until], or the flight ends, or he has gone.
/// [keepAlive] tops the hearts up.
void holdUntil(
  FlightSimulation sim,
  double until, {
  required double y,
  double width = w640,
  bool keepAlive = false,
}) {
  final boss = sim.boss!;
  for (var guard = 0; guard < 60 * 400; guard++) {
    if (boss.combatTime >= until - 1e-9 ||
        sim.phase == RunPhase.ended ||
        !identical(sim.boss, boss)) {
      return;
    }
    if (keepAlive) sim.hearts = 3;
    sim
      ..birdY = y
      ..velocity = 0;
    frame(sim, width: width);
    sim
      ..birdY = y
      ..velocity = 0;
  }
}

/// Takes [boss] to [share] of its health with one blow (the rules raise the
/// stage a step later).
void hurtTo(SkyBoss boss, double share) {
  final to = (boss.maxHp * share).floor();
  if (boss.hp > to) boss.takeDamage(boss.hp - to);
}

/// The fight's state, all of it, as text: two flights that agree here
/// agree on everything the rules latched.
String snapshot(SkyBoss boss) {
  final f = boss.neferhoo;
  return [
    'hp=${boss.hp} stage=${boss.stage}/${boss.stageReached} '
        'sig=${boss.signatureCycle} age=${boss.age}',
    'locks=${f.mailLocks}/${f.ankhLocks}/${f.ankhMoments} '
        'dealt=${f.lettersDealt} returned=${f.lettersReturned} '
        'landed=${f.returnsLanded} throws=${f.ankhThrows} '
        'catches=${f.ankhCatches} scuffs=${f.wrapScuffs}/'
        '${f.scuffsSinceReturn} hits=${f.letterHits}/${f.ankhHits}',
    'lane=${f.laneY} mail=${f.mailLockedAt} express=${f.express} '
        'ankh=${f.ankhLockedAt} two=${f.twoAnkhs} '
        'last=${f.lastReturnAt}/${f.lastLandAt}/${f.lastScuffAt}',
    for (final l in f.letters)
      'L ${l.cycle}/${l.index} ${l.lane} ${l.releaseAt} ${l.speed} '
          '${l.express} ${l.returnedAt} ${l.struckX} ${l.homeAt} '
          '${l.landedAt} ${l.spentAt} ${l.delivered}',
    for (final a in f.ankhs)
      'A ${a.cycle} ${a.laneA} ${a.laneB} ${a.lockedAt} ${a.thrownAt} '
          '${a.speed} ${a.second} ${a.caughtAt}',
  ].join('\n');
}

void main() {
  group('the mail call', () {
    test('the arrival deals nothing; then each cycle locks its lane on the '
        'bird and deals three letters down it', () {
      final sim = neferhooArena(version: v50);
      final boss = sim.boss!;
      final f = boss.neferhoo;
      final start = boss.arrivalDuration;
      expect(f.letters, isEmpty, reason: 'the arrival deals nothing');
      expect(boss.combatTime, lessThan(.05));
      holdUntil(sim, .55, y: .3);
      expect(f.mailLocks, 0);
      expect(boss.mailPhase, NeferhooMailPhase.idle);
      holdUntil(sim, .62, y: .3);
      expect(f.mailLocks, 1);
      expect(f.mailLockedAt, closeTo(start + Neferhoo.mailLockAt, 1e-9));
      expect(f.laneY, closeTo(.3, .002));
      expect(f.express, isFalse);
      expect(f.letters, hasLength(3));
      for (final (k, letter) in f.letters.indexed) {
        expect(letter.index, k);
        expect(letter.cycle, 0);
        expect(letter.lane, f.laneY);
        expect(letter.speed, Neferhoo.letterSpeed);
        expect(letter.express, isFalse);
        expect(letter.releaseAt, closeTo(start + 1.6 + .4 * k, 1e-9));
      }
      expect(boss.mailPhase, NeferhooMailPhase.windup);
      expect(boss.lettersInHand, 0, reason: 'they rise into his fan');
      holdUntil(sim, 1.0, y: .3);
      expect(boss.lettersInHand, 3);
      expect(boss.mailWindup, closeTo(.4, .02));
      expect(boss.liveLetters, isEmpty, reason: 'still in his hand');
      holdUntil(sim, 1.62, y: .3);
      expect(f.lettersDealt, 1);
      expect(boss.mailPhase, NeferhooMailPhase.flicking);
      expect(boss.mailWindup, 1);
      expect(boss.lettersInHand, 2);
      expect(boss.liveLetters, [f.letters.first]);
      holdUntil(sim, 2.42, y: .3);
      expect(f.lettersDealt, 3);
      expect(boss.lettersInHand, 0);
      // Screen-fixed, from his hand.
      final first = f.letters.first;
      expect(
        first.xAt(boss.age, boss.handX),
        closeTo(boss.x - .1 - .45 * (boss.age - first.releaseAt), 1e-9),
      );
      holdUntil(sim, 2.9, y: .7);
      expect(boss.mailPhase, NeferhooMailPhase.idle);
      // The bird leaves the lane: the letters fly past and off the left.
      holdUntil(sim, 8, y: .7);
      expect(sim.shield, isTrue);
      expect(sim.hearts, 3);
      for (final letter in f.letters) {
        expect(letter.spentAt, isNotNull);
        expect(letter.delivered, isFalse);
        expect(letter.xAt(letter.spentAt!, boss.handX), lessThan(-.1));
      }
      expect(boss.liveLetters, isEmpty);
      // The next cycle locks on the bird again, kept off the edges.
      holdUntil(sim, 12.62, y: .7);
      expect(f.mailLocks, 2);
      expect(f.mailLockedAt, closeTo(start + 12.6, 1e-9));
      expect(f.laneY, closeTo(.7, .002));
      holdUntil(sim, 24.62, y: .1);
      expect(f.laneY, Neferhoo.laneTop);
      expect(f.letters.map((l) => l.cycle), [0, 0, 0, 1, 1, 1, 2, 2, 2]);
    });

    test('a letter that meets the bird hurts it like a course edge and is '
        'spent; the next ones meet a recovering bird and do no harm', () {
      final sim = neferhooArena(version: v50);
      final boss = sim.boss!;
      final f = boss.neferhoo;
      holdUntil(sim, .62, y: .4);
      final first = f.letters.first;
      // The rectangle meets the circle when its near edge is a bird's radius
      // from the bird's centre.
      const reach = FlightSimulation.birdX + .045 + .038;
      final arrives = first.releaseAt + (boss.handX - reach) / first.speed;
      holdUntil(sim, arrives - boss.arrivalDuration - .03, y: .4);
      expect(sim.shield, isTrue);
      holdUntil(sim, 6, y: .4);
      expect(sim.shield, isFalse);
      expect(sim.hearts, 3);
      expect(f.letterHits, 1);
      expect(first.spentAt, closeTo(arrives, 1 / 60 + 1e-6));
      for (final letter in f.letters) {
        expect(letter.delivered, isTrue);
        expect(letter.returned, isFalse);
      }
    });
  });

  group('return to sender', () {
    test('the catch band is the hurt band: a shot from anywhere a letter '
        'can hit the bird sends it back', () {
      const lane = .5;
      const band = Neferhoo.letterHalfHeight + Neferhoo.catchReach;
      expect(band, closeTo(.070, 1e-12));
      // The hurt band, in the bird's centre.
      for (var i = -699; i <= 699; i += 3) {
        final dy = i / 10000;
        expect(
          Neferhoo.letterTouches(
            FlightSimulation.birdX,
            lane,
            FlightSimulation.birdX,
            lane + dy,
            FlightSimulation.birdRadius,
          ),
          isTrue,
          reason: '$dy',
        );
      }
      for (final dy in [-.0701, .0701]) {
        expect(
          Neferhoo.letterTouches(
            FlightSimulation.birdX,
            lane,
            FlightSimulation.birdX,
            lane + dy,
            FlightSimulation.birdRadius,
          ),
          isFalse,
        );
      }
      // A rock leaves the beak: from every bird in that band, at every tilt
      // and flap stretch, with or without Reduced Motion, it is caught.
      var lowest = 1.0, highest = -1.0;
      for (var v = -.6; v <= 1.6 + 1e-9; v += .05) {
        for (var since = 0.0; since <= .3; since += .005) {
          for (final reduced in [false, true]) {
            final beak = BirdFlightMotion.mouth(
              velocity: v,
              sinceFlap: since,
              reducedMotion: reduced,
            ).y;
            lowest = math.min(lowest, beak);
            highest = math.max(highest, beak);
            for (final dy in [-band + 1e-6, -.035, 0.0, .035, band - 1e-6]) {
              expect(
                Neferhoo.catches(lane + dy + beak, lane),
                isTrue,
                reason: 'dy $dy beak $beak',
              );
            }
          }
        }
      }
      expect(lowest, greaterThanOrEqualTo(-Neferhoo.beakAbove));
      expect(highest, lessThanOrEqualTo(Neferhoo.beakBelow));
      // No wider than that.
      expect(
        Neferhoo.catches(lane - band - Neferhoo.beakAbove - .001, lane),
        isFalse,
      );
      expect(
        Neferhoo.catches(lane + band + Neferhoo.beakBelow + .001, lane),
        isFalse,
      );
    });

    for (final dy in [-.065, 0.0, .065, .11]) {
      test('a shot fired ${dy.abs() < .07 ? 'inside' : 'outside'} the band '
          '(${dy >= 0 ? '+' : ''}$dy from the lane) '
          '${dy.abs() < .07 ? 'sends the letter back' : 'passes it by'}', () {
        final sim = neferhooArena(version: v50);
        final boss = sim.boss!;
        final f = boss.neferhoo;
        holdUntil(sim, .62, y: .5);
        final lane = f.laneY;
        holdUntil(sim, 1.7, y: lane + dy);
        expect(sim.shoot(), isTrue);
        holdUntil(sim, 2.3, y: lane + dy);
        expect(f.lettersReturned, dy.abs() < .07 ? 1 : 0);
        if (dy.abs() < .07) {
          expect(f.letters.first.returned, isTrue);
          expect(f.wrapScuffs, 0, reason: 'the rock was spent on it');
        }
      });
    }

    test('a returned letter flies home harmlessly and lands once for 25', () {
      final sim = neferhooArena(version: v50);
      final boss = sim.boss!;
      final f = boss.neferhoo;
      holdUntil(sim, .62, y: .5);
      final lane = f.laneY;
      holdUntil(sim, 1.7, y: lane);
      sim.shoot();
      final first = f.letters.first;
      for (var i = 0; i < 60 && !first.returned; i++) {
        holdUntil(sim, boss.combatTime + 1 / 60, y: lane);
      }
      expect(first.returned, isTrue);
      expect(f.lettersReturned, 1);
      expect(boss.lastReturnAt, first.returnedAt);
      expect(first.struckY, lane);
      final chest = math.sqrt(
        math.pow(boss.x - first.struckX, 2) + math.pow(boss.y - lane, 2),
      );
      expect(
        first.homeAt! - first.returnedAt!,
        closeTo(Neferhoo.returnSeconds(chest), .01),
      );
      // On its way home it is not a letter in the lane any more: a rock
      // flies through where it would have been.
      final rock = BirdRock(x: first.xAt(boss.age, boss.handX) - .03, y: lane);
      sim.rocks.add(rock);
      holdUntil(sim, boss.combatTime + 2 / 60, y: lane);
      expect(sim.rocks, contains(rock));
      expect(rock.x, greaterThan(first.xAt(boss.age, boss.handX)));
      expect(f.lettersReturned, 1);
      sim.rocks.remove(rock);
      final full = boss.maxHp;
      holdUntil(sim, first.homeAt! - boss.arrivalDuration - .02, y: lane);
      expect(f.returnsLanded, 0);
      expect(boss.hp, full);
      holdUntil(sim, first.homeAt! - boss.arrivalDuration + .02, y: lane);
      expect(f.returnsLanded, 1);
      expect(first.landedAt! - first.homeAt!, inInclusiveRange(0, 1 / 120));
      expect(boss.lastLandAt, first.landedAt);
      expect(boss.lastHitAt, boss.lastLandAt, reason: 'a landing, not a scuff');
      expect(boss.hp, full - Neferhoo.returnDamage);
      // It would have reached the bird .4 s before the second letter does:
      // the shield goes only when the second one arrives.
      const reach = FlightSimulation.birdX + .045 + .038;
      final second = f.letters[1];
      final wouldHave = first.releaseAt + (boss.handX - reach) / .45;
      final arrives = second.releaseAt + (boss.handX - reach) / .45;
      holdUntil(sim, wouldHave - boss.arrivalDuration + .1, y: lane);
      expect(sim.shield, isTrue);
      holdUntil(sim, arrives - boss.arrivalDuration + .05, y: lane);
      expect(sim.shield, isFalse);
      expect(f.letterHits, 1);
      holdUntil(sim, 11, y: .2);
      expect(f.returnsLanded, 1, reason: 'it landed once');
      expect(boss.hp, full - 25);
    });

    test('a charged rock sends back every letter it meets and carries on; a '
        'tapped one is spent on the first; the landings come one by one', () {
      for (final (charge, damage) in [
        (.5, 25),
        (.35, 21),
        (.34, 20),
        (0.0, 10),
      ]) {
        final sim = neferhooArena(version: v50);
        final boss = sim.boss!;
        final f = boss.neferhoo;
        holdUntil(sim, .62, y: .5);
        final lane = f.laneY;
        holdUntil(sim, 2.5, y: lane);
        expect(f.lettersDealt, 3);
        sim.rocks.add(
          BirdRock(x: .55, y: lane, damage: damage, charge: charge),
        );
        holdUntil(sim, 3.4, y: lane);
        final bulk = charge >= Neferhoo.bulkCharge;
        expect(f.lettersReturned, bulk ? 3 : 1, reason: '$charge');
        expect(f.wrapScuffs, bulk ? 1 : 0, reason: '$charge');
        final homes = [for (final l in f.letters) ?l.homeAt]..sort();
        for (var i = 1; i < homes.length; i++) {
          expect(
            homes[i] - homes[i - 1],
            greaterThanOrEqualTo(Neferhoo.landingGap - 1e-9),
          );
        }
        holdUntil(sim, 5, y: .2);
        expect(f.returnsLanded, bulk ? 3 : 1);
        expect(
          boss.hp,
          boss.maxHp -
              (bulk
                  ? 3 * 25 + Neferhoo.wrapsDamage(damage)
                  : Neferhoo.returnDamage),
        );
      }
    });

    test('a sprinting bird that meets a letter sends it back', () {
      final sim = neferhooArena(version: v50);
      final boss = sim.boss!;
      final f = boss.neferhoo;
      holdUntil(sim, .62, y: .5);
      final lane = f.laneY;
      holdUntil(sim, 2.2, y: lane);
      expect(sim.sprint(), isTrue);
      holdUntil(sim, 3.1, y: lane);
      final first = f.letters.first;
      expect(first.returned, isTrue);
      expect(first.delivered, isFalse);
      expect(first.struckX, closeTo(FlightSimulation.birdX + .083, .02));
      expect(sim.shield, isTrue);
      expect(f.letterHits, 0);
    });
  });

  group('the padded wraps', () {
    test('a rock or a blast on his chest deals a third, at least 1', () {
      final boss = SkyBoss(
        number: 1,
        x: 1.2,
        kind: BossKind.neferhoo,
        cinematic: true,
        staged: true,
        maxHp: Neferhoo.campaignHp,
      )..age = 8;
      expect(boss.strike(10), 3);
      expect(boss.strike(40), 13);
      expect(boss.strike(28), 9);
      expect(boss.strike(1), 1);
      expect(boss.hp, Neferhoo.campaignHp - 26);
      expect(boss.neferhoo.wrapScuffs, 4);
      expect(boss.neferhoo.scuffsSinceReturn, 4);
      expect(boss.lastScuffAt, 8);
    });

    test('in flight: a tapped rock scuffs for 3, and eight of them without a '
        'return bring the hint; a return resets it', () {
      final sim = neferhooArena(version: v50);
      final boss = sim.boss!;
      final f = boss.neferhoo;
      // Open sky (the stream is past) at his height.
      holdUntil(sim, .62, y: .3);
      holdUntil(sim, 6.5, y: .8);
      for (var i = 0; i < 8; i++) {
        sim.rocks.add(BirdRock(x: .6, y: boss.y));
        holdUntil(sim, boss.combatTime + .5, y: .8);
      }
      expect(f.wrapScuffs, 8);
      expect(boss.hp, boss.maxHp - 24);
      expect(boss.neferhooHint, Neferhoo.neferhooScuffHint);
      // The next mail call: the hint holds over the mail line until a
      // letter goes back.
      holdUntil(sim, 13.0, y: .5);
      expect(boss.neferhooHint, Neferhoo.neferhooScuffHint);
      holdUntil(sim, 13.7, y: f.laneY);
      sim.shoot();
      holdUntil(sim, 14.1, y: f.laneY);
      expect(f.lettersReturned, 1);
      expect(f.scuffsSinceReturn, 0);
      expect(boss.neferhooHint, Neferhoo.returnHint);
    });
  });

  group('the boomerang ankh', () {
    /// A fight in its full stage from combat time 0 (the ankh armed from
    /// cycle 0), the mail lane locked high at .15 and the bird then at
    /// [lockY] for the ankh's lock, [flyY] after it.
    ({FlightSimulation sim, NeferhooAnkh ankh}) ankhAt(
      double lockY,
      double flyY, {
      bool fury = false,
      double until = 11,
    }) {
      final sim = neferhooArena(version: v50);
      final boss = sim.boss!;
      hurtTo(boss, fury ? 1 / 3 : 2 / 3);
      holdUntil(sim, .62, y: .15);
      holdUntil(sim, 5.42, y: lockY);
      final ankh = boss.neferhoo.ankhs.first;
      holdUntil(sim, until, y: flyY);
      return (sim: sim, ankh: ankh);
    }

    test('it locks both lanes on the bird, is thrown at 6.8 and comes home '
        'along the second lane', () {
      final sim = neferhooArena(version: v50);
      final boss = sim.boss!;
      final f = boss.neferhoo;
      final start = boss.arrivalDuration;
      hurtTo(boss, 2 / 3);
      holdUntil(sim, .62, y: .15);
      expect(boss.stageReached, 1);
      expect(boss.signatureCycle, 0);
      holdUntil(sim, 5.38, y: .3);
      expect(boss.ankhPhase, NeferhooAnkhPhase.idle);
      holdUntil(sim, 5.42, y: .3);
      expect(f.ankhLocks, 1);
      expect(f.ankhLockedAt, closeTo(start + 5.4, 1e-9));
      expect(f.twoAnkhs, isFalse);
      final ankh = f.ankhs.single;
      expect(ankh.laneA, closeTo(.3, .002));
      expect(ankh.laneB, closeTo(ankh.laneA + .32, 1e-12));
      expect(ankh.thrownAt, closeTo(start + 6.8, 1e-9));
      expect(ankh.speed, Neferhoo.ankhSpeed);
      expect(ankh.second, isFalse);
      expect(boss.ankhPhase, NeferhooAnkhPhase.rise);
      expect(boss.liveAnkhs, [ankh], reason: 'the loop is drawn from the lock');
      holdUntil(sim, 6.3, y: .46);
      expect(boss.ankhPhase, NeferhooAnkhPhase.spinUp);
      expect(f.ankhThrows, 0);
      holdUntil(sim, 6.82, y: .46);
      expect(f.ankhThrows, 1);
      expect(boss.ankhPhase, NeferhooAnkhPhase.thrown);
      final home = ankh.homeAt(
        handX: boss.handX,
        turnX: Neferhoo.turnX(FlightSimulation.birdX),
      );
      // About 2.7 s round trip at 640 px.
      expect(home - ankh.thrownAt, closeTo(2.66, .05));
      holdUntil(sim, home - start + .02, y: .46);
      expect(ankh.caughtAt, home);
      expect(f.ankhCatches, 1);
      expect(boss.liveAnkhs, isEmpty);
      expect(boss.ankhPhase, NeferhooAnkhPhase.caught);
      holdUntil(sim, home - start + Neferhoo.catchSeconds + .02, y: .46);
      expect(boss.ankhPhase, NeferhooAnkhPhase.idle);
      // Between its two lanes the bird was never touched.
      expect(sim.shield, isTrue);
      expect(f.ankhHits, 0);
    });

    test(
      'both passes hurt: out along the first lane, back along the second',
      () {
        final turnX = Neferhoo.turnX(FlightSimulation.birdX);
        // Out: the bird stays on the first lane.
        final out = ankhAt(.3, .3, until: 9);
        final (passOut, passBack) = out.ankh.passes(
          handX: out.sim.boss!.handX,
          turnX: turnX,
          column: FlightSimulation.birdX,
        );
        expect(out.sim.boss!.neferhoo.ankhHits, 1);
        expect(out.sim.shield, isFalse);
        // Back: it moves to the second lane after the lock.
        final back = ankhAt(.3, .62, until: passOut - 4.6 + .3);
        expect(back.sim.shield, isTrue, reason: 'the first pass went by');
        holdUntil(back.sim, 10, y: .62);
        expect(back.sim.boss!.neferhoo.ankhHits, 1);
        expect(back.sim.shield, isFalse);
        expect(passBack, greaterThan(passOut + 1));
      },
    );

    test('fury throws two on mirrored loops, half a second apart, faster', () {
      final (:sim, :ankh) = ankhAt(.7, .54, fury: true, until: 8);
      final f = sim.boss!.neferhoo;
      expect(f.twoAnkhs, isTrue);
      expect(f.ankhs, hasLength(2));
      final second = f.ankhs[1];
      expect(ankh.laneA, closeTo(.7, .002));
      expect(ankh.laneB, closeTo(.38, .002));
      expect(second.second, isTrue);
      expect(second.laneA, ankh.laneB);
      expect(second.laneB, ankh.laneA);
      expect(second.thrownAt - ankh.thrownAt, closeTo(.5, 1e-9));
      expect(ankh.speed, Neferhoo.furyAnkhSpeed);
      expect(second.speed, Neferhoo.furyAnkhSpeed);
      expect(f.ankhThrows, 2);
      // The space between the loops (.38 + .083 to .7 - .083) is safe.
      holdUntil(sim, 12, y: .54);
      expect(f.ankhHits, 0);
      expect(f.ankhCatches, 2);
      expect(second.caughtAt! - ankh.caughtAt!, closeTo(.5, 1e-9));
    });

    test('rocks pass the ankh by', () {
      final sim = neferhooArena(version: v50);
      final boss = sim.boss!;
      hurtTo(boss, 2 / 3);
      holdUntil(sim, .62, y: .15);
      holdUntil(sim, 7.2, y: .5);
      final ankh = boss.neferhoo.ankhs.single;
      final at = ankh.at(
        boss.age,
        handX: boss.handX,
        turnX: Neferhoo.turnX(FlightSimulation.birdX),
      )!;
      final rock = BirdRock(x: at.$1 - .02, y: at.$2);
      sim.rocks.add(rock);
      holdUntil(sim, 7.25, y: .5);
      expect(sim.rocks, contains(rock));
      expect(rock.x, greaterThan(at.$1));
    });
  });

  group('three stages', () {
    test(
      'the warm-up deals the mail call only: no ankh, cycle after cycle',
      () {
        final sim = neferhooArena(version: v50);
        final boss = sim.boss!;
        final f = boss.neferhoo;
        for (final c in [0, 1, 2]) {
          holdUntil(sim, c * 12 + .62, y: .3);
          holdUntil(sim, c * 12 + 11.9, y: .7);
          expect(boss.ankhPhase, NeferhooAnkhPhase.idle);
        }
        holdUntil(sim, 40, y: .5);
        expect(boss.stage, 0);
        expect(f.mailLocks, 4);
        expect(f.ankhMoments, 3);
        expect(f.ankhLocks, 0);
        expect(f.ankhs, isEmpty);
        expect(boss.signatureArmed(3), isFalse);
      },
    );

    test('growing stronger arms the ankh on the first lock at least 1.6 s '
        'away', () {
      // Cycle 0's lock is at 5.4, cycle 1's at 17.4: a stage-up at 16 s is
      // too close to 17.4.
      for (final (at, cycle) in [(2.0, 0), (4.0, 1), (15.0, 1), (16.0, 2)]) {
        final sim = neferhooArena(version: v50);
        final boss = sim.boss!;
        holdUntil(sim, at, y: .5, keepAlive: true);
        hurtTo(boss, 2 / 3);
        holdUntil(sim, at + .05, y: .5, keepAlive: true);
        expect(boss.stageReached, 1);
        expect(boss.stageHint, 'STRONGER · The golden ankh comes back!');
        expect(boss.signatureCycle, cycle, reason: 'stronger at $at');
        holdUntil(sim, cycle * 12 + 5.42, y: .5, keepAlive: true);
        final f = boss.neferhoo;
        expect(f.ankhLocks, 1, reason: 'stronger at $at');
        expect(f.ankhs.single.cycle, cycle);
        expect(
          f.ankhLockedAt - boss.stageUpAt,
          greaterThanOrEqualTo(SkyBoss.signatureLead),
        );
      }
    });

    test('fury is latched at each lock: a calm stream stays calm, the next '
        'lock is the express post and two ankhs', () {
      final sim = neferhooArena(version: v50);
      final boss = sim.boss!;
      final f = boss.neferhoo;
      holdUntil(sim, .62, y: .3);
      expect(f.express, isFalse);
      hurtTo(boss, 1 / 3);
      holdUntil(sim, 1.0, y: .7);
      expect(boss.stage, 2);
      expect(boss.enraged, isTrue);
      // This call was locked calm: three letters at the calm speed.
      expect(f.letters, hasLength(3));
      expect(f.letters.every((l) => !l.express && l.speed == .45), isTrue);
      // The ankh's lock that cycle comes in fury: two.
      holdUntil(sim, 5.42, y: .7);
      expect(f.twoAnkhs, isTrue);
      expect(f.ankhs, hasLength(2));
      holdUntil(sim, 12.62, y: .5);
      expect(f.express, isTrue);
      final express = f.letters.where((l) => l.cycle == 1).toList();
      expect(express, hasLength(5));
      for (final (k, letter) in express.indexed) {
        expect(letter.express, isTrue);
        expect(letter.speed, Neferhoo.furyLetterSpeed);
        expect(letter.releaseAt - f.mailLockedAt, closeTo(1.0 + .32 * k, 1e-9));
      }
      expect(boss.lettersInHand, 0);
      holdUntil(sim, 13.0, y: .2);
      expect(boss.lettersInHand, 3, reason: 'five in the fan show as three');
    });
  });

  group('hints', () {
    test('the warm-up, the full fight and fury each say what is coming', () {
      final sim = neferhooArena(version: v50);
      final boss = sim.boss!;
      final f = boss.neferhoo;
      holdUntil(sim, .3, y: .3);
      expect(boss.neferhooHint, Neferhoo.warmUpHint);
      holdUntil(sim, 1.0, y: .3);
      expect(boss.neferhooHint, Neferhoo.mailHint);
      holdUntil(sim, 1.7, y: f.laneY);
      sim.shoot();
      holdUntil(sim, 2.05, y: f.laneY);
      expect(f.lettersReturned, 1);
      expect(boss.neferhooHint, Neferhoo.returnHint);
      holdUntil(sim, f.lastReturnAt - 4.6 + 1.55, y: .8);
      expect(boss.neferhooHint, Neferhoo.mailHint, reason: 'still coming');
      holdUntil(sim, 6, y: .8);
      expect(boss.neferhooHint, Neferhoo.warmUpHint);
      // The full fight.
      hurtTo(boss, 2 / 3);
      holdUntil(sim, 6.1, y: .8);
      expect(boss.stageHint, contains('ankh'));
      holdUntil(sim, 12.3, y: .8);
      expect(boss.stageHint, isNull);
      expect(boss.neferhooHint, Neferhoo.calmHint);
      holdUntil(sim, 17.5, y: .3);
      expect(boss.neferhooHint, Neferhoo.ankhHint);
      holdUntil(sim, 23.5, y: .46);
      expect(boss.neferhooHint, Neferhoo.calmHint);
      // Fury.
      hurtTo(boss, 1 / 3);
      holdUntil(sim, 24.4, y: .46);
      expect(boss.neferhooHint, Neferhoo.furyHint);
      holdUntil(sim, 25.0, y: .46);
      expect(boss.neferhooHint, Neferhoo.expressHint);
      holdUntil(sim, 28.9, y: .2);
      holdUntil(sim, 29.5, y: .3);
      expect(boss.neferhooHint, Neferhoo.twoAnkhsHint);
    });
  });

  group('the end of the fight', () {
    test('a landing that beats him clears everything, and nothing hurts '
        'the bird again on the way to the line', () {
      final sim = neferhooArena(version: v50);
      final boss = sim.boss!;
      final f = boss.neferhoo;
      boss.takeDamage(boss.hp - 25);
      holdUntil(sim, .62, y: .5);
      expect(f.express, isTrue);
      final lane = f.laneY;
      holdUntil(sim, 2.0, y: lane);
      // A charged rock sends three back; the first to land beats him.
      sim.rocks.add(BirdRock(x: .55, y: lane, damage: 25, charge: .5));
      for (var i = 0; i < 120 && boss.phase == BossPhase.attacking; i++) {
        holdUntil(sim, boss.combatTime + 1 / 60, y: lane);
      }
      expect(boss.phase, BossPhase.defeated);
      expect(sim.bossesDefeated, 1);
      expect(f.returnsLanded, 1, reason: 'the others never land');
      expect(f.lettersReturned, greaterThan(1));
      expect(boss.liveLetters, isEmpty);
      expect(boss.liveAnkhs, isEmpty);
      expect(boss.mailPhase, NeferhooMailPhase.idle);
      expect(boss.ankhPhase, NeferhooAnkhPhase.idle);
      expect(boss.lettersInHand, 0);
      // The bird stays in the lane through the defeat and the glide.
      final shield = sim.shield, hearts = sim.hearts;
      final counters = snapshot(boss);
      for (var i = 0; i < 60 * 60 && sim.phase != RunPhase.ended; i++) {
        sim
          ..birdY = lane
          ..velocity = 0;
        frame(sim, width: w640);
      }
      expect(sim.endReason, EndReason.completed);
      expect(sim.shield, shield);
      // (A heart knocked loose by his last stage-up may be picked up.)
      expect(sim.hearts, greaterThanOrEqualTo(hearts));
      expect(snapshot(boss).split('\n').skip(1), counters.split('\n').skip(1));
    });
  });

  group('the shared bot', () {
    for (final px in [640, 800, 864]) {
      test('$px px: it beats him in a fight that grows stronger twice, with '
          'a heart each time', () {
        double? start, strong, fury, end;
        final seen = <SkyHeart>{};
        final sim = levelFlight(Campaign.level('2-6')!, version: v50);
        flyLevel(
          sim,
          viewportWidth: px / 360,
          until: (sim) => sim.boss?.phase == BossPhase.defeated,
          watch: (sim) {
            final boss = sim.boss;
            if (boss == null) return;
            if (boss.phase == BossPhase.attacking) start ??= sim.elapsed;
            if (boss.stageReached >= 1) strong ??= sim.elapsed;
            if (boss.stageReached >= 2) fury ??= sim.elapsed;
            if (boss.phase == BossPhase.defeated) end ??= sim.elapsed;
            seen.addAll(sim.heartPickups);
          },
        );
        final f = sim.boss!.neferhoo;
        // It fires from the lane locked on it, a tapped rock every .18 s
        // and a charged one every 1.8 s: it sends every letter back and
        // ends the warm-up with the first ones, an expert's fight.
        expect(end! - start!, inInclusiveRange(20.0, 80.0));
        expect(strong! - start!, greaterThan(2));
        expect(fury! - strong!, greaterThan(8));
        expect(end! - fury!, greaterThan(8));
        expect(seen, hasLength(2));
        expect(f.returnsLanded, greaterThan(4));
        expect(f.wrapScuffs, greaterThan(10));
        expect(f.ankhThrows, greaterThan(0));
      });
    }
  });

  group('determinism', () {
    test('the counters the cues and voices read rise once per event, never '
        'twice in a frame, and seeks re-simulate them exactly', () {
      final (:tape, :simulation) = recordLevel(
        Campaign.level('2-6')!,
        version: v50,
        weaponDamage: BirdRock.baseDamage,
        viewportWidth: w640,
      );
      expect(simulation.bossesDefeated, 1);
      final player = ReplayPlayer(tape);
      SkyBoss? boss;
      var last = (0, 0, 0, 0, 0, 0);
      double? fightMs;
      String? midFight;
      for (var ms = 0.0; ms <= tape.durationMs; ms += 20) {
        player.seek(ms);
        boss = player.simulation.boss ?? boss;
        final b = boss;
        if (b == null) continue;
        if (b.phase == BossPhase.attacking) fightMs ??= ms;
        final f = b.neferhoo;
        final now = (
          f.mailLocks,
          f.ankhThrows,
          f.returnsLanded,
          f.lettersDealt,
          f.ankhLocks,
          f.ankhCatches,
        );
        for (final (a, z) in [
          (now.$1, last.$1),
          (now.$2, last.$2),
          (now.$3, last.$3),
          (now.$4, last.$4),
          (now.$5, last.$5),
          (now.$6, last.$6),
        ]) {
          expect(a - z, inInclusiveRange(0, 1), reason: 'at $ms ms');
        }
        last = now;
        if (fightMs != null && ms == fightMs + 14000) midFight = snapshot(b);
      }
      final f = boss!.neferhoo;
      // Each counter is its events.
      expect(f.mailLocks, f.letters.map((l) => l.cycle).toSet().length);
      expect(
        f.returnsLanded,
        f.letters.where((l) => l.landedAt != null).length,
      );
      expect(f.ankhThrows, f.ankhs.length);
      expect(f.returnsLanded, greaterThan(2));
      expect(f.ankhThrows, greaterThan(1));
      // A backward seek, and a fresh player straight to the same moment.
      final at = fightMs! + 14000;
      expect(midFight, isNotNull);
      player.seek(at);
      final again = snapshot(player.simulation.boss!);
      expect(again, midFight);
      final fresh = ReplayPlayer(tape)..seek(at);
      expect(snapshot(fresh.simulation.boss!), again);
      player.seek(tape.durationMs * .2);
      player.seek(tape.durationMs);
      expect(player.simulation.bossesDefeated, 1);
    });
  });
}
