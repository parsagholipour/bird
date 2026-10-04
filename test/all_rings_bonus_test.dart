import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';

import 'boss_fight_test.dart' show step;
import 'power_shot_test.dart' show flight;

/// Rules version 51: collecting every ring of a rush path keeps the last
/// ring sprint going longer, at full boost: [Rush.firstAllRingsBonus]
/// seconds until 57, [Rush.allRingsBonus] from 58.

const birdX = FlightSimulation.birdX;

/// A cleared touch flight with a wildfire run laid just off screen.
FlightSimulation laid(int version) {
  final sim = flight(practice: true, version: version)
    ..invulnerableUntil = double.infinity;
  sim.rushKinds
    ..clear()
    ..add(RushPathKind.wildfire);
  sim.elapsed = Rush.firstAt;
  step(sim);
  sim.obstacles.removeWhere((o) => !o.rubble);
  return sim;
}

/// Flies the run on its ring route, or [missing] the given beat's ring by
/// holding the bird well clear of it, until [until] or the escape.
void ride(
  FlightSimulation sim, {
  int? missing,
  bool Function()? until,
  void Function()? each,
}) {
  for (var i = 0; i < 2000; i++) {
    if (until?.call() ?? false) return;
    final path = sim.rushPath;
    if (path != null) {
      final world = sim.distance + birdX;
      final route = path.routeY(world);
      final beat = ((world - path.startDistance) / Rush.beatLength).floor();
      sim.birdY = beat == missing
          ? (route < .5 ? route + .2 : route - .2)
          : route;
    }
    sim.velocity = 0;
    step(sim);
    each?.call();
  }
  fail('the run never ended');
}

int count(FlightSimulation sim, FlightEventKind kind) =>
    sim.events.where((e) => e.kind == kind).length;

void main() {
  test('51 added the bonus (52, a tougher Neferhoo, 53, growing endless '
      'bosses, 54, King Coo\'s quick fury, and 55, a faster Neferhoo, came '
      'after it), 58 shortened it, and the bonus is touch Star Trail only', () {
    expect(FlightSimulation.allRingsRulesVersion, 51);
    expect(FlightSimulation.currentRulesVersion, greaterThanOrEqualTo(55));
    expect(
      FlightSimulation.allRingsRulesVersion,
      greaterThan(FlightSimulation.neferhooRulesVersion),
    );
    expect(Rush.firstAllRingsBonus, 2.0);
    expect(Rush.allRingsBonus, 1.2);
    expect(FlightSimulation.shorterRingsBonusRulesVersion, 58);
    expect(flight().allRingsBonus, 1.2);
    expect(flight(version: 57).allRingsBonus, 2.0);
    expect(flight(version: 51).allRingsBonus, 2.0);
    expect(flight().supportsAllRingsBonus, isTrue);
    expect(flight(version: 50).supportsAllRingsBonus, isFalse);
    expect(FlightEventKind.values.last, FlightEventKind.allRings);
  });

  for (final (version, bonusSeconds) in [
    (FlightSimulation.currentRulesVersion, Rush.allRingsBonus),
    (FlightSimulation.shorterRingsBonusRulesVersion - 1, 2.0),
  ]) {
    test('every ring adds $bonusSeconds seconds of full boost to the last '
        'ring sprint, rules $version', () {
      final sim = laid(version);
      final path = sim.rushPath!;
      ride(sim, until: () => sim.rushPathsEscaped > 0);
      expect(path.rings, Rush.beats);
      expect(count(sim, FlightEventKind.allRings), 1);
      final bonus = sim.events.lastWhere(
        (e) => e.kind == FlightEventKind.allRings,
      );
      final lastRing = sim.events.lastWhere(
        (e) => e.kind == FlightEventKind.sprintRing,
      );
      // In tenths of a second.
      expect(bonus.value, (bonusSeconds * 10).round());
      expect(sim.allRingsAt, bonus.at);
      // It comes with the sixth ring, not before.
      expect(bonus.at, lastRing.at);
      expect(lastRing.value, Rush.beats);
      final lastRingAt = lastRing.at;
      // The last ring sprint lasts its own 2 seconds plus the bonus.
      expect(
        sim.ringSprintUntil - lastRingAt,
        closeTo(RingSprint.seconds + bonusSeconds, 1e-9),
      );
      // Full speed holds until the last half second of the longer sprint.
      final fullUntil =
          lastRingAt +
          RingSprint.seconds +
          bonusSeconds -
          RingSprint.easeSeconds;
      while (sim.elapsed < fullUntil - .02) {
        expect(sim.courseBoost, RingSprint.peakBoost, reason: '${sim.elapsed}');
        expect(sim.allRingsBoosting, isTrue, reason: '${sim.elapsed}');
        sim
          ..birdY = .5
          ..velocity = 0;
        step(sim);
      }
      while (sim.ringSprinting) {
        sim
          ..birdY = .5
          ..velocity = 0;
        step(sim);
      }
      expect(
        sim.elapsed - lastRingAt,
        closeTo(RingSprint.seconds + bonusSeconds, .021),
      );
      expect(sim.courseBoost, 1);
      expect(sim.allRingsBoosting, isFalse);
    });
  }

  test('a missed ring earns no bonus', () {
    for (final missing in [0, 3, Rush.beats - 1]) {
      final sim = laid(FlightSimulation.currentRulesVersion);
      final path = sim.rushPath!;
      ride(sim, missing: missing, until: () => sim.rushPathsEscaped > 0);
      expect(path.rings, Rush.beats - 1, reason: 'beat $missing');
      expect(count(sim, FlightEventKind.allRings), 0, reason: 'beat $missing');
      expect(sim.allRingsAt, double.negativeInfinity, reason: 'beat $missing');
      expect(
        sim.ringSprintUntil -
            (sim.events
                .lastWhere((e) => e.kind == FlightEventKind.sprintRing)
                .at),
        closeTo(RingSprint.seconds, 1e-9),
        reason: 'beat $missing',
      );
    }
  });

  test('rules 50 flies a perfect run exactly as before', () {
    final old = laid(50), now = laid(51);
    expect(old.supportsAllRingsBonus, isFalse);
    var bonusAt = double.infinity;
    final oldPath = old.rushPath!, nowPath = now.rushPath!;
    for (var i = 0; i < 1000 && old.rushPathsEscaped == 0; i++) {
      for (final (sim, path) in [(old, oldPath), (now, nowPath)]) {
        sim
          ..birdY = path.routeY(sim.distance + birdX)
          ..velocity = 0;
        step(sim);
      }
      if (now.ringSprintUntil != old.ringSprintUntil) {
        bonusAt = bonusAt.isFinite ? bonusAt : now.elapsed;
      } else {
        // Frame for frame the same flight until the bonus.
        expect(now.distance, old.distance);
        expect(now.score, old.score);
      }
    }
    expect(oldPath.rings, Rush.beats);
    expect(count(old, FlightEventKind.allRings), 0);
    expect(count(now, FlightEventKind.allRings), 1);
    expect(bonusAt, isNot(double.infinity));
  });

  test('rules 57 flies a perfect run exactly as 58 until the bonus', () {
    final old = laid(57), now = laid(58);
    final oldPath = old.rushPath!, nowPath = now.rushPath!;
    var bonusAt = double.infinity;
    for (var i = 0; i < 1000 && old.rushPathsEscaped == 0; i++) {
      for (final (sim, path) in [(old, oldPath), (now, nowPath)]) {
        sim
          ..birdY = path.routeY(sim.distance + birdX)
          ..velocity = 0;
        step(sim);
      }
      if (now.ringSprintUntil != old.ringSprintUntil) {
        bonusAt = bonusAt.isFinite ? bonusAt : now.elapsed;
      } else if (!bonusAt.isFinite) {
        expect(now.distance, old.distance);
        expect(now.score, old.score);
      }
    }
    expect(count(old, FlightEventKind.allRings), 1);
    expect(count(now, FlightEventKind.allRings), 1);
    // Seen on the frame that won it.
    expect(bonusAt, closeTo(now.allRingsAt, .05));
    expect(
      old.ringSprintUntil - now.ringSprintUntil,
      closeTo(Rush.firstAllRingsBonus - Rush.allRingsBonus, 1e-9),
    );
  });
}
