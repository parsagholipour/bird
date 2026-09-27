import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/replay_highlights.dart';
import 'package:push_up_bird/domain/session_replay.dart';
import 'package:push_up_bird/domain/tracking.dart';
import 'package:push_up_bird/game/bird_game.dart';
import 'package:push_up_bird/game/combat_audio_cues.dart';
import 'boss_fight_test.dart' show step, snapshot;
import 'power_shot_test.dart' show flight;
import 'recorded_flight.dart';
import 'sprint_test.dart' show fly;

const birdX = FlightSimulation.birdX;

/// A cleared touch flight with the first run laid just off screen.
FlightSimulation laid({
  RushPathKind kind = RushPathKind.wildfire,
  double at = Rush.firstAt,
}) {
  final sim = flight(practice: true);
  sim.rushKinds
    ..clear()
    ..add(kind);
  sim.elapsed = at;
  step(sim);
  sim.obstacles.removeWhere((o) => !o.rubble);
  return sim;
}

double birdWorld(FlightSimulation sim) => sim.distance + birdX;

/// Holds the bird on the ring route, the line a perfect player flies.
void ride(
  FlightSimulation sim,
  double seconds, {
  bool Function()? until,
  void Function()? each,
}) {
  for (var i = 0; i < (seconds / .02).round(); i++) {
    if (until?.call() ?? false) return;
    if (sim.rushPath case final path?) sim.birdY = path.routeY(birdWorld(sim));
    sim.velocity = 0;
    step(sim);
    each?.call();
  }
}

/// Records 50 seconds of seeded autopilot flight through one run, checks
/// that replay seeks reproduce it and its highlight, and returns its kind.
RushPathKind replaysExactly(int seed) {
  var now = 0.0;
  final recorder = FlightRecorder(
    ReplayTape(
      mode: PlayMode.touch,
      course: FlightCourse.starTrail,
      practice: true,
      seed: seed,
      cycleSeconds: 3,
      bird: 0,
      reducedMotion: false,
      originMs: 0,
    ),
    () => now,
  );
  final sim = recorder.simulation;
  Object state(FlightSimulation s) => [
    snapshot(s),
    s.distance,
    s.courseBoost,
    s.ringSprints,
    s.ringChain,
    s.smashes,
    s.meteorsSmashed,
    s.ventsErupted,
    s.swarmSmashed,
    s.rushPathsRun,
    s.rushPathsEscaped,
    s.rushKinds.toList(),
    s.rushPath?.phase,
    s.rushPath?.fireDistance,
    s.sprintRings.map((r) => [r.x, r.collected]).toList(),
    s.meteors.map((m) => [m.x, m.y]).toList(),
    s.lavaVents.map((v) => [v.x, v.rumbledAt, v.eruptedAt]).toList(),
    s.swarm.map((b) => [b.x, b.y]).toList(),
    s.obstacles.map((o) => [o.x, o.hit, o.smashed]).toList(),
  ];
  final checkpoints = <double, Object>{};
  for (var frame = 1; frame <= 1000; frame++) {
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
    recorder.tick(.05, now, 2.2);
    if (frame % 100 == 0) checkpoints[now] = state(sim);
  }
  expect(sim.rushPathsEscaped, 1, reason: 'seed $seed');
  expect(sim.ringSprints, greaterThanOrEqualTo(3), reason: 'seed $seed');
  final tape = ReplayTape.fromJson(recorder.tape.toJson());
  final replay = ReplayPlayer(tape);
  for (final time in [50000.0, 30000.0, 35000.0, 10000.0, 50000.0]) {
    replay.seek(time);
    expect(state(replay.simulation), checkpoints[time], reason: 'seed $seed');
  }
  final rush = buildReplayHighlights(
    tape,
  ).where((m) => m.kind == ReplayMomentKind.rush);
  expect(rush, hasLength(1));
  expect(rush.single.title, sim.lastRushKind!.escape);
  return sim.lastRushKind!;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('rush paths belong to current touch Star Trail flights only', () {
    expect(flight().supportsRushPaths, isTrue);
    expect(flight(version: 31).supportsRushPaths, isFalse);
    for (final rules in [JumpFlyMode(), PushUpFlightMode(cycleSeconds: 3)]) {
      expect(
        FlightSimulation(
          rules: rules,
          practice: true,
          course: FlightCourse.starTrail,
        ).supportsRushPaths,
        isFalse,
      );
    }
    expect(
      FlightSimulation(
        rules: TapFlyMode(),
        practice: true,
        course: FlightCourse.classic,
      ).supportsRushPaths,
      isFalse,
    );
    final old = flight(version: 31, practice: true)
      ..invulnerableUntil = double.infinity;
    old.elapsed = Rush.firstAt;
    fly(old, 6);
    expect(old.rushPath, isNull);
    expect(old.sprintRings, isEmpty);
    expect(old.obstacles.where((o) => o.rubble), isEmpty);
  });

  test('each round runs every kind once, in a seeded order, never twice '
      'in a row', () {
    final openers = <RushPathKind>{};
    for (var seed = 0; seed < 12; seed++) {
      final random = Random(seed), bag = <RushPathKind>[];
      final drawn = <RushPathKind>[];
      for (var i = 0; i < 10 * RushPathKind.values.length; i++) {
        final kind = Rush.nextKind(bag, random, drawn.lastOrNull);
        if (drawn.isNotEmpty) expect(kind, isNot(drawn.last));
        drawn.add(kind);
      }
      for (var i = 0; i < drawn.length; i += RushPathKind.values.length) {
        expect(
          drawn.sublist(i, i + RushPathKind.values.length),
          unorderedEquals(RushPathKind.values),
        );
      }
      openers.add(drawn.first);
    }
    expect(openers.length, greaterThan(2), reason: 'Flights open differently');

    final sim = flight(practice: true);
    sim.elapsed = Rush.firstAt;
    step(sim);
    expect(sim.rushPath!.kind, sim.lastRushKind);
    expect(sim.rushKinds, hasLength(RushPathKind.values.length - 1));
    expect(sim.rushKinds, isNot(contains(sim.lastRushKind)));
  });

  test('a run lays rings, bats and rubble on one route and holds spawns', () {
    for (final kind in RushPathKind.values) {
      final sim = laid(kind: kind);
      final path = sim.rushPath!;
      expect(path.kind, kind);
      expect(sim.lastRushKind, kind);
      expect(path.number, 1);
      expect(path.phase, RushPhase.approach);
      expect(sim.rushPathsRun, 1);
      final rings = sim.sprintRings, rubble = sim.obstacles;
      expect(rings, hasLength(Rush.beats));
      expect(rubble, hasLength(Rush.beats));
      expect(path.heights, hasLength(Rush.beats + 1));
      expect(rings.first.x, greaterThan(2.2), reason: 'Laid off screen');
      for (var i = 0; i < Rush.beats; i++) {
        final h = path.heights[i], next = path.heights[i + 1];
        expect(h, inInclusiveRange(.24, .76));
        expect((next - h).abs(), lessThanOrEqualTo(.32 + 1e-9));
        expect(rings[i].y, h);
        expect(path.routeY(sim.distance + rings[i].x), closeTo(h, 1e-9));
        // The barrier after each ring opens at the next ring's height.
        expect(rubble[i].center, next);
        expect(rubble[i].gap, Rush.barrierGap);
        expect(rubble[i].x - rings[i].x, closeTo(.34, 1e-9));
        expect(rubble[i].appearance ~/ 3, kind.index);
        expect(path.routeY(sim.distance + rubble[i].x), closeTo(next, 1e-9));
        // Bats bob a little around the route.
        final bats = sim.enemies.where(
          (e) => (e.x - rings[i].x - .2).abs() < 1e-9 && (e.y - h).abs() < .02,
        );
        expect(bats, hasLength(i.isOdd ? 1 : 0));
      }
      // Every beat after the first has a vent among its stars.
      if (kind == RushPathKind.eruption) {
        expect(sim.lavaVents, hasLength(Rush.beats - 1));
        for (var i = 1; i < Rush.beats; i++) {
          final vent = sim.lavaVents[i - 1];
          expect(vent.x - rings[i].x, closeTo(Rush.ventAt - Rush.ringAt, 1e-9));
          expect(
            vent.top,
            max(path.heights[i] - Rush.ventOver, Rush.ventCeiling),
          );
          expect(vent.rumbledAt, isNull);
        }
      } else {
        expect(sim.lavaVents, isEmpty);
      }
      expect(sim.swarm, isEmpty, reason: 'Flocks fly once the run starts');
      fly(sim, 3, y: path.heights.first);
      expect(sim.obstacles.where((o) => !o.rubble), isEmpty);
    }
  });

  test('ring sprints surge to 3x and a chain never dips', () {
    expect(RingSprint.envelope(0, 2), 0);
    expect(RingSprint.envelope(RingSprint.surgeSeconds, 1), 1);
    expect(
      RingSprint.envelope(1, RingSprint.easeSeconds / 2),
      closeTo(.5, 1e-9),
    );
    expect(RingSprint.envelope(1, 0), 0);
    expect(RingSprint.envelope(double.nan, 1), 0);
    for (final level in [0.0, .2, .5, .9, 1.0]) {
      expect(
        RingSprint.envelope(RingSprint.surgeAgeFor(level), 1),
        closeTo(level, 1e-9),
      );
    }

    final sim = flight(practice: true)..invulnerableUntil = double.infinity;
    void ring() => sim.sprintRings.add(SprintRing(x: birdX, y: .5));
    ring();
    fly(sim, .02);
    expect(sim.ringSprinting, isTrue);
    expect(sim.ramming, isTrue);
    expect(sim.ringChain, 1);
    fly(sim, .04);
    final surging = sim.courseBoost;
    expect(surging, inExclusiveRange(1, RingSprint.peakBoost));
    ring();
    fly(sim, .02);
    expect(sim.ringChain, 2);
    expect(sim.courseBoost, greaterThan(surging));
    fly(sim, .5);
    expect(sim.courseBoost, RingSprint.peakBoost);
    while (sim.courseBoost > RingSprint.peakBoost - .6) {
      fly(sim, .02);
    }
    final easing = sim.courseBoost;
    ring();
    fly(sim, .02);
    expect(sim.ringChain, 3);
    expect(sim.courseBoost, greaterThan(easing));
    fly(sim, RingSprint.seconds + .04);
    expect(sim.ringSprinting, isFalse);
    expect(sim.courseBoost, 1);
    ring();
    fly(sim, .02);
    expect(sim.ringChain, 1, reason: 'A chain ends with its sprint');
    expect(sim.sprints, 0, reason: 'Rings never use the button sprint');
  });

  test('a ring sprint smashes walls, rubble, bats and meteors unhurt', () {
    final sim = flight(practice: true)
      ..invulnerableUntil = double.negativeInfinity;
    final hearts = sim.hearts, shield = sim.shield;
    sim.sprintRings.add(SprintRing(x: birdX, y: .5));
    fly(sim, .1);
    final score = sim.score;
    final wall = Obstacle(x: birdX + .1, center: .15, gap: .2);
    final rubble = Obstacle(
      x: birdX + .45,
      center: .5,
      gap: Rush.barrierGap,
      width: Rush.barrierWidth,
      rubble: true,
    );
    final bat = SkyEnemy(x: birdX + .75, y: .5);
    final meteor = Meteor(x: birdX + 1, y: .5, vx: 0, vy: 0, aimed: true);
    sim.obstacles.addAll([wall, rubble]);
    sim.enemies.add(bat);
    sim.meteors.add(meteor);
    fly(sim, 1);
    expect(sim.ringSprinting, isTrue);
    expect(wall.smashed, isTrue);
    expect(wall.hit, isFalse);
    expect(rubble.smashed, isTrue, reason: 'Even flown through its opening');
    expect(sim.enemies, isNot(contains(bat)));
    expect(sim.meteors, isEmpty);
    expect(sim.smashes, 2);
    expect(sim.meteorsSmashed, 1);
    expect(sim.smashChain, 4);
    expect(
      sim.events
          .where(
            (e) =>
                e.kind == FlightEventKind.smashed ||
                e.kind == FlightEventKind.meteorSmashed,
          )
          .map((e) => e.value),
      [1, 2, 4],
    );
    expect(
      sim.score,
      greaterThanOrEqualTo(score + 2 * Rush.smashPoints + Rush.meteorPoints),
    );
    expect((sim.hearts, sim.shield), (hearts, shield));
  });

  test(
    'without a ring sprint, walls stand; without any sprint rubble hurts',
    () {
      final sim = flight(practice: true)
        ..invulnerableUntil = double.negativeInfinity;
      expect(sim.sprint(), isTrue);
      fly(sim, .1);
      final rubble = Obstacle(
        x: birdX + .1,
        center: .85,
        gap: .2,
        width: Rush.barrierWidth,
        rubble: true,
      );
      sim.obstacles.add(rubble);
      fly(sim, .3);
      expect(rubble.smashed, isTrue, reason: 'Any sprint breaks rubble');
      final wall = Obstacle(x: birdX + .1, center: .15, gap: .2);
      sim.obstacles.add(wall);
      fly(sim, .3);
      expect(wall.smashed, isFalse);
      expect(wall.hit, isTrue, reason: 'The button sprint is not a shield');

      final slow = flight(practice: true)
        ..invulnerableUntil = double.negativeInfinity;
      final stone = Obstacle(
        x: birdX + .1,
        center: .85,
        gap: .2,
        width: Rush.barrierWidth,
        rubble: true,
      );
      slow.obstacles.add(stone);
      fly(slow, .5);
      expect(stone.smashed, isFalse);
      expect(stone.hit, isTrue);
      final hurt = (slow.hearts, slow.shield);
      slow.invulnerableUntil = double.negativeInfinity;
      slow.meteors.add(Meteor(x: birdX + .1, y: .5, vx: 0, vy: 0, aimed: true));
      fly(slow, .5);
      expect(slow.meteors, isEmpty);
      expect(slow.meteorsSmashed, 0);
      expect((slow.hearts, slow.shield), isNot(hurt));
    },
  );

  test(
    'the wildfire catches a slow bird, knocks back and trails a fast one',
    () {
      final sim = laid()..invulnerableUntil = double.negativeInfinity;
      sim.sprintRings.clear();
      sim.enemies.clear();
      final path = sim.rushPath!;
      final seen = <FlightEvent>{};
      void collect() => seen.addAll(sim.events);
      Iterable<FlightEventKind> events() => seen.map((e) => e.kind);
      ride(sim, 8, until: () => path.phase == RushPhase.running, each: collect);
      expect(events(), contains(FlightEventKind.rushWarning));
      expect(sim.rushWarnings, 1);
      expect(
        birdWorld(sim) - path.fireDistance,
        closeTo(Rush.fireStartGap, .03),
      );
      final started = sim.elapsed;
      ride(sim, 8, until: () => path.catches > 0, each: collect);
      expect(path.catches, 1);
      final closing = sim.speed * (Rush.fireChase - 1);
      expect(
        sim.elapsed - started,
        closeTo(
          (Rush.fireStartGap - FlightSimulation.birdRadius) / closing,
          .2,
        ),
      );
      // Knocked off screen, beyond where a ring sprint would drag it.
      expect(
        birdWorld(sim) - path.fireDistance,
        closeTo(Rush.fireKnockback, .005),
      );
      expect(Rush.fireKnockback, greaterThan(Rush.fireMaxGap));
      expect(path.hurt, isTrue);
      expect(events(), contains(FlightEventKind.scorched));

      sim.sprintRings.add(SprintRing(x: birdX, y: sim.birdY));
      ride(sim, .02);
      expect(sim.ringSprinting, isTrue);
      for (var i = 0; i < 60; i++) {
        ride(sim, .02);
        final gap = birdWorld(sim) - path.fireDistance;
        expect(gap, lessThanOrEqualTo(Rush.fireMaxGap + 1e-9));
        // Once the surge outpaces the fire, it trails at the screen's edge.
        if (sim.elapsed - sim.ringSprintFrom > RingSprint.surgeSeconds + .1) {
          expect(gap, closeTo(Rush.fireMaxGap, 1e-9));
        }
      }
      ride(sim, RingSprint.seconds, until: () => !sim.ringSprinting);
      final left = birdWorld(sim) - path.fireDistance;
      ride(sim, 1);
      expect(birdWorld(sim) - path.fireDistance, lessThan(left));
      expect(path.catches, 1);
    },
  );

  test(
    'a perfect run chains every ring, smashes every barrier and escapes',
    () {
      final sim = laid()..invulnerableUntil = double.negativeInfinity;
      final path = sim.rushPath!;
      final lastBarrier = sim.obstacles.last;
      final hearts = (sim.hearts, sim.shield);
      double? firstRing, lastRing;
      var slowest = double.infinity;
      RushPath? escaped;
      FlightEvent? bonus;
      ride(
        sim,
        20,
        until: () => sim.rushPathsEscaped > 0,
        each: () {
          if (sim.ringSprints == 1) firstRing ??= sim.elapsed;
          if (sim.ringSprints == Rush.beats) lastRing ??= sim.elapsed;
          if (firstRing != null &&
              lastRing == null &&
              sim.elapsed > firstRing! + RingSprint.surgeSeconds + .02) {
            slowest = [
              slowest,
              sim.courseBoost,
            ].reduce((a, b) => a < b ? a : b);
          }
        },
      );
      escaped = sim.rushPath;
      bonus = sim.events.lastWhere(
        (e) => e.kind == FlightEventKind.rushEscaped,
      );
      expect(escaped, same(path));
      expect(path.phase, RushPhase.escaped);
      expect(path.rings, Rush.beats);
      expect(sim.ringChain, Rush.beats);
      expect(slowest, RingSprint.peakBoost, reason: 'No dip between rings');
      expect(sim.smashes, Rush.beats);
      expect(sim.obstacles.where((o) => o.rubble && !o.smashed), isEmpty);
      expect(path.hurt, isFalse);
      expect((sim.hearts, sim.shield), hearts);
      expect(path.bonus, Rush.escapeBonus + Rush.flawlessBonus);
      expect(bonus.value, path.bonus);
      expect(sim.rushPathsEscaped, 1);
      // Ordinary passages resume behind the final barrier, never inside it.
      expect(path.resumed, isTrue);
      final resumed = sim.obstacles.where((o) => !o.rubble).toList();
      expect(resumed, isNotEmpty);
      expect(
        resumed.first.x,
        greaterThan(lastBarrier.x + lastBarrier.width + .5),
      );
      fly(sim, Rush.burnOutSeconds + .04, y: sim.birdY);
      expect(sim.rushPath, isNull);
    },
  );

  test('skyfall: sprinting smashes the meteors, cruising gets hit', () {
    final fast = laid(kind: RushPathKind.skyfall)
      ..invulnerableUntil = double.negativeInfinity;
    ride(fast, 20, until: () => fast.rushPathsEscaped > 0);
    final path = fast.rushPath!;
    expect(path.phase, RushPhase.escaped);
    expect(path.meteors, greaterThan(4));
    expect(fast.meteorsSmashed, greaterThanOrEqualTo(2));
    expect(path.hurt, isFalse);

    final slow = laid(kind: RushPathKind.skyfall)
      ..invulnerableUntil = double.negativeInfinity;
    slow.sprintRings.clear();
    slow.enemies.clear();
    final cruise = slow.rushPath!;
    ride(slow, 8, until: () => cruise.phase == RushPhase.running);
    final hearts = (slow.hearts, slow.shield);
    ride(slow, 4, until: () => cruise.hurt);
    expect(cruise.hurt, isTrue, reason: 'Aimed meteors fall on the route');
    expect(slow.meteorsSmashed, 0);
    expect((slow.hearts, slow.shield), isNot(hearts));
  });

  test('eruption: a vent blows as a cruising bird arrives, behind a fast '
      'one', () {
    final fast = laid(kind: RushPathKind.eruption)
      ..invulnerableUntil = double.negativeInfinity;
    final behind = <double>[];
    final seen = <LavaVent>{};
    ride(
      fast,
      20,
      until: () => fast.rushPathsEscaped > 0,
      each: () {
        for (final vent in fast.lavaVents) {
          if (vent.eruptedAt != null && seen.add(vent)) {
            behind.add(birdX - vent.x);
          }
        }
      },
    );
    final path = fast.rushPath!;
    expect(path.phase, RushPhase.escaped);
    expect(fast.ventsErupted, Rush.beats - 1);
    expect(behind, hasLength(Rush.beats - 1));
    for (final gap in behind) {
      // On screen, clear of the bird: the blast goes up right behind it.
      expect(gap, inInclusiveRange(Rush.ventBehind, birdX));
    }
    expect(path.catches, 0);
    expect(path.hurt, isFalse);

    final slow = laid(kind: RushPathKind.eruption)
      ..invulnerableUntil = double.negativeInfinity;
    slow.sprintRings.clear();
    slow.enemies.clear();
    final cruise = slow.rushPath!;
    final first = slow.lavaVents.first;
    final events = <FlightEvent>{};
    ride(
      slow,
      30,
      until: () => cruise.hurt,
      each: () => events.addAll(slow.events),
    );
    expect(cruise.catches, 1, reason: 'The first vent blows under the bird');
    expect(first.eruptedAt, closeTo(first.fuseEndsAt!, .01));
    expect(
      (first.x - birdX).abs(),
      lessThan(LavaVent.width / 2 + FlightSimulation.birdRadius),
    );
    expect(events.map((e) => e.kind), contains(FlightEventKind.scorched));
  });

  test('a bird hopping over a plume is safe; lava ignores sprints', () {
    FlightSimulation over(double y, {bool sprint = false}) {
      final sim = flight(practice: true)
        ..invulnerableUntil = double.negativeInfinity;
      if (sprint) expect(sim.sprint(), isTrue);
      sim.lavaVents.add(
        LavaVent(x: birdX, top: .5)
          ..rumbledAt = sim.elapsed - Rush.ventFuse + .02,
      );
      fly(sim, Rush.plumeSeconds, y: y);
      return sim;
    }

    final clear = .5 - FlightSimulation.birdRadius - .005;
    expect(over(clear).hearts, 3);
    expect(over(clear).shield, isTrue);
    expect(over(.5).shield, isFalse);
    expect(over(.5, sprint: true).shield, isFalse);
    expect(over(.5).ventsErupted, 1);
  });

  test('swarm: flocks stream down the route; a ring sprint plows through', () {
    final fast = laid(kind: RushPathKind.swarm)
      ..invulnerableUntil = double.negativeInfinity;
    final path = fast.rushPath!;
    final lanes = <SwarmBat, double>{};
    var chain = 0;
    ride(
      fast,
      20,
      until: () => fast.rushPathsEscaped > 0,
      each: () {
        for (final bat in fast.swarm) {
          lanes[bat] = bat.lane;
          final world = fast.distance + bat.x;
          expect(bat.y - path.routeY(world) - bat.lane, closeTo(0, .0121));
        }
        chain = max(chain, fast.smashChain);
      },
    );
    expect(path.phase, RushPhase.escaped);
    expect(path.flocks, greaterThanOrEqualTo(4));
    expect(fast.swarmSmashed, greaterThanOrEqualTo(2 * Rush.flockSize));
    expect(chain, greaterThanOrEqualTo(Rush.flockSize));
    expect(path.hurt, isFalse);
    // Flocks alternate between the route and one side of it.
    final byFlock = lanes.values.toList();
    expect(byFlock.first, 0);
    expect(
      byFlock.toSet().difference({0.0, Rush.flockLane, -Rush.flockLane}),
      isEmpty,
    );
    expect(byFlock.where((lane) => lane != 0), isNotEmpty);
    expect(
      fast.score,
      greaterThanOrEqualTo(fast.swarmSmashed * Rush.batPoints),
    );

    final slow = laid(kind: RushPathKind.swarm)
      ..invulnerableUntil = double.negativeInfinity;
    slow.sprintRings.clear();
    slow.enemies.clear();
    final cruise = slow.rushPath!;
    ride(slow, 8, until: () => cruise.phase == RushPhase.running);
    final hearts = (slow.hearts, slow.shield);
    ride(slow, 6, until: () => cruise.hurt);
    expect(cruise.hurt, isTrue, reason: 'Flocks on the route fly into it');
    expect(slow.swarmSmashed, 0);
    expect((slow.hearts, slow.shield), isNot(hearts));
  });

  test('a shot rock downs a swarm bat', () {
    final sim = flight(practice: true);
    final route = RushPath(
      kind: RushPathKind.swarm,
      number: 1,
      startDistance: 0,
      endDistance: 99,
      resumeDistance: 99,
      heights: const [.5, .5],
    );
    sim.swarm.add(
      SwarmBat(x: birdX + .8, y: .5, route: route, lane: 0, phase: 0),
    );
    expect(sim.shoot(), isTrue);
    fly(sim, .6);
    expect(sim.swarm, isEmpty);
    expect(sim.swarmSmashed, 1);
    expect(
      sim.events
          .where((e) => e.kind == FlightEventKind.swarmSmashed)
          .single
          .value,
      0,
    );
  });

  test('a boss waits for a slow run and follows it after a pause', () {
    // About the latest a run can start and still leave the boss its lead.
    const latest = FlightSimulation.bossInterval - Rush.bossLead - .1;
    final sim = laid(at: latest)..invulnerableUntil = double.infinity;
    sim.sprintRings.clear();
    sim.enemies.clear();
    final path = sim.rushPath!;
    ride(sim, 40, until: () => sim.boss != null);
    expect(path.escapedAt, isNotNull);
    expect(path.escapedAt!, greaterThan(FlightSimulation.bossInterval));
    expect(
      sim.elapsed,
      greaterThanOrEqualTo(path.escapedAt! + Rush.bossDelayAfter),
    );
    expect(sim.rushPath, isNull);
  });

  test('every kind of run replays exactly across seeks and becomes a '
      'highlight', () {
    final kinds = <RushPathKind>{};
    for (final seed in [8, 5, 3, 30]) {
      kinds.add(replaysExactly(seed));
    }
    expect(kinds, RushPathKind.values.toSet());
  });

  test('rush audio cues follow rings, smashes, eruptions, alarms and '
      'escapes', () {
    final cues = CombatAudioCues();
    final sim = flight(practice: true);
    expect(cues.advance(sim), isEmpty);
    sim
      ..ringSprints = 1
      ..ringChain = 1;
    expect(cues.advance(sim), ['sprint_ring', 'sprint']);
    sim
      ..ringSprints = 2
      ..ringChain = 2;
    expect(cues.advance(sim), ['sprint_ring']);
    sim.smashes++;
    expect(cues.advance(sim), ['rubble_smash']);
    sim.meteorsSmashed++;
    expect(cues.advance(sim), ['rubble_smash']);
    sim.ventsErupted++;
    expect(cues.advance(sim), ['lava_burst']);
    sim.swarmSmashed++;
    expect(cues.advance(sim), ['enemy_death']);
    sim.rushWarnings++;
    expect(cues.advance(sim), ['rush_alarm']);
    sim.rushPathsEscaped++;
    expect(cues.advance(sim), ['rush_clear']);
    sim
      ..ringSprints = 5
      ..smashes = 9;
    expect(cues.advance(sim, silent: true), isEmpty);
    expect(cues.advance(sim), isEmpty);
  });

  testWidgets('every kind of run renders, with and without Reduced Motion', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.runAsync(
      () => (FontLoader(
        'Fredoka',
      )..addFont(rootBundle.load('assets/fonts/Fredoka.ttf'))).load(),
    );
    Future<List<int>> render(FlightSimulation sim, bool reducedMotion) async {
      final game = BirdGame(
        simulation: sim,
        nowMs: () => 0,
        bird: 0,
        reducedMotion: reducedMotion,
        playback: true,
        onChanged: () {},
      );
      await tester.pumpWidget(GameWidget(game: game));
      late List<int> png;
      await tester.runAsync(() async {
        await game.loaded;
        game.pauseEngine();
        final recorder = ui.PictureRecorder();
        game.render(Canvas(recorder));
        final picture = recorder.endRecording();
        final image = await picture.toImage(800, 360);
        png = (await image.toByteData(
          format: ui.ImageByteFormat.png,
        ))!.buffer.asUint8List();
        image.dispose();
        picture.dispose();
      });
      return png;
    }

    final scenes = <String, FlightSimulation>{};
    // Mid-chain: rings, rubble just smashed and the fire on the left edge.
    final fire = laid()..invulnerableUntil = double.infinity;
    ride(fire, 20, until: () => fire.ringSprints >= 2);
    ride(fire, .3);
    scenes['wildfire'] = fire;
    // Cruising under the skyfall with meteors falling onto the route.
    final sky = laid(kind: RushPathKind.skyfall)
      ..invulnerableUntil = double.infinity;
    sky.sprintRings.removeRange(0, 2);
    ride(
      sky,
      20,
      until: () =>
          sky.rushPath!.phase == RushPhase.running &&
          sky.meteors.where((m) => m.y > .1).length >= 2,
    );
    scenes['skyfall'] = sky;
    // Cruising into a plume, with the next vent rumbling ahead.
    final lava = laid(kind: RushPathKind.eruption)
      ..invulnerableUntil = double.infinity;
    lava.sprintRings.clear();
    ride(
      lava,
      30,
      until: () => lava.lavaVents.any((v) => v.plume(lava.elapsed) >= 1),
    );
    ride(lava, .15);
    scenes['eruption'] = lava;
    // Mid-chain, plowing through a flock with the next one closing in.
    final swarm = laid(kind: RushPathKind.swarm)
      ..invulnerableUntil = double.infinity;
    ride(
      swarm,
      20,
      until: () =>
          swarm.swarmSmashed >= 2 &&
          swarm.swarm.where((b) => b.x < 2.2).length >= 3,
    );
    scenes['swarm'] = swarm;
    // A sprinter sees the plume go up right behind it.
    final blast = laid(kind: RushPathKind.eruption)
      ..invulnerableUntil = double.infinity;
    ride(blast, 20, until: () => blast.ventsErupted >= 2);
    ride(blast, .12);
    scenes['eruption-behind'] = blast;
    final warning = laid(kind: RushPathKind.swarm)
      ..invulnerableUntil = double.infinity;
    ride(warning, 8, until: () => warning.rushWarnings > 0);
    ride(warning, .4);
    scenes['warning'] = warning;
    final escape = laid()..invulnerableUntil = double.infinity;
    ride(escape, 20, until: () => escape.rushPathsEscaped > 0);
    ride(escape, .35);
    scenes['escape'] = escape;

    for (final MapEntry(key: name, value: sim) in scenes.entries) {
      final moving = await render(sim, false);
      final still = await render(sim, true);
      expect(moving.length, greaterThan(2000));
      expect(still.length, greaterThan(2000));
      if (name != 'warning') expect(moving, isNot(still));
      if (const bool.fromEnvironment('CAPTURE_VISUALS')) {
        Directory('build/visual-review').createSync(recursive: true);
        File('build/visual-review/rush-$name.png').writeAsBytesSync(moving);
        File(
          'build/visual-review/rush-$name-reduced.png',
        ).writeAsBytesSync(still);
      }
    }
    expect(tester.takeException(), isNull);
  });
}
