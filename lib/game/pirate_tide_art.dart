import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../domain/game_rules.dart';
import 'boss_motion.dart';

/// The Pirate Captain's tide telegraph: before every surge the line the sea
/// is about to reach is marked out across the sky, so nobody is caught out.
///
/// A pale shadow of the water-to-come fills the sky down to the sea, warning
/// signs stand on a dashed high-water line whose foam gathers as the surge
/// nears, chevrons well up toward it and a tag spells it out with a gauge
/// that fills until the water moves. It holds until the water arrives.
abstract final class PirateTideArt {
  static const _line = Color(0xff123049), _warn = Color(0xffff5a36);
  static const _amber = Color(0xffffb13d), _cream = Color(0xfffff9ed);
  static const _chevron = Color(0xffc9fff6), _aqua = Color(0xff6fe3d8);
  static const _shadow = Color(0xff0a6a90), _plate = Color(0xff123a52);
  static const _foam = Color(0xfff6fffc);

  static Paint _fill(Color color, [double alpha = 1]) =>
      Paint()
        ..color = color.withValues(alpha: (color.a * alpha).clamp(0.0, 1.0));
  static Paint _stroke(Color color, double width, [double alpha = 1]) =>
      _fill(color, alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

  /// The warning before each surge. [peak] is the y of the high-water line
  /// at a screen x, in screen heights.
  static void warning(
    Canvas c,
    Size size, {
    required SkyBoss boss,
    required bool reduced,
    required double distance,
    required double t,
    required double Function(double x) peak,
  }) {
    if (boss.phase != BossPhase.attacking) return;
    final level = boss.waterLevel;
    if (level == null) return;
    final warning = boss.tideWarning;
    final cycle = (boss.age - boss.arrivalDuration) % SkyBoss.tidePeriod;
    // Only a surge that comes: a staged captain's warm-up cycles stay calm.
    final rising =
        boss.tideRuns &&
        cycle >= SkyBoss.tideRiseAt &&
        cycle < SkyBoss.tidePeakAt + .2;
    if (warning <= 0 && !rising) return;
    final h = size.height, w = size.width;
    final show = warning > 0
        ? BossMotion.ease(BossMotion.ramp(warning, 0, .18))
        : 1 - BossMotion.ease(BossMotion.ramp(boss.tide, .55, 1));
    if (show <= 0) return;
    // The flash quickens as the surge nears; Reduced Motion holds it lit.
    final seconds = warning > 0
        ? warning * (SkyBoss.tideRiseAt - SkyBoss.tideWarnAt)
        : 1.3;
    final blink = reduced
        ? 1.0
        : .5 + .5 * math.cos(seconds * (9 + seconds * 9));
    // How close the surge is: 0 as the warning opens, 1 as the water moves.
    final near = warning > 0 ? warning : 1.0;
    final lineY = SkyBoss.tidePeak * h;
    // The ship rides the surge, so everything fades out toward its bow and
    // never veils the captain.
    final bow = (boss.x + SkyBoss.hullLeft) * h;
    final clear = bow - h * .16;
    double reach(double x) => (1 - (x - clear) / (bow - clear)).clamp(0.0, 1.0);
    Shader fading(Rect r, Color color, double alpha) => LinearGradient(
      colors: [
        color.withValues(alpha: alpha),
        color.withValues(alpha: alpha),
        color.withValues(alpha: 0),
      ],
      stops: [0, (clear / w).clamp(0.0, 1.0), (bow / w).clamp(0.0, 1.0)],
    ).createShader(Rect.fromLTRB(0, r.top, w, r.bottom));
    final surfaceY = level * h;
    if (surfaceY - lineY > 1 && bow > 1) {
      _shadowOfTheWater(
        c,
        h,
        w,
        bow,
        lineY,
        surfaceY,
        near,
        blink,
        show,
        fading,
      );
      _chevrons(c, h, w, distance, t, reduced, lineY, surfaceY, show, reach);
    }
    _highWater(
      c,
      size,
      distance,
      t,
      reduced,
      show,
      blink,
      near,
      clear,
      peak,
      reach,
      fading,
    );
    // A tag spells it out at the left edge: an arrow up to the line.
    _tag(c, size, Offset(h * .03, lineY), show, blink, near, reduced, t);
  }

  /// The water-to-come: a cool shadow that deepens as the surge nears, a
  /// bright wash under the line and a warm pulse around it.
  static void _shadowOfTheWater(
    Canvas c,
    double h,
    double w,
    double bow,
    double lineY,
    double surfaceY,
    double near,
    double blink,
    double show,
    Shader Function(Rect r, Color color, double alpha) fading,
  ) {
    const strips = 9;
    final height = surfaceY - lineY;
    for (var i = 0; i < strips; i++) {
      final u = (i + .5) / strips;
      final top = lineY + height * i / strips;
      final strip = Rect.fromLTRB(
        0,
        top,
        math.min(w, bow),
        lineY + height * (i + 1) / strips + .6,
      );
      // The true surface stays crisp: the shadow thins out just above it.
      final edge = ((surfaceY - top) / (h * .05)).clamp(0.0, 1.0);
      final a = (.2 + .24 * near) * show * (1 - u * .3) * edge;
      c.drawRect(strip, Paint()..shader = fading(strip, _shadow, a));
    }
    final deep = math.min(height, h * .09);
    for (var i = 0; i < 5; i++) {
      final strip = Rect.fromLTRB(
        0,
        lineY + deep * i / 5,
        math.min(w, bow),
        lineY + deep * (i + 1) / 5 + .6,
      );
      final a = (.34 + .14 * blink) * show * math.pow(1 - i / 5, 1.5);
      c.drawRect(strip, Paint()..shader = fading(strip, _aqua, a.toDouble()));
    }
    // A warm pulse rings the line: the danger colour against the cool sea.
    final ring = h * .03;
    for (final (from, to) in [
      (lineY - ring, lineY),
      (lineY, lineY + ring * .5),
    ]) {
      final strip = Rect.fromLTRB(0, from, math.min(w, bow), to);
      c.drawRect(
        strip,
        Paint()
          ..shader = fading(strip, _amber, (.06 + .14 * blink * near) * show),
      );
    }
  }

  /// Chevrons well up out of the sea toward the line, brick-laid so the
  /// whole band reads as moving up.
  static void _chevrons(
    Canvas c,
    double h,
    double w,
    double distance,
    double t,
    bool reduced,
    double lineY,
    double surfaceY,
    double show,
    double Function(double x) reach,
  ) {
    final gap = h * .19;
    final rise = reduced ? .5 : (t * .9) % 1;
    final columns = (w / gap).ceil() + 1;
    final scroll = (distance * h) % gap;
    for (var col = 0; col < columns; col++) {
      final x = col * gap + gap * .5 - scroll;
      final side = reach(x);
      if (side <= 0) continue;
      final stagger = col.isEven ? 0.0 : .5;
      for (var row = 0; row < 3; row++) {
        final k = ((row + rise + stagger) / 3) % 1;
        final y = surfaceY - (surfaceY - lineY) * (.15 + k * .8);
        final fade = math.sin(k * math.pi) * show * side;
        if (fade <= .02) continue;
        final arm = h * .028;
        final chevron = Path()
          ..moveTo(x - arm, y + arm * .75)
          ..lineTo(x, y)
          ..lineTo(x + arm, y + arm * .75);
        c.drawPath(chevron, _stroke(_line, h * .0135, .5 * fade));
        c.drawPath(chevron, _stroke(_chevron, h * .0068, fade));
      }
    }
  }

  /// The high-water line: the shape the surface will take, dashed and
  /// marching with the waves, with foam gathering under it and warning
  /// signs standing on it.
  static void _highWater(
    Canvas c,
    Size size,
    double distance,
    double t,
    bool reduced,
    double show,
    double blink,
    double near,
    double clear,
    double Function(double x) peak,
    double Function(double x) reach,
    Shader Function(Rect r, Color color, double alpha) fading,
  ) {
    final h = size.height, w = size.width;
    final line = Path();
    final step = math.max(4.0, w / 160);
    for (var x = -step; x <= w + step; x += step) {
      final y = peak(x / h) * h;
      x == -step ? line.moveTo(x, y) : line.lineTo(x, y);
    }
    final on = h * .034, off = h * .018;
    final marks = <Offset>[];
    final dashed = _dash(
      line,
      on,
      off,
      reduced ? 0 : (t * h * .06) % (on + off),
      marks,
    );
    final lane = Rect.fromLTRB(
      0,
      (SkyBoss.tidePeak - .03) * h,
      w,
      (SkyBoss.tidePeak + .03) * h,
    );
    Paint stroke(Color color, double width, double alpha) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..shader = fading(lane, color, alpha);
    c.drawPath(
      line.shift(Offset(0, h * .004)),
      stroke(_line, h * .006, .35 * show),
    );
    c.drawPath(dashed, stroke(_line, h * .0165, .6 * show));
    c.drawPath(dashed, stroke(_warn, h * .0115, (.35 + .4 * blink) * show));
    c.drawPath(dashed, stroke(_cream, h * .0068, (.8 + .2 * blink) * show));
    // Foam gathers under the dashes as the surge nears.
    final r = h * (.0026 + .0048 * near);
    for (final at in marks) {
      final a = reach(at.dx) * show * (.55 + .45 * near);
      if (a <= .02) continue;
      c.drawCircle(at + Offset(0, r * .9), r, _fill(_line, a * .35));
      c.drawCircle(at + Offset(0, r * .6), r, _fill(_foam, a));
    }
    // Warning signs stand on the line.
    for (final k in const [.5, .75, .98]) {
      final x = k * clear;
      final a = reach(x) * show;
      if (a <= .02) continue;
      final y = peak(x / h) * h - h * .002;
      _sign(
        c,
        h,
        Offset(x, y),
        a,
        blink,
        reduced ? 0.0 : math.sin(t * 5 + k * 9) * .06,
      );
    }
  }

  /// A rounded warning triangle with an exclamation mark, base on [base].
  static void _sign(
    Canvas c,
    double h,
    Offset base,
    double a,
    double blink,
    double tilt,
  ) {
    final s = h * (.03 + .003 * blink);
    c.save();
    c.translate(base.dx, base.dy);
    c.rotate(tilt);
    final tri = Path()
      ..moveTo(-s * .68, 0)
      ..lineTo(s * .68, 0)
      ..lineTo(0, -s * 1.15)
      ..close();
    c.drawPath(tri, _stroke(_line, s * .42, a * .8));
    c.drawPath(tri, _stroke(_warn, s * .3, a));
    c.drawPath(tri, _fill(Color.lerp(_amber, _cream, blink * .5)!, a));
    final mark = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(0, -s * .48),
        width: s * .15,
        height: s * .44,
      ),
      Radius.circular(s * .07),
    );
    c.drawRRect(mark, _fill(_line, a));
    c.drawCircle(Offset(0, -s * .14), s * .085, _fill(_line, a));
    c.restore();
  }

  /// [source] cut into dashes of length [on] with [off] between them, moving
  /// by [shift]. The dashes' midpoints go into [mids].
  static Path _dash(
    Path source,
    double on,
    double off,
    double shift,
    List<Offset> mids,
  ) {
    final dashed = Path();
    for (final metric in source.computeMetrics()) {
      var d = -shift;
      while (d < metric.length) {
        final start = math.max(0.0, d);
        final end = math.min(metric.length, d + on);
        if (end > start) {
          dashed.addPath(metric.extractPath(start, end), Offset.zero);
          if (end - start > on * .8) {
            final tangent = metric.getTangentForOffset((start + end) / 2);
            if (tangent != null) mids.add(tangent.position);
          }
        }
        d += on + off;
      }
    }
    return dashed;
  }

  static void _tag(
    Canvas c,
    Size size,
    Offset anchor,
    double show,
    double blink,
    double near,
    bool reduced,
    double t,
  ) {
    final h = size.height;
    final title = TextPainter(
      text: TextSpan(
        text: 'HIGH TIDE',
        style: TextStyle(
          fontFamily: 'Fredoka',
          fontWeight: FontWeight.w700,
          fontSize: h * .042,
          letterSpacing: h * .003,
          color: _cream.withValues(alpha: show),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final pad = h * .016, arrow = h * .03, gauge = h * .008;
    final plate = Rect.fromLTWH(
      anchor.dx,
      anchor.dy - title.height - pad * 2 - gauge - h * .022,
      arrow + pad * 3 + title.width,
      title.height + pad * 1.4 + gauge + h * .006,
    );
    final bob = reduced ? 0.0 : math.sin(t * 5) * h * .003;
    final r = RRect.fromRectAndRadius(
      plate.shift(Offset(0, bob)),
      Radius.circular(h * .018),
    );
    c.drawRRect(r.shift(Offset(0, h * .005)), _fill(_line, .45 * show));
    c.drawRRect(r, _fill(_plate, .95 * show));
    c.drawRRect(
      r,
      _stroke(Color.lerp(_chevron, _warn, .5 * blink)!, h * .004, show),
    );
    // A pointer from the plate down onto the line.
    final tip = Offset(r.left + pad + arrow / 2, anchor.dy - h * .002);
    final pointer = Path()
      ..moveTo(tip.dx - h * .012, r.bottom - 1)
      ..lineTo(tip.dx, tip.dy)
      ..lineTo(tip.dx + h * .012, r.bottom - 1)
      ..close();
    c.drawPath(pointer, _fill(_plate, .95 * show));
    // An up arrow: fly above.
    final a = Offset(
      r.left + pad + arrow / 2,
      r.top + pad * .7 + title.height / 2,
    );
    final up = Path()
      ..moveTo(a.dx, a.dy - arrow * .5)
      ..lineTo(a.dx + arrow * .45, a.dy)
      ..lineTo(a.dx + arrow * .16, a.dy)
      ..lineTo(a.dx + arrow * .16, a.dy + arrow * .45)
      ..lineTo(a.dx - arrow * .16, a.dy + arrow * .45)
      ..lineTo(a.dx - arrow * .16, a.dy)
      ..lineTo(a.dx - arrow * .45, a.dy)
      ..close();
    c.drawPath(up, _fill(Color.lerp(_warn, _amber, blink)!, show));
    title.paint(c, Offset(r.left + pad * 2 + arrow, r.top + pad * .7));
    // The gauge fills as the surge nears: a wave-crested bar that spills
    // over the moment the water moves.
    final track = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        r.left + pad,
        r.bottom - pad * .75 - gauge,
        r.width - pad * 2,
        gauge,
      ),
      Radius.circular(gauge / 2),
    );
    c.drawRRect(track, _fill(_line, .8 * show));
    final fill = RRect.fromRectAndRadius(
      Rect.fromLTWH(track.left, track.top, track.width * near, gauge),
      Radius.circular(gauge / 2),
    );
    if (near > .02) {
      c.drawRRect(fill, _fill(Color.lerp(_aqua, _warn, near * near)!, show));
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            fill.left + gauge * .3,
            fill.top + gauge * .18,
            math.max(0, fill.width - gauge * .6),
            gauge * .3,
          ),
          Radius.circular(gauge * .15),
        ),
        _fill(_foam, .55 * show),
      );
    }
  }
}
