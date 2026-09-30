import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../domain/obstacle.dart';
import '../domain/sky_door.dart';
import '../ui/theme.dart';
import 'door_break_art.dart';
import 'door_fracture.dart';
import 'door_parts.dart';
import 'door_slab.dart';

/// The breakable panel that plugs a wall opening, and everything that happens
/// to it: a sealed stone gate with a reinforced collar where it meets the
/// wall, a shudder, chip-and-dust reaction for every blow, cracks that grow
/// from each strike, and the choreographed shatter of the killing blow.
///
/// The panel exactly fills its parent wall's opening (its collision box). All
/// of its own artwork stays inside that box; only the wall-end collars (drawn
/// over the wall bodies) and short-lived decoration reach outside. Painting is
/// a pure function of the door's state and clock, so pausing, seeking and
/// replays are exact.
abstract final class DoorArt {
  /// How far the collars reach into the wall bodies, in viewport heights.
  static const collarReach = DoorLook.collar;

  static void paint(
    Canvas canvas,
    double height,
    Obstacle obstacle, {
    required bool reducedMotion,
  }) {
    final door = obstacle.door!;
    final w = obstacle.width, h = obstacle.bottom - obstacle.top;
    if (!(w > 0) || !(h > .08) || !height.isFinite || height <= 0) return;
    // Reduced Motion drops the broken panel at once, with all its dust.
    if (door.destroyed && reducedMotion) return;
    final look = DoorLook(door, obstacle);
    canvas.save();
    canvas.scale(height);
    canvas.translate(obstacle.x, obstacle.top);
    if (door.destroyed) {
      DoorBreakArt.paint(canvas, look);
    } else {
      _intact(canvas, look, reducedMotion);
    }
    canvas.restore();
  }

  static void _intact(Canvas c, DoorLook k, bool reduced) {
    final door = k.door;
    final w = k.w, h = k.h;
    final stress = k.damage;
    final last = door.lastHit;
    final since = last == null ? double.infinity : door.age - last.at;
    final live = !reduced && since >= 0 && since < _fxSeconds;

    // ---- crack growth --------------------------------------------------
    double target(int blow, double damage) =>
        .028 + .17 * damage + .03 * (k.blows[blow].power);
    final birth = live ? DoorMath.outCubic(since / .14) : 1.0;
    final before = last == null
        ? 0.0
        : (SkyDoor.maxHp - door.hp - math.min(last.damage, SkyDoor.maxHp)) /
              SkyDoor.maxHp;
    double reach(int blow) {
      final now = target(blow, k.damage);
      if (blow == k.blows.length - 1 && last != null) return now * birth;
      final was = target(blow, math.max(0, before));
      return was + (now - was) * birth;
    }

    final lateScale = .3 + .45 * k.damage;

    // ---- recoil ---------------------------------------------------------
    var recoil = 0.0;
    if (live && since < .16) {
      recoil = (.0032 + .003 * last!.power) * math.sin(math.pi * since / .16);
    }
    // ---- idle glint and glow (Reduced Motion keeps the still face) -------
    var glint = -1.0, pulse = 0.0;
    if (!reduced) {
      final phase = (door.age + DoorMath.hash(k.seed, 2) * 3.4) % 3.4;
      if (phase < .75) glint = phase / .75;
      pulse = .5 + .5 * math.sin(door.age * 3.1 + k.seed);
    }

    c.save();
    c.clipRect(k.rect);
    if (recoil > 0) {
      c.drawRect(
        Rect.fromLTWH(0, 0, recoil + .002, h),
        DoorParts.fill(DoorPalette.socket),
      );
      c.translate(recoil, 0);
    }
    final flash = live && since < .06 ? .34 * (1 - since / .06) : 0.0;
    DoorSlab.paint(
      c,
      k,
      reach: reach,
      lateScale: lateScale,
      glint: glint,
      pulse: pulse,
      flash: flash,
    );
    _spalls(c, k);
    c.restore();

    // The collars sit over the wall ends, framing the plug.
    DoorParts.collar(c, k, upper: true, stress: stress);
    DoorParts.collar(c, k, upper: false, stress: stress);

    if (live) _hitFx(c, k);
    assert(w > 0);
  }

  static const _fxSeconds = .55;

  /// Small chips knocked out of the panel's back face by the heavier hits.
  static void _spalls(Canvas c, DoorLook k) {
    final f = k.fracture;
    if (f == null || k.door.damageStage < 2) return;
    for (var i = 1; i < f.blows.length && i < 4; i++) {
      final y = f.blows[i].y + (i.isEven ? .028 : -.024);
      final x = k.w;
      final s = .011 + .004 * DoorMath.hash(k.seed, 7, i);
      final tri = Path()
        ..moveTo(x + .002, y - s * 1.2)
        ..lineTo(x - s, y + s * .1)
        ..lineTo(x + .002, y + s);
      c.drawPath(tri, DoorParts.fill(DoorPalette.socket));
      c.drawPath(
        Path()
          ..moveTo(x - s * .1, y - s * 1.0)
          ..lineTo(x - s * .9, y + s * .1)
          ..lineTo(x - s * .1, y + s * .8),
        DoorParts.stroke(DoorPalette.fresh.withValues(alpha: .85), .003),
      );
    }
  }

  /// Decoration that follows a blow: starburst, shock ring, gold sparks, chips
  /// and a puff of dust. It reaches out to the left of the wall, where the rock
  /// came from, and is gone within half a second.
  static void _hitFx(Canvas c, DoorLook k) {
    final f = k.fracture;
    if (f == null) return;
    final door = k.door;
    // Earlier blows may still be finishing; later blows draw on top.
    for (var i = 0; i < door.hits.length && i < f.origins.length; i++) {
      final hit = door.hits[i];
      final a = door.age - hit.at;
      if (a < 0 || a >= _fxSeconds) continue;
      _blowFx(c, k, f.origins[i], hit.power, a, i);
    }
  }

  static void _blowFx(
    Canvas c,
    DoorLook k,
    Offset origin,
    double power,
    double a,
    int index,
  ) {
    final face = Offset(-.004, origin.dy);
    final seed = k.seed * 7 + index * 31;
    // Starburst: full size at once, a small swell, then it snaps shut.
    final burstLife = .1;
    if (a < burstLife) {
      final t = a / burstLife;
      final size =
          (.036 + .018 * power) *
          (t < .3
              ? 1 + .18 * math.sin(t / .3 * math.pi)
              : 1 - DoorMath.inQuad((t - .3) / .7));
      DoorParts.burst(c, face, size, (DoorMath.hash(seed, 1) - .5) * .7);
    }
    // Shock ring.
    final ringLife = .17;
    if (a < ringLife) {
      final t = a / ringLife;
      c.drawCircle(
        face,
        .014 + (.062 + .03 * power) * DoorMath.outCubic(t),
        DoorParts.stroke(
          SkyColors.white.withValues(alpha: .95 * (1 - t) * (1 - t)),
          .0075 * (1 - t) + .0015,
        ),
      );
    }
    // Gold sparks thrown back toward the rock.
    for (var i = 0; i < 8; i++) {
      final u = DoorMath.hash(seed, 10, i), v = DoorMath.hash(seed, 20, i);
      final life = .2 + .16 * v;
      if (a >= life) continue;
      final angle = math.pi + (i - 3.5) * .3 + (u - .5) * .3;
      final speed = .7 + .7 * v + .35 * power;
      final reach = speed * (1 - math.exp(-8 * a)) / 8;
      final dir = Offset(math.cos(angle), math.sin(angle));
      final at = face + dir * reach + Offset(0, .5 * 1.5 * a * a);
      final t = a / life;
      final tail = at - dir * (.034 * (1 - t));
      c.drawLine(
        tail,
        at,
        DoorParts.stroke(
          DoorPalette.goldDeep.withValues(alpha: 1 - t * t),
          .0075 * (1 - t) + .0015,
        ),
      );
      c.drawLine(
        tail,
        at,
        DoorParts.stroke(
          DoorPalette.goldLight.withValues(alpha: 1 - t * t),
          .0038 * (1 - t) + .0008,
        ),
      );
    }
    // Stone chips: bigger for a harder blow.
    final chips = 3 + (power * 3).round();
    for (var i = 0; i < chips; i++) {
      final u = DoorMath.hash(seed, 30, i), v = DoorMath.hash(seed, 40, i);
      final life = .3 + .2 * v;
      if (a >= life) continue;
      final angle = math.pi + (u - .5) * 2.1;
      final speed = .28 + .42 * v + .15 * power;
      final reach = speed * (1 - math.exp(-5 * a)) / 5;
      final at =
          face +
          Offset(
            math.cos(angle) * reach,
            math.sin(angle) * reach + .5 * 1.9 * a * a,
          );
      final t = a / life;
      final size =
          (.0085 + .004 * u + .003 * power) *
          (1 - DoorMath.inQuad((t - .55) / .45));
      DoorParts.chip(c, at, size, (u - .5) * 14 * a, i + index);
    }
    // A small puff of dust that rises and thins.
    DoorBreakArt.puff(
      c,
      Offset(.004, origin.dy),
      .026 + .01 * power,
      a,
      .5,
      seed,
      delay: .02,
      lift: .03,
    );
  }
}
