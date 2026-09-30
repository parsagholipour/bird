import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../domain/sky_boss.dart' show BossKind;
import '../domain/world_region.dart';
import 'campaign_keepsake_art.dart' show CampaignHeadwear;
import 'campaign_region_still.dart';
import 'theme.dart';

/// The place behind a story scene: a region's scenery as a still, or the
/// Sky Club post's mail room when [region] is null. A soft shade over it
/// sets the cast and the speech panel apart from any scenery, bright or
/// dark. [floor] is where the cast stands, in logical pixels from the top.
class StoryBackdrop extends StatelessWidget {
  const StoryBackdrop({super.key, required this.region, required this.floor});
  final WorldRegion? region;
  final double floor;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: Stack(
      fit: StackFit.expand,
      children: [
        if (region case final region?)
          CampaignRegionView(region: region)
        else
          CustomPaint(painter: StoryPostPainter(floor: floor)),
        CustomPaint(
          painter: _ShadePainter(floor: floor, indoors: region == null),
        ),
      ],
    ),
  );
}

/// A shade that deepens toward the floor, where the panel sits, and leaves
/// the sky of the place readable.
class _ShadePainter extends CustomPainter {
  const _ShadePainter({required this.floor, required this.indoors});
  final double floor;
  final bool indoors;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final k = indoors ? .55 : 1.0;
    final at = (floor / size.height).clamp(.2, .9);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            SkyColors.ink.withValues(alpha: .2 * k),
            SkyColors.ink.withValues(alpha: .26 * k),
            SkyColors.ink.withValues(alpha: .5 * k + .12),
            SkyColors.ink.withValues(alpha: .78),
          ],
          stops: [0, at * .55, at, 1],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_ShadePainter old) =>
      old.floor != floor || old.indoors != indoors;
}

/// The Sky Club post at sunrise: a cosy mail room. A round window looks
/// east over the clouds, the five routes are pinned on a map by the door,
/// and the pigeonholes are full of letters waiting for a courier.
///
/// Authored for a 360-high stage and scaled to the box; a wider box shows
/// more wall between the map and the pigeonholes. The counter's top sits at
/// [floor].
class StoryPostPainter extends CustomPainter {
  const StoryPostPainter({required this.floor});
  final double floor;

  static const _ink = SkyColors.ink;
  static const _wood = Color(0xffc98a4f), _woodLit = Color(0xffe3ab6c);
  static const _woodDeep = Color(0xff96603a), _hollow = Color(0xff7a4b30);
  static const _paper = Color(0xfffff4d8);

  static Paint _fill(Color color) => Paint()..color = color;
  static Paint _line([double width = 2.2, double alpha = .8]) => Paint()
    ..color = _ink.withValues(alpha: alpha)
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final s = size.height / 360;
    final w = size.width / s, top = floor / s;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.scale(s);
    _wall(canvas, w, top);
    final window = Offset(w / 2, top * .42);
    _glow(canvas, window, w);
    _window(canvas, window, math.min(68, top * .27));
    _map(canvas, Rect.fromLTWH(w * .045, top * .13, 168, 132));
    _pigeonholes(canvas, Rect.fromLTWH(w * .955 - 190, top * .1, 190, 150));
    _bunting(canvas, w);
    _counter(canvas, w, top);
    canvas.restore();
  }

  /// Warm boards, with a dado rail above the counter.
  void _wall(Canvas c, double w, double top) {
    final rect = Rect.fromLTWH(0, 0, w, 360);
    c.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xffffe9c6), Color(0xffffd9a8), Color(0xfff6bd8a)],
        ).createShader(rect),
    );
    final seam = Paint()
      ..color = const Color(0xffd99a63).withValues(alpha: .28)
      ..strokeWidth = 1.5;
    for (var x = 28.0; x < w; x += 52) {
      c.drawLine(Offset(x, 0), Offset(x, top), seam);
    }
  }

  /// The sunrise spills into the room from the window.
  void _glow(Canvas c, Offset at, double w) {
    final r = math.max(260.0, w * .42);
    c.drawCircle(
      at,
      r,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xfffff6c9).withValues(alpha: .85),
            const Color(0xffffe6a6).withValues(alpha: .3),
            const Color(0xffffe6a6).withValues(alpha: 0),
          ],
          stops: const [0, .45, 1],
        ).createShader(Rect.fromCircle(center: at, radius: r)),
    );
  }

  /// A round window on the sunrise: the sun coming up through the clouds,
  /// and another of the club's islands far off.
  void _window(Canvas c, Offset at, double r) {
    final glass = Rect.fromCircle(center: at, radius: r);
    c.drawCircle(at + const Offset(0, 5), r + 11, _fill(_woodDeep));
    c.drawCircle(at, r + 11, _fill(_wood));
    c.drawCircle(at, r + 11, _line(2.6));
    c.save();
    c.clipPath(Path()..addOval(glass));
    c.drawRect(
      glass,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xff8ed2ef),
            Color(0xffc9ecf0),
            Color(0xffffe3a8),
            Color(0xffffb98a),
          ],
          stops: [0, .4, .72, 1],
        ).createShader(glass),
    );
    // Rays fan out from the sun, low in the glass.
    final sun = at + Offset(-r * .1, r * .62);
    final ray = _fill(SkyColors.white.withValues(alpha: .26));
    for (var i = 0; i < 9; i++) {
      final a = math.pi + (i + .5) * math.pi / 9;
      const spread = .07;
      c.drawPath(
        Path()
          ..moveTo(sun.dx, sun.dy)
          ..lineTo(
            sun.dx + math.cos(a - spread) * r * 2.2,
            sun.dy + math.sin(a - spread) * r * 2.2,
          )
          ..lineTo(
            sun.dx + math.cos(a + spread) * r * 2.2,
            sun.dy + math.sin(a + spread) * r * 2.2,
          )
          ..close(),
        ray,
      );
    }
    c.drawCircle(sun, r * .5, _fill(const Color(0xfffff3b8)));
    c.drawCircle(sun, r * .38, _fill(const Color(0xffffd96a)));
    // A far island with its flag, and cloud banks along the sill.
    final isle = at + Offset(r * .5, -r * .02);
    c.drawPath(
      Path()
        ..moveTo(isle.dx - r * .24, isle.dy)
        ..lineTo(isle.dx + r * .24, isle.dy)
        ..lineTo(isle.dx + r * .06, isle.dy + r * .26)
        ..lineTo(isle.dx - r * .1, isle.dy + r * .2)
        ..close(),
      _fill(const Color(0xffd6a883)),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(
          isle.dx - r * .28,
          isle.dy - r * .07,
          isle.dx + r * .28,
          isle.dy + r * .03,
        ),
        Radius.circular(r * .05),
      ),
      _fill(const Color(0xff9bd6a4)),
    );
    c.drawLine(
      isle + Offset(r * .06, -r * .06),
      isle + Offset(r * .06, -r * .3),
      _line(1.6, .7),
    );
    c.drawPath(
      Path()
        ..moveTo(isle.dx + r * .06, isle.dy - r * .3)
        ..lineTo(isle.dx + r * .24, isle.dy - r * .24)
        ..lineTo(isle.dx + r * .06, isle.dy - r * .18)
        ..close(),
      _fill(SkyColors.coral),
    );
    final cloud = _fill(SkyColors.white.withValues(alpha: .92));
    for (final (dx, dy, k) in const [
      (-.62, .74, .34),
      (-.2, .86, .4),
      (.34, .8, .36),
      (.76, .9, .3),
      (-.58, -.22, .16),
      (-.4, -.18, .2),
      (-.22, -.2, .14),
    ]) {
      c.drawCircle(at + Offset(dx * r, dy * r), k * r, cloud);
    }
    c.restore();
    // Glazing bars, and a gleam on the glass.
    final bar = _fill(_wood);
    c.drawRect(Rect.fromCenter(center: at, width: 7, height: r * 2), bar);
    c.drawRect(Rect.fromCenter(center: at, width: r * 2, height: 7), bar);
    c.drawLine(at + Offset(-3.5, -r), at + Offset(-3.5, r), _line(1.6, .55));
    c.drawLine(at + Offset(3.5, -r), at + Offset(3.5, r), _line(1.6, .55));
    c.drawLine(at + Offset(-r, -3.5), at + Offset(r, -3.5), _line(1.6, .55));
    c.drawLine(at + Offset(-r, 3.5), at + Offset(r, 3.5), _line(1.6, .55));
    c.drawCircle(at, r, _line(2.6));
    c.drawArc(
      glass.deflate(6),
      math.pi * 1.08,
      math.pi * .3,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round
        ..color = SkyColors.white.withValues(alpha: .8),
    );
    c.drawArc(
      Rect.fromCircle(center: at, radius: r + 11).deflate(3.5),
      math.pi * 1.1,
      math.pi * .5,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..color = _woodLit,
    );
  }

  /// The route map: five dotted routes out of the club, each to its pin in
  /// its chapter's colour.
  void _map(Canvas c, Rect r) {
    c.save();
    c.translate(r.center.dx, r.center.dy);
    c.rotate(-.025);
    c.translate(-r.center.dx, -r.center.dy);
    final frame = RRect.fromRectAndRadius(r, const Radius.circular(7));
    c.drawRRect(frame.shift(const Offset(0, 4)), _fill(_woodDeep));
    c.drawRRect(frame, _fill(_wood));
    c.drawRRect(frame, _line(2.6));
    final sheet = r.deflate(9);
    c.drawRect(sheet, _fill(_paper));
    c.save();
    c.clipRect(sheet);
    // Pale seas and a few islands of land.
    c.drawRect(sheet, _fill(const Color(0xffd7eef2).withValues(alpha: .8)));
    final land = _fill(const Color(0xffdfe9b8));
    for (final (x, y, rx, ry) in const [
      (.2, .3, .2, .16),
      (.34, .66, .16, .2),
      (.62, .28, .22, .14),
      (.8, .66, .2, .18),
      (.5, .9, .24, .1),
    ]) {
      c.drawOval(
        Rect.fromCenter(
          center: sheet.topLeft + Offset(x * sheet.width, y * sheet.height),
          width: rx * sheet.width * 2,
          height: ry * sheet.height * 2,
        ),
        land,
      );
    }
    final home = sheet.topLeft + Offset(sheet.width * .5, sheet.height * .48);
    const ends = [
      Offset(.14, .24),
      Offset(.3, .78),
      Offset(.66, .2),
      Offset(.86, .62),
      Offset(.9, .1),
    ];
    for (var i = 0; i < ends.length; i++) {
      final end =
          sheet.topLeft +
          Offset(ends[i].dx * sheet.width, ends[i].dy * sheet.height);
      final bend =
          (home + end) / 2 +
          Offset((end.dy - home.dy) * .3, (home.dx - end.dx) * .3);
      final route = Path()
        ..moveTo(home.dx, home.dy)
        ..quadraticBezierTo(bend.dx, bend.dy, end.dx, end.dy);
      final color = CampaignHeadwear.field(BossKind.values[i]);
      for (final metric in route.computeMetrics()) {
        for (var d = 7.0; d < metric.length - 5; d += 7) {
          final p = metric.getTangentForOffset(d)!.position;
          c.drawCircle(p, 1.7, _fill(color));
        }
      }
      // A pin at the end of the route.
      c.drawCircle(
        end + const Offset(0, 1.5),
        5,
        _fill(_ink.withValues(alpha: .25)),
      );
      c.drawCircle(end, 5, _fill(color));
      c.drawCircle(end, 5, _line(1.8, .85));
      c.drawCircle(end + const Offset(-1.4, -1.6), 1.4, _fill(SkyColors.white));
    }
    // The club, where every route begins.
    c.drawCircle(home, 7.5, _fill(SkyColors.yellow));
    c.drawCircle(home, 7.5, _line(2));
    c.drawCircle(home, 2.6, _fill(_ink));
    c.restore();
    c.drawRect(sheet, _line(1.8, .6));
    c.restore();
  }

  /// The sorting rack: a cabinet of pigeonholes, most of them full.
  void _pigeonholes(Canvas c, Rect r) {
    final frame = RRect.fromRectAndRadius(r, const Radius.circular(8));
    c.drawRRect(frame.shift(const Offset(0, 5)), _fill(_woodDeep));
    c.drawRRect(frame, _fill(_wood));
    c.drawRRect(frame, _line(2.6));
    c.drawLine(
      r.topLeft + const Offset(10, 4.5),
      r.topRight + const Offset(-10, 4.5),
      Paint()
        ..color = _woodLit
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    const columns = 5, rows = 4;
    final inner = r.deflate(9);
    final cw = inner.width / columns, ch = inner.height / rows;
    final rng = math.Random(11);
    const seals = [
      SkyColors.coral,
      Color(0xff4583c4),
      SkyColors.yellow,
      SkyColors.teal,
      SkyColors.purple,
    ];
    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < columns; col++) {
        final cell = Rect.fromLTWH(
          inner.left + col * cw + 2.5,
          inner.top + row * ch + 2.5,
          cw - 5,
          ch - 5,
        );
        final hole = RRect.fromRectAndRadius(cell, const Radius.circular(4));
        c.drawRRect(hole, _fill(_hollow));
        c.save();
        c.clipRRect(hole);
        c.drawRect(
          Rect.fromLTWH(cell.left, cell.top, cell.width, 5),
          _fill(_ink.withValues(alpha: .22)),
        );
        // Letters lean in the hole; a few holes hold a parcel, a few none.
        final pick = rng.nextInt(10);
        if (pick < 7) {
          final n = 1 + rng.nextInt(3);
          for (var i = 0; i < n; i++) {
            final x =
                cell.left +
                cell.width * (.24 + i * .24 + rng.nextDouble() * .06);
            final lean = (rng.nextDouble() - .5) * .5;
            c.save();
            c.translate(x, cell.bottom);
            c.rotate(lean);
            final letter = Rect.fromLTWH(
              -6,
              -cell.height * .78,
              12,
              cell.height * .8,
            );
            c.drawRect(
              letter,
              _fill(i.isEven ? _paper : const Color(0xffffe9c4)),
            );
            c.drawRect(letter, _line(1.4, .7));
            c.drawRect(
              Rect.fromLTWH(-6, -cell.height * .78, 12, 3.5),
              _fill(seals[rng.nextInt(seals.length)]),
            );
            c.restore();
          }
        } else if (pick < 9) {
          final box = Rect.fromLTWH(
            cell.left + cell.width * .2,
            cell.bottom - cell.height * .62,
            cell.width * .6,
            cell.height * .62,
          );
          c.drawRect(box, _fill(const Color(0xffe0a868)));
          c.drawRect(box, _line(1.4, .7));
          c.drawLine(
            box.topCenter,
            box.bottomCenter,
            Paint()
              ..color = SkyColors.coral
              ..strokeWidth = 3,
          );
        }
        c.restore();
        c.drawRRect(hole, _line(1.6, .7));
      }
    }
  }

  /// Flags strung across the ceiling.
  void _bunting(Canvas c, double w) {
    const colours = [
      SkyColors.coral,
      SkyColors.yellow,
      Color(0xff79aee2),
      SkyColors.mint,
      SkyColors.lavender,
    ];
    final string = Path()..moveTo(-10, 4);
    final spans = (w / 270).ceil();
    final span = (w + 20) / spans;
    for (var i = 0; i < spans; i++) {
      string.relativeQuadraticBezierTo(span / 2, 34, span, 0);
    }
    var n = 0;
    for (final metric in string.computeMetrics()) {
      for (var d = 16.0; d < metric.length - 10; d += 27) {
        final t = metric.getTangentForOffset(d)!;
        c.save();
        c.translate(t.position.dx, t.position.dy);
        c.rotate(math.atan2(t.vector.dy, t.vector.dx));
        final flag = Path()
          ..moveTo(-9, 0)
          ..lineTo(9, 0)
          ..lineTo(0, 19)
          ..close();
        c.drawPath(flag, _fill(colours[n++ % colours.length]));
        c.drawPath(flag, _line(1.8, .75));
        c.restore();
      }
    }
    c.drawPath(string, _line(2, .75));
  }

  /// The counter the cast stands at: its worktop, with a desk bell, an ink
  /// pad and stamp, and a tied parcel on it.
  void _counter(Canvas c, double w, double top) {
    final y = top - 18;
    final front = Rect.fromLTRB(0, y, w, 360);
    c.drawRect(
      front,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_wood, _woodDeep],
        ).createShader(front),
    );
    final worktop = Rect.fromLTRB(-4, y - 9, w + 4, y + 5);
    c.drawRect(worktop, _fill(_woodLit));
    c.drawRect(worktop, _line(2.4));
    c.drawLine(
      Offset(0, y - 5.5),
      Offset(w, y - 5.5),
      Paint()
        ..color = SkyColors.white.withValues(alpha: .45)
        ..strokeWidth = 2,
    );
    final mid = w / 2;
    // A desk bell.
    final bell = Offset(mid - 46, y - 9);
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: bell + const Offset(0, -2),
          width: 34,
          height: 5,
        ),
        const Radius.circular(2),
      ),
      _fill(_woodDeep),
    );
    final dome = Path()
      ..moveTo(bell.dx - 13, bell.dy - 4)
      ..arcToPoint(
        Offset(bell.dx + 13, bell.dy - 4),
        radius: const Radius.circular(13),
      )
      ..close();
    c.drawPath(dome, _fill(SkyColors.yellow));
    c.drawPath(dome, _line(2.2));
    c.drawCircle(bell + const Offset(0, -19), 3, _fill(SkyColors.gold));
    c.drawCircle(bell + const Offset(0, -19), 3, _line(1.8));
    c.drawArc(
      Rect.fromCircle(center: bell + const Offset(0, -4), radius: 9),
      math.pi * 1.15,
      math.pi * .3,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..color = SkyColors.white.withValues(alpha: .8),
    );
    // A parcel tied with string, a letter leaning on it.
    final box = Rect.fromLTWH(mid + 14, y - 9 - 30, 44, 30);
    c.drawRect(box, _fill(const Color(0xffe0a868)));
    c.drawRect(
      Rect.fromLTWH(box.left, box.top, box.width, 7),
      _fill(const Color(0xffefc084)),
    );
    final twine = Paint()
      ..color = SkyColors.coral
      ..strokeWidth = 3;
    c.drawLine(box.topCenter, box.bottomCenter, twine);
    c.drawLine(box.centerLeft, box.centerRight, twine);
    c.drawRect(box, _line(2.2));
    c.save();
    c.translate(box.right + 12, y - 9);
    c.rotate(.22);
    const letter = Rect.fromLTWH(-13, -19, 26, 19);
    c.drawRect(letter, _fill(_paper));
    c.drawRect(letter, _line(2));
    c.drawPath(
      Path()
        ..moveTo(-13, -19)
        ..lineTo(0, -9)
        ..lineTo(13, -19),
      _line(1.8),
    );
    c.drawCircle(const Offset(0, -9), 2.6, _fill(SkyColors.coral));
    c.restore();
  }

  @override
  bool shouldRepaint(StoryPostPainter old) => old.floor != floor;
}
