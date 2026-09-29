import 'dart:math' as math;
import 'package:flutter/painting.dart';
import 'package:flame/game.dart';
import '../domain/game_rules.dart';
import '../domain/bird_motion.dart';
import '../ui/theme.dart';
import 'regions/region_burst.dart';
import 'sky_scenery.dart';
import 'bird_trail.dart';
import 'bird_puppet.dart';
import 'star_trio_art.dart';
import 'star_group_aura.dart';
import 'star_pickup_art.dart';
import 'star_art.dart';
import 'arrival_art.dart';
import 'gate_art.dart';
import 'obstacle_art.dart';
import 'combat_art.dart';
import 'boss_art.dart';
import 'heart_pickup_art.dart';
import 'door_art.dart';
import 'gale_art.dart';
import 'rush_art.dart';
import 'sprint_art.dart';

class BirdGame extends FlameGame {
  BirdGame({
    required this.simulation,
    required this.nowMs,
    required this.bird,
    required this.reducedMotion,
    required this.onChanged,
    this.advance,
    this.playback = false,
    this.transparent = false,
  });
  FlightSimulation simulation;
  final void Function(double dt, double now, double width)? advance;
  final bool playback;
  bool transparent;
  final double Function() nowMs;
  final int bird;
  final bool reducedMotion;
  final void Function() onChanged;
  double _notify = 0;
  // Decorative motion follows the simulation clock, including pause and seek.
  double get _time => simulation.elapsed;
  final List<double> _frameDurations = [];
  double get renderHz => _frameDurations.isEmpty
      ? 0
      : _frameDurations.length / _frameDurations.reduce((a, b) => a + b);
  double get p95FrameMs {
    if (_frameDurations.isEmpty) return 0;
    final frames = [..._frameDurations]..sort();
    return frames[((frames.length - 1) * .95).ceil()] * 1000;
  }

  @override
  Color backgroundColor() =>
      transparent ? const Color(0x00000000) : SkyColors.sky;
  @override
  void update(double dt) {
    super.update(dt);
    if (size.y <= 0) return;
    if (simulation.phase == RunPhase.playing && dt > 0) {
      _frameDurations.add(dt);
      if (_frameDurations.length > 600) _frameDurations.removeAt(0);
    }
    if (playback) return;
    if (advance != null) {
      advance!(dt, nowMs(), size.x / size.y);
    } else {
      simulation.tick(
        dt,
        nowMs(),
        viewportWidth: size.x / size.y,
        reducedMotion: reducedMotion,
      );
    }
    _notify += dt;
    if (_notify >= .05 || simulation.phase == RunPhase.ended) {
      _notify = 0;
      onChanged();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final w = size.x, h = size.y;
    if (h <= 0) return;
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, w, h));
    final shake =
        (BossArt.cameraOffset(simulation.boss, reducedMotion) +
            RushArt.cameraOffset(simulation, reducedMotion) +
            GaleArt.cameraOffset(simulation, reducedMotion)) *
        h;
    if (shake != Offset.zero) {
      canvas.translate(w / 2, h / 2);
      canvas.scale(1.018);
      canvas.translate(-w / 2 + shake.dx, -h / 2 + shake.dy);
    }
    if (!transparent) {
      SkyScenery.paint(
        canvas,
        Size(w, h),
        seconds: simulation.elapsed,
        distance: simulation.distance,
        reducedMotion: reducedMotion,
      );
    }
    BossArt.backdrop(canvas, Size(w, h), simulation.boss, reducedMotion);
    RushArt.backdrop(
      canvas,
      Size(w, h),
      simulation,
      reducedMotion: reducedMotion,
    );
    GaleArt.backdrop(
      canvas,
      Size(w, h),
      simulation,
      reducedMotion: reducedMotion,
    );
    ArrivalArt.gate(canvas, h, simulation, reducedMotion: reducedMotion);
    SprintArt.streaks(
      canvas,
      Size(w, h),
      simulation,
      reducedMotion: reducedMotion,
    );
    for (final o in simulation.obstacles) {
      if (o.rubble) {
        RushArt.rubble(
          canvas,
          Size(w, h),
          o,
          simulation,
          reducedMotion: reducedMotion,
        );
        continue;
      }
      if (o.smashed) {
        RushArt.debris(
          canvas,
          h,
          o,
          simulation.elapsed - o.smashedAt!,
          reducedMotion: reducedMotion,
        );
        continue;
      }
      final x = o.x * h, width = o.width * h;
      final cleared = o.scored && !o.hit;
      final perfect = cleared && o.maxDeviation <= .075;
      if (o.hit) {
        canvas.saveLayer(
          Rect.fromLTWH(x - 8, 0, width + 16, h),
          Paint()..color = const Color(0x66ffffff),
        );
      }
      if (simulation.rulesVersion >= 13) {
        ObstacleArt.paint(
          canvas,
          o,
          h,
          seconds: simulation.elapsed,
          reducedMotion: reducedMotion,
          cleared: cleared,
          perfect: perfect,
          refined: simulation.rulesVersion >= 14,
          gardenStructures: simulation.rulesVersion >= 16,
        );
      } else {
        for (final passage in o.passages) {
          _tower(
            canvas,
            Rect.fromLTWH(
              passage.x * h,
              -10,
              passage.width * h,
              passage.top * h + 10,
            ),
            true,
            cleared: cleared,
            perfect: perfect,
            kind: o.kind,
          );
          _tower(
            canvas,
            Rect.fromLTWH(
              passage.x * h,
              passage.bottom * h,
              passage.width * h,
              h - passage.bottom * h + 10,
            ),
            false,
            cleared: cleared,
            perfect: perfect,
            kind: o.kind,
          );
        }
      }
      if (o.door != null) {
        DoorArt.paint(canvas, h, o, reducedMotion: reducedMotion);
      }
      if (cleared) {
        ObstacleArt.seal(
          canvas,
          Offset(x + width / 2, o.target * h),
          h,
          WorldTour.of(o),
          perfect: perfect,
        );
      }
      if (o.hit) canvas.restore();
      if (!o.scored) {
        final center = Offset(x + width / 2, o.target * h);
        final paint = Paint()
          ..color = SkyColors.white.withValues(alpha: .55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        // A closed panel shows its own health in place of the aiming mark.
        final open = o.door?.destroyed ?? true;
        if (open && !o.hit) {
          canvas.drawCircle(center, h * .035, paint);
          canvas.drawCircle(
            center,
            h * .008,
            Paint()..color = SkyColors.white.withValues(alpha: .7),
          );
        }
        // The dotted approach line makes the safe height readable at a glance.
        for (var i = 1; i <= 4; i++) {
          canvas.drawCircle(
            center - Offset(h * (.10 + i * .06), 0),
            h * .003,
            Paint()..color = SkyColors.white.withValues(alpha: .25 + i * .05),
          );
        }
      }
    }
    if (simulation.magnetActive) _magnet(canvas, h);
    for (final trio in simulation.starTrios) {
      if ((trio.x - .2) * h > w) continue;
      if (simulation.subtleStarRewards) {
        StarGroupAura.paint(
          canvas,
          h,
          trio,
          seconds: _time,
          reducedMotion: reducedMotion,
        );
      } else {
        StarTrioArt.paint(
          canvas,
          h,
          trio,
          seconds: _time,
          reducedMotion: reducedMotion,
        );
      }
    }
    for (final star in simulation.stars) {
      if (star.collected && simulation.subtleStarRewards) {
        StarPickupArt.paint(
          canvas,
          h,
          star,
          simulation,
          reducedMotion: reducedMotion,
        );
      }
      if (star.collected || star.x * h > w + h * StarArt.reach) continue;
      StarArt.paint(
        canvas,
        Offset(star.x * h, star.y * h),
        h * StarArt.radius,
        seconds: _time,
        reducedMotion: reducedMotion,
        // A star's course position never changes, so neither does its rhythm.
        phase: star.x + simulation.distance,
      );
    }
    for (final heart in simulation.heartPickups) {
      if (heart.x * h > w + h * .07) continue;
      HeartPickupArt.paint(
        canvas,
        h,
        heart,
        seconds: _time,
        reducedMotion: reducedMotion,
      );
    }
    RushArt.vents(canvas, Size(w, h), simulation, reducedMotion: reducedMotion);
    RushArt.rings(canvas, Size(w, h), simulation, reducedMotion: reducedMotion);
    BossArt.paint(canvas, Size(w, h), simulation, reducedMotion: reducedMotion);
    CombatArt.paint(canvas, h, simulation, reducedMotion: reducedMotion);
    RushArt.swarm(canvas, Size(w, h), simulation, reducedMotion: reducedMotion);
    RushArt.meteors(
      canvas,
      Size(w, h),
      simulation,
      reducedMotion: reducedMotion,
    );
    GaleArt.debris(
      canvas,
      Size(w, h),
      simulation,
      reducedMotion: reducedMotion,
    );
    {
      final cx = FlightSimulation.birdX * h, cy = simulation.birdY * h;
      final pose = BirdPose.forFlight(
        simulation,
        reducedMotion: reducedMotion,
        bird: bird,
      );
      if (simulation.recoveryRemaining > 0) {
        // A shrinking arc explains the brief hit protection without flashing
        // the bird or making its collision position harder to read.
        final recovery = Rect.fromCircle(
          center: Offset(cx, cy),
          radius: h * .096,
        );
        canvas.drawCircle(
          recovery.center,
          recovery.width / 2,
          Paint()..color = SkyColors.cream.withValues(alpha: .2),
        );
        canvas.drawArc(
          recovery,
          -math.pi / 2,
          math.pi * 2 * (simulation.recoveryRemaining / 1.5).clamp(0, 1),
          false,
          Paint()
            ..color = SkyColors.cream
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..strokeCap = StrokeCap.round,
        );
      }
      if (simulation.collectsStars &&
          !simulation.subtleStarRewards &&
          simulation.multiplier == 3) {
        // Star power is a visible reward, with a quiet static form in Reduced Motion.
        for (var i = 0; i < 3; i++) {
          final angle =
              -math.pi / 2 +
              i * math.pi * 2 / 3 +
              (reducedMotion ? 0 : _time * .7);
          final sparkle =
              Offset(cx, cy) +
              Offset(math.cos(angle), math.sin(angle)) * h * .095;
          // Small collectibles circle the bird, each point facing outward.
          StarArt.mini(
            canvas,
            sparkle,
            h * .015,
            rotation: angle + math.pi / 2,
          );
        }
      }
      if (simulation.phase == RunPhase.playing) {
        BirdTrail.paint(
          canvas,
          bird: bird,
          anchor: Offset(cx, cy),
          unit: h * .014,
          seconds: _time,
          animate: !reducedMotion,
          empowered: !simulation.subtleStarRewards && simulation.multiplier > 1,
          // Reduced Motion keeps the rigid trail instead of a swinging tail.
          path: reducedMotion
              ? null
              : [
                  for (final p in simulation.flightPath.recent)
                    Offset(
                      cx + (p.distance - simulation.distance) * h,
                      p.y * h,
                    ),
                ],
          flown: simulation.flightPath.flown * h,
        );
      }
      if (simulation.isTrail && simulation.shield) {
        canvas.drawCircle(
          Offset(cx, cy),
          h * .078,
          Paint()..color = SkyColors.cream.withValues(alpha: .16),
        );
        canvas.drawCircle(
          Offset(cx, cy),
          h * .078,
          Paint()
            ..color = SkyColors.teal.withValues(alpha: .8)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
        canvas.drawArc(
          Rect.fromCircle(center: Offset(cx, cy), radius: h * .068),
          -2.6,
          .7,
          false,
          Paint()
            ..color = SkyColors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..strokeCap = StrokeCap.round,
        );
      }
      final bw = h * BirdFlightMotion.size;
      void paintBird(Offset center) {
        canvas.save();
        canvas.translate(center.dx, center.dy);
        canvas.rotate(pose.tilt);
        canvas.scale(1 + pose.spring, 1 - pose.spring);
        BirdPuppet.paint(
          canvas,
          Rect.fromLTWH(-bw * .48, -bw * .43, bw, bw * 224 / 256),
          bird: bird,
          wing: pose.wing,
          expression: pose.expression,
        );
        canvas.restore();
      }

      RushArt.afterimages(
        canvas,
        h,
        simulation,
        reducedMotion: reducedMotion,
        paint: (center, alpha, tint) {
          canvas.saveLayer(
            Rect.fromCircle(center: center, radius: bw),
            Paint()
              ..color = SkyColors.white.withValues(alpha: alpha)
              ..colorFilter = ColorFilter.mode(
                tint.withValues(alpha: .55),
                BlendMode.srcATop,
              ),
          );
          paintBird(center);
          canvas.restore();
        },
      );
      GaleArt.buffet(canvas, h, simulation, reducedMotion: reducedMotion);
      SprintArt.aura(canvas, h, simulation, reducedMotion: reducedMotion);
      paintBird(Offset(cx, cy));
      CombatArt.paintCharge(
        canvas,
        h,
        simulation,
        reducedMotion: reducedMotion,
      );
      if (pose.flapWake > 0) {
        final t = pose.flapWake;
        final fadeIn = (t / .18).clamp(0.0, 1.0);
        final opacity = ((1 - t) * .7 * fadeIn * fadeIn * (3 - 2 * fadeIn))
            .clamp(0.0, .7);
        final wake = Paint()
          ..color = SkyColors.cream.withValues(alpha: opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round;
        for (var i = 0; i < 2; i++) {
          final offset = h * (.024 + i * .018 + t * .03);
          canvas.drawArc(
            Rect.fromCenter(
              center: Offset(cx - h * .039, cy + offset),
              width: h * (.055 + t * .045),
              height: h * .03,
            ),
            .3,
            math.pi * .7,
            false,
            wake,
          );
        }
      }
    }
    RushArt.effects(canvas, h, simulation, reducedMotion: reducedMotion);
    GaleArt.impacts(canvas, h, simulation, reducedMotion: reducedMotion);
    RushArt.fire(canvas, Size(w, h), simulation, reducedMotion: reducedMotion);
    GaleArt.warnings(
      canvas,
      Size(w, h),
      simulation,
      reducedMotion: reducedMotion,
    );
    _feedback(canvas, h);
    canvas.restore();
    BossArt.foreground(canvas, Size(w, h), simulation, reducedMotion);
    if (simulation.boss case final boss?) {
      BossArt.healthBar(canvas, Size(w, h), boss, reducedMotion: reducedMotion);
    }
    RushArt.banner(
      canvas,
      Size(w, h),
      simulation,
      reducedMotion: reducedMotion,
    );
  }

  void _magnet(Canvas canvas, double h) {
    final center = Offset(FlightSimulation.birdX * h, simulation.birdY * h);
    final radius = simulation.pickupRadius * h;
    final field = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            SkyColors.lavender.withValues(alpha: .02),
            SkyColors.lavender.withValues(alpha: .18),
            SkyColors.cream.withValues(alpha: .06),
          ],
          stops: const [0, .88, 1],
        ).createShader(field),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = SkyColors.cream.withValues(alpha: .30)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke,
    );
    final turn = reducedMotion ? 0.0 : _time * .7;
    final arc = Paint()
      ..color = SkyColors.lavender
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < 3; i++) {
      canvas.drawArc(field, turn + i * math.pi * 2 / 3, .8, false, arc);
    }
    // Field lines show which nearby stars the expanded pickup halo will catch.
    for (final star in simulation.stars) {
      if (star.collected || star.missed) continue;
      final position = Offset(star.x * h, star.y * h);
      final separation = (position - center).distance / h;
      if (separation > .34) continue;
      final path = Path()
        ..moveTo(position.dx, position.dy)
        ..quadraticBezierTo(
          (position.dx + center.dx) / 2,
          math.min(position.dy, center.dy) - h * .04,
          center.dx,
          center.dy,
        );
      canvas.drawPath(
        path,
        Paint()
          ..color = SkyColors.cream.withValues(
            alpha: (1 - separation / .34) * .8,
          )
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke,
      );
    }
  }

  void _feedback(Canvas canvas, double h) {
    final dark = SkyPalette.at(simulation.elapsed).top.computeLuminance() < .22;
    final active = simulation.events
        .where(
          (e) =>
              simulation.elapsed - e.at < 1.3 &&
              // Star feedback stays at the completed group, away from the bird.
              !(simulation.subtleStarRewards &&
                  (e.kind == FlightEventKind.star ||
                      e.kind == FlightEventKind.starTrio ||
                      e.kind == FlightEventKind.streak)) &&
              !(simulation.boss?.cinematic == true &&
                  e.kind == FlightEventKind.bossDefeated) &&
              // Rush and gale banners are drawn large at the top of the screen.
              e.kind != FlightEventKind.rushWarning &&
              e.kind != FlightEventKind.rushEscaped &&
              e.kind != FlightEventKind.galeWarning &&
              e.kind != FlightEventKind.galeWeathered,
        )
        .toList();
    final messages = active
        .where((e) => e.kind != FlightEventKind.star)
        .toList();
    final callouts = messages
        .where((e) => e.kind == FlightEventKind.heart)
        .toList();
    final major = callouts.isNotEmpty
        ? callouts.last
        : messages.isEmpty
        ? null
        : messages.last;
    for (final event in active) {
      final age = simulation.elapsed - event.at;
      final t = (age / 1.3).clamp(0.0, 1.0);
      final alpha = (1 - t * t).clamp(0.0, 1.0);
      final center = Offset(FlightSimulation.birdX * h, event.y * h);
      final color = switch (event.kind) {
        FlightEventKind.hit ||
        FlightEventKind.heart ||
        FlightEventKind.scorched => SkyColors.coral,
        FlightEventKind.sprintRing => SkyColors.yellow,
        FlightEventKind.shieldReady ||
        FlightEventKind.shieldUsed => SkyColors.teal,
        FlightEventKind.magnet => SkyColors.purple,
        _ => SkyColors.gold,
      };
      final gate =
          event.kind == FlightEventKind.perfect ||
          event.kind == FlightEventKind.milestone;
      if (!reducedMotion && gate) {
        // Gate rewards burst in the materials of the region they happened in.
        RegionBurst.paint(
          canvas,
          WorldTour.at(event.at).dominant,
          center,
          h,
          t: t,
          alpha: alpha,
          perfect: event.kind == FlightEventKind.perfect,
        );
      } else if (!reducedMotion) {
        for (var i = 0; i < 8; i++) {
          final a = i * math.pi / 4;
          final radius = h * (.05 + t * .13);
          final pos = center + Offset(math.cos(a), math.sin(a)) * radius;
          StarArt.sparkle(
            canvas,
            pos,
            h * .01 * (1 - t),
            color.withValues(alpha: alpha),
            rotation: a + math.pi / 2,
          );
        }
      }
      // Keep one major callout plus pickup points, so simultaneous rewards stay legible.
      if (event.kind != FlightEventKind.star && major != event) {
        continue;
      }
      final label = switch (event.kind) {
        FlightEventKind.star => '+${event.value}',
        FlightEventKind.heart => '+1 LIFE!',
        FlightEventKind.starTrio => 'STAR TRIO +${event.value}!',
        FlightEventKind.enemyHit =>
          event.value > 0 ? 'NICE SHOT +${event.value}!' : 'NICE SHOT!',
        FlightEventKind.enemyRammed =>
          event.value > 0 ? 'SMASH +${event.value}!' : 'SMASH!',
        FlightEventKind.bossDefeated =>
          event.value > 0 ? 'BOSS DOWN +${event.value}!' : 'BOSS DOWN!',
        FlightEventKind.streak => '${event.value}× STAR POWER!',
        FlightEventKind.perfect =>
          event.value > 1 ? 'PERFECT ×${event.value}' : 'PERFECT!',
        FlightEventKind.shieldReady => 'SHIELD READY',
        FlightEventKind.shieldUsed => 'SHIELD SAVE!',
        FlightEventKind.hit => 'KEEP FLYING!',
        FlightEventKind.milestone => '${event.value} GATES!',
        FlightEventKind.finalStretch => '10 SECONDS LEFT',
        FlightEventKind.magnet => 'STAR MAGNET!',
        FlightEventKind.sprintRing =>
          event.value > 1 ? 'RUSH ×${event.value}!' : 'SPRINT RING!',
        FlightEventKind.smashed =>
          event.value > 1
              ? 'SMASH ×${event.value}!'
              : 'SMASH +${Rush.smashPoints}!',
        FlightEventKind.meteorSmashed =>
          event.value > 1
              ? 'SMASH ×${event.value}!'
              : 'METEOR +${Rush.meteorPoints}!',
        FlightEventKind.swarmSmashed =>
          event.value > 1
              ? 'SMASH ×${event.value}!'
              : 'BAT +${Rush.batPoints}!',
        FlightEventKind.scorched => 'SCORCHED!',
        FlightEventKind.rushWarning ||
        FlightEventKind.rushEscaped ||
        FlightEventKind.galeWarning ||
        FlightEventKind.galeWeathered => '',
      };
      final text = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            fontFamily: 'Fredoka',
            fontWeight: FontWeight.w600,
            fontSize: h * (event.kind == FlightEventKind.star ? .045 : .038),
            color: (dark ? SkyColors.cream : SkyColors.ink).withValues(
              alpha: alpha,
            ),
            shadows: [
              Shadow(
                color: (dark ? SkyColors.ink : SkyColors.white).withValues(
                  alpha: alpha,
                ),
                offset: const Offset(0, 1),
                blurRadius: 2,
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final rise = reducedMotion ? 0.0 : t * h * .06;
      final labelY = event.kind == FlightEventKind.star
          ? center.dy + h * .025
          : center.dy + h * (event.y < .3 ? .16 : -.14);
      text.paint(
        canvas,
        Offset(center.dx + h * .09, (labelY - rise).clamp(h * .16, h * .85)),
      );
    }
  }

  void _tower(
    Canvas canvas,
    Rect bounds,
    bool top, {
    required bool cleared,
    required bool perfect,
    ObstacleKind kind = ObstacleKind.garden,
  }) {
    if (bounds.right < 0 || bounds.left > size.x) return;
    GateArt.paint(
      canvas,
      bounds,
      top: top,
      kind: kind,
      seconds: simulation.elapsed,
      reducedMotion: reducedMotion,
      cleared: cleared,
      perfect: perfect,
    );
  }
}
