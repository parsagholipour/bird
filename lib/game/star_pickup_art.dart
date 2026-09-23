import 'dart:math' as math;
import 'package:flutter/painting.dart';
import '../domain/game_rules.dart';
import '../ui/theme.dart';
import 'sky_scenery.dart';

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
    final radius = height * SkyStar.radius * (reducedMotion ? 1 : 1 - t);
    final alpha = 1 - t;
    canvas.drawPath(
      SkyScenery.star(center + Offset(0, radius * .15), radius),
      Paint()..color = SkyColors.gold.withValues(alpha: alpha),
    );
    canvas.drawPath(
      SkyScenery.star(center, radius),
      Paint()..color = SkyColors.yellow.withValues(alpha: alpha),
    );
    canvas.drawCircle(
      center - Offset(radius * .18, radius * .18),
      radius * .15,
      Paint()..color = SkyColors.cream.withValues(alpha: alpha),
    );
  }
}
