import 'dart:math' as math;
import 'package:flutter/painting.dart';
import '../domain/game_rules.dart';
import 'star_art.dart';

/// A collected star shrinks into the bird, using the replay's simulation clock.
abstract final class StarPickupArt {
  static const duration = .22;

  static void paint(
    Canvas canvas,
    double height,
    SkyStar star,
    FlightSimulation sim, {
    required bool reducedMotion,
  }) {
    final at = star.collectedAt;
    if (!star.collected || at == null) return;
    final age = sim.elapsed - at;
    if (age < 0 || age >= duration) return;
    final t = age / duration;
    final origin = Offset(
      star.x * height,
      (star.collectedY ?? star.y) * height,
    );
    final bird = Offset(FlightSimulation.birdX * height, sim.birdY * height);
    final travel = 1 - math.pow(1 - t, 3).toDouble();
    final center = reducedMotion ? origin : Offset.lerp(origin, bird, travel)!;
    // A quick swell on contact, then the star shrinks and turns into the bird.
    final size = reducedMotion
        ? 1.0
        : t < .25
        ? 1 + .18 * math.sin(t / .25 * math.pi / 2)
        : 1.18 * (1 - (t - .25) / .75 * .8);
    StarArt.paint(
      canvas,
      center,
      height * StarArt.radius * size,
      opacity: 1 - t * t,
      // The flight into the bird is the motion, so the idle life rests.
      rotation: reducedMotion ? 0 : travel * .9,
    );
  }
}
