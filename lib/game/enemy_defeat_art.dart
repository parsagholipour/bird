import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../domain/sky_enemy.dart';
import '../ui/theme.dart';
import 'enemy_designs/aimed_enemy.dart';
import 'enemy_designs/alley_pigeon.dart';
import 'enemy_designs/patrol_bat.dart';
import 'enemy_designs/simple_bat.dart';
import 'enemy_designs/spread_enemy.dart';

/// A small enemy's knockout, driven only by the defeat event's age.
///
/// The beaten enemy flashes, is knocked back and tumbles into a chunky
/// outlined poof, while debris that belongs to it (fur tufts, shell chips,
/// wing scales) is flung out under gravity and a few twinkles close the
/// moment. A shot knocks the enemy right, the way the rock was travelling; a
/// ram throws it up and away with a bigger cloud and more debris. Every
/// piece shrinks to nothing, so the effect ends cleanly without a layer.
abstract final class EnemyDefeatArt {
  static const seconds = .6;

  /// [center] is where the enemy stood and [radius] its hit radius in
  /// pixels. [kind] tints the cloud and debris and draws the enemy itself
  /// into the poof when [ghost] is set; without it a neutral burst is used.
  static void paint(
    Canvas canvas,
    Offset center,
    double radius, {
    required double age,
    required bool reducedMotion,
    bool rammed = false,
    EnemyKind? kind,
    bool ghost = true,
    int seed = 0,
  }) {
    if (!age.isFinite || age < 0 || age >= seconds) return;
    if (!radius.isFinite || radius <= 0) return;
    final tint = _Tint.of(kind);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(radius);
    if (reducedMotion) {
      _still(canvas, age, tint, seed);
    } else {
      _burst(
        canvas,
        radius,
        age,
        tint,
        ghost ? kind : null,
        rammed: rammed,
        seed: seed,
      );
    }
    canvas.restore();
  }

  static void _burst(
    Canvas c,
    double radius,
    double age,
    _Tint tint,
    EnemyKind? ghost, {
    required bool rammed,
    required int seed,
  }) {
    // Rocks arrive from the left, so a shot carries the enemy right. The
    // sprinting bird hits harder and lifts it.
    final knock = rammed ? const Offset(1.15, -.78) : const Offset(.78, -.2);
    final at = knock * _outCubic(age / .22);
    final size = rammed ? 1.28 : 1.0;
    final cloud = at + Offset(0, -.34 * size * _outQuad(age / seconds));

    _ring(c, age, rammed);
    if (ghost != null) _ghost(c, radius, ghost, age, at, rammed);
    _cloud(c, age, cloud, size, tint, seed);
    _impact(c, age, rammed, seed);
    _debris(c, age, knock * _outCubic(_launch / .22), tint, rammed, seed);
    _twinkles(c, age, cloud, size, rammed, seed);
  }

  // Reduced Motion: one stationary poof and star that simply fade away.
  static void _still(Canvas c, double age, _Tint tint, int seed) {
    final alpha = .5 + .5 * math.cos(math.pi * age / seconds);
    c.saveLayer(
      const Rect.fromLTRB(-2.4, -2.4, 2.4, 2.4),
      Paint()..color = Color.fromRGBO(0, 0, 0, alpha),
    );
    _cloud(c, null, Offset.zero, 1, tint, seed);
    _twinkle(c, const Offset(1.05, -.95), .38, .3);
    c.restore();
  }

  static const _launch = .045;
  static const _amber = Color(0xffb86a2a);

  static void _ring(Canvas c, double age, bool rammed) {
    // A quick shock that is gone before it can read as a bubble.
    final t = age / (rammed ? .2 : .13);
    if (t >= 1) return;
    c.drawCircle(
      Offset.zero,
      .8 + _outCubic(t) * (rammed ? 2.1 : 1.4),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = (rammed ? .32 : .24) * (1 - t)
        ..color = SkyColors.white.withValues(alpha: .95 * (1 - t) * (1 - t)),
    );
  }

  /// A hot cartoon starburst where the blow landed.
  static void _impact(Canvas c, double age, bool rammed, int seed) {
    final t = age / .12;
    if (t >= 1) return;
    // Full size on the very first frame, a small swell, then it snaps shut.
    final size =
        (rammed ? 1.1 : .85) *
        (t < .3
            ? 1 + .15 * math.sin(t / .3 * math.pi)
            : 1 - _inQuad((t - .3) / .7));
    if (size <= 0) return;
    c.save();
    // At the enemy's front, where the rock or the bird's beak connected.
    c.translate(rammed ? -.75 : -.85, .05);
    c.rotate((_hash(1, seed) - .5) * .6);
    c.scale(size);
    c.drawPath(_burstShape, Paint()..color = SkyColors.yellow);
    c.drawPath(
      _burstShape,
      Paint()
        ..color = SkyColors.coralDeep
        ..style = PaintingStyle.stroke
        ..strokeWidth = .1
        ..strokeJoin = StrokeJoin.round,
    );
    c.scale(.58);
    c.drawPath(_burstShape, Paint()..color = SkyColors.white);
    c.restore();
  }

  /// The enemy itself: a white flash, the knock, and a squash as it is
  /// swallowed by the poof, so it never simply vanishes.
  static void _ghost(
    Canvas c,
    double radius,
    EnemyKind kind,
    double age,
    Offset at,
    bool rammed,
  ) {
    const life = .17;
    if (age >= life) return;
    final swallow = ((age - .06) / (life - .06)).clamp(0.0, 1.0);
    final scale = 1 - .72 * swallow * swallow;
    final settle = (1 - age / life) * (1 - age / life);
    final wobble = -math.cos(age / .12 * math.pi * 2) * settle;
    final flash = age < .02 ? 1.0 : (1 - (age - .02) / .055).clamp(0.0, 1.0);
    c.save();
    c.translate(at.dx, at.dy);
    c.rotate((rammed ? 1.5 : .6) * _outCubic(age / .22));
    c.scale(scale * (1 + .2 * wobble), scale * (1 - .16 * wobble));
    if (flash > 0) {
      c.saveLayer(
        const Rect.fromLTRB(-2.2, -1.6, 2.2, 1.6),
        Paint()..colorFilter = _whiten(flash),
      );
    }
    c.scale(1 / radius);
    final painter = switch (kind) {
      EnemyKind.caveBat => PatrolBatArt.paint,
      EnemyKind.spitterBeetle => AimedEnemyArt.paint,
      EnemyKind.duskMoth => SpreadEnemyArt.paint,
      EnemyKind.simpleBat => SimpleBatArt.paint,
      EnemyKind.alleyPigeon => AlleyPigeonArt.paint,
    };
    if (kind == EnemyKind.alleyPigeon) {
      // Knocked silly: the pigeon's X eyes and open beak, wings up.
      AlleyPigeonArt.paint(
        c,
        radius,
        seconds: 0,
        reducedMotion: true,
        dazed: true,
      );
    } else {
      painter(c, radius, seconds: 0, reducedMotion: true);
    }
    if (flash > 0) c.restore();
    c.restore();
  }

  /// Blends toward a high-contrast grey ramp: fills blow out to white while
  /// the ink lines stay a readable grey, so the flash pops off a pale sky
  /// instead of turning the enemy into a translucent ghost.
  static ColorFilter _whiten(double w) {
    const k = 3.4, b = -95.0;
    final keep = 1 - w;
    return ColorFilter.matrix([
      keep + w * .3 * k, w * .59 * k, w * .11 * k, 0, w * b, //
      w * .3 * k, keep + w * .59 * k, w * .11 * k, 0, w * b, //
      w * .3 * k, w * .59 * k, keep + w * .11 * k, 0, w * b, //
      0, 0, 0, 1, 0,
    ]);
  }

  // Puff centers and radii in hit-radius units, before the per-defeat twist.
  static const _puffs = <(double, double, double)>[
    (0, 0, .64),
    (-.66, .06, .46),
    (-.4, -.46, .5),
    (.18, -.6, .5),
    (.7, -.22, .47),
    (.62, .4, .45),
    (.04, .54, .47),
    (-.52, .46, .4),
  ];

  /// Overlapping puffs share one outline: every puff's rim is drawn first,
  /// then the shadowed bodies, then the lit tops. The puffs pop in with an
  /// overshoot, billow and rise, then thin away one by one. A null [age]
  /// draws the settled cloud for Reduced Motion.
  static void _cloud(
    Canvas c,
    double? age,
    Offset center,
    double size,
    _Tint tint,
    int seed,
  ) {
    final twist = (_hash(0, seed) - .5) * 1.2;
    final cosT = math.cos(twist), sinT = math.sin(twist);
    final count = _puffs.length;
    final at = List.filled(count, Offset.zero);
    final radii = List.filled(count, 0.0);
    var evaporate = 0.0;
    for (var i = 0; i < count; i++) {
      final (px, py, pr) = _puffs[i];
      final base = Offset(px * cosT - py * sinT, px * sinT + py * cosT);
      var grow = 1.0, fade = 0.0, billow = 0.0;
      if (age != null) {
        final born = age - .05 - i * .01;
        if (born < 0) continue;
        grow = .4 + .6 * _outBack(born / .13);
        billow = _outQuad(age / seconds);
        final start = .22 + .2 * _hash(i + 11, seed);
        fade = ((age - start) / (seconds - .02 - start)).clamp(0.0, 1.0);
      }
      // Thinning puffs pull together and float off unevenly, so the cloud
      // breaks up like smoke rather than a ring of bubbles.
      final spread = (.6 + .4 * grow + .22 * billow) * (1 - .3 * fade);
      final float = _outQuad(fade) * size;
      at[i] =
          center +
          base * size * spread +
          Offset(
            (_hash(i + 30, seed) - .5) * .5 * float,
            -(.15 + .45 * _hash(i + 50, seed)) * float,
          );
      radii[i] =
          pr *
          (.9 + .2 * _hash(i + 3, seed)) *
          size *
          grow *
          (1 + .1 * billow) *
          (1 - fade) *
          (1 + .35 * fade);
      evaporate = math.max(evaporate, fade);
    }
    // The rim softens toward the shadow tone as the smoke thins, so the last
    // wisps evaporate instead of hardening into a ring of bubbles.
    final rim = Paint()..color = Color.lerp(tint.line, tint.shade, evaporate)!;
    final shade = Paint()..color = tint.shade;
    final light = Paint()..color = tint.light;
    for (var i = 0; i < count; i++) {
      final r = radii[i];
      if (r <= .01) continue;
      c.drawCircle(
        at[i],
        r + .085 * (1 - .5 * evaporate) * math.min(1, r / .25),
        rim,
      );
    }
    for (var i = 0; i < count; i++) {
      if (radii[i] > .01) c.drawCircle(at[i], radii[i], shade);
    }
    for (var i = 0; i < count; i++) {
      final r = radii[i];
      if (r <= .01) continue;
      c.drawCircle(at[i] + Offset(-.15 * r, -.19 * r), r * .74, light);
    }
  }

  static void _debris(
    Canvas c,
    double age,
    Offset origin,
    _Tint tint,
    bool rammed,
    int seed,
  ) {
    final t = age - _launch;
    if (t <= 0) return;
    final count = rammed ? 9 : 6;
    final from = rammed ? -2.9 : -2.3, to = rammed ? 1.1 : .9;
    final floaty =
        tint.debris == _Debris.scale || tint.debris == _Debris.feather;
    for (var i = 0; i < count; i++) {
      final u = _hash(i + 20, seed), v = _hash(i + 40, seed);
      final life = seconds - _launch - .06 * v;
      final lt = t / life;
      if (lt >= 1) continue;
      final angle = from + (to - from) * (i + .5 + (u - .5) * .6) / count;
      final speed = (rammed ? 19.0 : 14.0) * (.7 + .55 * v);
      const drag = 4.0;
      final reach = .35 + speed * (1 - math.exp(-drag * t)) / drag;
      final gravity = floaty ? 3.4 : 10.0;
      var pos =
          origin +
          Offset(math.cos(angle), math.sin(angle)) * reach +
          Offset(0, .5 * gravity * t * t);
      if (floaty) pos += Offset(math.sin(t * 16 + u * 6) * .2, 0);
      final full = (.19 + .09 * u) * (rammed ? 1.12 : 1);
      final size =
          full *
          _outBack(t / .06) *
          (1 - _inQuad(((lt - .55) / .45).clamp(0.0, 1.0)));
      if (size <= .005) continue;
      final spin = floaty
          ? math.sin(t * 11 + u * 5) * .9 + u * 4
          : u * 6 + (v > .5 ? 1 : -1) * (7 + 5 * u) * t;
      c.save();
      c.translate(pos.dx, pos.dy);
      c.rotate(spin);
      c.scale(size);
      final line = .062 / full;
      if (tint.debris == _Debris.star ||
          (tint.debris == _Debris.scale && i.isOdd)) {
        _twinkleShape(c, line * .75, SkyColors.yellow, _amber);
      } else {
        final shape = switch (tint.debris) {
          _Debris.fur => _furShape,
          _Debris.shell => _shellShape,
          _Debris.feather => _featherShape,
          _ => _scaleShape,
        };
        // Every third feather is one of the pigeon's iridescent neck ones.
        final neck = tint.debris == _Debris.feather && i % 3 == 2;
        c.drawPath(shape, Paint()..color = neck ? _neckFeather : tint.chip);
        c.drawPath(switch (tint.debris) {
          _Debris.fur => _furShine,
          _Debris.shell => _shellShine,
          _Debris.feather => _featherShine,
          _ => _scaleShine,
        }, Paint()..color = neck ? _neckFeatherLight : tint.chipLight);
        c.drawPath(
          shape,
          Paint()
            ..color = tint.chipLine
            ..style = PaintingStyle.stroke
            ..strokeWidth = line
            ..strokeJoin = StrokeJoin.round,
        );
      }
      c.restore();
    }
  }

  static void _twinkles(
    Canvas c,
    double age,
    Offset center,
    double size,
    bool rammed,
    int seed,
  ) {
    final count = rammed ? 4 : 3;
    for (var i = 0; i < count; i++) {
      final start = .13 + i * .06 + .03 * _hash(i + 60, seed);
      final lt = (age - start) / .2;
      if (lt <= 0 || lt >= 1) continue;
      final angle =
          -2.2 + i * (rammed ? 1.35 : 1.7) + (_hash(i + 70, seed) - .5) * .5;
      final dist = size * (1.2 + .25 * _hash(i + 80, seed));
      _twinkle(
        c,
        center + Offset(math.cos(angle), math.sin(angle)) * dist,
        math.sin(lt * math.pi) * (.3 + .08 * _hash(i + 90, seed)),
        lt * 1.2,
      );
    }
  }

  static void _twinkle(Canvas c, Offset at, double size, double turn) {
    if (size <= .01) return;
    c.save();
    c.translate(at.dx, at.dy);
    c.rotate(turn);
    c.scale(size);
    _twinkleShape(c, .075 / size, SkyColors.yellow, _amber);
    c.restore();
  }

  static void _twinkleShape(Canvas c, double line, Color fill, Color edge) {
    c.drawPath(_twinkleStar, Paint()..color = fill);
    c.drawPath(
      _twinkleStar,
      Paint()
        ..color = edge
        ..style = PaintingStyle.stroke
        ..strokeWidth = line
        ..strokeJoin = StrokeJoin.round,
    );
    c.drawCircle(Offset.zero, .22, Paint()..color = SkyColors.white);
  }

  static final _burstShape = _star(10, 1, .5);
  static final _twinkleStar = _star(4, 1, .34, curved: true);

  static Path _star(
    int points,
    double outer,
    double inner, {
    bool curved = false,
  }) {
    final path = Path();
    for (var i = 0; i < points; i++) {
      final a = -math.pi / 2 + i * 2 * math.pi / points;
      final tip = Offset(math.cos(a), math.sin(a)) * outer;
      final b = a + math.pi / points;
      final valley = Offset(math.cos(b), math.sin(b)) * inner;
      if (i == 0) path.moveTo(tip.dx, tip.dy);
      if (!curved) {
        if (i > 0) path.lineTo(tip.dx, tip.dy);
        path.lineTo(valley.dx, valley.dy);
      } else {
        final next = a + 2 * math.pi / points;
        final nextTip = Offset(math.cos(next), math.sin(next)) * outer;
        path.quadraticBezierTo(
          valley.dx * .45,
          valley.dy * .45,
          nextTip.dx,
          nextTip.dy,
        );
      }
    }
    return path..close();
  }

  // A two-tipped tuft of fur, pointing up in its own space.
  static final _furShape = Path()
    ..moveTo(0, .95)
    ..cubicTo(-.8, .9, -.9, .05, -.4, -.35)
    ..quadraticBezierTo(-.3, -.85, -.05, -1.05)
    ..quadraticBezierTo(0, -.62, .22, -.52)
    ..quadraticBezierTo(.52, -.86, .82, -.78)
    ..cubicTo(.55, -.4, 1.0, .62, 0, .95)
    ..close();
  static final _furShine = Path()
    ..addOval(
      Rect.fromCenter(
        center: const Offset(-.28, -.05),
        width: .42,
        height: .62,
      ),
    );

  // An angular chip of carapace with a bright reflected edge.
  static final _shellShape = Path()
    ..moveTo(-.95, -.3)
    ..lineTo(.2, -.85)
    ..lineTo(.95, .2)
    ..lineTo(-.2, .82)
    ..close();
  static final _shellShine = Path()
    ..moveTo(-.62, -.3)
    ..lineTo(.16, -.66)
    ..lineTo(.34, -.4)
    ..lineTo(-.44, -.08)
    ..close();

  // A pigeon's feather: a long leaf that flutters down like a wing scale.
  static final _featherShape = Path()
    ..moveTo(0, 1)
    ..cubicTo(-.78, .42, -.72, -.5, 0, -1.08)
    ..cubicTo(.72, -.5, .78, .42, 0, 1)
    ..close();
  static final _featherShine = Path()
    ..addOval(
      Rect.fromCenter(center: const Offset(-.2, -.1), width: .22, height: .86),
    );
  static const _neckFeather = Color(0xff2fd9b4);
  static const _neckFeatherLight = Color(0xffa8f5e0);

  // A soft wing scale that flutters down instead of dropping.
  static final _scaleShape = Path()
    ..moveTo(0, -1)
    ..quadraticBezierTo(.85, -.2, 0, 1)
    ..quadraticBezierTo(-.85, -.2, 0, -1)
    ..close();
  static final _scaleShine = Path()
    ..addOval(
      Rect.fromCenter(center: const Offset(0, -.15), width: .34, height: .9),
    );

  static double _hash(int a, int b) {
    final v = math.sin(a * 12.9898 + b * 78.233) * 43758.5453;
    return v - v.floorToDouble();
  }

  static double _outCubic(double t) {
    final x = 1 - t.clamp(0.0, 1.0);
    return 1 - x * x * x;
  }

  static double _outQuad(double t) {
    final x = 1 - t.clamp(0.0, 1.0);
    return 1 - x * x;
  }

  static double _inQuad(double t) {
    final x = t.clamp(0.0, 1.0);
    return x * x;
  }

  static double _outBack(double t) {
    final x = t.clamp(0.0, 1.0) - 1;
    const c1 = 1.70158, c3 = c1 + 1;
    return 1 + c3 * x * x * x + c1 * x * x;
  }
}

enum _Debris { fur, shell, scale, star, feather }

/// Cloud and debris colours taken from the enemy that went down.
class _Tint {
  const _Tint(
    this.line,
    this.shade,
    this.light,
    this.chip,
    this.chipLight,
    this.chipLine,
    this.debris,
  );
  final Color line, shade, light, chip, chipLight, chipLine;
  final _Debris debris;

  static _Tint of(EnemyKind? kind) => switch (kind) {
    EnemyKind.simpleBat => _simpleBat,
    EnemyKind.caveBat => _caveBat,
    EnemyKind.spitterBeetle => _beetle,
    EnemyKind.duskMoth => _moth,
    EnemyKind.alleyPigeon => _pigeon,
    null => _plain,
  };

  static const _simpleBat = _Tint(
    Color(0xff3b2f6b),
    Color(0xffcdc2f2),
    Color(0xfffdfbff),
    Color(0xff8572c5),
    Color(0xffc3b6f5),
    Color(0xff2e2456),
    _Debris.fur,
  );
  static const _caveBat = _Tint(
    Color(0xff3a2838),
    Color(0xffe6ccd6),
    Color(0xfffff9f7),
    Color(0xff8d596f),
    Color(0xffcf9aa4),
    Color(0xff302536),
    _Debris.fur,
  );
  static const _beetle = _Tint(
    Color(0xff1f4a47),
    Color(0xffc2e8d6),
    Color(0xfff7fffa),
    Color(0xff318876),
    Color(0xff9fe3c0),
    Color(0xff1c3c40),
    _Debris.shell,
  );
  static const _moth = _Tint(
    Color(0xff5b3a45),
    Color(0xfff6d6c6),
    Color(0xfffffaf3),
    Color(0xffd88671),
    Color(0xfff6c6a6),
    Color(0xff4b343d),
    _Debris.scale,
  );
  // A cool blue-grey puff with the pigeon's own feathers (every third one
  // teal, from its neck), falling like scales.
  static const _pigeon = _Tint(
    Color(0xff18182f),
    Color(0xffd3d8ee),
    Color(0xfff6f7fe),
    Color(0xff7d86ae),
    Color(0xffb4bcdc),
    Color(0xff2e3358),
    _Debris.feather,
  );
  static const _plain = _Tint(
    SkyColors.ink,
    Color(0xffd6e0f0),
    SkyColors.cream,
    SkyColors.yellow,
    SkyColors.cream,
    Color(0xffb86a2a),
    _Debris.star,
  );
}
