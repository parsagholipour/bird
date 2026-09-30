import 'dart:math' as math;
import 'package:flutter/painting.dart';
import '../domain/game_rules.dart';
import '../ui/theme.dart';
import 'boss_motion.dart';
import 'pirate_hud_art.dart';
import 'sky_scenery.dart';

/// The Pirate Captain's cinematic set-pieces: the arrival warning, the
/// parchment name card, the "ARRR!" shout, the roar, the fury and hit
/// flourishes, the treasure burst and the victory coin shower.
///
/// [BossEncounterArt] owns the staging and timing; these are only the
/// pirate's brushstrokes. Everything derives from the boss clock and the
/// death clock, so paused, replayed and captured frames repeat exactly, and
/// under Reduced Motion each piece holds still and only fades.
abstract final class PirateEncounterUi {
  static const ink = PirateHudArt.ink, gold = PirateHudArt.gold;
  static const goldDeep = PirateHudArt.goldDeep;
  static const goldLight = PirateHudArt.goldLight;
  static const crimson = Color(0xffc53b4d), crimsonDeep = Color(0xff7c2238);
  static const crimsonLit = Color(0xffe8636b), bone = PirateHudArt.bone;
  static const foam = PirateHudArt.foam, sea = Color(0xff4fd1c5);
  static const seaDeep = Color(0xff22919b), flame = Color(0xffffa23a);
  static const flameCore = Color(0xfffff1b8), ember = Color(0xffff5a3a);
  static const _deep = Color(0xff10233b), _parchment = Color(0xfff2dda8);
  static const _paper = Color(0xffe9cf92), _paperDeep = Color(0xffc79a58);
  static const _burn = Color(0xff8a5a2c), _quill = Color(0xff33200f);
  static const _rope = PirateHudArt.rope, _ropeDeep = PirateHudArt.ropeDeep;

  static Paint _fill(Color color, [double opacity = 1]) =>
      Paint()
        ..color = color.withValues(alpha: (color.a * opacity).clamp(0.0, 1.0));

  static Paint _line(Color color, double width, [double opacity = 1]) =>
      _fill(color, opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

  static double _hash(int i, int salt) {
    final v = math.sin(i * 127.1 + salt * 311.7) * 43758.5453;
    return v - v.floorToDouble();
  }

  static double _outCubic(double t) {
    final u = 1 - t.clamp(0.0, 1.0);
    return 1 - u * u * u;
  }

  static double _outBack(double t) {
    final u = t.clamp(0.0, 1.0) - 1;
    return 1 + u * u * (2.7 * u + 1.7);
  }

  /// Fredoka lettering with an optional gradient face, ink outline and a
  /// hard drop shadow. [at] is the top-left, or the middle when [centered]
  /// and [middle] are set.
  static Size _text(
    Canvas c,
    String value,
    Offset at,
    double size, {
    Color color = PirateHudArt.cream,
    List<Color>? ramp,
    bool centered = false,
    bool middle = false,
    double opacity = 1,
    double spacing = 0,
    double outline = 0,
    Color outlineColor = ink,
    double shadow = 0,
  }) {
    if (opacity <= 0) return Size.zero;
    TextPainter make(TextStyle style) => TextPainter(
      text: TextSpan(text: value, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    final base = heading(size).copyWith(letterSpacing: spacing);
    final probe = make(base);
    final origin =
        at -
        Offset(centered ? probe.width / 2 : 0, middle ? probe.height / 2 : 0);
    if (shadow > 0) {
      make(
        base.copyWith(color: outlineColor.withValues(alpha: opacity * .55)),
      ).paint(c, origin + Offset(0, shadow));
    }
    if (outline > 0) {
      make(
        base.copyWith(
          foreground: _line(outlineColor, outline, opacity)
            ..strokeJoin = StrokeJoin.round,
        ),
      ).paint(c, origin);
    }
    if (ramp == null) {
      make(
        base.copyWith(color: color.withValues(alpha: color.a * opacity)),
      ).paint(c, origin);
    } else {
      make(
        base.copyWith(
          foreground: Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                for (final k in ramp) k.withValues(alpha: k.a * opacity),
              ],
            ).createShader(origin & probe.size),
        ),
      ).paint(c, origin);
    }
    return probe.size;
  }

  // ---------------------------------------------------------------- bits --

  /// A doubloon, [flip] turning it edge-on (0) to face-on (1).
  static void coin(
    Canvas c,
    Offset at,
    double r, {
    double flip = 1,
    double alpha = 1,
    Color face = gold,
    Color rim = goldDeep,
  }) {
    final w = r * (.3 + .7 * flip.clamp(0.0, 1.0));
    final oval = Rect.fromCenter(center: at, width: w * 2, height: r * 2);
    c.drawOval(oval.inflate(r * .18), _fill(ink, alpha));
    c.drawOval(oval, _fill(rim, alpha));
    c.drawOval(
      Rect.fromCenter(
        center: at + Offset(-w * .07, -r * .08),
        width: w * 1.84,
        height: r * 1.8,
      ),
      _fill(face, alpha),
    );
    if (flip > .5) {
      c.drawOval(
        Rect.fromCenter(center: at, width: w * 1.15, height: r * 1.15),
        _line(rim, r * .15, alpha * .9),
      );
      c.drawCircle(
        at + Offset(-w * .42, -r * .44),
        r * .14,
        _fill(Color.lerp(face, const Color(0xffffffff), .7)!, alpha),
      );
    }
  }

  /// Four-point treasure glint.
  static void glint(Canvas c, Offset at, double r, double alpha) {
    if (r <= 0 || alpha <= 0) return;
    final path = Path()
      ..moveTo(at.dx, at.dy - r)
      ..quadraticBezierTo(at.dx + r * .14, at.dy - r * .14, at.dx + r, at.dy)
      ..quadraticBezierTo(at.dx + r * .14, at.dy + r * .14, at.dx, at.dy + r)
      ..quadraticBezierTo(at.dx - r * .14, at.dy + r * .14, at.dx - r, at.dy)
      ..quadraticBezierTo(at.dx - r * .14, at.dy - r * .14, at.dx, at.dy - r)
      ..close();
    c.drawPath(path, _line(goldDeep, r * .3, alpha));
    c.drawPath(path, _fill(goldLight, alpha));
    c.drawCircle(at, r * .2, _fill(const Color(0xffffffff), alpha));
  }

  /// A wavy ring: sea foam rolling round the boss.
  static Path _ring(
    Offset center,
    double rx,
    double ry,
    double amp,
    int lobes,
    double phase,
  ) {
    final p = Path();
    const steps = 120;
    for (var i = 0; i <= steps; i++) {
      final a = i / steps * 2 * math.pi;
      final k = 1 + amp * math.sin(a * lobes + phase);
      final pt = center + Offset(math.cos(a) * rx * k, math.sin(a) * ry * k);
      i == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
    }
    return p..close();
  }

  static void _ribbon(
    Canvas c,
    Offset center,
    double width,
    double height,
    double opacity,
  ) {
    final left = center.dx - width / 2, right = center.dx + width / 2;
    final top = center.dy - height / 2, bottom = center.dy + height / 2;
    final fold = height * .3, drop = height * .26, reach = height * .95;
    final edge = _line(ink, height * .09, opacity);
    for (final side in [-1.0, 1.0]) {
      final x = side < 0 ? left : right;
      final inner = x - side * fold;
      final tip = x + side * reach;
      final tail = Path()
        ..moveTo(inner, top + drop)
        ..lineTo(tip, top + drop)
        ..lineTo(tip - side * height * .38, center.dy + drop)
        ..lineTo(tip, bottom + drop)
        ..lineTo(inner, bottom + drop)
        ..close();
      c.drawPath(tail, edge);
      c.drawPath(tail, _fill(crimsonDeep, opacity));
      final flap = Path()
        ..moveTo(x, bottom)
        ..lineTo(inner, bottom)
        ..lineTo(inner, bottom + drop)
        ..close();
      c.drawPath(flap, edge);
      c.drawPath(flap, _fill(const Color(0xff4d1224), opacity));
    }
    final body = RRect.fromRectAndRadius(
      Rect.fromLTRB(left, top, right, bottom),
      Radius.circular(height * .1),
    );
    c.drawRRect(body.inflate(height * .045), _fill(ink, opacity));
    c.drawRRect(body, _fill(crimson, opacity));
    c.drawRect(
      Rect.fromLTRB(left, top, right, top + height * .42),
      _fill(crimsonLit, opacity * .5),
    );
    for (final y in [top + height * .13, bottom - height * .13]) {
      c.drawLine(
        Offset(left + height * .14, y),
        Offset(right - height * .14, y),
        _line(goldDeep, height * .035, opacity * .9),
      );
    }
  }

  static void _bell(Canvas c, Offset pivot, double s, double swing, double a) {
    c.save();
    c.translate(pivot.dx, pivot.dy);
    c.rotate(swing);
    c.scale(s);
    c.translate(0, .52);
    final bell = Path()
      ..moveTo(-.15, -.4)
      ..cubicTo(-.42, -.34, -.34, .16, -.52, .34)
      ..quadraticBezierTo(-.6, .44, -.46, .44)
      ..lineTo(.46, .44)
      ..quadraticBezierTo(.6, .44, .52, .34)
      ..cubicTo(.34, .16, .42, -.34, .15, -.4)
      ..close();
    // Bail and bracket.
    c.drawLine(const Offset(0, -.42), const Offset(0, -.6), _line(ink, .2, a));
    c.drawLine(
      const Offset(0, -.42),
      const Offset(0, -.6),
      _line(goldDeep, .09, a),
    );
    c.drawPath(bell, _line(ink, .16, a));
    c.drawPath(bell, _fill(gold, a));
    c.save();
    c.clipPath(bell);
    c.drawRect(const Rect.fromLTRB(.1, -.5, .7, .6), _fill(goldDeep, a * .85));
    c.drawRect(const Rect.fromLTRB(-.7, .3, .7, .5), _fill(goldDeep, a * .9));
    c.restore();
    c.drawPath(
      Path()
        ..moveTo(-.2, -.3)
        ..cubicTo(-.32, -.2, -.27, .06, -.38, .2),
      _line(goldLight, .07, a),
    );
    c.drawCircle(const Offset(0, .56), .11, _fill(ink, a));
    c.drawCircle(const Offset(0, .56), .075, _fill(goldDeep, a));
    c.restore();
  }

  // ------------------------------------------------------------- warning --

  /// "SAIL HO!": a swell of dark water rolls across the sky with a bell
  /// swinging either side of the call.
  static void warning(
    Canvas c,
    Size size,
    SkyBoss boss,
    BossMotion m,
    double fade,
  ) {
    if (fade <= 0) return;
    final h = size.height, w = size.width;
    final t = m.reducedMotion ? 0.0 : boss.age;
    final top = h * .262, bottom = h * .432;
    final amp = h * .006, length = h * .24;
    double edge(double x, double base, double dir) =>
        base + amp * math.sin(x / length * 2 * math.pi + t * 1.6 * dir);
    final step = h * .03;
    final band = Path()..moveTo(0, edge(0, top, 1));
    final topLine = Path()..moveTo(0, edge(0, top, 1));
    final lowLine = Path()..moveTo(0, edge(0, bottom, -1));
    for (var x = step; x < w + step; x += step) {
      band.lineTo(x, edge(x, top, 1));
      topLine.lineTo(x, edge(x, top, 1));
      lowLine.lineTo(x, edge(x, bottom, -1));
    }
    for (var x = w; x > -step; x -= step) {
      band.lineTo(x, edge(x, bottom, -1));
    }
    band.close();
    final rect = Rect.fromLTRB(0, top - amp, w, bottom + amp);
    Paint faded(Color color, double alpha) => Paint()
      ..shader = LinearGradient(
        colors: [
          color.withValues(alpha: 0),
          color.withValues(alpha: alpha * fade),
          color.withValues(alpha: alpha * fade),
          color.withValues(alpha: 0),
        ],
        stops: const [.05, .3, .7, .95],
      ).createShader(rect);
    c.drawPath(band, faded(_deep, .64));
    for (final (path, alpha) in [(topLine, .8), (lowLine, .55)]) {
      c.drawPath(
        path,
        faded(foam, alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = h * .0042
          ..strokeCap = StrokeCap.round,
      );
    }
    c.drawPath(
      topLine.shift(Offset(0, h * .012)),
      faded(sea, .5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * .0022,
    );

    final titleTop = h * .285, titleSize = h * .054;
    final title = _text(
      c,
      'SAIL HO!',
      Offset(w * .5, titleTop),
      titleSize,
      ramp: const [Color(0xfffff6cc), gold, Color(0xffe0a233)],
      opacity: fade,
      centered: true,
      spacing: 3,
      outline: h * .009,
      shadow: h * .007,
    );
    final mid = titleTop + title.height * .52;
    for (final side in [-1.0, 1.0]) {
      final x = w * .5 + side * (title.width / 2 + h * .092);
      final swing = m.reducedMotion
          ? 0.0
          : math.sin(boss.age * 4.4 + (side > 0 ? 0 : math.pi)) * .34;
      _bell(c, Offset(x, mid - h * .046), h * .08, swing, fade);
      if (swing.abs() > .16) {
        // Ding: two little strokes fly off the lip on the swing.
        final out = swing.sign;
        for (var i = 0; i < 2; i++) {
          final r = h * (.05 + i * .014);
          c.drawArc(
            Rect.fromCircle(center: Offset(x, mid + h * .012), radius: r),
            out > 0 ? -.3 : math.pi - .9,
            .6,
            false,
            _line(
              gold,
              h * .0032,
              fade * (swing.abs() - .16) * 4 * (1 - i * .35),
            ),
          );
        }
      }
      // A gold swell runs out from each bell.
      final wave = Path()..moveTo(x + side * h * .08, mid);
      for (var i = 1; i <= 16; i++) {
        final d = i * h * .01;
        wave.lineTo(
          x + side * (h * .08 + d),
          mid + math.sin(d / h * 46 - t * 3 * side) * h * .006,
        );
      }
      c.drawPath(wave, _line(gold, h * .0035, fade * .75));
      c.drawCircle(
        Offset(x + side * h * .246, mid),
        h * .005,
        _fill(gold, fade * .75),
      );
    }
    _text(
      c,
      'A ship rides in on the rising tide…',
      Offset(w * .5, h * .372),
      h * .03,
      color: PirateHudArt.cream,
      opacity: fade,
      centered: true,
      outline: h * .006,
    );
  }

  // ----------------------------------------------------------- name card --

  /// A weathered parchment scroll unrolls with the boss's name and a bold
  /// crimson ribbon carrying the title. A campaign boss's [line] is inked on
  /// the scroll under the ribbon, which then grows to hold it.
  static void nameCard(
    Canvas c,
    Size size,
    SkyBoss boss,
    BossMotion m, {
    required double birdY,
    String? line,
  }) {
    final h = size.height, w = size.width;
    final progress = BossMotion.ease(BossMotion.ramp(boss.age, 1.65, 2.25));
    final out = 1 - BossMotion.ramp(boss.age, 3.9, 4.5);
    final opacity =
        (m.reducedMotion ? progress : math.min(1.0, progress * 2.4)) * out;
    if (opacity <= 0) return;
    // A soft shade behind the scroll keeps it settled into any sky.
    final shade = Rect.fromLTRB(
      0,
      h * .1,
      w * .1 + h * .95,
      h * (line == null ? .4 : .48),
    );
    c.drawRect(
      shade,
      Paint()
        ..shader = LinearGradient(
          colors: [
            _deep.withValues(alpha: .5 * opacity),
            _deep.withValues(alpha: .34 * opacity),
            _deep.withValues(alpha: 0),
          ],
          stops: const [0, .55, 1],
        ).createShader(shade)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, h * .03),
    );

    final nameSize = h * .07;
    final nameProbe = TextPainter(
      text: TextSpan(
        text: boss.name.toUpperCase(),
        style: heading(nameSize).copyWith(letterSpacing: .4),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final titleSize = h * .029;
    final titleProbe = TextPainter(
      text: TextSpan(
        text: boss.title,
        style: heading(titleSize).copyWith(letterSpacing: 1.6),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final lineSize = h * .035;
    final lineProbe = line == null
        ? null
        : (TextPainter(
            text: TextSpan(text: line, style: heading(lineSize)),
            textDirection: TextDirection.ltr,
          )..layout());
    final paperW = math.max(
      math.max(nameProbe.width + h * .17, titleProbe.width + h * .16),
      lineProbe == null ? 0.0 : lineProbe.width + h * .12,
    );
    // The name and ribbon keep their places; a line adds a strip below.
    final bodyH = h * .235;
    final paperH = bodyH + (line == null ? 0 : h * .09);
    final roll = h * .038;
    final open = m.reducedMotion ? 1.0 : progress;
    final left = w * .1;
    final top = h * .124 + (m.reducedMotion ? 0 : (1 - progress) * h * .02);
    final cur = paperW * open;
    final x0 = left + roll / 2, x1 = x0 + cur;
    final rect = Rect.fromLTRB(x0, top, x1, top + paperH);
    final bounds = Rect.fromLTRB(
      left - h * .02,
      top - h * .04,
      x0 + paperW + roll + h * .12,
      top + paperH + h * .1,
    );
    // Parchment is opaque, so it turns see-through where the bird's lane (a
    // fixed column) runs behind it. A line's strip hangs clear of the lane
    // the cutscene holds the bird in, so only the body counts.
    final bird = Offset(FlightSimulation.birdX * h, birdY * h);
    final card = Rect.fromLTRB(
      left,
      top - h * .02,
      x1 + roll / 2,
      top + bodyH + h * .03,
    );
    final gap = Offset(
      math.max(math.max(card.left - bird.dx, bird.dx - card.right), 0.0),
      math.max(math.max(card.top - bird.dy, bird.dy - card.bottom), 0.0),
    ).distance;
    final clear = math.max(0.0, gap - FlightSimulation.birdRadius * h);
    final shown =
        opacity * (.38 + .62 * BossMotion.ramp(clear, h * .005, h * .05));
    final layered = shown < 1;
    if (layered) {
      c.saveLayer(
        bounds,
        Paint()..color = const Color(0xffffffff).withValues(alpha: shown),
      );
    }
    // The torn paper: ragged top and bottom edges, deterministic per notch.
    final tear = h * .0045;
    final paper = Path()..moveTo(x0, top);
    final notches = math.max(2, (paperW / (h * .03)).round());
    double ragged(int i, int salt) => (_hash(i, salt) - .5) * 2 * tear;
    for (var i = 1; i <= notches; i++) {
      paper.lineTo(x0 + paperW * i / notches, top + ragged(i, 1));
    }
    for (var i = notches; i >= 0; i--) {
      paper.lineTo(x0 + paperW * i / notches, top + paperH + ragged(i, 2));
    }
    paper.close();

    c.save();
    c.clipRect(
      Rect.fromLTRB(
        rect.left,
        top - h * .03,
        rect.right,
        rect.bottom + h * .09,
      ),
    );
    c.save();
    c.translate(0, h * .009);
    c.drawPath(paper, _fill(ink, .32));
    c.restore();
    c.drawPath(paper, _fill(_paper));
    c.save();
    c.clipPath(paper);
    c.drawRect(
      Rect.fromLTRB(x0, top, x0 + paperW, top + paperH * .45),
      _fill(_parchment, .75),
    );
    // Age: stains, folds and burnt edges.
    for (final (fx, fy, fr, fa) in const [
      (.22, .72, .11, .13),
      (.74, .3, .09, .11),
      (.56, .82, .07, .1),
      (.9, .68, .1, .12),
    ]) {
      c.drawOval(
        Rect.fromCenter(
          center: Offset(x0 + paperW * fx, top + paperH * fy),
          width: h * fr * 2.1,
          height: h * fr * 1.4,
        ),
        _fill(_paperDeep, fa),
      );
    }
    for (final f in const [.34, .68]) {
      final x = x0 + paperW * f;
      c.drawLine(
        Offset(x, top),
        Offset(x, top + paperH),
        _line(_burn, h * .0022, .13),
      );
      c.drawLine(
        Offset(x + h * .003, top),
        Offset(x + h * .003, top + paperH),
        _line(const Color(0xffffffff), h * .002, .13),
      );
    }
    // A faint skull-and-crossbones stamp behind the name.
    PirateHudArt.mark(
      c,
      Offset(x0 + paperW * .5, top + bodyH * .5),
      bodyH * .34,
      fill: _burn,
      edge: _burn,
      alpha: .1,
    );
    c.drawPath(paper, _line(_burn, h * .022, .3));
    c.drawPath(paper, _line(_burn, h * .009, .28));
    c.restore();
    c.drawPath(paper, _line(ink, h * .0062));

    final cx = x0 + paperW / 2;
    // "ENCOUNTER 04" between two little gems.
    final tagY = top + h * .034;
    final tag = _text(
      c,
      'ENCOUNTER ${boss.number.toString().padLeft(2, '0')}',
      Offset(cx, tagY),
      h * .026,
      color: crimsonDeep,
      centered: true,
      middle: true,
      spacing: 3,
    );
    for (final side in [-1.0, 1.0]) {
      final x = cx + side * (tag.width / 2 + h * .028);
      final d = h * .0085;
      c.drawPath(
        Path()
          ..moveTo(x, tagY - d)
          ..lineTo(x + d, tagY)
          ..lineTo(x, tagY + d)
          ..lineTo(x - d, tagY)
          ..close(),
        _fill(crimson),
      );
      c.drawLine(
        Offset(x + side * d * 1.8, tagY),
        Offset(x + side * h * .1, tagY),
        _line(_burn, h * .0028, .7),
      );
    }
    _text(
      c,
      boss.name.toUpperCase(),
      Offset(cx, top + h * .1),
      nameSize,
      color: _quill,
      centered: true,
      middle: true,
      spacing: .4,
      shadow: h * .0035,
      outlineColor: const Color(0xffffffff),
    );
    _ribbon(
      c,
      Offset(cx, top + bodyH - h * .008),
      titleProbe.width + h * .09,
      h * .056,
      1,
    );
    _text(
      c,
      boss.title,
      Offset(cx, top + bodyH - h * .008),
      titleSize,
      ramp: const [Color(0xfffff6cc), gold, Color(0xffe0a233)],
      centered: true,
      middle: true,
      spacing: 1.6,
      outline: h * .006,
    );
    if (line != null) {
      // Written in the captain's own quill under the ribbon.
      _text(
        c,
        line,
        Offset(cx, top + bodyH + h * .056),
        lineSize,
        color: _quill,
        centered: true,
        middle: true,
        shadow: h * .003,
        outlineColor: const Color(0xffffffff),
      );
    }
    c.restore();

    // Both rolls: the fixed one, and the one carrying the paper open.
    for (final x in [x0, x1]) {
      _roll(c, Offset(x, top + paperH / 2), roll, paperH + h * .03, h);
    }
    if (layered) c.restore();
  }

  static void _roll(
    Canvas c,
    Offset center,
    double width,
    double height,
    double h,
  ) {
    final body = Rect.fromCenter(center: center, width: width, height: height);
    final cap = width * .5;
    final r = RRect.fromRectAndRadius(body, Radius.circular(width * .28));
    c.drawRRect(r.inflate(h * .0055), _fill(ink));
    c.drawRRect(r, _fill(_paperDeep));
    c.save();
    c.clipRRect(r);
    c.drawRect(
      Rect.fromLTWH(body.left + width * .1, body.top, width * .34, height),
      _fill(_parchment),
    );
    c.drawRect(
      Rect.fromLTWH(body.right - width * .3, body.top, width * .3, height),
      _fill(_burn, .55),
    );
    c.restore();
    // Rope bands lash the roll.
    for (final f in const [.16, .84]) {
      final y = body.top + height * f;
      c.drawLine(
        Offset(body.left - h * .002, y),
        Offset(body.right + h * .002, y),
        _line(ink, h * .012),
      );
      c.drawLine(
        Offset(body.left - h * .002, y),
        Offset(body.right + h * .002, y),
        _line(_rope, h * .0075),
      );
    }
    for (final y in [body.top, body.bottom]) {
      final end = Rect.fromCenter(
        center: Offset(center.dx, y),
        width: width * 1.02,
        height: cap * .8,
      );
      c.drawOval(end.inflate(h * .0035), _fill(ink));
      c.drawOval(end, _fill(_parchment));
      c.drawOval(end.deflate(width * .2), _line(_burn, h * .0028, .8));
      c.drawOval(end.deflate(width * .36), _line(_burn, h * .0025, .7));
    }
  }

  // -------------------------------------------------------------- shout --

  static final Path _bubble = () {
    final blob = Path();
    const spikes = 11;
    for (var i = 0; i < spikes * 2; i++) {
      final a = i * math.pi / spikes - math.pi / 2 + .12;
      final r = i.isEven ? 1.0 + .13 * math.sin(i * 2.3 + 1) : .8;
      final p = Offset(math.cos(a) * r * 1.1, math.sin(a) * r * .72);
      i == 0 ? blob.moveTo(p.dx, p.dy) : blob.lineTo(p.dx, p.dy);
    }
    blob.close();
    final tail = Path()
      ..moveTo(-.02, .4)
      ..quadraticBezierTo(.45, .78, 1.16, 1.24)
      ..quadraticBezierTo(.78, .7, .58, .38)
      ..close();
    return Path.combine(PathOperation.union, blob, tail);
  }();

  /// "ARRR!" bursts out of the captain in a spiky speech bubble, the letters
  /// swelling with the roar.
  static void shout(Canvas c, Offset center, double h, BossMotion m) {
    final pop = m.reducedMotion
        ? 1.0
        : _outBack(BossMotion.ramp(m.boss.age - SkyBoss.roarAt, 0, .22));
    final fade = BossMotion.ramp(m.roar, 0, .25);
    if (pop <= 0 || fade <= 0) return;
    final unit = h * SkyBoss.radius;
    final shake = m.reducedMotion
        ? Offset.zero
        : Offset(
            math.sin(m.boss.age * 47) * unit * .022,
            math.cos(m.boss.age * 39) * unit * .016,
          );
    final at = center + Offset(-unit * 1.9, -unit * 1.55) + shake;
    c.save();
    c.translate(at.dx, at.dy);
    c.scale(unit * pop);
    c.rotate(-.12);
    c.save();
    c.translate(.05, .09);
    c.drawPath(_bubble, _fill(ink, fade * .3));
    c.restore();
    c.drawPath(_bubble, _line(ink, .13, fade));
    c.drawPath(_bubble, _fill(PirateHudArt.bone, fade));
    c.save();
    c.clipPath(_bubble);
    c.drawRect(
      const Rect.fromLTRB(-1.4, .12, 1.6, 1.4),
      _fill(_parchment, fade),
    );
    c.restore();
    // An inner line and a shine give the bubble some body.
    c.save();
    c.scale(.86);
    c.translate(-.03, -.03);
    c.drawPath(_bubble, _line(goldDeep, .035, fade * .7));
    c.restore();
    c.drawPath(
      Path()
        ..moveTo(-.86, -.1)
        ..quadraticBezierTo(-.74, -.42, -.42, -.5),
      _line(const Color(0xffffffff), .06, fade * .9),
    );
    // Emphasis strokes flung off the shout.
    for (var i = 0; i < 3; i++) {
      final a = -2.75 + i * .38;
      c.drawLine(
        Offset(math.cos(a), math.sin(a) * .72) * 1.32,
        Offset(math.cos(a), math.sin(a) * .72) * 1.58,
        _line(ink, .085, fade),
      );
    }
    c.restore();
    // The letters grow as the roar builds.
    const letters = ['A', 'R', 'R', 'R', '!'];
    const grow = [.82, .94, 1.05, 1.17, 1.3];
    const tilt = [-.16, -.08, .0, .09, .17];
    const lift = [.06, .03, -.01, -.04, -.07];
    final base = unit * .6 * pop;
    final painters = [
      for (var i = 0; i < letters.length; i++)
        TextPainter(
          text: TextSpan(
            text: letters[i],
            style: heading(base * grow[i]).copyWith(height: 1),
          ),
          textDirection: TextDirection.ltr,
        )..layout(),
    ];
    var total = 0.0;
    for (final p in painters) {
      total += p.width;
    }
    total -= base * .06 * (letters.length - 1);
    var x = -total / 2;
    for (var i = 0; i < letters.length; i++) {
      final p = painters[i];
      c.save();
      c.translate(
        at.dx +
            (x + p.width / 2) * math.cos(-.12) -
            lift[i] * unit * math.sin(-.12),
        at.dy +
            (x + p.width / 2) * math.sin(-.12) +
            lift[i] * unit * math.cos(-.12),
      );
      c.rotate(-.12 + tilt[i]);
      _text(
        c,
        letters[i],
        Offset.zero,
        base * grow[i],
        ramp: const [Color(0xffff7180), crimson, Color(0xff9c2337)],
        centered: true,
        middle: true,
        opacity: fade,
        outline: unit * .1 * pop,
        shadow: unit * .045 * pop,
      );
      c.restore();
      x += p.width - base * .06;
    }
  }

  // --------------------------------------------------------------- roar --

  /// A ring of rolling sea-water: a dark underline, a foam line and beads of
  /// spray riding along it.
  static void _swell(
    Canvas c,
    Offset center,
    double rx,
    double ry,
    double width,
    double fade, {
    required Color color,
    required int lobes,
    required double phase,
    int beads = 14,
  }) {
    final ring = _ring(center, rx, ry, .014, lobes, phase);
    c.drawPath(ring, _line(_deep, width * 2, fade * .3));
    c.drawPath(ring, _line(color, width, fade * .92));
    for (var j = 0; j < beads; j++) {
      final a = (j + _hash(j, lobes) * .6) / beads * 2 * math.pi + phase;
      final lift = 1 + .045 * (_hash(j, 9) - .3);
      final p =
          center + Offset(math.cos(a) * rx * lift, math.sin(a) * ry * lift);
      final r = width * (.55 + .5 * _hash(j, 5));
      c.drawCircle(p, r * 1.25, _fill(_deep, fade * .35));
      c.drawCircle(p, r, _fill(foam, fade));
    }
  }

  /// The roar: rings of sea-spray roll off the captain like a ship's horn
  /// blast, with spray streaks flung off in every direction.
  static void roar(Canvas c, Offset center, double h, BossMotion m) {
    final boss = m.boss;
    if (m.reducedMotion) {
      _swell(
        c,
        center,
        h * .31,
        h * .23,
        h * .0065,
        m.roar * .8,
        color: foam,
        lobes: 6,
        phase: 0,
      );
      return;
    }
    final k = boss.age - SkyBoss.roarAt;
    for (var i = 0; i < 3; i++) {
      final u = BossMotion.ramp(k, i * .13, .5 + i * .13);
      if (u <= 0 || u >= 1) continue;
      final e = _outCubic(u);
      _swell(
        c,
        center,
        h * (.16 + e * .25),
        h * (.12 + e * .19),
        h * .0095 * (1 - u * .55),
        1 - u,
        color: i.isEven ? foam : sea,
        lobes: 5 + i,
        phase: i * 1.7 + u * 1.5,
        beads: 12 + i * 2,
      );
    }
    for (var i = 0; i < 14; i++) {
      final a = i * math.pi / 7 + .2;
      final d = Offset(math.cos(a) * 1.25, math.sin(a));
      final from = h * (.25 + (i % 3) * .02 + m.roar * .05);
      final to = from + h * (.045 + (i % 2) * .035) * m.roar;
      final p0 = center + d * from, p1 = center + d * to;
      c.drawLine(p0, p1, _line(_deep, h * .0085, m.roar * .3));
      c.drawLine(p0, p1, _line(foam, h * .0055, m.roar * .9));
      c.drawCircle(p1 + d * (h * .008), h * .0055 * m.roar, _fill(sea, m.roar));
    }
  }

  /// Two quick rings of spray as the ship goes up in a burst.
  static void shockwave(Canvas c, Offset at, double h, double k) {
    for (var i = 0; i < 2; i++) {
      final u = BossMotion.ramp(k, i * .07, .42 + i * .12);
      if (u <= 0 || u >= 1) continue;
      final r = h * (.1 + _outCubic(u) * (.5 - i * .1));
      final fade = (1 - u) * (1 - u);
      _swell(
        c,
        at,
        r,
        r,
        h * (.0125 - i * .004) * (1 - u * .6),
        fade,
        color: i == 0 ? foam : gold,
        lobes: 7,
        phase: i * 2.0,
        beads: i == 0 ? 20 : 0,
      );
    }
  }

  // ---------------------------------------------------- rage and impact --

  /// Fury: a heat haze and a ring of flame swell round the captain.
  static void rage(Canvas c, Offset center, double h, BossMotion m) {
    final rage = m.rage;
    if (rage <= 0) return;
    // Reduced Motion holds the ring at one size; it only fades in and out.
    final swell = m.reducedMotion ? .55 : rage;
    final width = h * (.34 + swell * .26), height = h * (.25 + swell * .15);
    final glow = Rect.fromCenter(
      center: center,
      width: width * 1.5,
      height: height * 1.5,
    );
    c.drawOval(
      glow,
      Paint()
        ..shader = RadialGradient(
          colors: [
            ember.withValues(alpha: 0),
            ember.withValues(alpha: .3 * rage),
            ember.withValues(alpha: 0),
          ],
          stops: const [.5, .72, 1],
        ).createShader(glow),
    );
    final rect = Rect.fromCenter(center: center, width: width, height: height);
    c.drawOval(rect, _line(ink, h * .012, rage * .3));
    c.drawOval(rect, _line(ember, h * .006, rage * .85));
    c.drawOval(rect.deflate(h * .006), _line(flameCore, h * .0022, rage * .6));
    const tongues = 10;
    for (var i = 0; i < tongues; i++) {
      final a = i * 2 * math.pi / tongues + .3;
      final wobble = m.reducedMotion
          ? 0.0
          : math.sin(m.boss.age * 14 + i * 1.9) * .1;
      final p =
          center + Offset(math.cos(a) * width / 2, math.sin(a) * height / 2);
      final out = math.atan2(math.sin(a) / height, math.cos(a) / width);
      final s = h * (i.isEven ? .05 : .036) * (m.reducedMotion ? .8 : rage);
      c.save();
      c.translate(p.dx, p.dy);
      c.rotate(out + .5 + wobble);
      c.scale(s);
      final lick = Path()
        ..moveTo(-.1, -.4)
        ..quadraticBezierTo(.55, -.5, 1.2, -.3)
        ..quadraticBezierTo(.75, -.05, .75, .1)
        ..quadraticBezierTo(.5, .45, -.1, .4)
        ..close();
      c.drawPath(lick, _line(ink, .2, rage * .85));
      c.drawPath(lick, _fill(i.isEven ? ember : flame, rage));
      c.save();
      c.scale(.55, .5);
      c.translate(.15, 0);
      c.drawPath(lick, _fill(flameCore, rage));
      c.restore();
      c.restore();
    }
  }

  /// A hit on the captain: a gold starburst and a few doubloons knocked out
  /// of his coat.
  static void hit(Canvas c, Offset at, double h, double t, bool reduced) {
    if (t >= 1) return;
    final grow = reduced ? .8 : .45 + .55 * _outCubic(t / .5);
    final fade = 1 - t * t;
    final r = h * .062 * grow;
    final star = Path();
    for (var i = 0; i < 16; i++) {
      final a = i * math.pi / 8 + .2;
      final k = i.isEven ? 1.0 : (i % 4 == 1 ? .46 : .58);
      final p = at + Offset(math.cos(a), math.sin(a)) * r * k;
      i == 0 ? star.moveTo(p.dx, p.dy) : star.lineTo(p.dx, p.dy);
    }
    star.close();
    c.drawPath(star, _line(ink, h * .0065, fade));
    c.drawPath(star, _fill(gold, fade));
    c.save();
    c.translate(at.dx, at.dy);
    c.scale(.56);
    c.translate(-at.dx, -at.dy);
    c.drawPath(star, _fill(flameCore, fade));
    c.restore();
    for (var i = 0; i < 5; i++) {
      final a = -math.pi * .95 + i * .62 + .2;
      final travel = reduced ? .55 : math.pow(t, .6).toDouble();
      final drop = reduced ? 0.0 : t * t * h * .07;
      final pos =
          at +
          Offset(math.cos(a), math.sin(a)) * h * (.05 + .09 * travel) +
          Offset(0, drop);
      coin(
        c,
        pos,
        h * (.0075 - i % 2 * .0015) * (1 - t * .5),
        flip: reduced ? .8 : .3 + .7 * math.cos(t * 16 + i * 2).abs(),
        alpha: fade,
      );
    }
  }

  // ------------------------------------------------------------ treasure --

  /// The captain's hoard bursts: doubloons, silver, rubies and stars.
  static void treasure(Canvas c, Offset at, double h, double t, bool reduced) {
    if (t >= 1) return;
    final travel = reduced ? .45 : math.pow(t, .65).toDouble();
    final fade = 1 - t * t;
    for (var i = 0; i < 30; i++) {
      final a = i * 2.399963;
      final distance = h * (.05 + travel * .62 * (.5 + (i % 7) / 9));
      final fall = reduced ? 0.0 : t * t * h * .14;
      final pos =
          at + Offset(math.cos(a) * distance, math.sin(a) * distance + fall);
      final r = h * (.012 + (i % 4) * .0042) * (1 - t * .5);
      final flip = reduced ? .8 : .25 + .75 * math.cos(t * 14 + i).abs();
      switch (i % 6) {
        case 3:
          coin(
            c,
            pos,
            r,
            flip: flip,
            alpha: fade,
            face: const Color(0xffe9eef5),
            rim: const Color(0xff8b96a8),
          );
        case 4:
          c.save();
          c.translate(pos.dx, pos.dy);
          c.rotate(reduced ? a : a + t * 4);
          final gem = Path()
            ..moveTo(0, -r * 1.15)
            ..lineTo(r * .95, 0)
            ..lineTo(0, r * 1.15)
            ..lineTo(-r * .95, 0)
            ..close();
          c.drawPath(gem, _line(ink, r * .5, fade));
          c.drawPath(gem, _fill(const Color(0xffe0384f), fade));
          c.drawPath(
            Path()
              ..moveTo(0, -r * 1.15)
              ..lineTo(-r * .95, 0)
              ..lineTo(0, -r * .1)
              ..close(),
            _fill(const Color(0xffff9aa4), fade),
          );
          c.restore();
        case 5:
          c.save();
          c.translate(pos.dx, pos.dy);
          c.rotate(reduced ? a : a + t * 5);
          final star = SkyScenery.star(Offset.zero, r * 1.7);
          c.drawPath(star, _line(ink, r * .5, fade));
          c.drawPath(star, _fill(gold, fade));
          c.restore();
        default:
          coin(c, pos, r, flip: flip, alpha: fade);
      }
    }
  }

  // ------------------------------------------------------------ victory --

  /// "SKY RECLAIMED": warm rays open behind the title, doubloons rain over
  /// the sea and a ribbon carries the score.
  static void victory(Canvas c, Size size, FlightSimulation sim, BossMotion m) {
    final h = size.height, w = size.width, boss = m.boss;
    final show = BossMotion.ease(BossMotion.ramp(m.death, 1.55, 2.05));
    final fade = show * (1 - BossMotion.ramp(m.death, 3.3, 3.8));
    if (fade <= 0) return;
    final y = h * (.27 + (m.reducedMotion ? 0 : (1 - show) * .025));
    final focus = Offset(w * .5, y + h * .06);
    final turn = m.reducedMotion ? 0.0 : m.death * .12;
    final reach = h * (.3 + .22 * (m.reducedMotion ? 1 : show));
    final rays = Path();
    for (var i = 0; i < 16; i++) {
      final a = turn + i * math.pi / 8;
      final half = i.isEven ? .075 : .04;
      final r = reach * (i.isEven ? 1 : .72);
      rays
        ..moveTo(focus.dx, focus.dy)
        ..lineTo(
          focus.dx + math.cos(a - half) * r * 1.7,
          focus.dy + math.sin(a - half) * r,
        )
        ..lineTo(
          focus.dx + math.cos(a + half) * r * 1.7,
          focus.dy + math.sin(a + half) * r,
        )
        ..close();
    }
    final glow = Rect.fromCenter(
      center: focus,
      width: reach * 3.4,
      height: reach * 2,
    );
    c.drawPath(
      rays,
      Paint()
        ..shader = RadialGradient(
          colors: [
            gold.withValues(alpha: .3 * fade),
            gold.withValues(alpha: 0),
          ],
        ).createShader(glow),
    );
    _coinShower(c, size, m, fade, y);
    final title = _text(
      c,
      'SKY RECLAIMED',
      Offset(w * .5, y),
      h * .08,
      ramp: const [Color(0xfffffbf0), Color(0xfffff0c4), Color(0xffffd878)],
      centered: true,
      opacity: fade,
      spacing: .5,
      outline: h * .013,
      shadow: h * .009,
    );
    for (var i = 0; i < 5; i++) {
      final side = i.isEven ? -1.0 : 1.0;
      final twinkle = m.reducedMotion
          ? 1.0
          : .55 + .45 * math.sin(m.death * 5 + i * 1.7);
      glint(
        c,
        Offset(
          w * .5 + side * (title.width / 2 + h * (.04 + (i ~/ 2) * .035)),
          y +
              h *
                  (i < 2
                      ? .02
                      : i < 4
                      ? .078
                      : -.012),
        ),
        h * (i < 2 ? .024 : .014) * twinkle,
        fade,
      );
    }
    // A twisted rope for a rule, knotted at both ends.
    final rule = y + title.height + h * .009;
    final half = title.width * .55;
    final rope = Path()..moveTo(w * .5 - half, rule);
    for (var x = -half; x <= half; x += h * .006) {
      rope.lineTo(w * .5 + x, rule);
    }
    c.drawPath(rope, _line(ink, h * .0105, fade));
    c.drawPath(rope, _line(_rope, h * .0065, fade));
    final twist = Path();
    for (var x = -half + h * .01; x < half - h * .008; x += h * .0085) {
      twist
        ..moveTo(w * .5 + x, rule - h * .0035)
        ..lineTo(w * .5 + x + h * .004, rule + h * .0035);
    }
    c.drawPath(twist, _line(_ropeDeep, h * .0022, fade));
    for (final side in [-1.0, 1.0]) {
      c.drawCircle(
        Offset(w * .5 + side * half, rule),
        h * .0085,
        _fill(ink, fade),
      );
      c.drawCircle(
        Offset(w * .5 + side * half, rule),
        h * .0058,
        _fill(_rope, fade),
      );
    }
    final line = sim.isTrail
        ? '+${FlightSimulation.bossBonus} POINTS   ·   SHIELD RESTORED'
        : '${boss.name.toUpperCase()} DEFEATED';
    final probe = TextPainter(
      text: TextSpan(
        text: line,
        style: heading(h * .03).copyWith(letterSpacing: 1),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final ribbonY = rule + h * .048;
    _ribbon(c, Offset(w * .5, ribbonY), probe.width + h * .08, h * .054, fade);
    _text(
      c,
      line,
      Offset(w * .5, ribbonY),
      h * .03,
      ramp: const [Color(0xfffff6cc), gold, Color(0xffe0a233)],
      centered: true,
      middle: true,
      opacity: fade,
      spacing: 1,
      outline: h * .006,
    );
  }

  /// Doubloons tumbling out of the sky, gone before they reach the sea.
  static void _coinShower(
    Canvas c,
    Size size,
    BossMotion m,
    double fade,
    double titleY,
  ) {
    final h = size.height, w = size.width;
    final k = m.death - 1.55;
    final reduced = m.reducedMotion;
    for (var i = 0; i < 34; i++) {
      final x = w * (.03 + .94 * ((i * .6180339887) % 1));
      final delay = _hash(i, 1) * 1.0;
      final duration = 1.35 + _hash(i, 2) * .55;
      final u = reduced ? .16 + .62 * _hash(i, 1) : (k - delay) / duration;
      if (u <= 0 || u >= 1) continue;
      final y = -h * .04 + h * .78 * (u * .68 + u * u * .32);
      final sway = reduced ? 0.0 : math.sin(u * 6 + i) * h * .012;
      final r = h * (.016 + _hash(i, 3) * .009);
      // Held still, the shower keeps clear of the title and its ribbon.
      if (reduced &&
          Rect.fromLTRB(
            w * .5 - h * .4,
            titleY - h * .04,
            w * .5 + h * .4,
            titleY + h * .22,
          ).inflate(r * 1.5).contains(Offset(x, y))) {
        continue;
      }
      final alpha =
          fade * math.min(1.0, u * 7) * (1 - BossMotion.ramp(u, .7, 1));
      final flip = reduced ? .8 : .18 + .82 * math.cos(k * 9 + i * 2.1).abs();
      coin(c, Offset(x + sway, y), r, flip: flip, alpha: alpha);
      if (i % 5 == 0 && flip > .85) {
        glint(c, Offset(x + sway + r * .9, y - r * .9), r * .9, alpha);
      }
    }
  }
}
