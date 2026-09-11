import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/game/bird_game.dart';

void main() {
  testWidgets('flight scene loads and renders without framework errors', (
    tester,
  ) async {
    final game = BirdGame(
      simulation: FlightSimulation(
        rules: PushUpFlightMode(cycleSeconds: 3),
        practice: true,
      ),
      nowMs: () => 0,
      bird: 0,
      reducedMotion: true,
      onChanged: () {},
    );
    await tester.runAsync(() async {
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 900,
            height: 400,
            child: GameWidget(game: game),
          ),
        ),
      );
      await game.loaded.timeout(const Duration(seconds: 5));
    });
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(const SizedBox());
  });
}
