import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/tracking.dart';

import 'ny_arena.dart';
import 'steam_bot.dart';

/// The fairness proof of the steam geysers (`reports/03-steam-geysers/proof/
/// steam_reach.py`, ported with the domain's own cycle and lift functions):
/// can a bird that taps at most 2.5 or 3 times a second, reacting 0.5 or
/// 0.7 s after a hiss begins, always clear a hop vent laid by the layout
/// rules, from every state it can leave the gate before it in?
///
/// Same physics as TapFlyMode (gravity 1.1, flap -0.54, bird radius 0.038,
/// bird x 0.47, 60 Hz input frames on a 120 Hz step). The hit box runs from
/// the plume's top to the bottom of the screen, which is at least as big as
/// the vent's mouth, so the proof is the stronger one.
///
/// Then the same claim through the real simulation: a tap-limited player who
/// reacts to the hiss, flying Steam Alley's layout over many seeds.

const _g = 1.1, _flap = -.54, _r = FlightSimulation.birdRadius;
const _hit = SteamCycle.hitHalfWidth, _liftHalf = SteamCycle.liftHalfWidth;

/// One flight past one vent: [x0] ahead of the bird at t = 0, plume top
/// [top], a burst starting at route second [burstAt]. [target] is where the
/// player wants to be at time t (null: no wish).
bool clears({
  required double y0,
  required double v0,
  required double speed,
  required double x0,
  required double top,
  required double burstAt,
  required double? Function(double t, double burstAt) target,
  required double tapsPerSecond,
}) {
  const dt = 1 / 120;
  var y = y0, v = v0, t = 0.0, last = -9.0;
  var step = 0;
  while (t < x0 / speed + 1.0) {
    if (step.isEven) {
      // 60 Hz input frames.
      final want = target(t, burstAt);
      if (want != null &&
          t - last >= 1 / tapsPerSecond - 1e-9 &&
          y > want &&
          v > -.25) {
        v = _flap;
        last = t;
      }
    }
    step++;
    t += dt;
    v += _g * dt;
    y += v * dt;
    if (y - _r <= 0 || y + _r >= 1) return false; // the edge counts as a fail
    final dx = x0 - speed * t;
    final plume = SteamCycle.plume(t, burstAt);
    final plumeTop = 1 - (1 - top) * plume;
    if (plumeTop < 1) {
      // A circle against the column rectangle.
      final px = (-dx).clamp(-_hit, _hit);
      final py = y.clamp(plumeTop, 1.0);
      if ((-dx - px) * (-dx - px) + (y - py) * (y - py) <= _r * _r) {
        return false;
      }
    }
    final env = SteamCycle.lift(t, burstAt);
    if (env > 0 && dx.abs() <= _liftHalf) {
      final lift = SteamCycle.liftFor(env, y, top);
      if (lift > 0 && v > -lift) v = lift == 0 ? v : -lift;
    }
  }
  return true;
}

/// A hop vent [d1] after the back edge of the gate before it: the bird leaves
/// the gate anywhere in its gap at any vertical speed, idles at the gate's
/// height and only starts climbing [react] seconds after the hiss begins.
/// Returns (scalded starts, starts).
(int, int) hopAfterGate({
  required double speed,
  required double d1,
  required double Function(double centre) topFor,
  required double react,
  required double taps,
  double laneOff = .10,
}) {
  var failed = 0, total = 0;
  for (final c in const [.28, .36, .45, .55, .65, .72]) {
    final top = topFor(c);
    final burstAt = d1 / speed - SteamCycle.hopArrival;
    double? policy(double t, double b0) =>
        t >= b0 - SteamCycle.hiss + react ? top - laneOff : c;
    for (var i = 0; i < 29; i++) {
      for (final v0 in const [-.4, -.2, 0.0, .3, .6]) {
        total++;
        if (!clears(
          y0: c - .14 + i * .01,
          v0: v0,
          speed: speed,
          x0: d1,
          top: top,
          burstAt: burstAt,
          target: policy,
          tapsPerSecond: taps,
        )) {
          failed++;
        }
      }
    }
  }
  return (failed, total);
}

/// The layout rule's tallest plume for a previous gate centred on [c]: the
/// top never stands above the floor (.42) nor above `c - .22`.
double ruleTop(double c) => c - SteamCycle.hopBehind > SteamCycle.stubFloor
    ? c - SteamCycle.hopBehind
    : SteamCycle.stubFloor;

void main() {
  group('the proof, ported', () {
    // Wheels (the widest gate) and garden gates before the vent, at the
    // fastest (0.48) and slowest (0.43) speeds a level flies.
    const rows = [
      ('wheels, fast', .695, .4835),
      ('garden, fast', .855, .4835),
      ('wheels, slow', .695, .4332),
    ];
    for (final (label, d1, speed) in rows) {
      for (final react in [.5, .7]) {
        for (final taps in [2.5, 3.0]) {
          test('$label, react $react s, $taps taps/s: never scalded', () {
            final (failed, total) = hopAfterGate(
              speed: speed,
              d1: d1,
              topFor: ruleTop,
              react: react,
              taps: taps,
            );
            expect(total, 870);
            expect(failed, 0, reason: '$failed of $total starts scalded');
          });
        }
      }
    }

    test('without the rule the proof has teeth: tall hops scald', () {
      // Every hop stands as tall as a plume may (T = .40), whatever gate
      // came before it.
      var scalded = 0;
      for (final (_, d1, speed) in rows.take(2)) {
        final (failed, _) = hopAfterGate(
          speed: speed,
          d1: d1,
          topFor: (c) => .40,
          react: .7,
          taps: 3,
        );
        expect(failed, greaterThan(0));
        scalded += failed;
      }
      expect(scalded, greaterThan(10));
    });

    test('a bird that never reacts is scalded', () {
      var scalded = 0;
      for (final c in const [.36, .55, .72]) {
        final top = ruleTop(c);
        final burstAt = .855 / .4332 - SteamCycle.hopArrival;
        final ok = clears(
          y0: c,
          v0: 0,
          speed: .4332,
          x0: .855,
          top: top,
          burstAt: burstAt,
          target: (t, b0) => c,
          tapsPerSecond: 3,
        );
        if (!ok) scalded++;
      }
      expect(scalded, greaterThan(0));
    });

    test('the layout never stands a plume taller than the proof assumed', () {
      // The real top of any hop vent is at least the proof's worst case.
      for (var c = .28; c <= .72 + 1e-9; c += .02) {
        for (var prev = .28; prev <= .72 + 1e-9; prev += .02) {
          for (var k = 0; k < 12; k++) {
            expect(
              SteamCycle.hopTop(c, prev, k),
              greaterThanOrEqualTo(ruleTop(prev) - 1e-12),
              reason: 'c $c prev $prev k $k',
            );
          }
        }
      }
    });

    test('with the real tops, every centre and stub, nobody is scalded', () {
      // The proof with the layout's own tops for slot centres in the gate
      // band, for the first hops (stubs) and the tallest later ones.
      var total = 0, failed = 0;
      for (final k in const [0, 1, 3, 8]) {
        for (final centre in const [.30, .45, .60, .70]) {
          final (f, t) = hopAfterGate(
            speed: .4835,
            d1: .695,
            topFor: (prev) => SteamCycle.hopTop(centre, prev, k),
            react: .7,
            taps: 3,
          );
          total += t;
          failed += f;
        }
      }
      expect(total, 870 * 16);
      expect(failed, 0);
    });
  });

  group('through the simulation', () {
    LevelPlan alley(int seed) => rulesPlan(
      id: '3-3',
      length: 80,
      start: 100,
      seed: seed,
      lineup: const [],
      steam: SteamPlan.steady,
      marks: const StarMarks(55, 90),
    );

    for (final (react, taps) in const [
      (.5, 2.5),
      (.5, 3.0),
      (.7, 2.5),
      (.7, 3.0),
    ]) {
      test(
        'a player tapping $taps a second, reacting at $react s, never meets a plume',
        () {
          var touched = 0, scalds = 0, cleared = 0, hops = 0;
          for (var seed = 3100; seed < 3130; seed++) {
            final sim = arenaOf(alley(seed));
            final vents = <SteamVent>{};
            _fly(sim, react, taps, vents);
            expect(sim.endReason, EndReason.completed, reason: 'seed $seed');
            scalds += sim.steamScalds;
            cleared += sim.steamClears;
            hops += sim.route!.geysers
                .where((g) => g.kind == SteamKind.hop)
                .length;
            // The hit box itself, recovery or not: no hop vent was touched.
            touched += vents
                .where((v) => v.kind == SteamKind.hop && v.touched)
                .length;
          }
          expect(touched, 0, reason: 'touched $touched hop vents in 30 levels');
          expect(scalds, 0);
          expect(cleared, hops, reason: 'every hop vent cleared: +1 each');
        },
      );
    }

    test(
      'the proof has teeth in the simulation: a bird that ignores the hiss is scalded',
      () {
        var touched = 0;
        for (var seed = 3100; seed < 3130; seed++) {
          final sim = arenaOf(alley(seed));
          final vents = <SteamVent>{};
          // Never reacts: the react time is longer than any hiss lasts.
          _fly(sim, 99, 3, vents);
          touched += vents
              .where((v) => v.kind == SteamKind.hop && v.touched)
              .length;
        }
        expect(touched, greaterThan(10));
      },
    );
  });
}

/// Flies [sim] with [steamTapper] to its end; hearts are topped up so other
/// hazards cannot end the flight, and nothing else touches the bird.
void _fly(
  FlightSimulation sim,
  double react,
  double taps,
  Set<SteamVent> vents,
) {
  var now = 0.0;
  for (var i = 0; i < 200 * 50 && sim.phase != RunPhase.ended; i++) {
    now += 20;
    if (sim.hearts < 3) sim.hearts = 3;
    sim.apply(
      MovementInput(
        valid: true,
        height: .5,
        flap: steamTapper(sim, react: react, taps: taps),
      ),
      TrackingSample(
        mode: PlayMode.touch,
        timestampMs: now,
        receivedMs: now,
        joints: const [],
      ),
      now,
    );
    sim.tick(.02, now);
    vents.addAll(sim.steamVents);
  }
}
