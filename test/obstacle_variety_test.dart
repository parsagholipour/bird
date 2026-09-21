import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/session_replay.dart';
import 'replay_highlights_test.dart' show recordRoute;
import 'endless_flight_test.dart' show step;

void main() {
  test('version 12 keeps its original seeded obstacles and results', () {
    final tape = recordRoute(
      FlightCourse.starTrail,
      seconds: 180,
      rulesVersion: 12,
    );
    final player = ReplayPlayer(tape)..seek(95000);
    final s = player.simulation;
    expect([s.score, s.gates, s.collectedStars], [320, 24, 72]);
    expect(s.distance, closeTo(27.574597816167895, 1e-10));
    expect(s.obstacles.map((o) => o.kind), [
      ObstacleKind.garden,
      ObstacleKind.petalGate,
    ]);
    expect(s.obstacles.first.x, closeTo(.20158604862211701, 1e-10));
    expect(s.obstacles.last.phaseOffset, closeTo(6.069639914947585, 1e-10));
    expect(s.obstacles.every((o) => o.appearance == 0), isTrue);
  });

  for (final kind in [ObstacleKind.lanternDrift, ObstacleKind.sunWheels]) {
    test(
      '$kind collides with visible circles and permits open-sky bypasses',
      () {
        for (final y in [.15, .275, .5, .725, .85]) {
          final sim =
              FlightSimulation(
                  rules: PushUpFlightMode(cycleSeconds: 3),
                  practice: false,
                )
                ..phase = RunPhase.playing
                ..started = true;
          final o = Obstacle(
            x: FlightSimulation.birdX - kind.width / 2,
            center: .5,
            gap: .26,
            width: kind.width,
            kind: kind,
            phaseOffset: pi / 2,
          );
          sim.obstacles.add(o);
          step(sim, 20, y: y);
          expect(
            sim.endReason,
            (y == .275 || y == .725) ? EndReason.collision : isNull,
          );
          expect(
            o.passages,
            isEmpty,
            reason: 'Floating hazards have no invisible tower',
          );
        }
      },
    );

    test('$kind blocks rocks on its body, with no wall across its opening', () {
      final sim =
          FlightSimulation(
              rules: TapFlyMode(),
              practice: false,
              course: FlightCourse.starTrail,
            )
            ..phase = RunPhase.playing
            ..started = true;
      final o = Obstacle(
        x: .9,
        center: .5,
        gap: .3,
        width: kind.width,
        kind: kind,
        phaseOffset: pi / 2,
      );
      sim.obstacles.add(o);
      final blocked = BirdRock(x: .85, y: o.orbs.first.y);
      final through = BirdRock(x: .85, y: .5);
      sim.rocks.addAll([blocked, through]);
      step(sim, 200, dt: .2);
      expect(sim.rocks, isNot(contains(blocked)));
      expect(sim.rocks, contains(through));
    });

    test(
      '$kind motion is bounded by the scoring width and freezes with practice',
      () {
        final sim =
            FlightSimulation(
                rules: PushUpFlightMode(cycleSeconds: 3),
                practice: true,
              )
              ..phase = RunPhase.playing
              ..started = true;
        final o = Obstacle(
          x: 1.5,
          center: .5,
          gap: .4,
          width: kind.width,
          kind: kind,
          amplitude: .065,
        );
        sim.obstacles.add(o);
        for (var frame = 0; frame < 360; frame++) {
          step(sim, (frame + 1) * 20.0, y: .5);
          for (final orb in o.orbs) {
            expect(orb.x - orb.radius, greaterThanOrEqualTo(o.x));
            expect(orb.x + orb.radius, lessThanOrEqualTo(o.x + o.width));
          }
        }
        final before = o.orbs.map((b) => [b.x, b.y, b.radius]).toList();
        sim.takeBreak();
        sim.tick(.4, 8000);
        expect(o.orbs.map((b) => [b.x, b.y, b.radius]), before);
      },
    );
  }

  test(
    'crystal steps have three contiguous collision columns with distinct motion',
    () {
      final o = Obstacle(
        x: 1,
        center: .5,
        gap: .36,
        width: .30,
        kind: ObstacleKind.crystalSteps,
        amplitude: .065,
      );
      final before = o.passages.map((p) => p.center).toList();
      expect(before.toSet(), hasLength(3));
      final columns = o.passages.toList();
      expect(columns.first.x, o.x);
      expect(columns[0].x + columns[0].width, closeTo(columns[1].x, 1e-10));
      expect(
        columns.last.x + columns.last.width,
        closeTo(o.x + o.width, 1e-10),
      );
      o.advance(2);
      expect(o.passages.map((p) => p.center), isNot(equals(before)));
    },
  );

  test(
    'new flights mix all designs and appearances without repeated patterns after warmup',
    () {
      final sim = FlightSimulation(
        rules: PushUpFlightMode(cycleSeconds: 3),
        practice: true,
        course: FlightCourse.cloudCruise,
        random: Random(18),
      );
      final seen = <ObstacleKind>{};
      final appearances = <int>{};
      Obstacle? last;
      for (var frame = 0; frame < 15300; frame++) {
        step(sim, (frame + 1) * 20.0, y: .5);
        final current = sim.obstacles.lastOrNull;
        if (current == null || identical(current, last)) continue;
        if (sim.elapsed >= 18 && last != null) {
          expect(current.kind, isNot(last.kind));
        }
        if (sim.elapsed < 18) expect(current.kind, ObstacleKind.garden);
        seen.add(current.kind);
        appearances.add(current.appearance);
        last = current;
      }
      expect(seen, ObstacleKind.values.toSet());
      expect(appearances, {0, 1, 2});
    },
  );
}
