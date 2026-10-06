import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/tracking.dart';
import 'package:push_up_bird/game/pirate_tide_art.dart';

import 'built_pilot.dart';
import 'campaign_flight.dart';

/// Counts every call the art makes: anything drawn at all.
class _CountingCanvas implements Canvas {
  int calls = 0;
  @override
  dynamic noSuchMethod(Invocation invocation) {
    calls++;
    return null;
  }
}

/// Whether the tide warning draws anything for [boss] this frame.
bool _warningShows(SkyBoss boss) {
  final canvas = _CountingCanvas();
  PirateTideArt.warning(
    canvas,
    const Size(792, 360),
    boss: boss,
    reduced: true,
    distance: 0,
    t: boss.age,
    peak: (_) => SkyBoss.tidePeak,
  );
  return canvas.calls > 0;
}

/// The tide cycle [boss] is in.
int _cycle(SkyBoss boss) =>
    ((boss.age - boss.arrivalDuration) / SkyBoss.tidePeriod).floor();

void main() {
  // The owner (2026-10-06): "it showed the water is coming up two times but
  // it didn't come up, it only worked for the next ones". A staged captain's
  // warm-up keeps the sea calm, but the warning art read the bare tide
  // clock and called up a surge in each of those cycles anyway.
  test('a staged captain warns only of the surges that come', () {
    final plan = sampleLevel(
      PlayMode.touch,
      id: 'u-piratetide1',
      gates: 3,
      boss: BossKind.pirate,
    );
    final sim = builtFlight(plan);
    final shown = <int>{}, rose = <int>{};
    flyLevel(
      sim,
      watch: (s) {
        final boss = s.boss;
        if (boss == null || boss.phase != BossPhase.attacking) return;
        if (_warningShows(boss)) shown.add(_cycle(boss));
        if (boss.tide > 0) rose.add(_cycle(boss));
        if (!boss.tideRuns) expect(boss.tide, 0);
      },
    );
    expect(sim.bossesDefeated, 1, reason: 'the fight was flown to its end');
    // The warm-up's first cycles stay calm, and say nothing.
    expect(rose, isNot(contains(0)));
    expect(rose, isNotEmpty);
    expect(
      shown.difference(rose),
      isEmpty,
      reason: 'tide cycles warned of but never risen (rose in $rose)',
    );
    expect(rose.difference(shown), isEmpty, reason: 'a surge came unwarned');
  });

  test('a one-stage captain warns of every surge, and every one comes', () {
    final boss = SkyBoss(
      number: 4,
      x: 1.8,
      kind: BossKind.pirate,
      cinematic: true,
    );
    expect(boss.staged, isFalse);
    final shown = <int>{}, rose = <int>{};
    while (boss.age < boss.arrivalDuration + 4 * SkyBoss.tidePeriod) {
      boss.age += 1 / 60;
      if (boss.phase != BossPhase.attacking) continue;
      expect(boss.tideRuns, isTrue);
      if (_warningShows(boss)) shown.add(_cycle(boss));
      if (boss.tide > 0) rose.add(_cycle(boss));
    }
    expect(rose, {0, 1, 2, 3});
    expect(shown, rose);
  });
}
