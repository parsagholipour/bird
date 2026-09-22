import 'dart:math' as math;
import 'package:flutter/painting.dart';
import 'package:flame/game.dart';
import 'package:flame/sprite.dart';
import '../domain/game_rules.dart';
import '../domain/cloud_friends.dart';
import '../domain/bird_motion.dart';
import '../ui/theme.dart';
import 'sky_scenery.dart';
import 'bird_trail.dart';
import 'courier_art.dart';
import 'cloud_friend_art.dart';
import 'bird_puppet.dart';
import 'star_trio_art.dart';
import 'arrival_art.dart';
import 'gate_art.dart';
import 'obstacle_art.dart';
import 'combat_art.dart';
import 'boss_art.dart';
import 'heart_pickup_art.dart';
import 'door_art.dart';
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
  Sprite? _island;
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
  Future<void> onLoad() async {
    await super.onLoad();
    _island = await loadSprite('island.png');
  }

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
    final shake = BossArt.cameraOffset(simulation.boss, reducedMotion) * h;
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
      if (_island != null) {
        final scenicDistance = reducedMotion ? 0.0 : simulation.distance;
        final x =
            ((w * .73 + h * .5 - scenicDistance * h * .13) % (w + h * .5)) -
            h * .5;
        _island!.render(
          canvas,
          position: Vector2(x, h * .77),
          size: Vector2(h * .5, h * .3125),
          overridePaint: Paint()..color = const Color(0x77ffffff),
        );
        _island!.render(
          canvas,
          position: Vector2(
            ((w * .18 + h * .32 - scenicDistance * h * .08) % (w + h * .32)) -
                h * .32,
            h * .86,
          ),
          size: Vector2(h * .32, h * .20),
          overridePaint: Paint()..color = const Color(0x55ffffff),
        );
      }
    }
    BossArt.backdrop(canvas, Size(w, h), simulation.boss, reducedMotion);
    ArrivalArt.gate(canvas, h, simulation, reducedMotion: reducedMotion);
    SprintArt.streaks(
      canvas,
      Size(w, h),
      simulation,
      reducedMotion: reducedMotion,
    );
    for (final o in simulation.obstacles) {
      final x = o.x * h, width = o.width * h;
      final cleared = o.scored && !o.hit;
      final perfect = cleared && o.maxDeviation <= .075;
      if (simulation.isCruise) {
        final ring = Rect.fromCenter(
          center: Offset(x + width / 2, o.target * h),
          width: h * .12,
          height:
              math.min(
                o.gap * .68,
                2 * (math.min(o.target, 1 - o.target) - .012),
              ) *
              h,
        );
        if (simulation.rulesVersion >= 13) {
          ObstacleArt.ring(
            canvas,
            ring,
            o,
            seconds: simulation.elapsed,
            reducedMotion: reducedMotion,
            cleared: cleared,
            refined: simulation.rulesVersion >= 14,
          );
        } else {
          canvas.drawOval(
            ring,
            Paint()
              ..color = (cleared ? SkyColors.mint : SkyColors.cream).withValues(
                alpha: cleared ? .7 : .2,
              )
              ..strokeWidth = 8
              ..style = PaintingStyle.stroke,
          );
          canvas.drawOval(
            ring,
            Paint()
              ..color = cleared
                  ? SkyColors.teal
                  : SkyColors.cream.withValues(alpha: .65)
              ..strokeWidth = 2
              ..style = PaintingStyle.stroke,
          );
        }
        if (cleared) _gateSeal(canvas, ring.center, h, perfect);
      } else {
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
        if (cleared && !simulation.isCourier) {
          _gateSeal(canvas, Offset(x + width / 2, o.target * h), h, perfect);
        }
        if (o.hit) canvas.restore();
      }
      if (cleared && o.courierStop != null) {
        CourierArt.station(
          canvas,
          Offset(x + width / 2, o.target * h),
          h,
          o.courierStop!,
          carrying: simulation.carryingLetter || o.courierActionAt != null,
          handled:
              o.courierActionAt != null &&
              (o.courierStop == CourierStop.pickup ||
                  reducedMotion ||
                  simulation.elapsed - o.courierActionAt! >=
                      CourierArt.handoffDuration),
          showLabel: false,
        );
      }
      if (!o.scored) {
        final center = Offset(x + width / 2, o.target * h);
        final paint = Paint()
          ..color = SkyColors.white.withValues(alpha: .55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        // A closed panel shows its own health in place of the aiming mark.
        final open = o.door?.destroyed ?? true;
        if (open && o.courierStop != null && !o.hit) {
          CourierArt.station(
            canvas,
            center,
            h,
            o.courierStop!,
            carrying: simulation.carryingLetter,
          );
        } else if (open && !o.hit) {
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
    for (final cloud in simulation.clouds) {
      if (cloud.discovered || cloud.x * h > w + h * .2) continue;
      CloudFriendArt.inSky(
        canvas,
        center: Offset(cloud.x * h, cloud.y * h),
        height: h,
        friend: cloud.friend,
        known: simulation.cloudFriends.contains(cloud.friend),
        seconds: _time,
        reducedMotion: reducedMotion,
      );
    }
    if (simulation.magnetActive) _magnet(canvas, h);
    for (final trio in simulation.starTrios) {
      if ((trio.x - .2) * h > w) continue;
      StarTrioArt.paint(
        canvas,
        h,
        trio,
        seconds: _time,
        reducedMotion: reducedMotion,
      );
    }
    for (final star in simulation.stars) {
      if (star.collected || star.x * h > w + 30) continue;
      final center = Offset(star.x * h, star.y * h);
      final pulse = reducedMotion
          ? 1.0
          : 1 + math.sin(_time * 4 + star.x * 3) * .1;
      canvas.drawCircle(
        center,
        h * .055 * pulse,
        Paint()..color = SkyColors.yellow.withValues(alpha: .12),
      );
      canvas.drawCircle(
        center,
        h * .038,
        Paint()..color = SkyColors.cream.withValues(alpha: .6),
      );
      canvas.drawPath(
        SkyScenery.star(center + Offset(0, h * .004), h * SkyStar.radius),
        Paint()..color = SkyColors.gold,
      );
      canvas.drawPath(
        SkyScenery.star(center, h * SkyStar.radius),
        Paint()..color = SkyColors.yellow,
      );
      canvas.drawCircle(
        center - Offset(h * .005, h * .005),
        h * .004,
        Paint()..color = SkyColors.cream,
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
    BossArt.paint(canvas, Size(w, h), simulation, reducedMotion: reducedMotion);
    CombatArt.paint(canvas, h, simulation, reducedMotion: reducedMotion);
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
      if (simulation.collectsStars && simulation.multiplier == 3) {
        // Star power is a visible reward, with a quiet static form in Reduced Motion.
        for (var i = 0; i < 3; i++) {
          final angle =
              -math.pi / 2 +
              i * math.pi * 2 / 3 +
              (reducedMotion ? 0 : _time * .7);
          final sparkle =
              Offset(cx, cy) +
              Offset(math.cos(angle), math.sin(angle)) * h * .095;
          canvas.drawPath(
            SkyScenery.star(sparkle, h * .013),
            Paint()..color = SkyColors.yellow,
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
          empowered: simulation.multiplier > 1,
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
      SprintArt.aura(canvas, h, simulation, reducedMotion: reducedMotion);
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(pose.tilt);
      canvas.scale(1 + pose.spring, 1 - pose.spring);
      final bw = h * BirdFlightMotion.size;
      BirdPuppet.paint(
        canvas,
        Rect.fromLTWH(-bw * .48, -bw * .43, bw, bw * 224 / 256),
        bird: bird,
        wing: pose.wing,
        expression: pose.expression,
      );
      canvas.restore();
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
      if (simulation.isCourier &&
          simulation.carryingLetter &&
          !CourierArt.collecting(simulation, reducedMotion: reducedMotion)) {
        final parcel = Offset(cx + h * .045, cy + h * .065);
        canvas.drawLine(
          Offset(cx + h * .025, cy + h * .042),
          parcel,
          Paint()
            ..color = SkyColors.coralDeep
            ..strokeWidth = 2,
        );
        CourierArt.letter(canvas, parcel, h * .057, gold: true);
      }
    }
    if (simulation.isCourier) {
      CourierArt.handoff(canvas, h, simulation, reducedMotion: reducedMotion);
    }
    _feedback(canvas, h);
    canvas.restore();
    BossArt.foreground(canvas, Size(w, h), simulation, reducedMotion);
    if (simulation.boss case final boss?) {
      BossArt.healthBar(canvas, Size(w, h), boss);
    }
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
              !(simulation.boss?.cinematic == true &&
                  e.kind == FlightEventKind.bossDefeated),
        )
        .toList();
    final messages = active
        .where((e) => e.kind != FlightEventKind.star)
        .toList();
    final courierMessages = messages
        .where(
          (e) =>
              e.kind == FlightEventKind.cloudFriend ||
              e.kind == FlightEventKind.heart ||
              e.kind == FlightEventKind.letter ||
              e.kind == FlightEventKind.delivery ||
              e.kind == FlightEventKind.letterLost,
        )
        .toList();
    final major = courierMessages.isNotEmpty
        ? courierMessages.last
        : messages.isEmpty
        ? null
        : messages.last;
    for (final event in active) {
      final age = simulation.elapsed - event.at;
      final t = (age / 1.3).clamp(0.0, 1.0);
      final alpha = (1 - t * t).clamp(0.0, 1.0);
      final center = Offset(FlightSimulation.birdX * h, event.y * h);
      final color = switch (event.kind) {
        FlightEventKind.hit || FlightEventKind.heart => SkyColors.coral,
        FlightEventKind.shieldReady ||
        FlightEventKind.shieldUsed => SkyColors.teal,
        FlightEventKind.magnet => SkyColors.purple,
        FlightEventKind.letterLost => SkyColors.coral,
        FlightEventKind.delivery => SkyColors.teal,
        FlightEventKind.cloudFriend => SkyColors.skyDeep,
        _ => SkyColors.gold,
      };
      if (!reducedMotion) {
        for (var i = 0; i < 8; i++) {
          final a = i * math.pi / 4;
          final radius = h * (.05 + t * .13);
          final pos = center + Offset(math.cos(a), math.sin(a)) * radius;
          canvas.drawPath(
            SkyScenery.star(pos, h * .009 * (1 - t)),
            Paint()..color = color.withValues(alpha: alpha),
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
        FlightEventKind.letter => 'LETTER ABOARD!',
        FlightEventKind.delivery => 'DELIVERED!',
        FlightEventKind.letterLost => 'LETTER DROPPED',
        FlightEventKind.cloudFriend =>
          'HELLO, ${CloudFriend.values[event.value].title.toUpperCase()}!',
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

  void _gateSeal(Canvas c, Offset center, double h, bool perfect) {
    c.drawCircle(
      center,
      h * .032,
      Paint()..color = SkyColors.cream.withValues(alpha: .85),
    );
    if (perfect) {
      c.drawPath(
        SkyScenery.star(center, h * .023),
        Paint()..color = SkyColors.gold,
      );
    } else {
      c.drawPath(
        Path()
          ..moveTo(center.dx - h * .014, center.dy)
          ..lineTo(center.dx - h * .004, center.dy + h * .011)
          ..lineTo(center.dx + h * .016, center.dy - h * .012),
        Paint()
          ..color = SkyColors.teal
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
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
