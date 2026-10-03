import 'dart:ui';

import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/campaign.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/game/bird_game.dart';
import 'package:push_up_bird/game/neferhoo_encounter_art.dart';

/// On a phone running a debug build, building Neferhoo's art caches on his
/// arrival's first frame took over half a second, and a playing flight ends
/// as stalled after a frame that long: level 2-6 ended before he entered.
/// The game builds them during the countdown instead.
void main() {
  FlightSimulation flight(String id) => FlightSimulation(
    rules: TapFlyMode(),
    practice: false,
    course: FlightCourse.starTrail,
    plan: Campaign.level(id)!.plan,
  );

  Future<BirdGame> load(WidgetTester tester, FlightSimulation sim) async {
    tester.view.physicalSize = const Size(792, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final game = BirdGame(
      simulation: sim,
      nowMs: () => 0,
      bird: 0,
      reducedMotion: false,
      onChanged: () {},
    );
    await tester.pumpWidget(GameWidget(game: game));
    await tester.runAsync(() async => game.loaded);
    return game;
  }

  testWidgets('2-6 warms his art during the countdown', (tester) async {
    NeferhooEncounterArt.forgetWarmth();
    final sim = flight('2-6');
    final game = await load(tester, sim);
    expect(sim.phase, RunPhase.countdown);
    game.update(1 / 60);
    expect(NeferhooEncounterArt.warm, isTrue);
    // The countdown is not over: a long first frame here cannot end it.
    expect(sim.phase, isNot(RunPhase.ended));
  });

  testWidgets('another level does not build his art', (tester) async {
    NeferhooEncounterArt.forgetWarmth();
    final sim = flight('2-5');
    final game = await load(tester, sim);
    game.update(1 / 60);
    expect(NeferhooEncounterArt.warm, isFalse);
  });
}
