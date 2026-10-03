import 'dart:math' as math;
import 'package:flutter/painting.dart';
import '../domain/game_rules.dart';
import '../ui/theme.dart';
import 'alley_pigeon_overlay_art.dart';
import 'ammo_shatter_art.dart';
import 'enemy_design.dart';
import 'enemy_ammo_impact_art.dart';
import 'enemy_art.dart';
import 'enemy_defeat_art.dart';
import 'king_coo_staging_art.dart';
import 'stone_art.dart';
import 'straggler_art.dart';

abstract final class CombatArt {
  static void paint(
    Canvas canvas,
    double height,
    FlightSimulation sim, {
    required bool reducedMotion,
  }) {
    // The pigeons' telegraph (ring and swoop line on the prey) sits under
    // the enemies, so a diving pigeon passes over it.
    AlleyPigeonOverlayArt.paint(
      canvas,
      height,
      sim,
      reducedMotion: reducedMotion,
    );
    for (final enemy in sim.enemies) {
      // King Coo's squadron comes out from behind him: his stage paints those
      // pigeons under the figure until they are clear of it.
      if (KingCooStaging.squadBehind(sim.boss, enemy, height)) continue;
      if (sim.rulesVersion >= 18) {
        EnemyArt.paint(
          canvas,
          height,
          enemy,
          birdY: sim.birdY,
          reducedMotion: reducedMotion,
          straggler: StragglerArt.isStraggler(sim, enemy),
        );
        if (sim.supportsWeaponDamage) {
          EnemyArt.healthBar(
            canvas,
            height,
            enemy,
            reducedMotion: reducedMotion,
          );
        }
        continue;
      }
      canvas.save();
      canvas.translate(enemy.x * height, enemy.y * height);
      if (sim.rulesVersion >= 16) {
        EnemyDesign.paint(
          canvas,
          height * SkyEnemy.radius,
          appearance: enemy.appearance,
          seconds: sim.elapsed,
          reducedMotion: reducedMotion,
        );
        canvas.restore();
        continue;
      }
      canvas.scale(height * SkyEnemy.radius);
      final wing = reducedMotion ? 0.0 : math.sin(sim.elapsed * 12) * .18;
      final wings = Path()
        ..moveTo(-.55, -.1)
        ..quadraticBezierTo(-1.25, -.95 - wing, -1.9, -.65 - wing)
        ..lineTo(-1.6, .05)
        ..lineTo(-1.16, -.08)
        ..lineTo(-.92, .43)
        ..lineTo(-.45, .4)
        ..moveTo(.55, -.1)
        ..quadraticBezierTo(1.25, -.95 - wing, 1.9, -.65 - wing)
        ..lineTo(1.6, .05)
        ..lineTo(1.16, -.08)
        ..lineTo(.92, .43)
        ..lineTo(.45, .4);
      final outline = Paint()
        ..color = SkyColors.ink
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..strokeWidth = .085;
      canvas.drawPath(wings, Paint()..color = SkyColors.purple);
      canvas.drawPath(wings, outline);
      final body = Path()
        ..moveTo(-.72, -.48)
        ..lineTo(-.74, -1.13)
        ..lineTo(-.24, -.79)
        ..quadraticBezierTo(0, -.87, .28, -.79)
        ..lineTo(.76, -1.13)
        ..lineTo(.73, -.46)
        ..cubicTo(1.18, .87, -.98, 1.17, -.72, -.48)
        ..close();
      canvas.drawPath(body, Paint()..color = SkyColors.lavender);
      canvas.drawPath(body, outline);
      for (final x in [-.35, .3]) {
        canvas.drawOval(
          Rect.fromCenter(center: Offset(x, -.16), width: .48, height: .52),
          Paint()..color = SkyColors.cream,
        );
        canvas.drawCircle(
          Offset(x - .07, -.12),
          .115,
          Paint()..color = SkyColors.ink,
        );
      }
      canvas.drawPath(
        Path()
          ..moveTo(-.62, -.5)
          ..lineTo(-.14, -.35)
          ..moveTo(.07, -.35)
          ..lineTo(.55, -.5),
        outline,
      );
      canvas.drawOval(
        const Rect.fromLTWH(-.34, .2, .53, .27),
        Paint()..color = SkyColors.ink,
      );
      canvas.drawPath(
        Path()
          ..moveTo(-.24, .21)
          ..lineTo(-.16, .39)
          ..lineTo(-.06, .21)
          ..close(),
        Paint()..color = SkyColors.cream,
      );
      canvas.restore();
    }
    for (final ammo in sim.enemyAmmo) {
      EnemyArt.ammo(
        canvas,
        height,
        ammo,
        seconds: sim.elapsed,
        reducedMotion: reducedMotion,
      );
    }
    EnemyAmmoImpactArt.paint(canvas, height, sim, reducedMotion: reducedMotion);
    AmmoShatterArt.paint(canvas, height, sim, reducedMotion: reducedMotion);
    for (final rock in sim.rocks) {
      StoneArt.paint(
        canvas,
        height,
        rock,
        seconds: sim.elapsed,
        reducedMotion: reducedMotion,
      );
    }
    for (final event in sim.events.where(
      (e) =>
          e.kind == FlightEventKind.enemyHit ||
          e.kind == FlightEventKind.enemyRammed,
    )) {
      final age = sim.elapsed - event.at;
      if (age < 0) continue;
      final center = Offset(
        (event.gateWorldX! - sim.distance) * height,
        event.y * height,
      );
      if (sim.supportsWeaponDamage) {
        EnemyDefeatArt.paint(
          canvas,
          center,
          height * SkyEnemy.radius,
          age: age,
          reducedMotion: reducedMotion,
          rammed: event.kind == FlightEventKind.enemyRammed,
          kind: event.enemyKind,
          seed: (event.at * 1000).round(),
        );
        continue;
      }
      if (age > .4) continue;
      final t = reducedMotion ? .4 : age / .4;
      final paint = Paint()
        ..color = SkyColors.cream.withValues(alpha: 1 - age / .4)
        ..strokeWidth = height * .005
        ..strokeCap = StrokeCap.round;
      for (var i = 0; i < 6; i++) {
        final angle = i * math.pi / 3;
        final direction = Offset(math.cos(angle), math.sin(angle));
        canvas.drawLine(
          center + direction * height * (.025 + t * .03),
          center + direction * height * (.045 + t * .045),
          paint,
        );
      }
    }
  }

  /// The held power shot, drawn in front of the bird's beak. Its size and
  /// glow follow the same charge that sets the fired rock's size and damage.
  static void paintCharge(
    Canvas canvas,
    double height,
    FlightSimulation sim, {
    required bool reducedMotion,
  }) {
    StoneArt.charge(canvas, height, sim, reducedMotion: reducedMotion);
  }
}
