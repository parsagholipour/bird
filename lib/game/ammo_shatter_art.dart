import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../domain/game_rules.dart';
import '../ui/theme.dart';
import 'crust_art.dart';
import 'enemy_ammo_art.dart';

/// A charged rock breaking an enemy pellet: a flash of the rock's amber
/// core, the pellet flung apart in its own material and a shockwave ring
/// that stops on the blast's reach, so the player sees which enemies it
/// caught.
///
/// Everything is a pure function of the stored shatter and its age, so a
/// paused frame stays exact and seeking reproduces it. Under Reduced Motion
/// nothing flies or expands; the ring and a star mark the blast and fade.
abstract final class AmmoShatterArt {
  static const seconds = .6;

  /// The charged rock's core, as [StoneArt] lights it.
  static const _amber = Color(0xffffb843), _hot = Color(0xffffefb5);
  static const _slate = Color(0xff425b63), _chipLight = Color(0xff8aa3a8);
  static const _smoke = Color(0xff9d93b6);

  static void paint(
    Canvas canvas,
    double height,
    FlightSimulation sim, {
    required bool reducedMotion,
  }) {
    for (final shatter in sim.ammoShatters) {
      final age = sim.elapsed - shatter.at;
      if (!(age >= 0 && age < seconds)) continue;
      // Anchored in the world, so the blast scrolls with the scenery.
      blast(
        canvas,
        Offset(shatter.worldX - sim.distance, shatter.y) * height,
        height * EnemyAmmo.radius,
        reach: height * shatter.reach,
        charge: shatter.charge,
        direction: shatter.direction,
        attack: shatter.attack,
        age: age,
        reducedMotion: reducedMotion,
        seed: (shatter.worldX * 37.7 + shatter.y * 91.3) % 1,
      );
    }
  }

  /// [radius] is the pellet's hit radius and [reach] the blast radius, both
  /// in pixels; everything else is drawn in pellet-radius units.
  static void blast(
    Canvas c,
    Offset center,
    double radius, {
    required double reach,
    required double charge,
    required double direction,
    required EnemyAttack attack,
    required double age,
    required bool reducedMotion,
    double seed = 0,
  }) {
    if (!radius.isFinite ||
        radius <= 0 ||
        !reach.isFinite ||
        reach <= 0 ||
        !(age >= 0 && age < seconds)) {
      return;
    }
    final tone = switch (attack) {
      EnemyAttack.aimed => _spit,
      EnemyAttack.crumb => _crust,
      EnemyAttack.none || EnemyAttack.fan => _ember,
    };
    final power = charge.isFinite
        ? ((charge - PowerShot.shatterCharge) / (1 - PowerShot.shatterCharge))
              .clamp(0.0, 1.0)
        : 0.0;
    final back = direction.isFinite ? direction + math.pi : 0.0;
    final edge = math.max(.15, 1.6 / radius);
    final span = reach / radius;
    c.save();
    c.translate(center.dx, center.dy);
    c.scale(radius);
    if (reducedMotion) {
      _still(c, tone, age, span, power, seed, edge);
    } else {
      _wash(c, tone, age, span);
      _glow(c, age, span, power);
      _ring(c, tone, age, span, power, edge);
      _spokes(c, age, span, power, seed);
      if (tone == _ember) _smokePuffs(c, age, back, power);
      // A crust goes up in a cloud of old flour.
      if (tone == _crust) {
        _smokePuffs(c, age, back, power, color: CrustArt.dust, alpha: .55);
      }
      _flash(c, age, power, seed, edge);
      _shards(c, tone, age, span, power, seed, edge);
      _chips(c, age, back, edge);
    }
    c.restore();
  }

  /// Pellet materials from [EnemyAmmoArt]: highlight, body and ring band.
  static const _spit = (
    light: EnemyAmmoArt.mint,
    body: EnemyAmmoArt.leaf,
    band: EnemyAmmoArt.jade,
  );
  static const _ember = (
    light: EnemyAmmoArt.hot,
    body: EnemyAmmoArt.amber,
    band: EnemyAmmoArt.flame,
  );

  /// A pigeon's stale crust ([CrustArt]): crumb light, crumb, baked crust.
  static const _crust = (
    light: CrustArt.crumbHi,
    body: CrustArt.crumb,
    band: CrustArt.crust,
  );

  static double _out(double t) => 1 - math.pow(1 - t, 3).toDouble();
  static double _inQuad(double t) => t * t;

  /// The shockwave front: it rushes out and stops on the reach.
  static double _front(double age, double span) =>
      1.4 + (span - 1.4) * _out(math.min(1.0, age / .13));

  // A tint of the pellet's material fills the blast area for a moment,
  // strongest at the rim so the edge reads without hiding the middle.
  static void _wash(Canvas c, _Tone tone, double age, double span) {
    const life = .24;
    if (age >= life) return;
    final r = _front(age, span);
    final a = .34 * (1 - age / life);
    c.drawCircle(
      Offset.zero,
      r,
      Paint()
        ..shader = RadialGradient(
          colors: [
            tone.light.withValues(alpha: 0),
            tone.light.withValues(alpha: a * .35),
            tone.light.withValues(alpha: a),
          ],
          stops: const [.3, .78, 1],
        ).createShader(Rect.fromCircle(center: Offset.zero, radius: r)),
    );
  }

  // The charged core's amber light blooms over the break and dies away.
  static void _glow(Canvas c, double age, double span, double power) {
    const life = .12;
    if (age >= life) return;
    final t = age / life;
    final r = span * (.34 + .14 * power) * (.8 + .2 * _out(t));
    final a = (.55 + .3 * power) * (1 - t) * (1 - t);
    c.drawCircle(
      Offset.zero,
      r,
      Paint()
        ..shader = RadialGradient(
          colors: [
            _hot.withValues(alpha: a),
            _amber.withValues(alpha: a * .6),
            _amber.withValues(alpha: 0),
          ],
          stops: const [0, .45, 1],
        ).createShader(Rect.fromCircle(center: Offset.zero, radius: r)),
    );
  }

  // An inked band in the pellet's colour with the rock's hot light inside.
  // It holds on the reach just long enough to read, then thins away.
  static void _ring(
    Canvas c,
    _Tone tone,
    double age,
    double span,
    double power,
    double edge,
  ) {
    const hold = .26, gone = .46;
    if (age >= gone) return;
    final fade = age < hold ? 1.0 : 1 - (age - hold) / (gone - hold);
    final grow = _out(math.min(1.0, age / .13));
    final r = _front(age, span);
    final w = (1.5 - .75 * grow) * (.8 + .4 * power) * (.55 + .45 * fade);
    final layered = fade < 1;
    if (layered) {
      c.saveLayer(
        Rect.fromCircle(center: Offset.zero, radius: r + w + edge * 2),
        Paint()..color = Color.fromRGBO(0, 0, 0, fade),
      );
    }
    c.drawCircle(Offset.zero, r, _stroke(SkyColors.ink, w + edge * 2));
    c.drawCircle(Offset.zero, r, _stroke(tone.band, w));
    c.drawCircle(
      Offset.zero,
      r - w * .2,
      _stroke(Color.lerp(tone.light, _hot, .5)!, w * .4),
    );
    if (layered) c.restore();
  }

  // Comic action lines in the rock's amber shoot out toward the ring.
  static void _spokes(
    Canvas c,
    double age,
    double span,
    double power,
    double seed,
  ) {
    const life = .16;
    if (age >= life) return;
    final q = age / life;
    for (var i = 0; i < 8; i++) {
      final a = (i + seed) * math.pi / 4 + (i.isOdd ? .2 : 0);
      final v = Offset(math.cos(a), math.sin(a));
      final inner = 1.6 + span * .7 * _out(q);
      final outer = math.min(
        span - 1.0,
        inner + (span * .32 + 1) * (1 - q) * (i.isEven ? 1 : .65),
      );
      if (outer <= inner) continue;
      c.drawLine(
        v * inner,
        v * outer,
        _stroke(
          _amber.withValues(alpha: 1 - q * q),
          (.8 + .4 * power) * (1 - q) + .2,
        ),
      );
      c.drawLine(
        v * inner,
        v * outer,
        _stroke(_hot.withValues(alpha: 1 - q), (.36 + .2 * power) * (1 - q)),
      );
    }
  }

  // The rock's core lets go: an inked starburst that swells and snaps shut.
  static void _flash(
    Canvas c,
    double age,
    double power,
    double seed,
    double edge,
  ) {
    const life = .15;
    final t = age / life;
    if (t >= 1) return;
    final size =
        (2.3 + 1.5 * power) *
        (t < .3
            ? 1 + .18 * math.sin(t / .3 * math.pi)
            : 1 - _inQuad((t - .3) / .7));
    if (size <= .05) return;
    c.save();
    c.rotate(seed * math.pi);
    c.scale(size);
    c.drawPath(_burst, _fill(_amber));
    c.drawPath(_burst, _stroke(SkyColors.ink, edge / size));
    c.scale(.6);
    c.drawPath(_burst, _fill(_hot));
    c.drawCircle(Offset.zero, .42, _fill(SkyColors.white));
    c.restore();
  }

  // The pellet itself flies apart into goo drops or little flames, carried
  // out toward the edge of the blast and spent there.
  static void _shards(
    Canvas c,
    _Tone tone,
    double age,
    double span,
    double power,
    double seed,
    double edge,
  ) {
    final count = 6 + (4 * power).round();
    final spit = tone == _spit;
    for (var i = 0; i < count; i++) {
      final u = _hash(i, seed), v = _hash(i + 17, seed);
      final w = _hash(i + 31, seed);
      final start = .006 + .03 * w;
      final life = .34 + .16 * v;
      final lt = (age - start) / life;
      if (lt <= 0 || lt >= 1) continue;
      // Uneven angles, reaches and timing keep the spray from reading as a
      // flower, while every piece still lands inside the ring.
      final a = (i + .9 * (u - .5) + seed) * 2 * math.pi / count;
      final far = span * (.42 + .5 * _hash(i + 43, seed));
      final at =
          Offset(math.cos(a), math.sin(a)) * (.9 + (far - .9) * _out(lt)) +
          Offset(0, 2.2 * lt * lt);
      final full = (.5 + .4 * w) * (1 + .3 * power);
      final size = full * (1 - _inQuad(((lt - .45) / .55).clamp(0.0, 1.0)));
      if (size <= .02) continue;
      // Fast shards stretch along their flight and round off as they slow.
      final stretch = 1 + (spit ? .8 : .45) * (1 - lt) * (1 - lt);
      c.save();
      c.translate(at.dx, at.dy);
      c.rotate(a);
      c.scale(size * stretch, size / math.sqrt(stretch));
      final line = edge / size;
      if (tone == _crust) {
        // Chunks of crust tumble out instead of stretching.
        c.restore();
        c.save();
        c.translate(at.dx, at.dy);
        c.rotate(a + lt * (i.isEven ? 5 : -5));
        c.scale(size);
        CrustArt.chunk(c, edge: line);
      } else if (spit) {
        c.drawPath(_drop, _fill(tone.body));
        c.drawCircle(const Offset(.12, -.38), .34, _fill(tone.light));
        c.drawPath(_drop, _stroke(SkyColors.ink, line));
      } else {
        // The tongues shorten as each little flame burns down.
        c.save();
        c.scale(1 - .35 * lt, 1);
        c.drawPath(_flame, _emberFlame);
        c.drawPath(_flame, _stroke(SkyColors.ink, line));
        c.restore();
        c.drawCircle(const Offset(.2, 0), .46, _fill(tone.light));
      }
      c.restore();
    }
  }

  // Embers leave a little smoke that drifts up out of the blast (a crust,
  // a cloud of flour: [color] and [alpha]).
  static void _smokePuffs(
    Canvas c,
    double age,
    double back,
    double power, {
    Color color = _smoke,
    double alpha = .3,
  }) {
    const end = .5;
    for (var i = 0; i < 3; i++) {
      final start = .06 + i * .035;
      final p = ((age - start) / (end - start)).clamp(0.0, 1.0);
      if (p <= 0 || p >= 1) continue;
      final a = back + (i - 1) * .9;
      final spread = 1.2 + 1.8 * _out(p);
      c.drawCircle(
        Offset(math.cos(a) * spread, math.sin(a) * spread - 4 * p),
        (.9 + 1.2 * _out(p)) * (1 + .3 * power),
        _fill(color.withValues(alpha: alpha * (1 - p) * (1 - p))),
      );
    }
  }

  // Two chips of the spent stone pop up and down, tumble and drop away.
  static void _chips(Canvas c, double age, double back, double edge) {
    const end = .5;
    for (var i = 0; i < 2; i++) {
      final p = ((age - .02) / (end - .02)).clamp(0.0, 1.0);
      if (p <= 0 || p >= 1) continue;
      final a = back + (i == 0 ? -1.0 : 1.2);
      final d = .9 + (4.6 - i * 1.2) * _out(p);
      final at = Offset(math.cos(a) * d, math.sin(a) * d + 11 * p * p);
      final fade = p < .6 ? 1.0 : (1 - p) / .4;
      c.save();
      c.translate(at.dx, at.dy);
      c.rotate(p * (i == 0 ? 7 : -6));
      final s = .95 - i * .15;
      c.scale(s);
      c.drawPath(_stone, _fill(_slate.withValues(alpha: fade)));
      c.drawLine(
        const Offset(-.45, -.4),
        const Offset(.5, -.45),
        _stroke(_chipLight.withValues(alpha: fade), .3),
      );
      c.drawPath(
        _stone,
        _stroke(SkyColors.ink.withValues(alpha: fade), edge / s),
      );
      c.restore();
    }
  }

  // Reduced Motion: the ring already on the reach, the broken pellet's
  // pieces resting inside it and a star at its heart, fading together
  // without moving.
  static void _still(
    Canvas c,
    _Tone tone,
    double age,
    double span,
    double power,
    double seed,
    double edge,
  ) {
    final fade = age < .15 ? 1.0 : 1 - (age - .15) / (seconds - .15);
    c.saveLayer(
      Rect.fromCircle(center: Offset.zero, radius: span + 1 + edge * 2),
      Paint()..color = Color.fromRGBO(0, 0, 0, fade),
    );
    c.drawCircle(Offset.zero, span, _stroke(SkyColors.ink, .8 + edge * 2));
    c.drawCircle(Offset.zero, span, _stroke(tone.band, .8));
    c.drawCircle(
      Offset.zero,
      span - .16,
      _stroke(Color.lerp(tone.light, _hot, .5)!, .32),
    );
    final spit = tone == _spit;
    for (var i = 0; i < 6; i++) {
      final a = (i + .5 * _hash(i, seed)) * math.pi / 3 + seed;
      final d = span * (.36 + .12 * _hash(i + 17, seed));
      final size = .6 * (1 + .3 * power);
      c.save();
      c.translate(math.cos(a) * d, math.sin(a) * d);
      c.rotate(a);
      c.scale(size);
      if (tone == _crust) {
        CrustArt.chunk(c, edge: edge / size);
        c.restore();
        continue;
      }
      c.drawPath(spit ? _drop : _flame, spit ? _fill(tone.body) : _emberFlame);
      c.drawPath(spit ? _drop : _flame, _stroke(SkyColors.ink, edge / size));
      c.drawCircle(
        spit ? const Offset(.12, -.38) : const Offset(.2, 0),
        spit ? .34 : .46,
        _fill(tone.light),
      );
      c.restore();
    }
    c.scale(2.2);
    c.drawPath(_burst, _fill(_amber));
    c.drawPath(_burst, _stroke(SkyColors.ink, edge / 2.2));
    c.scale(.6);
    c.drawPath(_burst, _fill(_hot));
    c.restore();
  }

  static final _burst = _star(9, 1, .52);

  static Path _star(int points, double outer, double inner) {
    final path = Path();
    for (var i = 0; i < points; i++) {
      final a = -math.pi / 2 + i * 2 * math.pi / points;
      final b = a + math.pi / points;
      final tip = Offset(math.cos(a), math.sin(a)) * outer;
      final valley = Offset(math.cos(b), math.sin(b)) * inner;
      if (i == 0) {
        path.moveTo(tip.dx, tip.dy);
      } else {
        path.lineTo(tip.dx, tip.dy);
      }
      path.lineTo(valley.dx, valley.dy);
    }
    return path..close();
  }

  // A flung goo drop in unit space, heading along +x with its tail behind.
  static final _drop = Path()
    ..moveTo(1, 0)
    ..cubicTo(1, -.56, .56, -1, 0, -1)
    ..cubicTo(-.6, -1, -1.1, -.35, -1.8, 0)
    ..cubicTo(-1.1, .35, -.6, 1, 0, 1)
    ..cubicTo(.56, 1, 1, .56, 1, 0)
    ..close();

  // A little flame broken off the ember: a round hot head along +x with
  // three tongues licking back toward the blast's centre.
  static final _flame = Path()
    ..moveTo(1, 0)
    ..cubicTo(1, -.56, .56, -1, 0, -1)
    ..quadraticBezierTo(-.75, -1.02, -1.45, -.8)
    ..quadraticBezierTo(-1.05, -.52, -.88, -.34)
    ..quadraticBezierTo(-1.6, -.26, -2.3, 0)
    ..quadraticBezierTo(-1.6, .26, -.88, .34)
    ..quadraticBezierTo(-1.05, .52, -1.45, .8)
    ..quadraticBezierTo(-.75, 1.02, 0, 1)
    ..cubicTo(.56, 1, 1, .56, 1, 0)
    ..close();

  static final _emberFlame = Paint()
    ..shader = const LinearGradient(
      begin: Alignment.centerRight,
      end: Alignment.centerLeft,
      colors: [EnemyAmmoArt.amber, EnemyAmmoArt.flame, EnemyAmmoArt.ember],
      stops: [.2, .55, 1],
    ).createShader(const Rect.fromLTRB(-2.3, -1, 1, 1));

  static final _stone = Path()
    ..moveTo(.8, -.35)
    ..lineTo(-.2, -.8)
    ..lineTo(-.8, -.05)
    ..lineTo(-.1, .7)
    ..lineTo(.7, .4)
    ..close();

  static double _hash(int a, double seed) {
    final v = math.sin(a * 12.9898 + seed * 787.233) * 43758.5453;
    return v - v.floorToDouble();
  }

  static Paint _fill(Color color) => Paint()..color = color;

  static Paint _stroke(Color color, double width) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
}

typedef _Tone = ({Color light, Color body, Color band});
