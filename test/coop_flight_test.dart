import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/session_replay.dart';
import 'package:push_up_bird/domain/tracking.dart';

/// A co-op Star Trail flight past its countdown with an empty sky, so a
/// test chooses what the birds meet.
FlightSimulation pair({int seed = 4, CoopMode coop = CoopMode.roped}) {
  final sim = FlightSimulation(
    rules: TapFlyMode(),
    practice: false,
    course: FlightCourse.starTrail,
    coop: coop,
    random: Random(seed),
  );
  step(sim, 3);
  clearSky(sim);
  return sim;
}

void clearSky(FlightSimulation sim) {
  sim.obstacles.clear();
  sim.stars.clear();
  sim.starTrios.clear();
  sim.enemies.clear();
  sim.heartPickups.clear();
}

void step(FlightSimulation sim, double seconds, {double dt = .02}) {
  for (var i = 0; i < (seconds / dt).round(); i++) {
    final now = (sim.elapsed + dt) * 1000;
    sim.apply(
      const MovementInput(valid: true),
      TrackingSample(
        mode: PlayMode.touch,
        timestampMs: now,
        receivedMs: now,
        joints: const [],
      ),
      now,
    );
    sim.tick(dt, now);
  }
}

/// Places both birds level and still at [y], in their formation places.
void settle(FlightSimulation sim, {double y = .55}) {
  for (final bird in sim.flock) {
    bird
      ..y = y
      ..velocity = 0
      ..x = bird.homeX
      ..vx = 0;
  }
}

/// How far the pair's middle rises after [flappers] flap once together.
double climb(Set<int> flappers) {
  final sim = pair()..invulnerableUntil = double.infinity;
  settle(sim, y: .75);
  for (final player in flappers) {
    expect(sim.flap(player), isTrue);
  }
  final start = (sim.lead.y + sim.partner!.y) / 2;
  var top = start;
  for (var i = 0; i < 60; i++) {
    step(sim, .02);
    top = min(top, (sim.lead.y + sim.partner!.y) / 2);
  }
  return start - top;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('the rope', () {
    test('a taut rope shares the pull between two equal birds', () {
      final a = FlightBird(homeX: .4)..y = .3;
      final b = FlightBird(homeX: .4)..y = .3 + Tether.length + .01;
      // The top bird flaps away from the hanging one.
      a.velocity = -.54;
      b.velocity = 0;
      final pull = Tether.bind(a, b);
      expect(pull, closeTo(.54, 1e-9));
      expect(a.velocity, closeTo(-.27, 1e-9));
      expect(b.velocity, closeTo(-.27, 1e-9));
      // Each moved half the way back to the rope's length.
      expect(b.y - a.y, closeTo(Tether.length, 1e-9));
      expect(a.y, closeTo(.305, 1e-9));
    });

    test('a slack rope leaves the birds alone', () {
      final a = FlightBird(homeX: .4)..y = .4;
      final b = FlightBird(homeX: .54)..y = .5;
      a.velocity = -.54;
      b.velocity = .3;
      expect(Tether.bind(a, b), 0);
      expect(a.velocity, -.54);
      expect(b.velocity, .3);
    });

    test('birds that meet bump apart instead of passing through', () {
      final a = FlightBird(homeX: .4)..y = .5;
      final b = FlightBird(homeX: .4)..y = .5 - Tether.contact / 2;
      a.velocity = -.5;
      b.velocity = .2;
      Tether.bind(a, b);
      expect((a.y - b.y).abs(), closeTo(Tether.contact, 1e-9));
      // They leave the bump together, carrying the same total momentum.
      expect(a.velocity, closeTo(b.velocity, 1e-9));
      expect(a.velocity + b.velocity, closeTo(-.3, 1e-9));
    });
  });

  group('co-op flight', () {
    test('needs an endless touch flight from rules 42', () {
      expect(
        () => FlightSimulation(
          rules: JumpFlyMode(),
          practice: false,
          coop: CoopMode.roped,
        ),
        throwsArgumentError,
      );
      expect(
        () => FlightSimulation(
          rules: TapFlyMode(rulesVersion: 41),
          practice: false,
          rulesVersion: 41,
          coop: CoopMode.roped,
        ),
        throwsArgumentError,
      );
      final sim = pair();
      expect(sim.paired, isTrue);
      expect(sim.roped, isTrue);
      expect(sim.flock, hasLength(2));
      expect(sim.lead.homeX, FlightSimulation.birdX - Tether.spread);
      expect(sim.partner!.homeX, FlightSimulation.birdX + Tether.spread);
    });

    test('flapping together climbs higher than one bird lifting both', () {
      final alone = climb({0});
      final other = climb({1});
      final together = climb({0, 1});
      // A lone flap lifts its partner too, so the pair still rises.
      expect(alone, greaterThan(.01));
      expect(other, closeTo(alone, .01));
      expect(together, greaterThan(alone * 2));
      // Together they rise like a solo bird: v² / 2g.
      final rules = TapFlyMode();
      final solo = rules.flapImpulse * rules.flapImpulse / (2 * rules.gravity);
      expect(together, closeTo(solo, .02));
    });

    test('one bird flapping drags its partner up once the rope is taut', () {
      final sim = pair()..invulnerableUntil = double.infinity;
      settle(sim, y: .45);
      // The partner hangs on a taut rope below and ahead of the lead.
      final dx = sim.partner!.homeX - sim.lead.homeX;
      final start = sim.partner!.y =
          .45 + sqrt(Tether.length * Tether.length - dx * dx) - .001;
      sim.flap(0);
      var partnerTop = sim.partner!.y;
      var separation = 0.0;
      for (var i = 0; i < 40; i++) {
        step(sim, .02);
        partnerTop = min(partnerTop, sim.partner!.y);
        final dx = sim.partner!.x - sim.lead.x;
        final dy = sim.partner!.y - sim.lead.y;
        separation = max(separation, sqrt(dx * dx + dy * dy));
      }
      expect(partnerTop, lessThan(start - .02));
      expect(separation, lessThanOrEqualTo(Tether.length + 1e-9));
      expect(sim.ropeSnaps, greaterThan(0));
    });

    test('one sprinting bird drags the other; both sprinting go faster', () {
      double peakBoost(Set<int> sprinters) {
        final sim = pair()..invulnerableUntil = double.infinity;
        settle(sim);
        for (final player in sprinters) {
          expect(sim.sprint(player: player), isTrue);
        }
        var peak = 1.0;
        for (var i = 0; i < 30; i++) {
          settleHeights(sim);
          step(sim, .02);
          peak = max(peak, sim.courseBoost);
        }
        return peak;
      }

      final one = peakBoost({1});
      final both = peakBoost({0, 1});
      expect(one, closeTo(1 + (Sprint.peakBoost - 1) / 2, .01));
      expect(both, closeTo(Sprint.peakBoost, .01));
    });

    test('the sprinter surges ahead and pulls its partner along', () {
      final sim = pair()..invulnerableUntil = double.infinity;
      settle(sim);
      expect(sim.sprint(player: 1), isTrue);
      expect(sim.viewing(sim.partner!, () => sim.sprinting), isTrue);
      expect(sim.sprinting, isFalse, reason: 'the lead did not sprint');
      var leadAhead = 0.0, partnerAhead = 0.0;
      for (var i = 0; i < 40; i++) {
        settleHeights(sim);
        step(sim, .02);
        leadAhead = max(leadAhead, sim.lead.x - sim.lead.homeX);
        partnerAhead = max(partnerAhead, sim.partner!.x - sim.partner!.homeX);
      }
      expect(partnerAhead, greaterThan(.1));
      // The rope pulled the lead forward out of its place.
      expect(leadAhead, greaterThan(.02));
      // After the burst both ease back into formation.
      step(sim, 3);
      expect(sim.lead.x, closeTo(sim.lead.homeX, .01));
      expect(sim.partner!.x, closeTo(sim.partner!.homeX, .01));
    });

    test('a sprinting rear bird pushes the front bird ahead of it', () {
      final sim = pair()..invulnerableUntil = double.infinity;
      settle(sim);
      expect(sim.sprint(player: 0), isTrue);
      var pushed = 0.0;
      for (var i = 0; i < 40; i++) {
        settleHeights(sim);
        step(sim, .02);
        pushed = max(pushed, sim.partner!.x - sim.partner!.homeX);
        final dx = sim.partner!.x - sim.lead.x;
        final dy = sim.partner!.y - sim.lead.y;
        expect(sqrt(dx * dx + dy * dy), greaterThan(Tether.contact - 1e-6));
      }
      expect(pushed, greaterThan(.01));
    });

    test('either bird collects stars and either can be hurt', () {
      final sim = pair()..invulnerableUntil = 0;
      settle(sim);
      final partner = sim.partner!;
      sim.stars.add(SkyStar(x: partner.x + .01, y: partner.y));
      settleHeights(sim);
      step(sim, .02);
      expect(sim.collectedStars, 1);
      sim.enemies.add(
        SkyEnemy(x: partner.x + .02, y: partner.y, appearance: 0, maxHp: 10),
      );
      final shield = sim.shield;
      settleHeights(sim);
      step(sim, .02);
      expect(sim.enemies, isEmpty);
      expect(sim.shield, isNot(shield));
    });

    test('gates count once both birds are past', () {
      final sim = pair()..invulnerableUntil = double.infinity;
      settle(sim);
      final gate = Obstacle(
        x: sim.partner!.x - .1,
        center: .55,
        gap: .5,
        target: .55,
        width: .06,
      );
      sim.obstacles.add(gate);
      var scoredWhileBetween = false;
      for (var i = 0; i < 60 && !gate.scored; i++) {
        settleHeights(sim);
        step(sim, .02);
        final end = gate.x + gate.width;
        if (gate.scored && end > sim.lead.x - FlightSimulation.birdRadius) {
          scoredWhileBetween = true;
        }
      }
      expect(gate.scored, isTrue);
      expect(scoredWhileBetween, isFalse);
      expect(sim.gates, 1);
    });

    test('each bird has its own ammo and charge', () {
      final sim = pair()..invulnerableUntil = double.infinity;
      settle(sim);
      expect(sim.shoot(player: 1), isTrue);
      expect(sim.partner!.ammo, lessThan(1));
      expect(sim.lead.ammo, 1);
      expect(sim.startCharge(player: 0), isTrue);
      expect(sim.charging, isTrue);
      expect(sim.viewing(sim.partner!, () => sim.charging), isFalse);
      expect(sim.shots, 1);
      expect(sim.rocks.single.x, greaterThan(sim.partner!.x));
    });

    test('the rope never stretches past its length on a long flight', () {
      final sim = FlightSimulation(
        rules: TapFlyMode(),
        practice: true,
        course: FlightCourse.starTrail,
        coop: CoopMode.roped,
        random: Random(9),
      )..invulnerableUntil = double.infinity;
      final random = Random(2);
      for (var i = 0; i < 3000 && sim.phase != RunPhase.ended; i++) {
        if (sim.phase == RunPhase.playing) {
          if (sim.lead.y > .55 && random.nextDouble() < .3) sim.flap(0);
          if (sim.partner!.y > .45 && random.nextDouble() < .3) sim.flap(1);
          if (random.nextDouble() < .01) sim.sprint(player: random.nextInt(2));
        }
        step(sim, .02);
        final dx = sim.partner!.x - sim.lead.x;
        final dy = sim.partner!.y - sim.lead.y;
        expect(sqrt(dx * dx + dy * dy), lessThan(Tether.length + 1e-6));
        expect(sim.lead.x, inInclusiveRange(.15, .95));
        expect(sim.partner!.x, inInclusiveRange(.15, .95));
      }
      expect(sim.elapsed, greaterThan(20));
    });
  });

  group('no rope', () {
    test('each bird flaps for itself and they can fly far apart', () {
      final sim = pair(coop: CoopMode.free)
        ..invulnerableUntil = double.infinity;
      expect(sim.paired, isTrue);
      expect(sim.roped, isFalse);
      settle(sim, y: .5);
      var apart = 0.0;
      for (var i = 0; i < 40; i++) {
        // Player 1 keeps climbing; player 2 never flaps.
        if (sim.lead.velocity > -.1) sim.flap(0);
        step(sim, .02);
        final dx = sim.partner!.x - sim.lead.x;
        final dy = sim.partner!.y - sim.lead.y;
        apart = max(apart, sqrt(dx * dx + dy * dy));
      }
      expect(apart, greaterThan(Tether.length + .1));
      expect(sim.partner!.flaps, 0);
      expect(sim.ropeSnaps, 0);
    });

    test('a lone flap lifts its own bird as high as a solo flap', () {
      final sim = pair(coop: CoopMode.free)
        ..invulnerableUntil = double.infinity;
      settle(sim, y: .75);
      sim.flap(0);
      var top = sim.lead.y;
      for (var i = 0; i < 60; i++) {
        step(sim, .02);
        top = min(top, sim.lead.y);
      }
      final rules = TapFlyMode();
      final solo = rules.flapImpulse * rules.flapImpulse / (2 * rules.gravity);
      expect(.75 - top, closeTo(solo, .02));
      // Its partner just fell.
      expect(sim.partner!.y, greaterThan(.75));
    });

    test('a sprint surges ahead alone, and the course follows the pair', () {
      final sim = pair(coop: CoopMode.free)
        ..invulnerableUntil = double.infinity;
      settle(sim);
      expect(sim.sprint(player: 1), isTrue);
      var leadMoved = 0.0, partnerAhead = 0.0, peak = 1.0;
      for (var i = 0; i < 40; i++) {
        settleHeights(sim);
        step(sim, .02);
        leadMoved = max(leadMoved, (sim.lead.x - sim.lead.homeX).abs());
        partnerAhead = max(partnerAhead, sim.partner!.x - sim.partner!.homeX);
        peak = max(peak, sim.courseBoost);
      }
      expect(partnerAhead, greaterThan(.15));
      expect(leadMoved, lessThan(1e-9), reason: 'nothing drags the lead');
      expect(peak, closeTo(1 + (Sprint.peakBoost - 1) / 2, .01));
    });

    test('the birds still bump into each other', () {
      final sim = pair(coop: CoopMode.free)
        ..invulnerableUntil = double.infinity;
      settle(sim);
      expect(sim.sprint(player: 0), isTrue);
      var pushed = 0.0;
      for (var i = 0; i < 40; i++) {
        settleHeights(sim);
        step(sim, .02);
        pushed = max(pushed, sim.partner!.x - sim.partner!.homeX);
      }
      expect(pushed, greaterThan(.01));
    });
  });

  group('co-op journal', () {
    ReplayTape record({int seconds = 40, CoopMode coop = CoopMode.roped}) {
      final tape = ReplayTape(
        mode: PlayMode.touch,
        course: FlightCourse.starTrail,
        practice: false,
        seed: 77,
        cycleSeconds: 3,
        bird: 2,
        partner: 3,
        coop: coop,
        reducedMotion: false,
        originMs: 0,
      );
      var now = 0.0;
      final recorder = FlightRecorder(tape, () => now);
      final sim = recorder.simulation;
      final random = Random(5);
      for (var i = 0; i < seconds * 50 && sim.phase != RunPhase.ended; i++) {
        now += 20;
        if (sim.phase == RunPhase.playing) {
          if (sim.lead.y > .55 && random.nextDouble() < .3) {
            recorder.command('flap', null, 0);
          }
          if (sim.partner!.y > .5 && random.nextDouble() < .3) {
            recorder.command('flap', null, 1);
          }
          if (random.nextDouble() < .02) {
            recorder.command('sprint', null, random.nextInt(2));
          }
          if (random.nextDouble() < .05) {
            recorder.command('shoot', null, random.nextInt(2));
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
      return tape;
    }

    for (final coop in CoopMode.values) {
      test('replays ${coop.title} exactly from its JSON', () {
        final tape = record(coop: coop);
        final live = tape.createSimulation();
        for (final event in tape.events) {
          applyReplayEvent(live, event);
        }
        final json =
            jsonDecode(jsonEncode(tape.toJson())) as Map<String, dynamic>;
        expect(json['partner'], 3);
        expect(json['coop'], coop.name);
        final loaded = ReplayTape.fromJson(json);
        expect(loaded.partner, 3);
        expect(loaded.coop, coop);
        final player = ReplayPlayer(loaded)..seek(loaded.durationMs);
        final replayed = player.simulation;
        expect(replayed.paired, isTrue);
        expect(replayed.coop, coop);
        expect(replayed.score, live.score);
        expect(replayed.flaps, live.flaps);
        expect(replayed.shots, live.shots);
        expect(replayed.sprints, live.sprints);
        expect(replayed.lead.y, live.lead.y);
        expect(replayed.partner!.x, live.partner!.x);
        expect(replayed.partner!.flaps, live.partner!.flaps);
        expect(live.partner!.flaps, greaterThan(0));
        expect(live.sprints, greaterThan(0));
      });
    }

    test('a co-op journal without a mode flies roped', () {
      final json = record(seconds: 5).toJson()..remove('coop');
      expect(ReplayTape.fromJson(json).coop, CoopMode.roped);
      final bad = record(seconds: 5).toJson()..['coop'] = 'bungee';
      expect(() => ReplayTape.fromJson(bad), throwsFormatException);
    });

    test('a solo journal refuses co-op events and a partner', () {
      final solo = record().toJson()
        ..remove('partner')
        ..['events'] = [
          [0, 'flap', 1],
        ];
      expect(() => ReplayTape.fromJson(solo), throwsFormatException);
      final old = record().toJson()..['version'] = 41;
      final loaded = ReplayTape.fromJson(old..['events'] = <List<dynamic>>[]);
      expect(loaded.partner, isNull, reason: 'partners start at rules 42');
      final bad = record().toJson()..['partner'] = 7;
      expect(() => ReplayTape.fromJson(bad), throwsFormatException);
    });
  });
}

/// Holds both birds at their current heights, so a test of the formation
/// never drifts into the ground.
void settleHeights(FlightSimulation sim) {
  for (final bird in sim.flock) {
    bird
      ..y = .55
      ..velocity = 0;
  }
}
