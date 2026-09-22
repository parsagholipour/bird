import 'dart:math' as math;
import 'package:flutter/painting.dart';
import '../domain/game_rules.dart';
import '../ui/theme.dart';
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
    final reacting = hitAge >= 0 && hitAge < EnemyHitArt.hitSeconds;
    canvas.save();
    canvas.translate(enemy.x * height, enemy.y * height);
    if (reacting && !reducedMotion) {
      final t = hitAge / EnemyHitArt.hitSeconds;
      final settle = math.pow(1 - t, 3).toDouble();
      final squeeze = math.cos(t * math.pi * 2) * settle;
      // Visual recoil stays within a few pixels of the unchanged hit circle.
      canvas.translate(radius * .18 * settle, 0);
      canvas.rotate(-.10 * squeeze);
      canvas.scale(1 - .16 * squeeze, 1 + .13 * squeeze);
    }
    if (enemy.x < FlightSimulation.birdX) canvas.scale(-1, 1);
    if (!reducedMotion) canvas.rotate(enemy.flightBank);
    final flash = !reducedMotion && hitAge >= 0 && hitAge < .095;
    if (flash) {
      canvas.saveLayer(
        Rect.fromCircle(center: Offset.zero, radius: radius * 3),
        Paint()
          ..colorFilter = ColorFilter.mode(
            SkyColors.cream.withValues(alpha: .85 * (1 - hitAge / .095)),
            BlendMode.srcATop,
          ),
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
      Offset(enemy.x * height - radius * .65, enemy.y * height),
      radius,
      age: hitAge,
      reducedMotion: reducedMotion,
    );
  }

  static void healthBar(Canvas canvas, double height, SkyEnemy enemy) {
    if (enemy.hp <= 0 || enemy.hp == enemy.maxHp) return;
    final width = height * .10;
    final track = Rect.fromLTWH(
      enemy.x * height - width / 2,
      (enemy.y - .085) * height,
      width,
      height * .011,
    );
    final radius = Radius.circular(track.height / 2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(track.inflate(height * .003), radius),
      Paint()..color = SkyColors.ink,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(track, radius),
      Paint()..color = SkyColors.purple,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          track.left,
          track.top,
          width * enemy.hp / enemy.maxHp,
          track.height,
        ),
        radius,
      ),
      Paint()
        ..color = enemy.age - enemy.lastHitAt < .15
            ? SkyColors.cream
            : enemy.hp <= enemy.maxHp / 2
            ? SkyColors.coral
            : SkyColors.mint,
    );
  }

  static void ammo(Canvas canvas, double height, EnemyAmmo ammo) {
    final aimed = ammo.attack == EnemyAttack.aimed;
    final color = aimed ? SkyColors.teal : SkyColors.coralDeep;
    final light = aimed ? SkyColors.mint : SkyColors.gold;
    final radius = height * EnemyAmmo.radius;
    canvas.save();
    canvas.translate(ammo.x * height, ammo.y * height);
    canvas.rotate(math.atan2(ammo.vy, ammo.vx));
    // The tail points away from travel, so the shot's direction reads even
    // without motion. A mint seed and amber diamond distinguish the volleys.
    final trail = Path()
      ..moveTo(-radius * 4.2, 0)
      ..quadraticBezierTo(-radius * 1.4, -radius, 0, -radius * .65)
      ..lineTo(0, radius * .65)
      ..quadraticBezierTo(-radius * 1.4, radius, -radius * 4.2, 0);
    canvas.drawPath(trail, Paint()..color = light.withValues(alpha: .40));
    final core = aimed
        ? (Path()..addOval(Rect.fromLTRB(-radius, -radius, radius, radius)))
        : (Path()
            ..moveTo(radius * 1.1, 0)
            ..lineTo(0, -radius)
            ..lineTo(-radius * 1.1, 0)
            ..lineTo(0, radius)
            ..close());
    canvas.drawPath(core, Paint()..color = color);
    canvas.drawPath(
      core,
      Paint()
        ..color = SkyColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1, radius * .22),
    );
    canvas.drawCircle(
      Offset(radius * .14, -radius * .18),
      radius * .48,
      Paint()..color = light,
    );
    canvas.drawCircle(
      Offset(radius * .3, -radius * .28),
      radius * .18,
      Paint()..color = SkyColors.cream,
    );
    canvas.restore();
  }
}
