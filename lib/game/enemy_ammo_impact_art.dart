import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../domain/game_rules.dart';
import '../ui/theme.dart';
import 'enemy_ammo_art.dart';

/// The last beat of an enemy pellet: spit splats and embers fizzle against a
/// wall or the bird, and either one bursts when the player's rock meets it.
///
/// Everything is a pure function of the stored impact and its age, so a
/// paused frame stays exact and seeking reproduces it. Under Reduced Motion
/// nothing flies or expands; a still mark acknowledges the impact and fades.
abstract final class EnemyAmmoImpactArt {
  static const seconds = .34;
  static const _slate = Color(0xff425b63), _chipLight = Color(0xff8aa3a8);
  static const _smoke = Color(0xff9d93b6);

  static void paint(
    Canvas canvas,
    double height,
    FlightSimulation sim, {
    required bool reducedMotion,
  }) {
    for (final impact in sim.enemyAmmoImpacts) {
      final age = sim.elapsed - impact.at;
      if (!(age >= 0 && age < seconds)) continue;
      // A wall splat scrolls with the wall; a hit on the bird stays on it.
      final center = impact.stop == AmmoStop.struck
          ? Offset(impact.x, impact.y + sim.birdY - impact.birdY)
          : Offset(impact.worldX - sim.distance, impact.y);
      splash(
        canvas,
        center * height,
        height * EnemyAmmo.radius,
        direction: impact.direction,
        attack: impact.attack,
        stop: impact.stop,
        age: age,
        reducedMotion: reducedMotion,
        seed: (impact.worldX * 37.7 + impact.y * 91.3) % 1,
      );
    }
  }

  static void splash(
    Canvas c,
    Offset center,
    double radius, {
    required double direction,
    required EnemyAttack attack,
    required AmmoStop stop,
    required double age,
    required bool reducedMotion,
    double seed = 0,
  }) {
    if (!radius.isFinite || radius <= 0 || !(age >= 0 && age < seconds)) {
      return;
    }
    final spit = attack == EnemyAttack.aimed;
    final edge = math.max(.15, 1.6 / radius);
    c.save();
    c.translate(center.dx, center.dy);
    c.scale(radius);
    if (reducedMotion) {
      _still(c, spit, stop, age, direction, edge);
    } else if (stop == AmmoStop.deflected) {
      _burst(c, spit, age, direction, seed);
    } else if (spit) {
      _splat(c, age, direction, edge, seed, stop == AmmoStop.struck);
    } else {
      _fizzle(c, age, direction, edge, seed, stop == AmmoStop.struck);
    }
    c.restore();
  }

  static double _out(double t) => 1 - math.pow(1 - t, 3).toDouble();

  /// Local frame with +x along the pellet's travel and the light on top.
  static void _face(Canvas c, double direction) {
    c.rotate(direction);
    if (math.cos(direction) < 0) c.scale(1, -1);
  }

  /// Rebounding debris: a cone around [back], a little gravity, then fade.
  static Iterable<(Offset, double, double, int)> _spray(
    double age,
    double back,
    double seed, {
    required List<double> spreads,
    required List<double> speeds,
    double from = .45,
    double reach = 3.0,
    double gravity = 2.8,
    double delay = .012,
  }) sync* {
    final p = ((age - delay) / (seconds - delay)).clamp(0.0, 1.0);
    if (p <= 0) return;
    final travel = _out(p);
    final fade = p < .6 ? 1.0 : (1 - p) / .4;
    for (var i = 0; i < spreads.length; i++) {
      final a = back + spreads[i] + (seed - .5) * .3;
      final d = from + reach * speeds[i] * travel;
      yield (
        Offset(math.cos(a) * d, math.sin(a) * d + gravity * p * p),
        p,
        fade,
        i,
      );
    }
  }

  // Spit meets a wall or the bird: the drop flattens, splats and sprays back.
  static void _splat(
    Canvas c,
    double age,
    double direction,
    double edge,
    double seed,
    bool struck,
  ) {
    const sizes = [.34, .26, .40, .30, .36, .24];
    for (final (at, p, fade, i) in _spray(
      age,
      direction + math.pi,
      seed,
      spreads: struck
          ? const [-1.25, -.75, -.25, .25, .75, 1.25]
          : const [-1.0, -.6, -.2, .2, .6, 1.0],
      speeds: const [.7, 1.35, .95, 1.2, .75, 1.05],
    )) {
      final r = sizes[i] * (1.15 - p * .75);
      c.drawCircle(at, r, _fill(EnemyAmmoArt.green.withValues(alpha: fade)));
      c.drawCircle(
        at + Offset(-r * .12, -r * .22),
        r * .6,
        _fill(EnemyAmmoArt.jade.withValues(alpha: fade)),
      );
    }
    c.save();
    _face(c, direction);
    // A goo star stays on the wall a moment after the drop is gone.
    final mark = ((age - .015) / .1).clamp(0.0, 1.0);
    if (mark > 0) {
      final fade = age < .16 ? 1.0 : 1 - (age - .16) / (seconds - .16);
      c.save();
      c.translate(.3, 0);
      c.scale(.5 + .1 * mark, .75 + .55 * _out(mark));
      final star = _gooStar(seed);
      c.drawPath(star, _fill(EnemyAmmoArt.jade.withValues(alpha: fade)));
      c.drawPath(
        star,
        _stroke(EnemyAmmoArt.green.withValues(alpha: fade), edge * 1.1),
      );
      c.drawCircle(
        const Offset(-.1, -.3),
        .26,
        _fill(EnemyAmmoArt.mint.withValues(alpha: fade)),
      );
      c.restore();
    }
    // The drop itself squashes flat against the surface, then gives way.
    if (age < .09) {
      final flat = _out(math.min(1.0, age / .05));
      final fade = age < .05 ? 1.0 : 1 - (age - .05) / .04;
      final body = 1 - edge / 2;
      final rect = Rect.fromCenter(
        center: Offset(.3 * flat, 0),
        width: 2 * body * (1 - .55 * flat),
        height: 2 * body * (1 + .45 * flat),
      );
      c.drawOval(rect, _fill(EnemyAmmoArt.leaf.withValues(alpha: fade)));
      c.drawOval(
        Rect.fromCenter(
          center: rect.center + Offset(0, -rect.height * .2),
          width: rect.width * .5,
          height: rect.height * .3,
        ),
        _fill(SkyColors.cream.withValues(alpha: fade)),
      );
      c.drawOval(rect, _stroke(SkyColors.ink.withValues(alpha: fade), edge));
    }
    c.restore();
  }

  static Path _gooStar(double seed) {
    final path = Path();
    const lobes = 7;
    for (var i = 0; i <= lobes; i++) {
      final a = i * math.pi * 2 / lobes + seed;
      final reach = 1.05 + .28 * math.sin(i * 2.7 + seed * 6);
      final tip = Offset(math.cos(a) * reach, math.sin(a) * reach);
      if (i == 0) {
        path.moveTo(tip.dx, tip.dy);
        continue;
      }
      final mid = a - math.pi / lobes;
      path.quadraticBezierTo(
        math.cos(mid) * .5,
        math.sin(mid) * .5,
        tip.dx,
        tip.dy,
      );
    }
    return path..close();
  }

  // An ember meets a wall or the bird: it flattens into a hot flash, sparks
  // spray back and a small puff of smoke drifts up.
  static void _fizzle(
    Canvas c,
    double age,
    double direction,
    double edge,
    double seed,
    bool struck,
  ) {
    final back = direction + math.pi;
    for (var i = 0; i < 3; i++) {
      final start = .035 + i * .03;
      final p = ((age - start) / (seconds - start)).clamp(0.0, 1.0);
      if (p <= 0) continue;
      final a = back + (i - 1) * .75;
      final spread = .55 + 1.0 * _out(p);
      c.drawCircle(
        Offset(math.cos(a) * spread, math.sin(a) * spread - 1.6 * p),
        .5 + .75 * _out(p),
        _fill(_smoke.withValues(alpha: .45 * (1 - p))),
      );
    }
    for (final (head, p, fade, i) in _spray(
      age,
      back,
      seed,
      spreads: struck
          ? const [-1.2, -.72, -.28, .14, .6, 1.1]
          : const [-1.0, -.62, -.25, .12, .5, .88],
      speeds: const [.8, 1.3, 1.0, 1.4, .9, 1.15],
      from: .6,
      reach: 3.4,
      gravity: 2.2,
      delay: .008,
    )) {
      final a = back + (struck ? 1.0 : .85) * (i - 2.5) * .42;
      final streak = Offset(math.cos(a), math.sin(a)) * (1.2 * (1 - p) + .15);
      final color = Color.lerp(
        EnemyAmmoArt.hot,
        EnemyAmmoArt.flame,
        math.min(1.0, p * 1.6),
      )!;
      c.drawLine(
        head - streak,
        head,
        _stroke(color.withValues(alpha: fade), .34 * (1 - p) + .12),
      );
    }
    if (age < .14) {
      final p = age / .14;
      final r = 1.1 + 1.1 * _out(p);
      c.drawCircle(
        Offset.zero,
        r,
        Paint()
          ..shader = RadialGradient(
            colors: [
              EnemyAmmoArt.hot.withValues(alpha: 1 - p),
              EnemyAmmoArt.amber.withValues(alpha: .8 * (1 - p)),
              EnemyAmmoArt.amber.withValues(alpha: 0),
            ],
            stops: const [.3, .6, 1],
          ).createShader(Rect.fromCircle(center: Offset.zero, radius: r)),
      );
    }
    // The ember's head squashes flat against the surface, then burns out.
    if (age < .08) {
      final flat = _out(math.min(1.0, age / .045));
      final fade = age < .045 ? 1.0 : 1 - (age - .045) / .035;
      final body = 1 - edge / 2;
      c.save();
      _face(c, direction);
      final rect = Rect.fromCenter(
        center: Offset(.3 * flat, 0),
        width: 2 * body * (1 - .55 * flat),
        height: 2 * body * (1 + .4 * flat),
      );
      c.drawOval(
        rect,
        Paint()
          ..shader = RadialGradient(
            colors: [
              EnemyAmmoArt.hot.withValues(alpha: fade),
              EnemyAmmoArt.amber.withValues(alpha: fade),
              EnemyAmmoArt.flame.withValues(alpha: fade),
            ],
            stops: const [.25, .6, 1],
          ).createShader(rect),
      );
      c.drawOval(rect, _stroke(SkyColors.ink.withValues(alpha: fade), edge));
      c.restore();
    }
  }

  // The player's rock wins: a crisp pop ring, the pellet shattered back
  // toward its shooter and two chips of the spent stone falling away.
  static void _burst(
    Canvas c,
    bool spit,
    double age,
    double direction,
    double seed,
  ) {
    final accent = spit ? EnemyAmmoArt.jade : EnemyAmmoArt.flame;
    final back = direction + math.pi;
    final p = math.min(1.0, age / .22);
    if (p < 1) {
      final r = 1.0 + 2.2 * _out(p);
      final w = .75 * (1 - p) + .08;
      c.drawCircle(
        Offset.zero,
        r,
        _stroke(accent.withValues(alpha: 1 - p * p), w),
      );
      c.drawCircle(
        Offset.zero,
        r - w * .45,
        _stroke(SkyColors.cream.withValues(alpha: 1 - p), w * .5),
      );
    }
    // A comic "clack": short cream strokes snap outward from the contact.
    if (age < .1) {
      final q = age / .1;
      for (var i = 0; i < 6; i++) {
        final a = back + .26 + i * math.pi / 3;
        final v = Offset(math.cos(a), math.sin(a));
        final inner = 1.1 + 1.5 * _out(q);
        c.drawLine(
          v * inner,
          v * (inner + .95 * (1 - q) + .15),
          _stroke(
            SkyColors.cream.withValues(alpha: 1 - q * q),
            .36 * (1 - q) + .1,
          ),
        );
      }
    }
    if (age < .04) {
      final flash = 1 - age / .04;
      c.drawCircle(
        Offset.zero,
        .35 + .6 * flash,
        _fill(SkyColors.cream.withValues(alpha: flash)),
      );
    }
    for (final (at, p, fade, i) in _spray(
      age,
      back,
      seed,
      spreads: const [-.95, -.35, .3, .9],
      speeds: const [1.15, 1.5, 1.35, 1.05],
      from: .6,
      reach: 3.2,
      gravity: 2.4,
      delay: .02,
    )) {
      if (spit) {
        final r = (.38 - (i % 2) * .08) * (1.1 - p * .7);
        c.drawCircle(at, r, _fill(EnemyAmmoArt.green.withValues(alpha: fade)));
        c.drawCircle(
          at + Offset(-r * .12, -r * .22),
          r * .6,
          _fill(EnemyAmmoArt.jade.withValues(alpha: fade)),
        );
      } else {
        final a = back + const [-.95, -.35, .3, .9][i];
        final streak = Offset(math.cos(a), math.sin(a)) * (1.1 * (1 - p) + .15);
        c.drawLine(
          at - streak,
          at,
          _stroke(
            Color.lerp(
              EnemyAmmoArt.hot,
              EnemyAmmoArt.flame,
              p,
            )!.withValues(alpha: fade),
            .32 * (1 - p) + .12,
          ),
        );
      }
    }
    // Stone chips pop up and down off the impact, tumbling as they fall.
    for (final (at, p, fade, i) in _spray(
      age,
      direction,
      seed,
      spreads: const [-1.9, 1.7],
      speeds: const [.9, .7],
      from: .5,
      reach: 2.4,
      gravity: 3.4,
      delay: .015,
    )) {
      c.save();
      c.translate(at.dx, at.dy);
      c.rotate(p * (i == 0 ? 5 : -4));
      final s = .46 - i * .08;
      c.drawPath(
        Path()
          ..moveTo(s * .8, -s * .35)
          ..lineTo(-s * .2, -s * .8)
          ..lineTo(-s * .8, -s * .05)
          ..lineTo(-s * .1, s * .7)
          ..lineTo(s * .7, s * .4)
          ..close(),
        _fill(_slate.withValues(alpha: fade)),
      );
      c.drawLine(
        Offset(-s * .45, -s * .4),
        Offset(s * .5, -s * .45),
        _stroke(_chipLight.withValues(alpha: fade), s * .35),
      );
      c.restore();
    }
  }

  static void _still(
    Canvas c,
    bool spit,
    AmmoStop stop,
    double age,
    double direction,
    double edge,
  ) {
    final fade = age < .12 ? 1.0 : 1 - (age - .12) / (seconds - .12);
    if (stop == AmmoStop.deflected) {
      final accent = spit ? EnemyAmmoArt.jade : EnemyAmmoArt.flame;
      c.drawCircle(
        Offset.zero,
        1.9,
        _stroke(accent.withValues(alpha: fade), .45),
      );
      c.drawCircle(
        Offset.zero,
        1.8,
        _stroke(SkyColors.cream.withValues(alpha: fade), .22),
      );
      return;
    }
    if (spit) {
      c.save();
      _face(c, direction);
      c.translate(.3, 0);
      c.scale(.6, 1.3);
      final star = _gooStar(0);
      c.drawPath(star, _fill(EnemyAmmoArt.jade.withValues(alpha: fade)));
      c.drawPath(
        star,
        _stroke(EnemyAmmoArt.green.withValues(alpha: fade), edge * 1.1),
      );
      c.drawCircle(
        const Offset(-.1, -.3),
        .26,
        _fill(EnemyAmmoArt.mint.withValues(alpha: fade)),
      );
      c.restore();
      return;
    }
    c.drawCircle(
      Offset.zero,
      1.8,
      Paint()
        ..shader = RadialGradient(
          colors: [
            EnemyAmmoArt.hot.withValues(alpha: fade),
            EnemyAmmoArt.amber.withValues(alpha: .8 * fade),
            EnemyAmmoArt.amber.withValues(alpha: 0),
          ],
          stops: const [.3, .6, 1],
        ).createShader(Rect.fromCircle(center: Offset.zero, radius: 1.8)),
    );
  }

  static Paint _fill(Color color) => Paint()..color = color;

  static Paint _stroke(Color color, double width) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
}
