import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../ui/theme.dart';
import 'door_fracture.dart';
import 'door_parts.dart';

/// The face of the sealed stone plug: bevelled granite blocks, a carved
/// keystone holding the sun-and-bird medallion, two iron straps (the upper one
/// carries the four health gems), moss, weathering and, on a damaged panel,
/// the crater bites and the cracks that will later be the shards' seams.
abstract final class DoorSlab {
  /// Stone gradient paints, keyed by panel size (they never change).
  static final _shaders = <int, ui.Shader>{};

  static ui.Shader stoneShader(
    double w,
    double h, [
    Offset origin = Offset.zero,
  ]) {
    final key = (w * 1000).round() * 10007 + (h * 1000).round();
    if (_shaders.length > 48) _shaders.clear();
    final base = _shaders.putIfAbsent(
      key,
      () => ui.Gradient.linear(
        Offset.zero,
        Offset(w * .9, h * .62),
        const [
          DoorPalette.stoneLight,
          DoorPalette.stone,
          DoorPalette.stoneShade,
        ],
        const [0, .34, 1],
      ),
    );
    return base;
  }

  /// The face of the panel in panel coordinates.
  ///
  /// [reach] says how far each blow's cracks have run; [lateScale] how far the
  /// seams between undamaged pieces have opened. [glint] (0..1) sweeps a sheen
  /// across; [pulse] (0..1) breathes the sun's glow; [flash] whitens the slab.
  static void paint(
    Canvas c,
    DoorLook k, {
    required double Function(int blow) reach,
    required double lateScale,
    double glint = -1,
    double pulse = 0,
    double flash = 0,
    double swell = 1,
    bool medallion = true,
    bool straps = true,
  }) {
    final w = k.w, h = k.h;
    final sil = k.silhouette;
    c.drawPath(sil, Paint()..shader = stoneShader(w, h));
    c.save();
    c.clipPath(sil);
    _blocks(c, k);
    _shade(c, k);
    _weathering(c, k);
    if (straps) {
      _strap(c, k, upper: true);
      _strap(c, k, upper: false);
    }
    _cracks(c, k, reach, lateScale);
    if (medallion) _medallion(c, k, pulse, swell);
    _bevel(c, k, sil);
    if (glint >= 0) _glint(c, k, glint);
    if (flash > 0) {
      c.drawRect(
        k.rect,
        Paint()..color = SkyColors.white.withValues(alpha: flash),
      );
    }
    c.restore();
    // The chunky ink outline follows the bitten silhouette, inner edge only:
    // the caller clips to the collision rectangle.
    c.drawPath(sil, DoorParts.stroke(DoorPalette.ink, .0085));
    _rims(c, k);
  }

  /// Mortar and block bevels as segments (start, end), also used by the
  /// shattering pieces so their faces carry the same masonry.
  static List<(Offset, Offset)> mortar(DoorLook k) {
    final w = k.w, h = k.h;
    final zones = zoneRects(k);
    final out = <(Offset, Offset)>[];
    var i = 0;
    for (final z in zones) {
      if (z.height < .01) {
        i++;
        continue;
      }
      final x = z.left + z.width * (.3 + .4 * DoorMath.hash(k.seed, 5, i));
      out.add((Offset(x, z.top), Offset(x, z.bottom)));
      i++;
    }
    assert(w > 0 && h > 0);
    return out;
  }

  /// The four stone zones between the straps and the keystone.
  static List<Rect> zoneRects(DoorLook k) {
    final w = k.w;
    final hh = DoorLook.strapHeight;
    final keyTop = k.medallion.dy - k.medallionRadius - .014;
    final keyBottom = k.medallion.dy + k.medallionRadius + .014;
    final upperStrapTop = k.topStrap - hh / 2,
        upperStrapBottom = k.topStrap + hh / 2;
    final lowerStrapTop = k.bottomStrap - hh / 2,
        lowerStrapBottom = k.bottomStrap + hh / 2;
    return [
      Rect.fromLTRB(0, 0, w, upperStrapTop),
      Rect.fromLTRB(0, upperStrapBottom, w, math.max(upperStrapBottom, keyTop)),
      Rect.fromLTRB(0, math.min(lowerStrapTop, keyBottom), w, lowerStrapTop),
      Rect.fromLTRB(0, lowerStrapBottom, w, k.h),
    ];
  }

  static Rect keystone(DoorLook k) => Rect.fromLTRB(
    k.w * .085,
    k.medallion.dy - k.medallionRadius - .014,
    k.w * .915,
    k.medallion.dy + k.medallionRadius + .014,
  );

  static void _blocks(Canvas c, DoorLook k) {
    const ink = DoorPalette.ink;
    final zones = zoneRects(k);
    // Every block is a slightly different stone, with a few chisel marks.
    var z = 0;
    for (final zone in zones) {
      if (zone.height >= .012) {
        final cut =
            zone.left + zone.width * (.3 + .4 * DoorMath.hash(k.seed, 5, z));
        for (var half = 0; half < 2; half++) {
          final tone = DoorMath.hash(k.seed, 13 + half, z) - .5;
          final part = half == 0
              ? Rect.fromLTRB(zone.left, zone.top, cut, zone.bottom)
              : Rect.fromLTRB(cut, zone.top, zone.right, zone.bottom);
          c.drawRect(
            part,
            DoorParts.fill(
              (tone > 0 ? SkyColors.white : DoorPalette.stoneDeep).withValues(
                alpha: tone.abs() * .3,
              ),
            ),
          );
        }
        for (var m = 0; m < 3; m++) {
          final at = Offset(
            zone.left +
                zone.width * (.1 + .8 * DoorMath.hash(k.seed, 17, z * 3 + m)),
            zone.top +
                zone.height * (.25 + .5 * DoorMath.hash(k.seed, 19, z * 3 + m)),
          );
          c.drawLine(
            at,
            at + const Offset(.0055, .0022),
            DoorParts.stroke(
              DoorPalette.stoneLight.withValues(alpha: .8),
              .0022,
            ),
          );
          c.drawLine(
            at + const Offset(.0012, .0028),
            at + const Offset(.0058, .0048),
            DoorParts.stroke(
              DoorPalette.stoneDeep.withValues(alpha: .45),
              .0018,
            ),
          );
        }
      }
      z++;
    }
    // Mortar joints.
    var i = 0;
    for (final (a, b) in mortar(k)) {
      c.drawLine(a, b, DoorParts.stroke(ink, .0032));
      c.drawLine(
        a + const Offset(.0024, .002),
        b + const Offset(.0024, -.002),
        DoorParts.stroke(DoorPalette.stoneLight.withValues(alpha: .8), .002),
      );
      i++;
    }
    // Each block is bevelled: a lit top and left, a shaded bottom and right.
    for (final z in zones) {
      if (z.height < .012) continue;
      final r = z.deflate(.0042);
      c.drawLine(
        r.topLeft,
        r.topRight,
        DoorParts.stroke(DoorPalette.stoneLight.withValues(alpha: .9), .0028),
      );
      c.drawLine(
        r.topLeft,
        r.bottomLeft,
        DoorParts.stroke(DoorPalette.stoneLight.withValues(alpha: .7), .0028),
      );
      c.drawLine(
        r.bottomLeft,
        r.bottomRight,
        DoorParts.stroke(DoorPalette.stoneDeep.withValues(alpha: .55), .003),
      );
      c.drawLine(
        r.topRight,
        r.bottomRight,
        DoorParts.stroke(DoorPalette.stoneDeep.withValues(alpha: .45), .003),
      );
    }
    // The keystone: a raised, lighter wedge of stone with a gold inlay line.
    final key = keystone(k);
    final rr = RRect.fromRectAndRadius(key, const Radius.circular(.012));
    c.drawRRect(
      rr,
      DoorParts.fill(DoorPalette.stoneLight.withValues(alpha: .55)),
    );
    c.drawRRect(
      rr.deflate(.006),
      DoorParts.stroke(DoorPalette.goldDeep, .0032),
    );
    c.drawRRect(
      rr.deflate(.0064).shift(const Offset(-.0007, -.0007)),
      DoorParts.stroke(DoorPalette.gold, .0018),
    );
    c.drawRRect(rr, DoorParts.stroke(ink, .0036));
    c.drawLine(
      key.topLeft + const Offset(.009, .0035),
      key.topRight + const Offset(-.009, .0035),
      DoorParts.stroke(DoorPalette.stoneLight, .0024),
    );
    c.drawLine(
      key.bottomLeft + const Offset(.009, -.0035),
      key.bottomRight + const Offset(-.009, -.0035),
      DoorParts.stroke(DoorPalette.stoneDeep.withValues(alpha: .6), .0028),
    );
    assert(i >= 0);
  }

  static void _weathering(Canvas c, DoorLook k) {
    final w = k.w, h = k.h;
    final flip = k.seed.isOdd;
    double fx(double x) => flip ? w - x : x;
    // Moss creeping up from the bottom and dripping from the top.
    void moss(double x, double y, double r) {
      final p = Offset(fx(x), y);
      c.drawCircle(p, r, DoorParts.fill(DoorPalette.moss));
      c.drawCircle(
        p + Offset(-r * .18, -r * .3),
        r * .66,
        DoorParts.fill(DoorPalette.mossLight),
      );
    }

    final sm = DoorMath.hash(k.seed, 21) * .02;
    moss(w * .14 + sm, h - .002, .017);
    moss(w * .30 + sm, h + .001, .012);
    moss(w * .46 + sm, h + .003, .008);
    moss(w * .05, h - .019, .011);
    moss(w * .86 - sm, .001, .013);
    moss(w * .70 - sm, -.001, .009);
    moss(w * .95, .02, .007);
    // Damp streaks running down from the moss and the strap rivets.
    for (final x in [w * .86 - sm, w * .22, w * .72]) {
      c.drawLine(
        Offset(fx(x), .012),
        Offset(
          fx(x),
          .012 + .026 + .01 * DoorMath.hash(k.seed, 25, (x * 1000).round()),
        ),
        DoorParts.stroke(DoorPalette.stoneDeep.withValues(alpha: .28), .0042),
      );
    }
    c.drawLine(
      Offset(fx(w * .86 - sm), .015),
      Offset(fx(w * .86 - sm), .03),
      DoorParts.stroke(DoorPalette.moss, .0032),
    );
    // Speckles and nicks.
    for (var i = 0; i < 14; i++) {
      final p = Offset(
        w * (.06 + .88 * DoorMath.hash(k.seed, 31, i)),
        h * (.03 + .94 * DoorMath.hash(k.seed, 41, i)),
      );
      if (i.isEven) {
        c.drawCircle(
          p,
          .0014,
          DoorParts.fill(DoorPalette.stoneDeep.withValues(alpha: .5)),
        );
      } else {
        c.drawLine(
          p,
          p + const Offset(.005, .0016),
          DoorParts.stroke(
            DoorPalette.stoneLight.withValues(alpha: .75),
            .0018,
          ),
        );
      }
    }
  }

  /// Cel-shaded ambient occlusion where the wall lips overhang the panel.
  static void _shade(Canvas c, DoorLook k) {
    final w = k.w, h = k.h;
    const ink = DoorPalette.ink;
    for (var i = 0; i < 3; i++) {
      final a = [.38, .2, .09][i];
      c.drawRect(
        Rect.fromLTWH(0, [0.0, .007, .014][i], w, [.007, .007, .009][i]),
        DoorParts.fill(ink.withValues(alpha: a)),
      );
      c.drawRect(
        Rect.fromLTWH(0, h - [.007, .014, .022][i], w, [.007, .007, .008][i]),
        DoorParts.fill(ink.withValues(alpha: a * .72)),
      );
    }
    c.drawRect(
      Rect.fromLTWH(w - .008, 0, .008, h),
      DoorParts.fill(ink.withValues(alpha: .16)),
    );
    c.drawRect(
      Rect.fromLTWH(0, 0, .005, h),
      DoorParts.fill(ink.withValues(alpha: .1)),
    );
  }

  static void _strap(Canvas c, DoorLook k, {required bool upper}) {
    DoorParts.strap(c, k, upper ? k.topStrap : k.bottomStrap, upper: upper);
  }

  static void _medallion(Canvas c, DoorLook k, double pulse, double swell) {
    final r = k.medallionRadius;
    final at = k.medallion;
    // The plug's socket: a dark recess the medallion is set into.
    c.drawCircle(
      at + const Offset(.001, .0025),
      r + .008,
      DoorParts.fill(DoorPalette.ink),
    );
    c.drawCircle(
      at + const Offset(.001, .0025),
      r + .005,
      DoorParts.fill(DoorPalette.stoneDeep),
    );
    c.save();
    c.translate(at.dx, at.dy);
    c.scale(swell);
    DoorParts.medallion(
      c,
      r,
      sun: (k.door.damageStage >= 2 ? .75 : 0) + .1 * pulse,
      glow: pulse,
    );
    c.restore();
  }

  static void _cracks(
    Canvas c,
    DoorLook k,
    double Function(int) reach,
    double lateScale,
  ) {
    final fracture = k.fracture;
    if (fracture == null) return;
    final path = fracture.crackPath(reach, lateScale: lateScale);
    final width = .0032 + k.damage * .0016;
    c.drawPath(
      path.shift(const Offset(.0017, .0021)),
      DoorParts.stroke(
        DoorPalette.stoneLight.withValues(alpha: .9),
        width * .95,
      ),
    );
    c.drawPath(path, DoorParts.stroke(DoorPalette.ink, width));
  }

  /// Light on the top and left rim, shade on the bottom and right.
  static void _bevel(Canvas c, DoorLook k, Path sil) {
    c.drawPath(
      sil.shift(const Offset(.0045, .0045)),
      DoorParts.stroke(DoorPalette.stoneLight.withValues(alpha: .85), .0085),
    );
    c.drawPath(
      sil.shift(const Offset(-.0045, -.0045)),
      DoorParts.stroke(DoorPalette.stoneDeep.withValues(alpha: .5), .0085),
    );
  }

  /// A diagonal band of light crossing the panel, [t] running 0..1.
  static void _glint(Canvas c, DoorLook k, double t) {
    final w = k.w, h = k.h;
    final x = -.05 + t * (w + .1);
    final band = Path()
      ..moveTo(x, 0)
      ..lineTo(x + .022, 0)
      ..lineTo(x + .022 - h * .18, h)
      ..lineTo(x - h * .18, h)
      ..close();
    c.drawPath(band, DoorParts.fill(SkyColors.white.withValues(alpha: .2)));
    final thin = Path()
      ..moveTo(x + .026, 0)
      ..lineTo(x + .033, 0)
      ..lineTo(x + .033 - h * .18, h)
      ..lineTo(x + .026 - h * .18, h)
      ..close();
    c.drawPath(thin, DoorParts.fill(SkyColors.white.withValues(alpha: .14)));
    // A twinkle on the medallion's rim as the sheen passes over it.
    final near = 1 - ((x + .01 - w / 2 + h * .09) / .05).abs().clamp(0.0, 1.0);
    if (near > 0) {
      DoorParts.twinkle(
        c,
        k.medallion +
            Offset(-k.medallionRadius * .55, -k.medallionRadius * .62),
        .016 * near,
        .3,
        fill: DoorPalette.goldLight,
      );
    }
  }

  /// A pale fresh-break rim inside every crater, on top of the outline.
  static void _rims(Canvas c, DoorLook k) {
    final fracture = k.fracture;
    if (fracture == null) return;
    for (final crater in fracture.craters) {
      // Only the torn edges, not the side that lies on the panel's own face.
      final path = Path();
      for (var i = 0; i < crater.length; i++) {
        final a = crater[i], b = crater[(i + 1) % crater.length];
        if (a.dx < 1e-5 && b.dx < 1e-5) continue;
        path
          ..moveTo(a.dx + .0026, a.dy)
          ..lineTo(b.dx + .0026, b.dy);
      }
      c.drawPath(
        path,
        DoorParts.stroke(DoorPalette.fresh.withValues(alpha: .9), .0034),
      );
    }
  }
}
