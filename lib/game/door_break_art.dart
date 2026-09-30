import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../domain/sky_door.dart';
import '../ui/theme.dart';
import 'door_fracture.dart';
import 'door_parts.dart';
import 'door_slab.dart';

/// The choreographed break of the panel, driven only by the destruction age.
///
///     0 ms      the blow lands: white-gold flash, starburst, shock ring; the
///               slab strains and every crack races out from the strike
///     50 ms     the slab lets go along those cracks; shards, straps, rivets
///               and the medallion burst out, dust blooms
///     0.1-0.4 s pieces tumble, the medallion flips and twinkles, dust rises
///     0.4-0.95 s everything shrinks away; the chewed wall sockets stay
///
/// A ram throws bigger debris further and higher than a base rock, a charged
/// rock in between. Collision is long gone by the first frame; nothing here
/// can be mistaken for a hazard, and nothing is left in the opening.
abstract final class DoorBreakArt {
  /// The slab holds still (strained, flashed) for this long before it goes.
  static const hold = .05;

  static void paint(Canvas c, DoorLook k) {
    final door = k.door;
    final f = k.fracture;
    if (f == null) return;
    final t = door.destructionAge.isFinite
        ? math.max(0.0, door.destructionAge)
        : 0.0;
    final released = t >= hold;
    final killer = door.lastHit;
    final rammed = killer?.rammed ?? false;
    final power = rammed ? 1.0 : (killer?.power ?? 0);
    final strike = Offset(-.004, f.origins.last.dy);

    // The wall remembers: the sockets are chewed, dusty and stay that way.
    final stain = DoorMath.smooth((t - hold) / .45);
    DoorParts.collar(
      c,
      k,
      upper: true,
      stress: .9,
      broken: released,
      dust: stain,
    );
    DoorParts.collar(
      c,
      k,
      upper: false,
      stress: .9,
      broken: released,
      dust: stain,
    );
    if (t >= SkyDoor.crumbleDuration) return;

    if (!released) {
      _strain(c, k, f, t, power);
    } else {
      final s = t - hold;
      _shards(c, k, f, s, power, rammed, strike);
      _straps(c, k, s, power, rammed);
      _gold(c, k, s, power, rammed);
      _dust(c, k, f, t, s, power, rammed, strike);
    }
    _impact(c, k, t, power, strike);
  }

  // ---------------------------------------------------------------------
  // The instant of the blow.
  // ---------------------------------------------------------------------

  /// The intact slab, straining and blown out by the flash, its cracks
  /// racing across the whole face.
  static void _strain(
    Canvas c,
    DoorLook k,
    DoorFracture f,
    double t,
    double power,
  ) {
    final p = DoorMath.clamp01(t / hold);
    final door = k.door;
    var before = 0.0;
    for (var i = 0; i < door.hits.length - 1; i++) {
      before += door.hits[i].damage;
    }
    before = math.min(before, SkyDoor.maxHp - 1) / SkyDoor.maxHp;
    final race = DoorMath.outCubic(p);
    double reach(int blow) {
      final was = blow == f.blows.length - 1
          ? 0.0
          : .028 + .17 * before + .03 * f.blows[blow].power;
      return was + (.55 - was) * race;
    }

    final swell = 1 + (.05 + .03 * power) * math.sin(math.pi * math.pow(p, .7));
    c.save();
    c.clipRect(k.rect);
    final centre = Offset(k.w / 2, k.h / 2);
    c.translate(centre.dx, centre.dy);
    c.scale(swell);
    // A hard shudder, in whole pixels.
    c.translate(
      math.sin(t * 900) * .0032 * (1 - p),
      math.cos(t * 760) * .0022 * (1 - p),
    );
    c.translate(-centre.dx, -centre.dy);
    DoorSlab.paint(
      c,
      k,
      reach: reach,
      lateScale: .3 + .45 * before + (1 - .3 - .45 * before) * race,
      flash: .5 - .22 * p,
      pulse: 1,
      swell: 1 + .12 * p,
    );
    c.restore();
  }

  /// Flash, starburst, shock rings and speed lines at the point of impact.
  static void _impact(
    Canvas c,
    DoorLook k,
    double t,
    double power,
    Offset strike,
  ) {
    // Bloom.
    if (t < .13) {
      final b = 1 - t / .13;
      c.drawCircle(
        strike + const Offset(.012, 0),
        .085 + .05 * power,
        DoorParts.fill(SkyColors.white.withValues(alpha: .55 * b * b)),
      );
      c.drawCircle(
        strike + const Offset(.012, 0),
        .05 + .03 * power,
        DoorParts.fill(DoorPalette.goldLight.withValues(alpha: .6 * b)),
      );
    }
    // Speed lines fanning out from the strike.
    if (t < .1) {
      final u = t / .1;
      for (var i = 0; i < 9; i++) {
        final a = -1.2 + i * .3 + (DoorMath.hash(k.seed, 90, i) - .5) * .12;
        final near = .028 + (.03 + .04 * power) * DoorMath.outCubic(u);
        final far = near + (.03 + .035 * power) * (1 - u);
        c.drawLine(
          strike + Offset(math.cos(a), math.sin(a)) * near,
          strike + Offset(math.cos(a), math.sin(a)) * far,
          DoorParts.stroke(
            SkyColors.white.withValues(alpha: 1 - u * u),
            .0055 * (1 - u) + .001,
          ),
        );
      }
    }
    // Starburst: full size on the very first frame, a swell, then it snaps.
    if (t < .16) {
      final u = t / .16;
      final size =
          (.058 + .03 * power) *
          (u < .3
              ? 1 + .16 * math.sin(u / .3 * math.pi)
              : 1 - DoorMath.inQuad((u - .3) / .7));
      DoorParts.burst(c, strike, size, (DoorMath.hash(k.seed, 91) - .5) * .6);
    }
    // Shock rings.
    if (t < .3) {
      final u = t / .3;
      c.drawCircle(
        strike + const Offset(.012, 0),
        .025 + (.15 + .09 * power) * DoorMath.outCubic(u),
        DoorParts.stroke(
          SkyColors.white.withValues(alpha: .95 * (1 - u) * (1 - u)),
          .014 * (1 - u) + .002,
        ),
      );
    }
    if (t > .03 && t < .3) {
      final u = (t - .03) / .27;
      c.drawCircle(
        strike + const Offset(.012, 0),
        .015 + (.1 + .06 * power) * DoorMath.outCubic(u),
        DoorParts.stroke(
          DoorPalette.gold.withValues(alpha: .8 * (1 - u)),
          .007 * (1 - u) + .001,
        ),
      );
    }
  }

  // ---------------------------------------------------------------------
  // Flying pieces.
  // ---------------------------------------------------------------------

  /// Ballistic flight with air drag and gravity, from [from] at velocity [v].
  static Offset fly(
    Offset from,
    Offset v,
    double s, {
    double drag = 2.2,
    double gravity = 1.7,
  }) =>
      from +
      v * ((1 - math.exp(-drag * s)) / drag) +
      Offset(0, .5 * gravity * s * s);

  static void _shards(
    Canvas c,
    DoorLook k,
    DoorFracture f,
    double s,
    double power,
    bool rammed,
    Offset strike,
  ) {
    final flash = _tailFlash(s);
    final mortar = DoorSlab.mortar(k);
    final origin = f.origins.last;
    for (final shard in f.byArea) {
      double h(int n) => DoorMath.hash(k.seed, shard.index * 13 + n, 3);
      final r = shard.centroid - origin;
      final d = r.distance;
      final radial = d > 1e-4 ? r / d : const Offset(1, 0);
      var dir =
          radial * .85 +
          const Offset(1, 0) * (.55 + .35 * power) +
          (rammed ? const Offset(0, -.55) : Offset.zero);
      dir = dir / dir.distance;
      final tilt = (h(1) - .5) * .5;
      dir = Offset(
        dir.dx * math.cos(tilt) - dir.dy * math.sin(tilt),
        dir.dx * math.sin(tilt) + dir.dy * math.cos(tilt),
      );
      final boost = math.pow(.0018 / shard.area.clamp(.0003, .01), .25);
      final speed =
          (.5 + 1.5 / (1 + d * 11) + .7 * h(2)) *
          (.85 + .6 * power + (rammed ? .5 : 0)) *
          boost;
      final life = math.min(
        .93,
        .45 + .4 * h(5) + .1 * math.min(1.0, shard.area / .004),
      );
      if (s >= life) continue;
      final shrink = 1 - DoorMath.inQuad((s - .55 * life) / (.45 * life));
      final pop =
          1 +
          (.09 + .1 * power) * math.sin(math.pi * DoorMath.clamp01(s / .16));
      final omega =
          (h(3) > .5 ? 1 : -1) *
          (2 + 7 * h(4)) *
          (.04 / shard.radius).clamp(.5, 2.2);
      final angle = omega * (1 - math.exp(-1.8 * s)) / 1.8;
      final pos = fly(shard.centroid, dir * speed, s, drag: 2.6);
      final depth = DoorMath.smooth(s / .05);
      final look = _shardPaint(shard, k, h(6));
      c.save();
      c.translate(pos.dx, pos.dy);
      c.rotate(angle);
      c.scale(pop * shrink);
      // The slab's thickness: a darker copy pushed down and right.
      c.save();
      c.translate(.0035 * depth, .0055 * depth);
      c.drawPath(shard.face, DoorParts.fill(DoorPalette.stoneShade));
      c.restore();
      c.drawPath(shard.face, look.face);
      if (!shard.gravel) {
        c.save();
        c.clipPath(shard.face);
        for (final (a, b) in mortar) {
          _mortar(c, shard, a, b);
        }
        final socket = k.medallionRadius + .008;
        if ((shard.centroid - k.medallion).distance < shard.radius + socket) {
          final at = k.medallion - shard.centroid;
          c.drawCircle(at, socket, DoorParts.fill(DoorPalette.ink));
          c.drawCircle(
            at,
            socket - .003,
            DoorParts.fill(DoorPalette.stoneDeep),
          );
        }
        c.restore();
        c.drawPath(
          shard.lit,
          DoorParts.stroke(DoorPalette.stoneLight.withValues(alpha: .95), .003),
        );
        c.drawPath(
          shard.shade,
          DoorParts.stroke(DoorPalette.stoneDeep.withValues(alpha: .55), .0032),
        );
      }
      if (flash > 0) {
        c.drawPath(
          shard.face,
          DoorParts.fill(SkyColors.white.withValues(alpha: flash)),
        );
      }
      c.drawPath(
        shard.face,
        DoorParts.stroke(DoorPalette.ink, shard.gravel ? .0032 : .0038),
      );
      c.restore();
    }
  }

  /// The slab's flash (.28 at the moment it lets go) fading over its pieces.
  static double _tailFlash(double s) => s < .1 ? .28 * (1 - s / .1) : 0.0;

  static void _mortar(Canvas c, DoorShard shard, Offset a, Offset b) {
    final la = a - shard.centroid, lb = b - shard.centroid;
    c.drawLine(
      la,
      lb,
      DoorParts.stroke(DoorPalette.ink.withValues(alpha: .75), .003),
    );
    c.drawLine(
      la + const Offset(.0024, .002),
      lb + const Offset(.0024, .002),
      DoorParts.stroke(DoorPalette.stoneLight.withValues(alpha: .7), .0018),
    );
  }

  static _ShardLook _shardPaint(DoorShard shard, DoorLook k, double variation) {
    final cached = shard.paintCache;
    if (cached is _ShardLook) return cached;
    // The stone tone where the piece sat, lit from its own top-left so every
    // shard reads as a bevelled slab whichever way it spins.
    final axis = Offset(k.w * .9, k.h * .62);
    final t =
        ((shard.centroid.dx * axis.dx + shard.centroid.dy * axis.dy) /
                (axis.dx * axis.dx + axis.dy * axis.dy))
            .clamp(0.0, 1.0);
    final base = t < .34
        ? Color.lerp(DoorPalette.stoneLight, DoorPalette.stone, t / .34)!
        : Color.lerp(
            DoorPalette.stone,
            DoorPalette.stoneShade,
            (t - .34) / .66,
          )!;
    final shift = (variation - .5) * .14;
    final mid = shift >= 0
        ? Color.lerp(base, SkyColors.white, shift)!
        : Color.lerp(base, DoorPalette.ink, -shift)!;
    final r = shard.radius;
    final paint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(-r * .7, -r * .8),
        Offset(r * .7, r * .8),
        [
          Color.lerp(mid, SkyColors.white, .26)!,
          mid,
          Color.lerp(mid, DoorPalette.stoneDeep, .38)!,
        ],
        const [0, .5, 1],
      );
    final look = _ShardLook(paint);
    shard.paintCache = look;
    return look;
  }

  static void _straps(
    Canvas c,
    DoorLook k,
    double s,
    double power,
    bool rammed,
  ) {
    final sp = .85 + .5 * power + (rammed ? .4 : 0);
    final pieces = [
      (true, false, Offset(.3, -.4), -4.5),
      (true, true, Offset(.75, -.55), 6.0),
      (false, false, Offset(.28, .1), 5.0),
      (false, true, Offset(.7, -.05), -5.5),
    ];
    final xb = k.w * (.36 + .28 * DoorMath.hash(k.seed, 51));
    for (var i = 0; i < pieces.length; i++) {
      final (upper, rightHalf, v, omega) = pieces[i];
      final life = .5 + .22 * DoorMath.hash(k.seed, 52, i);
      if (s >= life) continue;
      final cy = upper ? k.topStrap : k.bottomStrap;
      final x0 = rightHalf ? xb : 0.0, x1 = rightHalf ? k.w : xb;
      final centre = Offset((x0 + x1) / 2, cy);
      final pos = fly(centre, v * sp, s, gravity: 1.9);
      final shrink = 1 - DoorMath.inQuad((s - .55 * life) / (.45 * life));
      final pop =
          1 +
          (.08 + .08 * power) * math.sin(math.pi * DoorMath.clamp01(s / .16));
      c.save();
      c.translate(pos.dx, pos.dy);
      c.rotate(omega * (1 - math.exp(-1.6 * s)) / 1.6);
      c.scale(pop * shrink);
      c.translate(-centre.dx, -centre.dy);
      DoorParts.strap(
        c,
        k,
        cy,
        upper: upper,
        x0: x0,
        x1: x1,
        snapLeft: rightHalf,
        snapRight: !rightHalf,
        shadow: false,
        flash: _tailFlash(s),
      );
      c.restore();
    }
  }

  /// The gold: the medallion coin-flips out and twinkles away, rivets pop,
  /// flecks glitter.
  static void _gold(Canvas c, DoorLook k, double s, double power, bool rammed) {
    final r = k.medallionRadius;
    final start = k.medallion;
    final v = Offset(
      .42 + .32 * power + (rammed ? .25 : 0),
      -.62 - .25 * power - (rammed ? .3 : 0),
    );
    // Rivets.
    for (var i = 0; i < 6; i++) {
      final u = DoorMath.hash(k.seed, 60, i), w = DoorMath.hash(k.seed, 61, i);
      final life = .38 + .2 * w;
      if (s >= life) continue;
      final upper = i < 3;
      final left = i % 3 != 1;
      final from = Offset(
        left ? .011 : k.w - .011,
        upper ? k.topStrap : k.bottomStrap,
      );
      final vel = Offset(
        (left ? -.15 : .25) + .5 * u,
        (upper ? -.55 : -.1) + .5 * (w - .5),
      );
      final pos = fly(from, vel * (.9 + .5 * power), s, gravity: 2.0);
      final t = s / life;
      final size = .0046 * (1 - DoorMath.inQuad((t - .5) / .5));
      c.drawCircle(pos, size + .0016, DoorParts.fill(DoorPalette.ink));
      c.drawCircle(pos, size, DoorParts.fill(DoorPalette.goldDeep));
      c.drawCircle(
        pos + Offset(-size * .3, -size * .3),
        size * .45,
        DoorParts.fill(DoorPalette.goldLight),
      );
    }
    // Flecks.
    for (var i = 0; i < 10; i++) {
      final u = DoorMath.hash(k.seed, 70, i), w = DoorMath.hash(k.seed, 71, i);
      final life = .28 + .3 * w;
      if (s >= life) continue;
      final a = u * math.pi * 2;
      final from = start + Offset(math.cos(a), math.sin(a)) * r * .8;
      final vel =
          Offset(math.cos(a) * .5 + .4, math.sin(a) * .6 - .25) *
          (.7 + .6 * w + .4 * power);
      final pos = fly(from, vel, s, drag: 3, gravity: 1.2);
      final t = s / life;
      DoorParts.twinkle(
        c,
        pos,
        (.006 + .005 * u) * math.sin(math.pi * math.min(1.0, t * 1.15)),
        s * 8 + u * 6,
        fill: i.isEven ? DoorPalette.gold : DoorPalette.goldLight,
      );
    }
    // The medallion coin-flips off its socket.
    const life = .66;
    if (s < life) {
      final pos = fly(start, v, s, drag: 1.4, gravity: 1.9);
      final flip = math.cos(s * 12.5);
      final sx = math.max(.13, flip.abs());
      final t = s / life;
      final pop = 1 + .42 * math.sin(math.pi * DoorMath.clamp01(s / .34));
      final shrink = s < .52
          ? 1.0
          : 1 - DoorMath.inQuad((s - .52) / (life - .52));
      final hot = k.door.damageStage >= 2 ? .8 : .2;
      // A halo at the pop, then a sparkle trail.
      if (s < .12) {
        c.drawCircle(
          pos,
          r * (1.15 + s * 7),
          DoorParts.fill(
            DoorPalette.goldLight.withValues(alpha: .6 * (1 - s / .12)),
          ),
        );
      }
      c.save();
      c.translate(pos.dx, pos.dy);
      c.rotate(s * 2.4 * (k.seed.isEven ? 1 : -1));
      c.scale(sx * pop * shrink, pop * shrink);
      DoorParts.medallion(
        c,
        r,
        sun: hot,
        glow: 1,
        back: flip < 0,
        flash: _tailFlash(s),
      );
      c.restore();
      assert(t >= 0);
    }
    // Trail twinkles behind the coin.
    for (var i = 0; i < 6; i++) {
      final born = .03 + .075 * i;
      final dt = s - born;
      if (dt <= 0 || dt >= .24) continue;
      final at =
          fly(start, v, born, drag: 1.4, gravity: 1.9) +
          Offset(
            (DoorMath.hash(k.seed, 80, i) - .5) * .03,
            (DoorMath.hash(k.seed, 81, i) - .5) * .03,
          );
      DoorParts.twinkle(
        c,
        at,
        (.013 + .006 * DoorMath.hash(k.seed, 82, i)) *
            math.sin(math.pi * dt / .24),
        dt * 5,
        fill: DoorPalette.goldLight,
      );
    }
    // Last burst where the coin vanishes.
    if (s >= .5 && s < .86) {
      final u = (s - .5) / .36;
      final at = fly(start, v, .52, drag: 1.4, gravity: 1.9);
      for (var i = 0; i < 6; i++) {
        final a = i * math.pi / 3 + .4;
        DoorParts.twinkle(
          c,
          at +
              Offset(math.cos(a), math.sin(a)) *
                  (.012 + .05 * DoorMath.outCubic(u)),
          (i.isEven ? .016 : .011) * math.sin(math.pi * u),
          u * 3 + i,
          fill: i.isEven ? DoorPalette.gold : SkyColors.white,
        );
      }
    }
  }

  // ---------------------------------------------------------------------
  // Dust, grit and pebbles.
  // ---------------------------------------------------------------------

  static void _dust(
    Canvas c,
    DoorLook k,
    DoorFracture f,
    double t,
    double s,
    double power,
    bool rammed,
    Offset strike,
  ) {
    final size = 1 + .25 * power + (rammed ? .15 : 0);
    // The blast cloud, the two seats and the exit side.
    puff(
      c,
      Offset(.03, strike.dy),
      .046 * size,
      t,
      .9,
      k.seed + 1,
      delay: .03,
      lift: .06,
      drift: const Offset(.09, 0),
    );
    puff(
      c,
      Offset(k.w * .5, -.004),
      .032 * size,
      t,
      .8,
      k.seed + 2,
      delay: .045,
      lift: .07,
      drift: const Offset(.02, -.02),
    );
    puff(
      c,
      Offset(k.w * .5, k.h + .004),
      .032 * size,
      t,
      .8,
      k.seed + 3,
      delay: .055,
      lift: .05,
      drift: const Offset(.04, .02),
    );
    puff(
      c,
      Offset(k.w - .004, strike.dy + .02),
      .036 * size,
      t,
      .82,
      k.seed + 4,
      delay: .06,
      lift: .05,
      drift: const Offset(.11, -.01),
    );

    // Grit.
    for (var i = 0; i < 14; i++) {
      final u = DoorMath.hash(k.seed, 100, i),
          v = DoorMath.hash(k.seed, 101, i);
      final life = .25 + .3 * v;
      if (s >= life) continue;
      final a = -1.35 + 2.7 * u;
      final speed = .6 + 1.1 * v + .4 * power;
      final pos = fly(
        strike + const Offset(.014, 0),
        Offset(math.cos(a), math.sin(a)) * speed,
        s,
        drag: 4,
        gravity: 1.0,
      );
      final q = s / life;
      final r = .0028 * (1 - q) + .0006;
      c.drawCircle(
        pos,
        r,
        DoorParts.fill(i.isEven ? DoorPalette.stoneDeep : DoorPalette.fresh),
      );
    }
    // Pebbles.
    final pebbles = 6 + (power * 2).round();
    for (var i = 0; i < pebbles; i++) {
      final u = DoorMath.hash(k.seed, 110, i),
          v = DoorMath.hash(k.seed, 111, i);
      final life = .5 + .35 * v;
      if (s >= life) continue;
      final a = -1.1 + 2.3 * u - (rammed ? .35 : 0);
      final speed = (.7 + .9 * v) * (.85 + .4 * power + (rammed ? .3 : 0));
      final pos = fly(
        strike + const Offset(.02, 0),
        Offset(math.cos(a), math.sin(a)) * speed,
        s,
        drag: 2.6,
        gravity: 2.2,
      );
      final q = s / life;
      final sz = (.0075 + .005 * v) * (1 - DoorMath.inQuad((q - .55) / .45));
      DoorParts.chip(c, pos, sz, (u - .5) * 22 * s, i + 3);
    }
    // Chips off the collars.
    for (var i = 0; i < 4; i++) {
      final upper = i < 2;
      final u = DoorMath.hash(k.seed, 120, i);
      final life = .45 + .2 * u;
      if (s >= life) continue;
      final from = Offset(
        k.w * (.3 + .4 * (i % 2)),
        upper ? -.006 : k.h + .006,
      );
      final vel = Offset(.35 * (u + .3), upper ? -.4 - .3 * u : .25 + .2 * u);
      final pos = fly(from, vel, s, drag: 2.4, gravity: 2.0);
      final q = s / life;
      DoorParts.chip(
        c,
        pos,
        (.008 + .003 * u) * (1 - DoorMath.inQuad((q - .5) / .5)),
        (u - .5) * 16 * s,
        i,
      );
    }
  }

  static const _dustLine = Color(0xff6f5e57);
  static const _dustShade = Color(0xffdacfc3);
  static const _dustLight = Color(0xfffcf6ec);

  // Puff centres and radii in [size] units.
  static const _puffs = <(double, double, double)>[
    (0, 0, .64),
    (-.66, .06, .46),
    (-.4, -.46, .5),
    (.18, -.6, .5),
    (.7, -.22, .47),
    (.62, .4, .45),
  ];

  /// A chunky outlined cloud that pops in, billows, drifts and thins to
  /// nothing over [life] seconds, [delay] after the start of [age].
  static void puff(
    Canvas c,
    Offset center,
    double size,
    double age,
    double life,
    int seed, {
    double delay = 0,
    double lift = .03,
    Offset drift = Offset.zero,
  }) {
    final a = age - delay;
    if (a < 0 || a >= life) return;
    final twist = (DoorMath.hash(seed, 0) - .5) * 1.2;
    final cosT = math.cos(twist), sinT = math.sin(twist);
    final at = List.filled(_puffs.length, Offset.zero);
    final radii = List.filled(_puffs.length, 0.0);
    var evaporate = 0.0;
    final billow = DoorMath.outQuad(a / life);
    for (var i = 0; i < _puffs.length; i++) {
      final (px, py, pr) = _puffs[i];
      final born = a - i * .008;
      if (born < 0) continue;
      final grow = .2 + .8 * DoorMath.outBack(born / .11);
      final start = .3 * life + .25 * life * DoorMath.hash(seed, i + 11);
      final fade = DoorMath.clamp01((a - start) / (life - .02 - start));
      final base = Offset(px * cosT - py * sinT, px * sinT + py * cosT);
      final spread = (.6 + .4 * grow + .22 * billow) * (1 - .3 * fade);
      final float = DoorMath.outQuad(fade);
      at[i] =
          center +
          drift * billow +
          Offset(0, -lift * billow) +
          base * size * spread +
          Offset(
            (DoorMath.hash(seed, i + 30) - .5) * .5 * float * size,
            -(.15 + .45 * DoorMath.hash(seed, i + 50)) * float * size,
          );
      radii[i] =
          pr *
          (.9 + .2 * DoorMath.hash(seed, i + 3)) *
          size *
          grow *
          (1 + .1 * billow) *
          (1 - fade) *
          (1 + .35 * fade);
      evaporate = math.max(evaporate, fade);
    }
    final rim = Paint()..color = Color.lerp(_dustLine, _dustShade, evaporate)!;
    final shade = Paint()..color = _dustShade;
    final light = Paint()..color = _dustLight;
    final line = .0042 * (1 - .5 * evaporate);
    for (var i = 0; i < _puffs.length; i++) {
      if (radii[i] > .005) c.drawCircle(at[i], radii[i] + line, rim);
    }
    for (var i = 0; i < _puffs.length; i++) {
      if (radii[i] > .005) c.drawCircle(at[i], radii[i], shade);
    }
    for (var i = 0; i < _puffs.length; i++) {
      final r = radii[i];
      if (r > .005) {
        c.drawCircle(at[i] + Offset(-.15 * r, -.19 * r), r * .74, light);
      }
    }
  }
}

class _ShardLook {
  _ShardLook(this.face);
  final Paint face;
}
