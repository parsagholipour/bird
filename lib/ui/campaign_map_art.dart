import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show ValueListenable, listEquals;
import 'package:flutter/material.dart';

import '../domain/sky_boss.dart' show BossKind;
import '../game/regions/world_region.dart';
import '../game/star_art.dart';
import 'campaign_keepsake_art.dart';
import 'campaign_region_still.dart';
import 'theme.dart';

/// Painters for the campaign map: the region scenery strip, the cloud banks
/// between stops, the dotted mail route and the level nodes.

/// How a node is drawn.
enum MapNodeLook { locked, open, current, cleared }

/// The strip of region stills behind the map, one per stop. Each still is
/// feathered into the one before it, so a stop hands over to the next like
/// the flight's own crossing. Only stops in view are drawn, from cached
/// images, so a swipe costs a few image draws a frame.
class MapSceneryPainter extends CustomPainter {
  MapSceneryPainter({
    required this.regions,
    required this.dims,
    required this.page,
    required this.pixelRatio,
    required this.scroll,
  }) : super(repaint: scroll);
  final List<WorldRegion> regions;
  final List<double> dims;
  final Size page;
  final double pixelRatio;
  final ScrollController scroll;

  /// Width of the hand-over between two stills, each side of the seam.
  static const feather = 56.0;

  /// A stop's still: one stop wide plus a feather each side, the left one
  /// fading in over the stop before (except on the [first] stop). The map
  /// also calls this ahead of a swipe, to have the next stills ready.
  static ui.Image still(
    WorldRegion region,
    Size page,
    double pixelRatio, {
    required bool first,
  }) => CampaignRegionStill.image(
    region,
    Size(page.width + feather * 2, page.height),
    pixelRatio,
    fadeIn: first ? 0 : feather * 2,
    forMap: true,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final offset = scroll.hasClients ? scroll.offset : 0.0;
    final first = ((offset - feather) / page.width).floor();
    final last = ((offset + page.width + feather) / page.width).floor();
    for (
      var i = math.max(0, first);
      i <= math.min(regions.length - 1, last);
      i++
    ) {
      final image = still(regions[i], page, pixelRatio, first: i == 0);
      final dst = Rect.fromLTWH(
        i * page.width - feather,
        0,
        page.width + feather * 2,
        page.height,
      );
      final paint = Paint()..filterQuality = FilterQuality.medium;
      if (dims[i] > 0) paint.colorFilter = CampaignRegionStill.dim(dims[i]);
      canvas.drawImageRect(
        image,
        Offset.zero & Size(image.width.toDouble(), image.height.toDouble()),
        dst,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(MapSceneryPainter old) =>
      old.page != page ||
      old.pixelRatio != pixelRatio ||
      !listEquals(old.regions, regions) ||
      !listEquals(old.dims, dims);
}

/// Banks of cloud over each seam between stops, and a soft cloud veil over
/// locked stops. Puffs are chunky and flat like the menu clouds.
class MapCloudPainter extends CustomPainter {
  const MapCloudPainter({
    required this.page,
    required this.stops,
    required this.veils,
  });
  final Size page;
  final int stops;

  /// Per stop, how thick the cloud cover over it is (0 for an open stop).
  final List<double> veils;

  @override
  void paint(Canvas canvas, Size size) {
    final h = page.height;
    for (var i = 0; i < stops; i++) {
      final x0 = i * page.width;
      if (veils[i] > 0) _veil(canvas, x0, veils[i]);
      if (i > 0) _seam(canvas, x0, i);
    }
    // The strip ends in cloud either side, where the world runs out.
    _bank(canvas, Offset(-10, h * .92), 1.1, 7, fade: .95);
    _bank(canvas, Offset(stops * page.width + 10, h * .92), 1.1, 9, fade: .95);
  }

  void _seam(Canvas canvas, double x, int seed) {
    final h = page.height;
    _bank(canvas, Offset(x, h * 1.04), .92, seed * 3, fade: .96);
    _bank(canvas, Offset(x - 8, h * .04), .46, seed * 5 + 1, fade: .7);
  }

  /// A cloud cover that thickens toward the ground and leaves the skyline
  /// peeking out above it.
  void _veil(Canvas canvas, double x0, double t) {
    final w = page.width, h = page.height;
    final rect = Rect.fromLTWH(x0, 0, w, h);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.linear(
          rect.topCenter,
          rect.bottomCenter,
          [
            Colors.white.withValues(alpha: .12 * t),
            Colors.white.withValues(alpha: .3 * t),
            Colors.white.withValues(alpha: .55 * t),
          ],
          const [0, .55, 1],
        ),
    );
    final random = math.Random(x0.round());
    for (var k = 0; k < 5; k++) {
      final cx = x0 + w * (.08 + k * .21) + random.nextDouble() * 30;
      final cy = h * (.8 + random.nextDouble() * .12);
      _bank(
        canvas,
        Offset(cx, cy),
        .7 + random.nextDouble() * .3,
        k + 40,
        fade: .72 * t,
      );
    }
  }

  static final _shade = Paint()..color = const Color(0xff9dbdcc);

  /// A heap of round puffs around [at], with a cool shadow underneath.
  static void _bank(
    Canvas canvas,
    Offset at,
    double scale,
    int seed, {
    double fade = 1,
  }) {
    final random = math.Random(seed);
    final puffs = <Rect>[];
    for (var k = 0; k < 9; k++) {
      final dx = (k - 4) * 26.0 * scale + (random.nextDouble() - .5) * 18;
      final lift = (1 - (k - 4).abs() / 5) * 44 * scale;
      final r = (30 + random.nextDouble() * 22) * scale;
      puffs.add(
        Rect.fromCircle(center: at + Offset(dx, -lift * .9), radius: r),
      );
    }
    canvas.saveLayer(
      null,
      Paint()..color = Colors.white.withValues(alpha: fade),
    );
    for (final p in puffs) {
      canvas.drawOval(p.shift(const Offset(0, 7)), _shade);
    }
    final body = Paint()..color = SkyColors.white;
    for (final p in puffs) {
      canvas.drawOval(p, body);
    }
    final light = Paint()..color = SkyColors.cream.withValues(alpha: .8);
    for (final p in puffs.take(5)) {
      canvas.drawOval(
        Rect.fromCenter(
          center: p.center.translate(-p.width * .12, -p.height * .2),
          width: p.width * .42,
          height: p.height * .3,
        ),
        light,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(MapCloudPainter old) =>
      old.page != page || old.stops != stops || !listEquals(old.veils, veils);
}

/// One dot on the mail route. [done] dots are on the stretch already flown;
/// [faint] dots cross a locked stop.
typedef RouteDot = ({Offset at, bool done, bool faint});

/// The dotted mail route: gold where the courier has already flown, cream
/// beyond, and faint across locked stops.
class MapRoutePainter extends CustomPainter {
  const MapRoutePainter(this.dots, {this.scale = 1});
  final List<RouteDot> dots;

  /// From the layout's coordinates to the canvas.
  final double scale;

  static final _edge = Paint()..color = SkyColors.ink.withValues(alpha: .55);
  static final _faintEdge = Paint()
    ..color = SkyColors.ink.withValues(alpha: .22);
  static final _gold = Paint()..color = SkyColors.yellow;
  static final _cream = Paint()..color = SkyColors.cream;
  static final _faint = Paint()..color = SkyColors.cream.withValues(alpha: .7);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(scale);
    for (final d in dots) {
      if (d.done) {
        canvas.drawCircle(d.at.translate(0, 1.2), 5.2, _edge);
        canvas.drawCircle(d.at, 4.2, _gold);
      } else if (d.faint) {
        canvas.drawCircle(d.at.translate(0, 1), 3.6, _faintEdge);
        canvas.drawCircle(d.at, 2.9, _faint);
      } else {
        canvas.drawCircle(d.at.translate(0, 1), 4.2, _edge);
        canvas.drawCircle(d.at, 3.3, _cream);
      }
    }
  }

  @override
  bool shouldRepaint(MapRoutePainter old) =>
      !identical(old.dots, dots) || old.scale != scale;
}

/// A level node: a chunky inked coin on a darker base, like the menu's
/// keys. The label, lock or headwear sits on the face.
class MapNodePainter extends CustomPainter {
  const MapNodePainter({
    required this.look,
    required this.radius,
    this.boss,
    this.pressed = false,
  });
  final MapNodeLook look;
  final double radius;
  final BossKind? boss;
  final bool pressed;

  static const depth = 5.0;

  (Color face, Color base) get _colors => switch (look) {
    MapNodeLook.locked => (const Color(0xffdfe7ea), const Color(0xffa9bcc4)),
    MapNodeLook.open => (SkyColors.cream, const Color(0xffd9c79c)),
    MapNodeLook.current => (SkyColors.yellow, SkyColors.gold),
    MapNodeLook.cleared =>
      boss != null
          ? (SkyColors.coral, SkyColors.coralDeep)
          : (const Color(0xffbfe6c9), const Color(0xff6fb795)),
  };

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero).translate(0, -depth / 2);
    final (face, base) = boss != null && look == MapNodeLook.open
        ? (SkyColors.coral, SkyColors.coralDeep)
        : _colors;
    final ink = Paint()
      ..color = look == MapNodeLook.locked
          ? SkyColors.ink.withValues(alpha: .55)
          : SkyColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6;
    final press = pressed ? depth - 1 : 0.0;
    // Soft ground shadow, then the base, then the face.
    canvas.drawOval(
      Rect.fromCenter(
        center: c.translate(0, radius + depth + 1),
        width: radius * 1.6,
        height: radius * .34,
      ),
      Paint()..color = SkyColors.ink.withValues(alpha: .16),
    );
    canvas.drawCircle(c.translate(0, depth), radius, Paint()..color = base);
    canvas.drawCircle(c.translate(0, depth), radius, ink);
    final top = c.translate(0, press);
    canvas.drawCircle(top, radius, Paint()..color = face);
    // A gloss along the upper rim.
    canvas.drawArc(
      Rect.fromCircle(center: top, radius: radius * .74),
      math.pi * 1.12,
      math.pi * .5,
      false,
      Paint()
        ..color = Colors.white.withValues(alpha: .6)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = radius * .12,
    );
    canvas.drawCircle(top, radius, ink);
    if (look == MapNodeLook.cleared) _check(canvas, top, radius);
    if (boss != null) {
      final box = Rect.fromCenter(
        center: top.translate(0, radius * .06),
        width: radius * 1.36,
        height: radius * 1.02,
      );
      if (look == MapNodeLook.locked) {
        canvas.saveLayer(
          box.inflate(radius * .3),
          Paint()
            ..colorFilter = CampaignRegionStill.dim(.9)
            ..color = Colors.white.withValues(alpha: .7),
        );
        CampaignHeadwear.paint(canvas, box, boss!);
        canvas.restore();
      } else {
        CampaignHeadwear.paint(canvas, box, boss!);
      }
    }
  }

  /// A small inked tick on the upper right rim of a finished level.
  static void _check(Canvas canvas, Offset center, double radius) {
    final at = center + Offset(radius * .74, -radius * .74);
    final r = math.max(8.5, radius * .3);
    canvas.drawCircle(at.translate(0, 1.5), r, Paint()..color = SkyColors.ink);
    canvas.drawCircle(at, r, Paint()..color = SkyColors.teal);
    canvas.drawCircle(
      at,
      r,
      Paint()
        ..color = SkyColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawPath(
      Path()
        ..moveTo(at.dx - r * .45, at.dy + r * .02)
        ..lineTo(at.dx - r * .1, at.dy + r * .36)
        ..lineTo(at.dx + r * .48, at.dy - r * .34),
      Paint()
        ..color = SkyColors.cream
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * .32
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(MapNodePainter old) =>
      old.look != look ||
      old.radius != radius ||
      old.boss != boss ||
      old.pressed != pressed;
}

/// A padlock glyph: a chunky ink-edged body and shackle.
class MapPadlockPainter extends CustomPainter {
  const MapPadlockPainter({this.color = SkyColors.muted, this.fill});
  final Color color;
  final Color? fill;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * .15
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromLTWH(w * .24, h * .06, w * .52, h * .62),
      math.pi,
      math.pi,
      false,
      stroke,
    );
    canvas.drawLine(Offset(w * .24, h * .37), Offset(w * .24, h * .46), stroke);
    canvas.drawLine(Offset(w * .76, h * .37), Offset(w * .76, h * .46), stroke);
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * .1, h * .44, w * .8, h * .52),
      Radius.circular(w * .16),
    );
    canvas.drawRRect(body, Paint()..color = fill ?? color);
    if (fill != null) {
      canvas.drawRRect(
        body,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * .09,
      );
    }
    final hole = Paint()..color = fill == null ? SkyColors.cream : color;
    canvas.drawCircle(Offset(w * .5, h * .64), w * .085, hole);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(w * .5, h * .74),
          width: w * .08,
          height: h * .14,
        ),
        Radius.circular(w * .04),
      ),
      hole,
    );
  }

  @override
  bool shouldRepaint(MapPadlockPainter old) =>
      old.color != color || old.fill != fill;
}

/// Three star slots under a node: earned stars in gold, the rest as empty
/// inked outlines.
class MapStarsPainter extends CustomPainter {
  const MapStarsPainter(this.earned);
  final int earned;

  static final _empty = Paint()..color = const Color(0xffe9dfcb);
  static final _emptyEdge = Paint()
    ..color = SkyColors.muted.withValues(alpha: .55)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.3
    ..strokeJoin = StrokeJoin.round;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.height * .44;
    final gap = (size.width - r * 6) / 2;
    for (var i = 0; i < 3; i++) {
      final at = Offset(
        r + i * (r * 2 + gap),
        size.height / 2 + (i == 1 ? -1.5 : 0),
      );
      final tilt = (i - 1) * .18;
      if (i < earned) {
        StarArt.mini(canvas, at, r, rotation: tilt, outline: 1.4);
      } else {
        final path = StarArt.path(at, r * .9, rotation: -math.pi / 2 + tilt);
        canvas.drawPath(path, _empty);
        canvas.drawPath(path, _emptyEdge);
      }
    }
  }

  @override
  bool shouldRepaint(MapStarsPainter old) => old.earned != earned;
}

/// The soft light behind the current node, breathing with [clock].
class MapGlowPainter extends CustomPainter {
  MapGlowPainter(this.clock, {required this.still}) : super(repaint: clock);
  final ValueListenable<double> clock;
  final bool still;

  @override
  void paint(Canvas canvas, Size size) {
    final pulse = still ? .5 : .5 + .5 * math.sin(clock.value * 2.4);
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2 * (.86 + .14 * pulse);
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = ui.Gradient.radial(
          c,
          r,
          [
            SkyColors.yellow.withValues(alpha: .78),
            SkyColors.yellow.withValues(alpha: .42),
            SkyColors.yellow.withValues(alpha: 0),
          ],
          const [.35, .62, 1],
        ),
    );
    // A ring of light that swells outward and fades, once a breath.
    if (!still) {
      final u = (clock.value * .6) % 1;
      canvas.drawCircle(
        c,
        size.shortestSide * (.3 + .2 * u),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3 * (1 - u)
          ..color = SkyColors.cream.withValues(alpha: .8 * (1 - u)),
      );
    }
  }

  @override
  bool shouldRepaint(MapGlowPainter old) => old.still != still;
}

/// A swallow-tailed ribbon behind a line of lettering.
class MapRibbonPainter extends CustomPainter {
  const MapRibbonPainter({
    this.color = SkyColors.coral,
    this.shade = SkyColors.coralDeep,
  });
  final Color color, shade;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final tail = h * .55, notch = h * .32;
    final ink = Paint()
      ..color = SkyColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeJoin = StrokeJoin.round;
    // Folded tails tuck behind the band at both ends.
    for (final side in [-1.0, 1.0]) {
      final x = side < 0 ? 0.0 : w;
      final inner = x - side * tail * .2;
      final outer = x + side * tail;
      final path = Path()
        ..moveTo(inner, h * .22)
        ..lineTo(outer, h * .22)
        ..lineTo(outer - side * notch, h * .61)
        ..lineTo(outer, h)
        ..lineTo(inner, h)
        ..close();
      canvas.drawPath(path, Paint()..color = shade);
      canvas.drawPath(path, ink);
    }
    final band = RRect.fromRectAndRadius(
      Rect.fromLTWH(tail * .3, 0, w - tail * .6, h * .8),
      const Radius.circular(4),
    );
    canvas.drawRRect(band, Paint()..color = color);
    canvas.drawRRect(band, ink);
  }

  @override
  bool shouldRepaint(MapRibbonPainter old) =>
      old.color != color || old.shade != shade;
}

/// The postcard waiting on a beaten chapter's last stop: a little card with
/// a stamp, tucked in an envelope.
class MapPostcardPainter extends CustomPainter {
  const MapPostcardPainter(this.boss);
  final BossKind boss;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final ink = Paint()
      ..color = SkyColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeJoin = StrokeJoin.round;
    final card = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * .06, h * .1, w * .88, h * .74),
      const Radius.circular(5),
    );
    canvas.drawRRect(
      card.shift(const Offset(0, 3)),
      Paint()..color = SkyColors.ink.withValues(alpha: .2),
    );
    canvas.drawRRect(card, Paint()..color = const Color(0xfffffcf4));
    // Airmail stripes along the edge.
    canvas.save();
    canvas.clipRRect(card);
    final stripe = Paint()..strokeWidth = w * .07;
    final rect = card.outerRect;
    for (var k = -6; k < 16; k++) {
      stripe.color = k.isEven ? SkyColors.coral : const Color(0xff5c8fd6);
      final x = rect.left + k * w * .12;
      canvas.drawLine(Offset(x, rect.top), Offset(x + h, rect.bottom), stripe);
    }
    canvas.drawRRect(
      card.deflate(w * .07),
      Paint()..color = const Color(0xfffffcf4),
    );
    canvas.restore();
    canvas.drawRRect(card, ink);
    // Lines of a letter and a tiny stamp.
    final text = Paint()
      ..color = SkyColors.muted.withValues(alpha: .55)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    for (var k = 0; k < 3; k++) {
      final y = rect.top + rect.height * (.42 + k * .17);
      canvas.drawLine(
        Offset(rect.left + w * .17, y),
        Offset(rect.left + w * (k == 2 ? .42 : .52), y),
        text,
      );
    }
    final stamp = Rect.fromLTWH(
      rect.right - w * .34,
      rect.top + h * .1,
      w * .22,
      h * .3,
    );
    canvas.drawRect(stamp, Paint()..color = CampaignHeadwear.field(boss));
    canvas.drawRect(
      stamp,
      Paint()
        ..color = SkyColors.ink.withValues(alpha: .6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    CampaignHeadwear.paint(canvas, stamp.deflate(w * .03), boss);
    // A heart seal on the corner.
    final heart = Offset(rect.left + w * .16, rect.bottom - h * .02);
    canvas.drawCircle(heart, w * .12, Paint()..color = SkyColors.coral);
    canvas.drawCircle(heart, w * .12, ink..strokeWidth = 2);
    StarArt.sparkle(canvas, heart, w * .07, SkyColors.cream);
  }

  @override
  bool shouldRepaint(MapPostcardPainter old) => old.boss != boss;
}
