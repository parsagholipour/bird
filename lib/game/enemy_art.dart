import 'package:flutter/painting.dart';
import '../domain/game_rules.dart';
import 'enemy_ammo_art.dart';
import 'enemy_health_bar_art.dart';
import 'enemy_hit_art.dart';
import 'enemy_designs/aimed_enemy.dart';
import 'enemy_designs/simple_bat.dart';
import 'enemy_designs/patrol_bat.dart';
import 'enemy_designs/spread_enemy.dart';

/// Directional silhouettes and attack cues, including the plain purple bat.
abstract final class EnemyArt {
  static void paint(
    Canvas canvas,
    double height,
    SkyEnemy enemy, {
    required double birdY,
    required bool reducedMotion,
  }) {
    final radius = height * SkyEnemy.radius;
    final look = ((birdY - enemy.y) * 3).clamp(-1.0, 1.0);
    final time = enemy.wingTime;
    final hitAge = enemy.age - enemy.lastHitAt;
    final hit = EnemyHitArt.pose(hitAge, reducedMotion: reducedMotion);
    canvas.save();
    canvas.translate(enemy.x * height, enemy.y * height);
    if (hit != null) {
      // Rocks arrive from the bird's side: knock the body away from it. The
      // hit circle itself never moves.
      canvas.translate(radius * hit.shift, 0);
      canvas.rotate(hit.tilt);
      canvas.scale(hit.scaleX, hit.scaleY);
    }
    if (enemy.x < FlightSimulation.birdX) canvas.scale(-1, 1);
    if (!reducedMotion) canvas.rotate(enemy.flightBank);
    final flash = hit != null && hit.flash > 0;
    if (flash) {
      // Only alive for the few frames of the pop.
      canvas.saveLayer(
        Rect.fromCircle(center: Offset.zero, radius: radius * 3),
        Paint()..colorFilter = EnemyHitArt.flashFilter(hit.flash),
      );
    }
    final painter = switch (enemy.kind) {
      EnemyKind.caveBat => PatrolBatArt.paint,
      EnemyKind.spitterBeetle => AimedEnemyArt.paint,
      EnemyKind.duskMoth => SpreadEnemyArt.paint,
      EnemyKind.simpleBat => SimpleBatArt.paint,
    };
    painter(
      canvas,
      radius,
      seconds: time,
      reducedMotion: reducedMotion,
      lookY: look,
      charge: enemy.charge,
      recoil: enemy.recoil,
    );
    if (flash) canvas.restore();
    canvas.restore();
    EnemyHitArt.paint(
      canvas,
      // Where the rock meets the front of the hit circle.
      Offset(enemy.x * height - radius * .9, enemy.y * height),
      radius,
      age: hitAge,
      reducedMotion: reducedMotion,
    );
  }

  static void healthBar(
    Canvas canvas,
    double height,
    SkyEnemy enemy, {
    bool reducedMotion = false,
  }) => EnemyHealthBarArt.paint(
    canvas,
    height,
    enemy,
    reducedMotion: reducedMotion,
  );

  static void ammo(
    Canvas canvas,
    double height,
    EnemyAmmo ammo, {
    required double seconds,
    required bool reducedMotion,
  }) {
    EnemyAmmoArt.paint(
      canvas,
      height,
      ammo,
      seconds: seconds,
      reducedMotion: reducedMotion,
    );
  }
}
