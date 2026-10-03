import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/campaign.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'boss_fight_test.dart' show step;
import 'boss_stages_test.dart' show flyUntil, level;

/// Rules version 47: a campaign bird catches a boss's heart when it touches
/// the heart as drawn, and a heart any bird misses drifts off the screen
/// instead of vanishing just behind it.

FlightSimulation flight({
  String? levelId,
  int version = FlightSimulation.currentRulesVersion,
}) =>
    FlightSimulation(
        rules: TapFlyMode(rulesVersion: version),
        practice: true,
        course: FlightCourse.starTrail,
        rulesVersion: version,
        plan: levelId == null
            ? FlightPlan.endless
            : Campaign.level(levelId)!.plan,
        random: Random(4),
      )
      ..phase = RunPhase.playing
      ..started = true
      ..invulnerableUntil = double.infinity;

/// Steps [sim] once, adding any heart it catches to [caught] (events
/// expire after two seconds).
void stepCatching(FlightSimulation sim, Set<FlightEvent> caught) {
  step(sim);
  caught.addAll(sim.events.where((e) => e.kind == FlightEventKind.heart));
}

/// Holds the bird [offset] below a heart at mid-height as it drifts past
/// and on off the screen, and returns the hearts caught.
int flyPast(FlightSimulation sim, double offset, {double from = .9}) {
  final caught = <FlightEvent>{};
  sim
    ..hearts = 2
    ..heartPickups.add(SkyHeart(x: from, y: .5));
  for (var i = 0; i < 400; i++) {
    sim
      ..birdY = .5 + offset
      ..velocity = 0;
    stepCatching(sim, caught);
  }
  expect(sim.hearts, 2 + caught.length);
  return caught.length;
}

void main() {
  test('from 47 a campaign bird catches the heart it touches', () {
    expect(FlightSimulation.fairHeartsRulesVersion, 47);
    expect(SkyHeart.touchRadius, greaterThan(SkyHeart.pickupRadius));
    for (final offset in [.1, -.1]) {
      expect(flyPast(flight(levelId: '3-4'), offset), 1, reason: '$offset');
      // A rules 46 tape keeps the 0.085 reach.
      expect(
        flyPast(flight(levelId: '3-4', version: 46), offset),
        0,
        reason: '$offset at 46',
      );
    }
    // Clear of the heart's disc it is still missed.
    expect(flyPast(flight(levelId: '3-4'), .13), 0);
    expect(flyPast(flight(levelId: '3-4'), .08), 1);
  });

  test('endless keeps the 0.085 reach at 47', () {
    expect(flyPast(flight(), .1), 0);
    expect(flyPast(flight(), .08), 1);
  });

  test('a missed heart drifts off the screen instead of vanishing behind the '
      'bird, and is never caught after it', () {
    for (final (levelId, version) in [
      ('3-4', 47),
      ('3-4', 46),
      (null, 47),
      (null, 24),
    ]) {
      final sim = flight(levelId: levelId, version: version)
        ..hearts = 2
        ..heartPickups.add(SkyHeart(x: .9, y: .5));
      final why = '$levelId at $version';
      final caught = <FlightEvent>{};
      var drifted = false, gone = false;
      for (var i = 0; i < 400 && !gone; i++) {
        // Well clear of the heart until it has passed, then onto it.
        final passed = sim.heartPickups.isEmpty;
        sim
          ..birdY = passed ? .5 : .25
          ..velocity = 0;
        stepCatching(sim, caught);
        if (sim.missedHearts.isNotEmpty) {
          final heart = sim.missedHearts.single;
          expect(heart.x, lessThan(FlightSimulation.birdX), reason: why);
          expect(heart.x, greaterThan(-SkyHeart.haloRadius), reason: why);
          drifted |= heart.x < FlightSimulation.birdX - .3;
        } else if (sim.heartPickups.isEmpty) {
          gone = true;
        }
      }
      expect(drifted, isTrue, reason: why);
      expect(gone, isTrue, reason: why);
      expect(sim.hearts, 2, reason: why);
      expect(caught, isEmpty, reason: why);
    }
  });

  test('a boss arriving clears drifting hearts with the pickups', () {
    final sim = flight()..missedHearts.add(SkyHeart(x: .2, y: .5));
    sim.elapsed = FlightSimulation.bossInterval;
    step(sim);
    expect(sim.boss, isNotNull);
    expect(sim.missedHearts, isEmpty);
  });

  test("3-4: the bird catches the Gargoyle's stage heart a touch off its "
      'height', () {
    final sim = flyUntil(level('3-4'), (sim) => sim.heartPickups.isNotEmpty);
    expect(sim.boss!.stageReached, 1);
    sim.invulnerableUntil = double.infinity;
    final heart = sim.heartPickups.single;
    final caught = <FlightEvent>{};
    sim.hearts = 2;
    while (sim.heartPickups.isNotEmpty) {
      sim
        ..birdY = heart.y + .1
        ..velocity = 0;
      stepCatching(sim, caught);
    }
    expect(caught, hasLength(1));
    expect(sim.hearts, 3);
    expect(sim.missedHearts, isEmpty);
  });
}
