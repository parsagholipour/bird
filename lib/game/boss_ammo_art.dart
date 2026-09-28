import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../domain/game_rules.dart';
import '../ui/theme.dart';

/// Which boss a projectile belongs to; each has its own silhouette so a
/// volley reads as "that boss" even at a few pixels.
enum BossAmmoStyle {
  /// Baron Bat: a red bat-winged fireball around a gold star.
  ember,

  /// Spitter King: a boiling acid globule that drips as it flies.
  acid,

  /// Dusk Empress: a spinning pollen rosette trailing silk and glitter.
  pollen,
}

/// Boss shots: bigger, hotter siblings of the small-enemy pellets in
/// `EnemyAmmoArt`, drawn in hit-radius units travelling along +x.
///
/// The solid, ink-rimmed body ends exactly on the hit circle
/// (`BossAmmo.radius`) so a dodge that looks clean is clean; the halo and the
/// wake behind may extend further so the shot and its heading read at a
/// glance against any sky. Every motion follows simulation time, so pause and
/// replay seeking stay exact, and Reduced Motion freezes it to one pose.
abstract final class BossAmmoArt {
  // Palettes mirror BossRig, SpitterBossRig and DuskMothBossRig (kept as
  // literals so projectiles never depend on the rigs' drawing code).
  // Baron Bat.
  static const _gold = Color(0xffffd878), _ember = Color(0xffff775c);
  static const _blaze = Color(0xffff9f5a), _crimson = Color(0xffc23a48);
  static const _emberHot = Color(0xfffff2c9), _batInk = Color(0xff18182f);
  // Spitter King.
  static const _acid = Color(0xff6fe3a4), _mint = Color(0xffd4ffc1);
  static const _jade = Color(0xff2f9f78), _bog = Color(0xff1d5f52);
  static const _acidInk = Color(0xff223437);
  // Dusk Empress.
  static const _pollen = Color(0xffffc96f), _silk = Color(0xffffe3ba);
  static const _coral = Color(0xffefaa91), _plum = Color(0xff704663);
  static const _mothInk = Color(0xff392e4b), _pearl = Color(0xfffff3da);
  static const _rose = Color(0xffe0788a);

  static BossAmmoStyle styleFor(BossKind kind) => switch (kind) {
    BossKind.baronBat => BossAmmoStyle.ember,
    BossKind.spitterBeetle => BossAmmoStyle.acid,
    BossKind.duskMoth => BossAmmoStyle.pollen,
  };

  /// One in-flight boss shot at its simulated position, for [boss].
  static void shot(
    Canvas c,
    double height,
    BossAmmo ammo,
    SkyBoss boss, {
    required double seconds,
    required bool reducedMotion,
  }) => paint(
    c,
    center: Offset(ammo.x * height, ammo.y * height),
    radius: BossAmmo.radius * height,
    direction: math.atan2(ammo.vy, ammo.vx),
    attack: EnemyAttack.none,
    kind: boss.kind,
    enraged: boss.enraged,
    speed: math.sqrt(ammo.vx * ammo.vx + ammo.vy * ammo.vy),
    seconds: seconds,
    reducedMotion: reducedMotion,
  );

  /// Draws a boss shot centered on its hit circle of [radius] pixels.
  ///
  /// [kind] picks the boss; without it the legacy [attack] mapping is used
  /// (aimed → acid, fan → pollen, otherwise ember). [speed] (sim units per
  /// second) stretches the wake; [enraged] heats the shot up for the fury
  /// phase. [showTrail] false draws just the charged shot, e.g. at the muzzle.
  static void paint(
    Canvas c, {
    required Offset center,
    required double radius,
    required double direction,
    required EnemyAttack attack,
    required double seconds,
    required bool reducedMotion,
    bool showTrail = true,
    BossKind? kind,
    bool enraged = false,
    double speed = .6,
  }) {
    if (!radius.isFinite || radius <= 0 || !direction.isFinite) return;
    final style = kind != null
        ? styleFor(kind)
        : switch (attack) {
            EnemyAttack.aimed => BossAmmoStyle.acid,
            EnemyAttack.fan => BossAmmoStyle.pollen,
            EnemyAttack.none => BossAmmoStyle.ember,
          };
    // Direction gives each member of a fan its own rhythm without storing
    // particle state or changing projectile movement/collision geometry.
    final time = reducedMotion || !seconds.isFinite
        ? 0.0
        : seconds + direction * .37;
    final reach = speed.isFinite ? (speed / .6).clamp(.8, 1.3) : 1.0;
    c.save();
    c.translate(center.dx, center.dy);
    c.rotate(direction);
    // Keep the sky light on top whichever way the shot is heading.
    if (math.cos(direction) < 0) c.scale(1, -1);
    c.scale(radius);
    // Fine detail only where it can be seen; at gameplay size the shapes
    // stay bold and the ink rim holds ~1.8 px, ending on the hit circle.
    final fine = radius >= 14;
    final edge = math.max(.14, 1.8 / radius);
    switch (style) {
      case BossAmmoStyle.ember:
        if (showTrail) _emberWake(c, time, reach, enraged, fine);
        _emberBody(c, time, edge, enraged, fine);
      case BossAmmoStyle.acid:
        if (showTrail) _acidWake(c, time, reach, enraged, fine);
        _acidBody(c, time, edge, enraged, fine);
      case BossAmmoStyle.pollen:
        if (showTrail) _pollenWake(c, time, reach, enraged, fine);
        _pollenBody(c, time, edge, enraged, fine);
    }
    c.restore();
  }

  // Gradients are fixed in local units, so their shaders are built once and
  // shared by every shot on screen instead of being rebuilt each frame.
  static Paint _haloPaint(Color color, double alpha, double size) =>
      Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: alpha),
            color.withValues(alpha: alpha * .5),
            color.withValues(alpha: 0),
          ],
          stops: const [.4, .6, 1],
        ).createShader(Rect.fromCircle(center: Offset.zero, radius: size));

  /// A wake fill for unit space: transparent at x = -1, [alpha] at x = 0.
  static Paint _wakePaint(Color color, double alpha) => Paint()
    ..shader = LinearGradient(
      colors: [
        color.withValues(alpha: 0),
        color.withValues(alpha: alpha),
      ],
    ).createShader(const Rect.fromLTRB(-1, -1, 0, 1));

  static const _bounds = Rect.fromLTRB(-1, -1, 1, 1);

  // --------------------------------------------------------- Baron ember --

  static final _emberHalo = _haloPaint(_ember, .5, 2.4);
  static final _emberHaloFury = _haloPaint(_blaze, .62, 2.7);
  static final _emberWakeOuter = _wakePaint(_ember, .8);
  static final _emberWakeMid = _wakePaint(_blaze, .9);
  static final _emberWakeInner = _wakePaint(_gold, 1);
  static final _emberFill = Paint()
    ..shader = const LinearGradient(
      begin: Alignment.centerRight,
      end: Alignment.centerLeft,
      colors: [_gold, _blaze, _ember, _crimson],
      stops: [.1, .34, .6, 1],
    ).createShader(const Rect.fromLTRB(-3, -1, 1, 1));
  static final _emberCore = Paint()
    ..shader = RadialGradient(
      colors: [_emberHot, _emberHot, _gold, _gold.withValues(alpha: 0)],
      stops: const [0, .35, .62, 1],
    ).createShader(_bounds);

  static void _emberWake(
    Canvas c,
    double time,
    double reach,
    bool fury,
    bool fine,
  ) {
    final tail = (fury ? 6.6 : 5.8) * reach;
    final lick = math.sin(time * 11 - 1.2);
    final root = -.5 / tail;
    c.save();
    c.scale(tail, 1);
    c.drawPath(
      Path()
        ..moveTo(root, -.98)
        ..cubicTo(-.3, -.95, -.62, -.42 + lick * .16, -1, lick * .24)
        ..cubicTo(-.62, .42 + lick * .16, -.3, .95, root, .98)
        ..close(),
      _emberWakeOuter,
    );
    c.drawPath(
      Path()
        ..moveTo(root, -.62)
        ..quadraticBezierTo(-.45, -.42 + lick * .12, -.78, lick * .2)
        ..quadraticBezierTo(-.45, .42 + lick * .12, root, .62)
        ..close(),
      _emberWakeMid,
    );
    c.drawPath(
      Path()
        ..moveTo(root, -.3)
        ..quadraticBezierTo(-.3, -.18 + lick * .08, -.52, lick * .14)
        ..quadraticBezierTo(-.3, .18 + lick * .08, root, .3)
        ..close(),
      _emberWakeInner,
    );
    c.restore();
    // Sparks shed from the wings stream back, flicker and fade; in the fury
    // phase a few of them crackle into little storm zig-zags.
    final count = fury ? 5 : 4;
    for (var i = 0; i < count; i++) {
      final life = (time * 1.6 + i / count) % 1;
      final x = -2.0 - life * (tail - 1.6);
      final fade =
          math.sin(life * math.pi) * (.75 + .25 * math.sin(time * 31 + i));
      final side = i.isEven ? -1.0 : 1.0;
      final at = Offset(x, side * (.55 + life * .7 + (i % 3) * .1));
      final s = .62 * (1 - life * .45);
      final color = Color.lerp(_gold, _emberHot, .4)!.withValues(alpha: fade);
      if (fury && i.isOdd) {
        c.drawPath(
          Path()
            ..moveTo(at.dx, at.dy)
            ..lineTo(at.dx - s * .45, at.dy - side * s * .35)
            ..lineTo(at.dx - s * .6, at.dy + side * s * .05)
            ..lineTo(at.dx - s * 1.1, at.dy - side * s * .3),
          _stroke(color, .2),
        );
      } else {
        // A glowing gold ember chip, pointed along the flight line.
        c.drawPath(
          Path()
            ..moveTo(at.dx + s * .35, at.dy)
            ..lineTo(at.dx - s * .2, at.dy - s * .22)
            ..lineTo(at.dx - s * .9, at.dy)
            ..lineTo(at.dx - s * .2, at.dy + s * .22)
            ..close(),
          _fill(color),
        );
      }
    }
  }

  static void _emberBody(
    Canvas c,
    double time,
    double edge,
    bool fury,
    bool fine,
  ) {
    final f1 = math.sin(time * 17.3);
    final f2 = math.sin(time * 23.9 + 1.7);
    final f3 = math.sin(time * 19.1 + 3.1);
    final beat = math.sin(time * (fury ? 16 : 11));
    final heat =
        .5 + .28 * math.sin(time * 13) + .22 * math.sin(time * 29.3 + 1.1);
    c.drawCircle(
      Offset.zero,
      fury ? 2.7 : 2.4,
      fury ? _emberHaloFury : _emberHalo,
    );
    c.save();
    final body = 1 - edge / 2;
    c.scale(body);
    // A round head swept back into two bat-wing flames with scalloped
    // trailing edges and a long middle tongue: Baron's own silhouette, and
    // the heading stays obvious even at a few pixels.
    final flap = beat * .06;
    final shape = Path()
      ..moveTo(1, 0)
      ..cubicTo(1, -.56, .56, -1, 0, -1)
      ..quadraticBezierTo(-1.1, -1.12, -2.05 - f1 * .14, -1.0 - flap)
      ..quadraticBezierTo(-1.72, -.84, -1.62, -.62)
      ..quadraticBezierTo(-1.4, -.66, -1.18, -.46)
      ..quadraticBezierTo(-2.1, -.44, -3.0 - f2 * .24, .02 + f2 * .07)
      ..quadraticBezierTo(-2.1, .44, -1.18, .46)
      ..quadraticBezierTo(-1.4, .66, -1.62, .62)
      ..quadraticBezierTo(-1.72, .84, -2.05 - f3 * .14, 1.0 + flap)
      ..quadraticBezierTo(-1.1, 1.12, 0, 1)
      ..cubicTo(.56, 1, 1, .56, 1, 0)
      ..close();
    c.drawPath(shape, _emberFill);
    if (fine) {
      // Soot-dark veins along each flame, like the ribs of a bat wing.
      c.drawPath(
        Path()
          ..moveTo(-1.82, -.9)
          ..quadraticBezierTo(-1.2, -.8, -.62, -.66)
          ..moveTo(-2.6, .02)
          ..quadraticBezierTo(-1.7, .02, -1.0, .05)
          ..moveTo(-1.82, .9)
          ..quadraticBezierTo(-1.2, .8, -.62, .66),
        _stroke(_crimson.withValues(alpha: .55), .12),
      );
    }
    // White-hot heart with Baron's gold star turning inside it.
    c.save();
    c.translate(.16, 0);
    c.save();
    c.scale(.66 + heat * .08);
    c.drawCircle(Offset.zero, 1, _emberCore);
    c.restore();
    c.rotate(time * (fury ? 4.2 : 2.6));
    final star = _star(fury ? .6 : .54, .42);
    c.drawPath(star, _fill(_gold));
    c.drawPath(star, _stroke(_crimson.withValues(alpha: .8), fine ? .07 : .11));
    c.drawCircle(Offset.zero, .17, _fill(_emberHot));
    c.restore();
    c.drawPath(shape, _stroke(_batInk, edge / body));
    // A sky-lit gleam on the leading brow.
    c.drawPath(
      Path()
        ..moveTo(.08, -.74)
        ..quadraticBezierTo(.56, -.66, .72, -.3),
      _stroke(_emberHot.withValues(alpha: .9), fine ? .12 : .16),
    );
    c.restore();
  }

  /// A four-point sparkle star of outer radius [r].
  static Path _star(double r, double waist) {
    final path = Path();
    for (var i = 0; i < 8; i++) {
      final a = -math.pi / 2 + i * math.pi / 4;
      final d = i.isEven ? r : r * waist;
      final p = Offset(math.cos(a), math.sin(a)) * d;
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    return path..close();
  }

  // ------------------------------------------------------ Spitter acid --

  static final _acidHalo = _haloPaint(_acid, .62, 2.45);
  static final _acidHaloFury = _haloPaint(_acid, .74, 2.75);
  static final _acidWakeOuter = _wakePaint(_acid, .9);
  static final _acidWakeInner = _wakePaint(_mint, 1);
  static final _acidFill = Paint()
    ..shader = const RadialGradient(
      center: Alignment(.32, -.42),
      radius: 1.1,
      colors: [_mint, _acid, _jade],
      stops: [0, .32, 1],
    ).createShader(_bounds);

  static void _acidWake(
    Canvas c,
    double time,
    double reach,
    bool fury,
    bool fine,
  ) {
    final wag = math.sin(time * 9 - .9);
    final tail = (fury ? 6.2 : 5.5) * reach;
    final root = -.4 / tail;
    c.save();
    c.scale(tail, 1);
    // A thick goo ribbon, lumpy like a poured syrup.
    c.drawPath(
      Path()
        ..moveTo(root, -.95)
        ..cubicTo(-.3, -.9 + wag * .06, -.62, -.36 + wag * .2, -1, wag * .3)
        ..cubicTo(-.62, .44 + wag * .2, -.3, .98 - wag * .06, root, .95)
        ..close(),
      _acidWakeOuter,
    );
    c.drawPath(
      Path()
        ..moveTo(root, -.5)
        ..quadraticBezierTo(-.46, -.34 + wag * .14, -.78, wag * .24)
        ..quadraticBezierTo(-.46, .38 + wag * .14, root, .5)
        ..close(),
      _acidWakeInner,
    );
    c.restore();
    // Drops pinch off the ribbon and sag earthward (local +y is always the
    // lower side of the wake); bubbles ride along the top and pop.
    final drops = fury ? 4 : 3;
    for (var i = 0; i < drops; i++) {
      final life = (time * 1.25 + i / drops) % 1;
      final x = -1.5 - life * (tail - 1.4) * .9;
      final fade = math.sin(life * math.pi);
      final size = .42 * (1 - life * .5);
      final at = Offset(x, .3 + life * life * 1.5 + (i % 2) * .15);
      // A teardrop stretched along its fall.
      final drip = Path()
        ..moveTo(at.dx + size * .35, at.dy - size * 1.5)
        ..cubicTo(
          at.dx + size * .5,
          at.dy - size * .9,
          at.dx + size * 1.05,
          at.dy - size * .3,
          at.dx + size * .95,
          at.dy + size * .2,
        )
        ..arcToPoint(
          Offset(at.dx - size * .95, at.dy + size * .2),
          radius: Radius.circular(size * .96),
        )
        ..cubicTo(
          at.dx - size * .95,
          at.dy - size * .4,
          at.dx - size * .1,
          at.dy - size * .8,
          at.dx + size * .35,
          at.dy - size * 1.5,
        )
        ..close();
      c.drawPath(drip, _fill(_jade.withValues(alpha: .95 * fade)));
      c.drawCircle(
        at + Offset(size * .2, -size * .1),
        size * .4,
        _fill(_mint.withValues(alpha: fade)),
      );
    }
    for (var i = 0; i < 3; i++) {
      final life = (time * 1.7 + i / 3 + .15) % 1;
      final x = -1.7 - life * (tail - 1.8) * .75;
      final at = Offset(x, -.5 - life * .55 - (i % 2) * .12);
      final r = .2 + life * .14;
      final fade = 1 - life;
      if (life > .82) {
        // Pop: a broken ring flashes and vanishes.
        c.drawArc(
          Rect.fromCircle(center: at, radius: r * 1.5),
          .4,
          4.6,
          false,
          _stroke(_mint.withValues(alpha: (1 - life) * 5), .09),
        );
      } else {
        c.drawCircle(at, r, _fill(_mint.withValues(alpha: .28 * fade)));
        c.drawCircle(at, r, _stroke(_mint.withValues(alpha: .95 * fade), .1));
      }
    }
  }

  static void _acidBody(
    Canvas c,
    double time,
    double edge,
    bool fury,
    bool fine,
  ) {
    final boil = fury ? 1.5 : 1.0;
    c.drawCircle(
      Offset.zero,
      fury ? 2.65 : 2.35,
      fury ? _acidHaloFury : _acidHalo,
    );
    // The rim is laid down first at double width and the goo fills over its
    // inner half, so ink traces only the outer silhouette of the globule
    // and the blob it drags behind.
    final body = 1 - edge;
    c.save();
    c.scale(body);
    final rim = edge / body;
    // A boiling surface: gentle lobes roll around the rim but never push
    // past the hit circle.
    final shape = Path();
    const steps = 36;
    for (var i = 0; i <= steps; i++) {
      final a = i / steps * math.pi * 2;
      final lobes =
          math.sin(a * 3 + time * 7 * boil) * .5 +
          math.sin(a * 5 - time * 5.3 * boil + 1.3) * .5;
      final r = 1 - (.016 + .016 * lobes) * boil;
      final p = Offset(math.cos(a), math.sin(a)) * r;
      i == 0 ? shape.moveTo(p.dx, p.dy) : shape.lineTo(p.dx, p.dy);
    }
    shape.close();
    // Behind it a smaller blob hangs on a pinched neck of goo, stretching
    // and wagging like syrup; the pair is the Spitter King's silhouette.
    final wag = math.sin(time * 9 * boil - .9);
    final stretch = math.sin(time * 6.5 * boil);
    final blob = Offset(-1.74 - stretch * .08, wag * .14);
    final blobR = .42 + stretch * .03;
    final neck = Path()
      ..moveTo(-.5, -.72)
      ..quadraticBezierTo(
        -1.15,
        -.24 + wag * .06,
        blob.dx,
        blob.dy - blobR * .7,
      )
      ..lineTo(blob.dx, blob.dy + blobR * .7)
      ..quadraticBezierTo(-1.15, .24 + wag * .06, -.5, .72)
      ..close();
    final ink = _stroke(_acidInk, rim * 2);
    c.drawPath(neck, ink);
    c.drawCircle(blob, blobR, ink);
    c.drawPath(shape, ink);
    c.drawPath(neck, _fill(_acid));
    c.drawCircle(blob, blobR, _fill(_acid));
    c.drawCircle(
      blob + Offset(blobR * .2, -blobR * .35),
      blobR * .36,
      _fill(_mint.withValues(alpha: .95)),
    );
    c.drawPath(shape, _acidFill);
    c.save();
    c.clipPath(shape);
    // Bubbles rise through the brew and wrap around.
    for (var i = 0; i < (fury ? 4 : 3); i++) {
      final life = (time * .9 * boil + i / 3.3) % 1;
      final at = Offset(
        -.5 + i * .34 + math.sin(time * 3 + i * 2) * .08,
        .75 - life * 1.4,
      );
      final r = (.13 + (i % 2) * .06) * (fine ? 1 : 1.25);
      c.drawCircle(at, r, _fill(_mint.withValues(alpha: .38)));
      c.drawCircle(
        at,
        r,
        _stroke(_mint.withValues(alpha: .9), fine ? .05 : .08),
      );
    }
    // A darker toxic swirl turning in the middle.
    c.save();
    c.rotate(time * 2.6 * boil);
    c.drawPath(
      Path()
        ..moveTo(.5, -.1)
        ..cubicTo(.46, -.56, -.3, -.6, -.46, -.14)
        ..cubicTo(-.16, -.36, .3, -.2, .18, .1)
        ..cubicTo(.06, .36, -.28, .22, -.3, .04)
        ..cubicTo(-.46, .56, .6, .5, .5, -.1)
        ..close(),
      _fill(_bog.withValues(alpha: fine ? .34 : .5)),
    );
    c.restore();
    // Belly light bounced off the liquid.
    c.drawPath(
      Path()
        ..moveTo(-.64, .5)
        ..quadraticBezierTo(0, .92, .66, .46),
      _stroke(_mint.withValues(alpha: .75), fine ? .12 : .16),
    );
    c.restore();
    // Glossy highlight on the sky side.
    c.save();
    c.translate(.22, -.5);
    c.rotate(-.42);
    c.drawOval(
      fine
          ? const Rect.fromLTRB(-.4, -.17, .4, .17)
          : const Rect.fromLTRB(-.28, -.15, .28, .15),
      _fill(SkyColors.cream),
    );
    c.restore();
    if (fine) {
      c.drawCircle(const Offset(.66, -.08), .11, _fill(SkyColors.cream));
    }
    c.restore();
  }

  // ---------------------------------------------------- Empress pollen --

  static final _pollenHalo = _haloPaint(_pollen, .55, 2.35);
  static final _pollenHaloFury = _haloPaint(_coral, .6, 2.7);
  static final _silkWake = _wakePaint(_silk, .95);
  static final _pollenWakeGlow = _wakePaint(_pollen, .55);
  static final _petalFill = Paint()
    ..shader = const RadialGradient(
      colors: [_coral, _pollen, _silk],
      stops: [.18, .5, .95],
    ).createShader(_bounds);
  static final _petalFillFury = Paint()
    ..shader = const RadialGradient(
      colors: [_rose, _coral, _pollen, _silk],
      stops: [.16, .36, .66, 1],
    ).createShader(_bounds);

  /// Five round petals whose tips touch the hit circle; they overlap out
  /// to ~.67 of the radius, deep enough notches to read as a flower.
  static const _petalAt = Offset(.6, 0), _petalR = .4;
  static final _pollenCloud = Paint()
    ..shader = RadialGradient(
      colors: [_pollen.withValues(alpha: .75), _pollen.withValues(alpha: .5)],
    ).createShader(_bounds);
  static final _pollenCloudFury = Paint()
    ..shader = RadialGradient(
      colors: [_coral.withValues(alpha: .8), _coral.withValues(alpha: .55)],
    ).createShader(_bounds);

  static void _pollenWake(
    Canvas c,
    double time,
    double reach,
    bool fury,
    bool fine,
  ) {
    final tail = (fury ? 6.4 : 5.6) * reach;
    final root = -.4 / tail;
    c.save();
    c.scale(tail, 1);
    // A soft golden glow under two silk ribbons twisting round each other.
    c.drawPath(
      Path()
        ..moveTo(root, -.9)
        ..quadraticBezierTo(-.55, -.55, -1, 0)
        ..quadraticBezierTo(-.55, .55, root, .9)
        ..close(),
      _pollenWakeGlow,
    );
    // Two silk ribbons twist round each other, tapering as they fade;
    // they are built in wake-length units so one shared gradient fits.
    for (final phase in [0.0, math.pi]) {
      final top = <Offset>[], bottom = <Offset>[];
      const steps = 24;
      for (var i = 0; i <= steps; i++) {
        final u = i / steps;
        final x = root - u * (1 + root);
        final y = math.sin(u * 7.5 - time * 9 + phase) * (.74 - u * .28);
        final w = .17 * (1 - u * .75);
        top.add(Offset(x, y - w));
        bottom.add(Offset(x, y + w));
      }
      final ribbon = Path()..addPolygon([...top, ...bottom.reversed], true);
      c.drawPath(ribbon.shift(const Offset(0, .12)), _silkShadow);
      c.drawPath(ribbon, _silkWake);
    }
    c.restore();
    // Glittering pollen motes drift loose and twinkle out.
    final motes = fury ? 6 : 5;
    for (var i = 0; i < motes; i++) {
      final life = (time * 1.1 + i / motes) % 1;
      final spread = (i.isEven ? -1 : 1) * (.3 + (i % 3) * .28);
      final at = Offset(
        -1.6 - life * (tail - 1.2),
        spread * (1 + life * 1.1) + math.sin(time * 4 + i) * .12,
      );
      final fade = math.sin(life * math.pi);
      final twinkle = .7 + .3 * math.sin(time * 21 + i * 1.9);
      final s = (i % 3 == 0 ? .5 : .34) * (1 - life * .4) * twinkle;
      if (i % 3 == 0) {
        c.drawPath(
          _star(s, .3).shift(at),
          _fill(_pearl.withValues(alpha: fade)),
        );
      } else {
        c.drawCircle(at, s * .6, _fill(_pollen.withValues(alpha: fade)));
        c.drawCircle(
          at,
          s * .6,
          _stroke(_mothInk.withValues(alpha: .35 * fade), .06),
        );
      }
    }
  }

  static final _silkShadow = _wakePaint(_plum, .3);

  static void _pollenBody(
    Canvas c,
    double time,
    double edge,
    bool fury,
    bool fine,
  ) {
    c.drawCircle(
      Offset.zero,
      fury ? 2.7 : 2.35,
      fury ? _pollenHaloFury : _pollenHalo,
    );
    // A glowing pollen cloud fills the whole hit circle, so the notches
    // between petals never hide part of what can hit the bird.
    c.drawCircle(Offset.zero, 1, fury ? _pollenCloudFury : _pollenCloud);
    // The rim is laid down first at double width and the petals fill over
    // its inner half, so ink traces only the outer silhouette.
    final body = 1 - edge;
    c.save();
    c.scale(body);
    final rim = edge / body;
    final spin = time * (fury ? 3.4 : 2.3);
    c.rotate(spin);
    const step = math.pi * 2 / 5;
    for (var i = 0; i < 5; i++) {
      c.drawCircle(_petalAt, _petalR, _stroke(_mothInk, rim * 2));
      c.rotate(step);
    }
    // Each petal overlaps the one before, a pinwheel that shows the spin.
    final fill = fury ? _petalFillFury : _petalFill;
    for (var i = 0; i < 5; i++) {
      c.drawCircle(_petalAt, _petalR, fill);
      if (fine) {
        c.drawArc(
          Rect.fromCircle(center: _petalAt, radius: _petalR),
          -2.5,
          1.3,
          false,
          _stroke(fury ? _rose : _coral, rim * .6),
        );
        // A gleam along each petal's sky edge.
        c.drawArc(
          Rect.fromCircle(center: _petalAt, radius: _petalR * .7),
          -1.3,
          1.0,
          false,
          _stroke(_pearl.withValues(alpha: .85), .06),
        );
      }
      c.rotate(step);
    }
    // A plum heart ringed with pollen stamens and a pearl gleam.
    c.rotate(-spin * 1.5);
    c.drawCircle(Offset.zero, fine ? .3 : .2, _fill(fury ? _rose : _plum));
    if (fine) {
      for (var i = 0; i < 6; i++) {
        c.drawCircle(
          Offset(math.cos(i * math.pi / 3), math.sin(i * math.pi / 3)) * .19,
          .06,
          _fill(_pollen),
        );
      }
    }
    final pulse = .1 + math.sin(time * 10) * .02;
    c.drawCircle(Offset.zero, pulse, _fill(_pearl));
    c.restore();
  }

  static Paint _fill(Color color) => Paint()..color = color;

  static Paint _stroke(Color color, double width) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
}
