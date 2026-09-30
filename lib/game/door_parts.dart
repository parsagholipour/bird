import 'dart:math' as math;
import 'package:flutter/painting.dart';

import '../domain/obstacle.dart';
import '../domain/sky_door.dart';
import '../ui/theme.dart';
import 'door_fracture.dart';

/// Colours of the sealed stone plug: a cool lilac-grey granite bound in dark
/// iron and gold, so it never reads as the (warmer, brighter) wall around it.
abstract final class DoorPalette {
  static const ink = Color(0xff342d33);
  static const stoneLight = Color(0xffe4dde6);
  static const stone = Color(0xffb1a9bb);
  static const stoneShade = Color(0xff766d86);
  static const stoneDeep = Color(0xff544c63);
  static const iron = Color(0xff4b4760);
  static const ironLight = Color(0xff827d9a);
  static const gold = Color(0xffffcf6a);
  static const goldDeep = Color(0xffc98428);
  static const goldLight = Color(0xfffff3bd);
  static const fresh = Color(0xfff6efe4);
  static const socket = Color(0xff2d2624);
  static const moss = Color(0xff4f8a4c);
  static const mossLight = Color(0xff9bcb72);
  static const navy = Color(0xff2d2848);
}

/// Everything the painters need to know about one panel, derived once from
/// the simulation's state: the geometry, the blows and the fracture pattern.
class DoorLook {
  DoorLook(this.door, Obstacle o)
    : w = o.width,
      h = o.bottom - o.top,
      top = o.top,
      seed = (o.appearance * 131 + (o.bornAt * 1000).round()) & 0xffff;

  final SkyDoor door;
  final double w, h, top;
  final int seed;

  static const strapHeight = .03;

  late final Rect rect = Rect.fromLTWH(0, 0, w, h);

  /// The blows in panel units. A panel whose health was set without blows
  /// (older fixtures) gets one imagined blow so it still shows its damage.
  late final List<DoorBlow> blows = () {
    if (door.hits.isNotEmpty) {
      return [
        for (final hit in door.hits)
          DoorBlow((hit.y - top).clamp(.02, h - .02), hit.power),
      ];
    }
    if (door.hp < SkyDoor.maxHp || door.destroyed) {
      return [DoorBlow(h / 2, damage)];
    }
    return const <DoorBlow>[];
  }();

  late final DoorFracture? fracture = blows.isEmpty
      ? null
      : DoorFracture.of(
          w: w,
          h: h,
          seed: seed,
          blows: blows,
          lethal: door.destroyed,
        );

  late final Path silhouette = fracture?.silhouette ?? (Path()..addRect(rect));

  /// 0 intact .. 1 destroyed.
  double get damage => (SkyDoor.maxHp - door.hp) / SkyDoor.maxHp;

  /// The lethal blow, if this panel has been broken.
  DoorHit? get killer => door.destroyed ? door.lastHit : null;

  Offset get medallion => Offset(w / 2, h / 2);
  double get medallionRadius => math.min(w * .36, h * .19);
  double get topStrap => h * .2;
  double get bottomStrap => h * .8;

  /// How far the wall-end collars reach into the wall bodies.
  static const collar = .046;
}

abstract final class DoorParts {
  static Paint fill(Color color) => Paint()..color = color;

  static Paint stroke(Color color, double width) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  static Color tint(Color a, Color b, double t) => Color.lerp(a, b, t)!;

  /// The sun-and-bird keystone medallion, centred on the origin with the
  /// given outer [r]. [sun] warms the sun from gold (0) to hot coral (1).
  static void medallion(
    Canvas c,
    double r, {
    double sun = 0,
    double glow = 0,
    bool back = false,
    double flash = 0,
  }) {
    const ink = DoorPalette.ink;
    c.drawCircle(Offset.zero, r + .0035, fill(ink));
    c.drawCircle(Offset.zero, r, fill(DoorPalette.goldDeep));
    c.drawCircle(Offset(-r * .05, -r * .06), r * .9, fill(DoorPalette.gold));
    // Bright bevel on the ring's light side.
    c.drawArc(
      Rect.fromCircle(center: Offset.zero, radius: r * .8),
      -2.75,
      1.2,
      false,
      stroke(DoorPalette.goldLight, r * .09),
    );
    c.drawCircle(Offset.zero, r * .64, fill(ink));
    if (back) {
      c.drawCircle(Offset.zero, r * .55, fill(DoorPalette.goldDeep));
      c.drawCircle(Offset(-r * .04, -r * .05), r * .5, fill(DoorPalette.gold));
      c.drawCircle(Offset.zero, r * .22, stroke(DoorPalette.goldDeep, r * .07));
      _whiten(c, r, flash);
      return;
    }
    c.drawCircle(Offset.zero, r * .57, fill(DoorPalette.navy));
    // Sun: rays, disc, hot core.
    final sunColor = tint(DoorPalette.gold, SkyColors.coral, sun);
    final ray = Path();
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4 + math.pi / 8;
      final left = Offset(math.cos(a - .2), math.sin(a - .2));
      final right = Offset(math.cos(a + .2), math.sin(a + .2));
      final tip = Offset(math.cos(a), math.sin(a));
      ray
        ..moveTo(left.dx * r * .3, left.dy * r * .3 + r * .1)
        ..lineTo(tip.dx * r * .5, tip.dy * r * .5 + r * .1)
        ..lineTo(right.dx * r * .3, right.dy * r * .3 + r * .1)
        ..close();
    }
    c.drawPath(ray, fill(DoorPalette.goldDeep));
    c.drawCircle(Offset(0, r * .1), r * .3, fill(ink));
    c.drawCircle(Offset(0, r * .1), r * .26, fill(sunColor));
    c.drawCircle(
      Offset(-r * .06, r * .04),
      r * (.1 + .05 * glow),
      fill(DoorPalette.goldLight.withValues(alpha: .55 + .4 * glow)),
    );
    // The bird: a cream gull riding across the sun.
    final bird = Path()
      ..moveTo(-r * .48, -r * .12)
      ..quadraticBezierTo(-r * .24, -r * .5, 0, -r * .2)
      ..quadraticBezierTo(r * .24, -r * .5, r * .48, -r * .12)
      ..quadraticBezierTo(r * .26, -r * .27, 0, -r * .02)
      ..quadraticBezierTo(-r * .26, -r * .27, -r * .48, -r * .12)
      ..close();
    c.drawPath(bird, fill(SkyColors.cream));
    c.drawPath(bird, stroke(ink, r * .07));
    _whiten(c, r, flash);
  }

  static void _whiten(Canvas c, double r, double flash) {
    if (flash <= 0) return;
    c.drawCircle(
      Offset.zero,
      r + .0035,
      fill(SkyColors.white.withValues(alpha: flash)),
    );
  }

  /// One iron strap. [x0]..[x1] select a piece of it (the whole width by
  /// default); a piece can have a snapped, jagged end on either side.
  static void strap(
    Canvas c,
    DoorLook k,
    double cy, {
    required bool upper,
    double x0 = 0,
    double? x1,
    bool snapLeft = false,
    bool snapRight = false,
    bool shadow = true,
    double gem = 0,
    double flash = 0,
  }) {
    final right = x1 ?? k.w;
    final hh = DoorLook.strapHeight;
    final top = cy - hh / 2, bottom = cy + hh / 2;
    final body = Path();
    void jag(bool leftSide) {
      final x = leftSide ? x0 : right;
      final s = leftSide ? -1.0 : 1.0;
      // Sheared iron: a zig-zag, not a straight cut.
      final pts = leftSide ? [1.0, .66, .33, 0.0] : [0.0, .33, .66, 1.0];
      for (var i = 0; i < 4; i++) {
        final wobble = (i.isEven ? .5 : -.7) * .006 * s;
        body.lineTo(x + (i == 0 || i == 3 ? 0 : wobble), top + hh * pts[i]);
      }
    }

    body.moveTo(x0, top);
    body.lineTo(right, top);
    if (snapRight) {
      jag(false);
    } else {
      body.lineTo(right, bottom);
    }
    body.lineTo(x0, bottom);
    if (snapLeft) jag(true);
    body.close();
    if (shadow) {
      c.drawPath(
        body.shift(const Offset(.0015, .007)),
        fill(DoorPalette.ink.withValues(alpha: .32)),
      );
    }
    c.save();
    c.clipPath(body);
    c.drawRect(
      Rect.fromLTRB(x0 - .01, top, right + .01, bottom),
      fill(DoorPalette.iron),
    );
    // Lit top edge and shaded underside.
    c.drawRect(
      Rect.fromLTRB(x0 - .01, top, right + .01, top + .0055),
      fill(DoorPalette.ironLight),
    );
    c.drawRect(
      Rect.fromLTRB(x0 - .01, bottom - .005, right + .01, bottom),
      fill(DoorPalette.ink.withValues(alpha: .45)),
    );
    // Gold inlay running the length of the strap.
    c.drawRect(
      Rect.fromLTRB(x0 - .01, top + .0085, right + .01, top + .0125),
      fill(DoorPalette.gold),
    );
    c.drawRect(
      Rect.fromLTRB(x0 - .01, bottom - .0135, right + .01, bottom - .0095),
      fill(DoorPalette.goldDeep),
    );
    // Rivets at both ends of the whole strap.
    for (final x in [.011, k.w - .011]) {
      if (x < x0 - .004 || x > right + .004) continue;
      c.drawCircle(Offset(x, cy), .0048, fill(DoorPalette.ink));
      c.drawCircle(Offset(x, cy), .0034, fill(DoorPalette.goldDeep));
      c.drawCircle(
        Offset(x - .001, cy - .001),
        .0016,
        fill(DoorPalette.goldLight),
      );
    }
    if (upper) _pips(c, k, cy, gem);
    if (flash > 0) {
      c.drawRect(
        Rect.fromLTRB(x0 - .01, top, right + .01, bottom),
        fill(SkyColors.white.withValues(alpha: flash)),
      );
    }
    c.restore();
    c.drawPath(body, stroke(DoorPalette.ink, .0042));
  }

  static void _pips(Canvas c, DoorLook k, double cy, double gem) {
    // Four gems, one per quarter of health, shown even after the strap breaks.
    const cell = .0205, gap = .0045, hh = .0135;
    final total = cell * 4 + gap * 3;
    final left = (k.w - total) / 2;
    final hot = k.door.damageStage >= 2;
    final color = hot ? SkyColors.coral : DoorPalette.gold;
    for (var i = 0; i < 4; i++) {
      final r = RRect.fromRectAndRadius(
        Rect.fromLTWH(left + i * (cell + gap), cy - hh / 2, cell, hh),
        const Radius.circular(.003),
      );
      c.drawRRect(r.inflate(.0016), fill(DoorPalette.ink));
      c.drawRRect(r, fill(DoorPalette.navy));
      final part = (k.door.hp / SkyDoor.maxHp * 4 - i).clamp(0.0, 1.0);
      if (part > 0) {
        c.save();
        c.clipRRect(r);
        c.drawRect(
          Rect.fromLTWH(r.left, r.top, cell * part, hh),
          fill(tint(color, SkyColors.white, .25 * gem)),
        );
        c.drawRect(
          Rect.fromLTWH(r.left, r.top, cell * part, hh * .38),
          fill(DoorPalette.goldLight.withValues(alpha: .7)),
        );
        c.restore();
      }
    }
  }

  // -- wall-end collars -----------------------------------------------------

  /// The reinforced collar where the panel meets a wall end. It sits inside
  /// the wall body (never in the opening). [broken] draws the chewed socket a
  /// destroyed panel leaves behind; [dust] stains it.
  static void collar(
    Canvas c,
    DoorLook k, {
    required bool upper,
    double stress = 0,
    bool broken = false,
    double dust = 0,
  }) {
    final w = k.w;
    const reach = DoorLook.collar;
    c.save();
    if (upper) {
      c.translate(0, -reach);
    } else {
      c.translate(0, k.h + reach);
      c.scale(1, -1);
    }
    // Band space: x across, v from the far edge (0) to the opening (reach).
    c.clipRect(Rect.fromLTWH(0, 0, w, reach));
    final salt = upper ? 3 : 8;
    const ink = DoorPalette.ink;
    c.drawRect(Rect.fromLTWH(0, 0, w, reach), fill(DoorPalette.stone));
    // The stripe on the screen-top edge catches the light, the bottom one
    // sits in shade.
    c.drawRect(
      Rect.fromLTWH(0, upper ? 0 : reach - .006, w, .006),
      fill(upper ? DoorPalette.stoneLight : DoorPalette.stoneShade),
    );
    c.drawRect(
      Rect.fromLTWH(0, upper ? .006 : reach - .012, w, .006),
      fill(
        (upper ? DoorPalette.stoneLight : DoorPalette.stoneShade).withValues(
          alpha: .45,
        ),
      ),
    );
    c.drawRect(
      Rect.fromLTWH(w - .008, 0, .008, reach),
      fill(DoorPalette.stoneShade.withValues(alpha: .5)),
    );
    if (!broken) {
      c.drawRect(Rect.fromLTWH(0, reach - .0175, w, .003), fill(ink));
      c.drawRect(
        Rect.fromLTWH(0, reach - .0145, w, .006),
        fill(DoorPalette.gold),
      );
      c.drawRect(
        Rect.fromLTWH(0, reach - .0085, w, .0015),
        fill(DoorPalette.goldDeep),
      );
      // Dentils: the stone teeth that grip the panel's lip.
      c.drawRect(Rect.fromLTWH(0, reach - .007, w, .007), fill(ink));
      for (var i = 0; i < 4; i++) {
        if (stress >= .75 && i == 2) continue;
        c.drawRect(
          Rect.fromLTWH(w * (.045 + i * .235), reach - .0068, w * .17, .0058),
          fill(i.isEven ? DoorPalette.stoneLight : DoorPalette.stone),
        );
      }
    } else {
      _brokenLip(c, k, salt, reach);
    }
    // Rivets.
    for (final x in [.17, .83]) {
      final p = Offset(w * x, (reach - .0175) * .5);
      if (broken && (x > .5) == (salt.isOdd)) continue;
      c.drawCircle(p, .0046, fill(ink));
      c.drawCircle(p, .0032, fill(DoorPalette.goldDeep));
      c.drawCircle(
        p + const Offset(-.001, -.001),
        .0015,
        fill(DoorPalette.goldLight),
      );
    }
    if (!broken && stress >= .5) {
      final crack = Path()
        ..moveTo(w * .3, reach - .0175)
        ..lineTo(w * .25, reach * .55)
        ..lineTo(w * .32, reach * .3)
        ..lineTo(w * .24, .004);
      c.drawPath(
        crack.shift(const Offset(.0015, 0)),
        stroke(DoorPalette.stoneLight, .003),
      );
      c.drawPath(crack, stroke(ink, .003));
      if (stress >= .75) {
        final second = Path()
          ..moveTo(w * .74, reach - .0175)
          ..lineTo(w * .79, reach * .5)
          ..lineTo(w * .72, reach * .25);
        c.drawPath(second, stroke(ink, .003));
      }
    }
    if (dust > 0) {
      final tone = const Color(0xffcaa36e);
      for (var i = 0; i < 3; i++) {
        c.drawRect(
          Rect.fromLTWH(0, reach * (.45 - i * .14), w, reach * (.55 + i * .14)),
          fill(tone.withValues(alpha: .1 * dust)),
        );
      }
      for (var i = 0; i < 4; i++) {
        final x = w * (.12 + .25 * i + .08 * DoorMath.hash(k.seed, salt, i));
        c.drawLine(
          Offset(x, reach * .1),
          Offset(x, reach),
          stroke(ink.withValues(alpha: .12 * dust), .004),
        );
      }
    }
    // Outline: far edge and both sides.
    c.drawRect(Rect.fromLTWH(0, 0, w, .0048), fill(ink));
    c.drawRect(Rect.fromLTWH(0, 0, .0038, reach), fill(ink));
    c.drawRect(Rect.fromLTWH(w - .0038, 0, .0038, reach), fill(ink));
    c.restore();
  }

  /// The chewed lip of a broken socket: a dark hollow, a jagged stone edge,
  /// pale fresh breaks and the stubs of the gold brackets that held the plug.
  static void _brokenLip(Canvas c, DoorLook k, int salt, double reach) {
    final w = k.w;
    const ink = DoorPalette.ink;
    c.drawRect(
      Rect.fromLTWH(0, reach - .034, w, .034),
      fill(DoorPalette.socket),
    );
    const steps = 8;
    final profile = <Offset>[];
    for (var i = 0; i <= steps; i++) {
      final v =
          reach - .0175 + (DoorMath.hash(k.seed, salt + 40, i) - .5) * .03;
      profile.add(Offset(w * i / steps, v.clamp(reach - .033, reach - .003)));
    }
    final stone = Path()..moveTo(0, 0);
    stone.lineTo(w, 0);
    for (var i = steps; i >= 0; i--) {
      stone.lineTo(profile[i].dx, profile[i].dy);
    }
    stone.close();
    c.drawPath(stone, fill(DoorPalette.stone));
    c.drawPath(stone, fill(DoorPalette.stoneShade.withValues(alpha: .28)));
    final edge = Path()..moveTo(profile[0].dx, profile[0].dy);
    for (var i = 1; i <= steps; i++) {
      edge.lineTo(profile[i].dx, profile[i].dy);
    }
    c.drawPath(
      edge.shift(const Offset(0, -.0034)),
      stroke(DoorPalette.fresh, .0034),
    );
    c.drawPath(edge, stroke(ink, .0046));
    // Fresh pale scars on the stone above the break.
    for (var i = 0; i < 3; i++) {
      final at = profile[1 + i * 3 - (i == 2 ? 1 : 0)];
      final s = .005 + .004 * DoorMath.hash(k.seed, salt + 60, i);
      c.drawPath(
        Path()
          ..moveTo(at.dx - s, at.dy - .0025)
          ..lineTo(at.dx + s * .3, at.dy - s * 1.9)
          ..lineTo(at.dx + s * 1.2, at.dy - .0025)
          ..close(),
        fill(DoorPalette.fresh.withValues(alpha: .8)),
      );
    }
    // Cracks running back into the wall.
    for (var i = 0; i < 3; i++) {
      final x = w * (.2 + .3 * i + .06 * DoorMath.hash(k.seed, salt + 70, i));
      final p = profile[(x / w * steps).round().clamp(0, steps)];
      final crack = Path()
        ..moveTo(p.dx, p.dy - .002)
        ..lineTo(p.dx - .006, p.dy * .62)
        ..lineTo(p.dx + .004, p.dy * .34);
      c.drawPath(crack, stroke(ink, .003));
    }
    // Bracket stubs: a bent gold tongue still bolted into a socket.
    for (final f in [.22, .74]) {
      final p = profile[(f * steps).round()];
      final stub = Rect.fromLTWH(
        w * f - .0055,
        p.dy - .002,
        .011,
        math.min(.011, reach - p.dy + .002),
      );
      if (stub.height <= .002) continue;
      c.drawRect(stub.inflate(.0016), fill(ink));
      c.drawRect(stub, fill(DoorPalette.goldDeep));
      c.drawRect(
        Rect.fromLTWH(stub.left, stub.top, stub.width * .55, stub.height),
        fill(DoorPalette.gold),
      );
    }
  }

  // -- shared decorative shapes ---------------------------------------------

  static final Path _sparkle = _star4();

  static Path _star4() {
    final path = Path();
    for (var i = 0; i < 4; i++) {
      final a = -math.pi / 2 + i * math.pi / 2;
      final tip = Offset(math.cos(a), math.sin(a));
      final next = a + math.pi / 2;
      final nextTip = Offset(math.cos(next), math.sin(next));
      if (i == 0) path.moveTo(tip.dx, tip.dy);
      final b = a + math.pi / 4;
      path.quadraticBezierTo(
        math.cos(b) * .16,
        math.sin(b) * .16,
        nextTip.dx,
        nextTip.dy,
      );
    }
    return path..close();
  }

  /// A four-point gold twinkle of radius [size] turned by [turn].
  static void twinkle(
    Canvas c,
    Offset at,
    double size,
    double turn, {
    Color fill = DoorPalette.gold,
  }) {
    if (size <= .001) return;
    c.save();
    c.translate(at.dx, at.dy);
    c.rotate(turn);
    c.scale(size);
    c.drawPath(_sparkle, Paint()..color = fill);
    c.drawPath(
      _sparkle,
      stroke(DoorPalette.goldDeep, .16)..strokeJoin = StrokeJoin.round,
    );
    c.drawCircle(Offset.zero, .2, Paint()..color = SkyColors.white);
    c.restore();
  }

  /// The hot cartoon starburst where a blow lands: yellow, coral outline,
  /// white heart. [size] is the outer radius.
  static void burst(Canvas c, Offset at, double size, double turn) {
    if (size <= .002) return;
    c.save();
    c.translate(at.dx, at.dy);
    c.rotate(turn);
    c.scale(size);
    c.drawPath(_burstShape, Paint()..color = SkyColors.yellow);
    c.drawPath(
      _burstShape,
      stroke(SkyColors.coralDeep, .12)..strokeJoin = StrokeJoin.round,
    );
    c.scale(.56);
    c.drawPath(_burstShape, Paint()..color = SkyColors.white);
    c.restore();
  }

  static final Path _burstShape = () {
    final path = Path();
    const points = 10;
    for (var i = 0; i < points; i++) {
      final a = -math.pi / 2 + i * 2 * math.pi / points;
      final tip = Offset(math.cos(a), math.sin(a));
      final b = a + math.pi / points;
      final valley = Offset(math.cos(b), math.sin(b)) * .52;
      if (i == 0) path.moveTo(tip.dx, tip.dy);
      if (i > 0) path.lineTo(tip.dx, tip.dy);
      path.lineTo(valley.dx, valley.dy);
    }
    return path..close();
  }();

  /// A small angular stone chip, [size] across, with a lit face.
  static void chip(
    Canvas c,
    Offset at,
    double size,
    double turn,
    int seed, {
    Color face = DoorPalette.stone,
    Color lit = DoorPalette.stoneLight,
  }) {
    if (size <= .0015) return;
    c.save();
    c.translate(at.dx, at.dy);
    c.rotate(turn);
    c.scale(size);
    final shape = _chipShape(seed);
    c.drawPath(shape, Paint()..color = face);
    c.drawPath(
      Path()
        ..moveTo(-.55, -.1)
        ..lineTo(-.05, -.6)
        ..lineTo(.3, -.35)
        ..lineTo(-.3, .05)
        ..close(),
      Paint()..color = lit,
    );
    c.drawPath(
      shape,
      stroke(DoorPalette.ink, .3)..strokeJoin = StrokeJoin.round,
    );
    c.restore();
  }

  static final Map<int, Path> _chipShapes = {};

  static Path _chipShape(int seed) => _chipShapes.putIfAbsent(seed % 6, () {
    final s = seed % 6;
    final path = Path();
    const n = 5;
    for (var i = 0; i < n; i++) {
      final a = i * 2 * math.pi / n + s * .7;
      final r = .62 + .38 * DoorMath.hash(s, i, 5);
      final p = Offset(math.cos(a) * r, math.sin(a) * r * .9);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    return path..close();
  });
}
