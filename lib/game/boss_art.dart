import 'dart:math' as math;
import 'package:flutter/painting.dart';
import '../domain/game_rules.dart';
import '../ui/theme.dart';
import 'sky_scenery.dart';
import 'boss_motion.dart';
import 'boss_encounter_art.dart';

abstract final class BossArt {
  static Offset cameraOffset(SkyBoss? boss, bool reducedMotion) =>
      boss?.cinematic == true
      ? BossMotion(boss!, reducedMotion: reducedMotion).shake
      : Offset.zero;

  static void backdrop(Canvas c, Size size, SkyBoss? boss, bool reducedMotion) {
    if (boss?.cinematic != true) return;
    BossEncounterArt.backdrop(
      c,
      size,
      boss!,
      BossMotion(boss, reducedMotion: reducedMotion),
    );
  }

  static void foreground(
    Canvas c,
    Size size,
    FlightSimulation sim,
    bool reducedMotion,
  ) {
    final boss = sim.boss;
    if (boss?.cinematic != true) return;
    BossEncounterArt.foreground(
      c,
      size,
      sim,
      BossMotion(boss!, reducedMotion: reducedMotion),
    );
  }

  static void paint(
    Canvas canvas,
    Size size,
    FlightSimulation sim, {
    required bool reducedMotion,
  }) {
    final boss = sim.boss;
    if (boss == null) return;
    if (boss.cinematic) {
      BossEncounterArt.paint(
        canvas,
        size,
        sim,
        BossMotion(boss, reducedMotion: reducedMotion),
      );
      return;
    }
    final h = size.height;
    final defeated = boss.phase == BossPhase.defeated;
    final departure = defeated
        ? ((boss.age - boss.defeatedAt!) / SkyBoss.departureSeconds).clamp(
            0.0,
            1.0,
          )
        : 0.0;

    for (final ammo in sim.bossAmmo) {
      final center = Offset(ammo.x * h, ammo.y * h);
      final radius = BossAmmo.radius * h;
      final direction = Offset(ammo.vx, ammo.vy);
      final tail = direction / direction.distance * radius * 3.4;
      canvas.drawLine(
        center - tail,
        center,
        Paint()
          ..color = SkyColors.coral.withValues(alpha: .5)
          ..strokeCap = StrokeCap.round
          ..strokeWidth = radius * 1.5,
      );
      canvas.drawCircle(center, radius * 1.2, Paint()..color = SkyColors.ink);
      canvas.drawCircle(center, radius, Paint()..color = SkyColors.coralDeep);
      canvas.drawCircle(
        center - Offset(radius * .12, radius * .12),
        radius * .48,
        Paint()..color = SkyColors.yellow,
      );
    }

    canvas.save();
    canvas.translate(
      boss.x * h,
      (boss.y - (reducedMotion ? 0 : departure * .22)) * h,
    );
    canvas.scale(h * SkyBoss.radius * (1 - departure * .35));
    if (defeated) {
      for (var i = 0; i < 9; i++) {
        final angle = i * math.pi * 2 / 9;
        final distance = reducedMotion ? 1.5 : 1.2 + departure * 2;
        canvas.drawPath(
          SkyScenery.star(
            Offset(math.cos(angle), math.sin(angle)) * distance,
            .13,
          ),
          Paint()..color = SkyColors.gold.withValues(alpha: 1 - departure),
        );
      }
    }
    final alpha = 1 - departure;
    Paint fill(Color color) =>
        Paint()..color = color.withValues(alpha: color.a * alpha);
    final outline = fill(SkyColors.ink)
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..strokeWidth = .045;
    final wing = reducedMotion || defeated ? 0.0 : math.sin(boss.age * 7) * .12;
    for (final side in [-1.0, 1.0]) {
      canvas.save();
      canvas.scale(side, 1);
      final wings = Path()
        ..moveTo(.5, -.35)
        ..cubicTo(.95, -1.08 - wing, 1.7, -1.08 - wing, 2.15, -.7 - wing)
        ..quadraticBezierTo(1.65, -.35, 1.9, .05 + wing)
        ..quadraticBezierTo(1.45, -.18, 1.4, .48 + wing)
        ..quadraticBezierTo(.97, .18, .82, .64)
        ..lineTo(.5, .35)
        ..close();
      canvas.drawPath(wings, fill(SkyColors.purple));
      canvas.drawPath(wings, outline);
      canvas.drawPath(
        Path()
          ..moveTo(.66, -.26)
          ..quadraticBezierTo(1.21, -.7, 1.88, -.7 - wing)
          ..moveTo(.66, -.26)
          ..lineTo(1.4, .37 + wing),
        outline..color = SkyColors.lavender.withValues(alpha: alpha),
      );
      outline.color = SkyColors.ink.withValues(alpha: alpha);
      canvas.restore();
    }
    final body = Path()
      ..moveTo(-.71, -.46)
      ..lineTo(-.78, -1.02)
      ..lineTo(-.35, -.73)
      ..quadraticBezierTo(0, -.9, .35, -.73)
      ..lineTo(.78, -1.02)
      ..lineTo(.71, -.46)
      ..cubicTo(1.08, .9, -.97, 1.15, -.71, -.46)
      ..close();
    final hit = boss.age - boss.lastHitAt < .12 && !reducedMotion;
    canvas.drawPath(body, fill(hit ? SkyColors.cream : SkyColors.lavender));
    canvas.drawPath(body, outline);
    canvas.drawOval(
      const Rect.fromLTWH(-.54, .18, 1.08, .59),
      fill(SkyColors.purple),
    );
    for (final x in [-.31, .31]) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, -.19), width: .47, height: .43),
        fill(SkyColors.cream),
      );
      if (defeated) {
        canvas.drawLine(Offset(x - .12, -.2), Offset(x + .09, -.08), outline);
        canvas.drawLine(Offset(x - .12, -.08), Offset(x + .09, -.2), outline);
      } else {
        canvas.drawCircle(Offset(x - .07, -.17), .105, fill(SkyColors.ink));
      }
    }
    canvas.drawPath(
      Path()
        ..moveTo(-.58, -.5)
        ..lineTo(-.12, -.37)
        ..moveTo(.12, -.37)
        ..lineTo(.58, -.5),
      outline..strokeWidth = .075,
    );
    outline.strokeWidth = .045;
    canvas.drawOval(
      const Rect.fromLTWH(-.35, .12, .58, .28),
      fill(SkyColors.ink),
    );
    for (final x in [-.23, .09]) {
      canvas.drawPath(
        Path()
          ..moveTo(x - .065, .14)
          ..lineTo(x, .33)
          ..lineTo(x + .065, .14)
          ..close(),
        fill(SkyColors.cream),
      );
    }
    final crown = Path()
      ..moveTo(-.47, -.84)
      ..lineTo(-.58, -1.35)
      ..lineTo(-.22, -1.16)
      ..lineTo(0, -1.55)
      ..lineTo(.22, -1.16)
      ..lineTo(.58, -1.35)
      ..lineTo(.47, -.84)
      ..close();
    canvas.drawPath(crown, fill(SkyColors.yellow));
    canvas.drawPath(crown, outline);
    canvas.drawCircle(const Offset(0, -1.04), .1, fill(SkyColors.coralDeep));
    canvas.drawPath(
      SkyScenery.star(const Offset(0, .55), .16),
      fill(boss.enraged ? SkyColors.coral : SkyColors.yellow),
    );
    if (boss.charge > 0) {
      final r = .16 + boss.charge * .13;
      canvas.drawCircle(
        const Offset(-1.02, 0),
        r * 1.5,
        fill(SkyColors.coral.withValues(alpha: .25)),
      );
      canvas.drawCircle(const Offset(-1.02, 0), r, fill(SkyColors.coralDeep));
      canvas.drawPath(
        SkyScenery.star(const Offset(-1.02, 0), r * .8),
        fill(SkyColors.yellow),
      );
    }
    canvas.restore();
  }

  static void healthBar(Canvas canvas, Size size, SkyBoss boss) {
    if (boss.cinematic) {
      BossEncounterArt.healthBar(canvas, size, boss);
      return;
    }
    final h = size.height;
    final w = math.min(size.width * .33, h * .76);
    final left = (size.width - w) / 2;
    final defeated = boss.phase == BossPhase.defeated;
    final arriving = boss.phase == BossPhase.arriving;
    final title = defeated
        ? '${boss.name.toUpperCase()} DEFEATED'
        : '${arriving ? 'BOSS INCOMING' : boss.name.toUpperCase()}  ·  ${boss.hp}/${boss.maxHp}';
    final panel = RRect.fromRectAndRadius(
      Rect.fromLTWH(left - h * .025, h * .035, w + h * .05, h * .153),
      Radius.circular(h * .025),
    );
    canvas.drawRRect(
      panel,
      Paint()..color = SkyColors.ink.withValues(alpha: .93),
    );
    void text(String label, double y, double fontSize, Color color) {
      final painter = TextPainter(
        text: TextSpan(
          text: label,
          style: heading(fontSize, color: color),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout(maxWidth: w);
      painter.paint(canvas, Offset((size.width - painter.width) / 2, y));
    }

    text(
      title,
      h * .052,
      h * .033,
      defeated ? SkyColors.mint : SkyColors.cream,
    );
    final track = Rect.fromLTWH(left, h * .098, w, h * .022);
    canvas.drawRRect(
      RRect.fromRectAndRadius(track, Radius.circular(h * .011)),
      Paint()..color = SkyColors.muted,
    );
    if (!defeated) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            track.left,
            track.top,
            w * boss.hp / boss.maxHp,
            track.height,
          ),
          Radius.circular(h * .011),
        ),
        Paint()..color = boss.enraged ? SkyColors.coral : SkyColors.yellow,
      );
    }
    text(
      defeated
          ? 'Clear skies ahead!'
          : arriving
          ? 'Get ready to dodge & shoot'
          : boss.enraged
          ? 'FURIOUS!  Keep shooting'
          : 'Dodge the fireballs · Shoot to hit',
      h * .141,
      h * .027,
      SkyColors.cream,
    );
  }
}
