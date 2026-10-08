import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../domain/game_rules.dart';
import '../l10n/l10n.dart';
import '../ui/theme.dart';
import 'boss_motion.dart';
import 'dragon_kit.dart';
import 'dragon_layout.dart';
import 'regions/world_region.dart';

/// The Ember Dragon's breath on screen: the warning that marks out the band
/// of sky about to burn, the breath drawn in, and the river of fire itself.
///
/// The warning washes the band in ember red with hazard stripes, marches a
/// dashed fire line along each edge the bird can cross, lights the whole
/// safe side cool, points chevrons toward safety and spells the dodge out in
/// a tag whose three pips fill until the flame comes. The inhale draws a
/// funnel of spiralling embers into the jaws and gathers a white-hot glow
/// there. The flame bursts from the jaws at [DragonTimeline.igniteAt], a
/// tapered, layered, hot-cored jet of turbulent tongues that widens to
/// exactly the band and races across the sky so it reaches the bird's column
/// as the rules start to burn, never after. It lights the scenery it burns
/// through. When the breath ends it tears free of the jaws, splits into
/// three wisps and blows away.
///
/// Everything derives from the boss clock (and [seconds] for the decor that
/// marches with the world), so pauses, replays and captures repeat exactly.
abstract final class DragonBreathArt {
  static const _p = DragonPalette.ink;
  static const _cool = Color(0xffd9fbff), _plate = Color(0xff2a1630);

  /// The cool wash and motes on the safe side.
  static const _safe = Color(0xff2fb4ff);

  /// The jet leaves the jaws here and is gone here (tear-off included).
  static const _lit = DragonTimeline.igniteAt;
  static const _gone = DragonBreath.endAt + .32;

  /// Diagnostics only (tests read them; they never influence a pixel): the
  /// path vertices the last [flame] and [inhale] calls emitted. The flame's
  /// budget is 250; sparks are points and count separately.
  static int flameVertices = 0, inhaleVertices = 0;

  /// Diagnostic only: tests switch the scene light off to measure what it
  /// adds to the scenery.
  static bool sceneLight = true;

  static double _cycle(SkyBoss boss) =>
      (boss.age - boss.arrivalDuration) % DragonBreath.period;

  /// Only a dragon in the fight on a finite clock has a breath: a NaN or
  /// infinite age (a corrupt or hostile replay) draws nothing rather than
  /// throwing in the canvas.
  static bool _active(SkyBoss boss) =>
      boss.isDragon &&
      boss.age.isFinite &&
      boss.arrivalDuration.isFinite &&
      boss.phase == BossPhase.attacking &&
      _cycle(boss).isFinite;

  /// Whether the inputs of a draw call are numbers a canvas can take.
  static bool _sane(double h, Offset mouth, [double seconds = 0]) =>
      h.isFinite &&
      h > 0 &&
      mouth.dx.isFinite &&
      mouth.dy.isFinite &&
      seconds.isFinite;

  /// How strongly the warning marks show: in through the inhale, held
  /// faintly through the flame, out as it ends.
  static double markings(SkyBoss boss) {
    if (!_active(boss)) return 0;
    final t = _cycle(boss);
    if (t < DragonBreath.warnAt) return 0;
    if (t < DragonBreath.blastAt) {
      return BossMotion.ease(
        BossMotion.ramp(t, DragonBreath.warnAt, DragonBreath.warnAt + .18),
      );
    }
    if (t < DragonBreath.endAt) return .55;
    return .55 *
        (1 - BossMotion.ramp(t, DragonBreath.endAt, DragonBreath.endAt + .25));
  }

  // -------------------------------------------------------------- warning --

  /// Under the dragon: the wash, stripes and chevrons over the band to burn
  /// and the cool light on the safe side. [mouth] is the jaws in pixels.
  static void warning(
    Canvas c,
    Size size,
    SkyBoss boss,
    BossMotion m, {
    required Offset mouth,
    required double seconds,
  }) {
    if (!_sane(size.height, mouth, seconds) || !size.width.isFinite) return;
    final show = markings(boss);
    if (show <= 0) return;
    final h = size.height;
    final t = _cycle(boss);
    final inhale = t < DragonBreath.blastAt;
    final (top, bottom) = DragonBreath.band(boss.breathLane);
    final y0 = top * h, y1 = bottom * h;
    // The marks fade out before the jaws, so they never veil the dragon.
    final clear = mouth.dx - h * .1;
    if (clear <= 0) return;
    final near = inhale ? boss.breathWarning : 1.0;
    final reduced = m.reducedMotion;
    // The pulse quickens as the flame nears; Reduced Motion holds it lit.
    final blink = reduced
        ? 1.0
        : .6 + .4 * math.cos((t - DragonBreath.warnAt) * (8 + near * 14));
    final fadeFrom = ((clear - h * .2) / clear).clamp(0.0, 1.0);
    Paint fading(Color color, double alpha) => DragonKit.linear(
      Offset.zero,
      Offset(clear, 0),
      [
        color.withValues(alpha: alpha),
        color.withValues(alpha: alpha),
        color.withValues(alpha: 0),
      ],
      [0, fadeFrom, 1],
    );
    final band = Rect.fromLTRB(0, y0, clear, y1);
    if (inhale) {
      c.drawRect(
        band,
        fading(DragonPalette.flameDark, (.24 + near * .22) * show * blink),
      );
      // Hazard stripes creep toward the bird.
      c.save();
      c.clipRect(band);
      final gap = h * .07;
      final drift = reduced ? 0.0 : (seconds * h * .22) % gap;
      final stripes = Path();
      for (var x = -h + drift; x < clear + h; x += gap) {
        stripes
          ..moveTo(x, y1)
          ..lineTo(x + (y1 - y0), y0);
      }
      c.drawPath(
        stripes,
        fading(DragonPalette.flame, .24 * show)
          ..style = PaintingStyle.stroke
          ..strokeWidth = h * .016,
      );
      c.restore();
      _chevrons(c, h, boss.breathLane, y0, y1, clear, show, near, t, reduced);
    }
    _safeSide(c, h, boss.breathLane, clear, show, t, reduced, fading);
  }

  /// The whole safe side reads: a cool wash over every safe band, motes
  /// drifting up through it, and a bright bank along each edge the bird can
  /// cross. The wash is a wide, calm counterpart to the hot band, so the
  /// safe half is never a guess on the high and low breaths.
  static void _safeSide(
    Canvas c,
    double h,
    BreathLane lane,
    double clear,
    double show,
    double t,
    bool reduced,
    Paint Function(Color, double) fading,
  ) {
    final wash = fading(_safe, .22 * show);
    for (final (top, bottom) in DragonBreath.safeBands(lane)) {
      final rect = Rect.fromLTRB(0, top * h, clear, bottom * h);
      c.drawRect(rect, wash);
      if (reduced) continue;
      // Motes rise through the wash and fade at both ends of their climb.
      final rise = rect.height * .8, span = clear - h * .25;
      final dim = <Offset>[], lit = <Offset>[];
      for (var i = 0; i < 12; i++) {
        final life = (t * (.16 + .1 * DragonKit.hash(i, 3)) + i / 12) % 1;
        final at = Offset(
          h * .1 + span * DragonKit.hash(i, 5) * .98,
          rect.bottom - rect.height * .1 - rise * life,
        );
        (life > .2 && life < .8 ? lit : dim).add(at);
      }
      // Ink-blue rings under white cores, so the motes show on pale skies.
      final ring = DragonKit.line(
        const Color(0xff1f6fa8),
        h * .0125,
        .4 * show,
      );
      c.drawPoints(ui.PointMode.points, lit, ring);
      final dot = DragonKit.line(_cool, h * .0075, .9 * show);
      c.drawPoints(ui.PointMode.points, lit, dot);
      c.drawPoints(
        ui.PointMode.points,
        dim,
        dot..color = _cool.withValues(alpha: .35 * show),
      );
    }
    // The safe side of every edge the bird can cross lights up.
    for (final (edge, safeBelow) in _edges(lane)) {
      final y = edge * h;
      final depth = h * .09;
      final rect = safeBelow
          ? Rect.fromLTRB(0, y, clear, y + depth)
          : Rect.fromLTRB(0, y - depth, clear, y);
      c.drawRect(
        rect,
        DragonKit.linear(
          Offset(0, safeBelow ? rect.top : rect.bottom),
          Offset(0, safeBelow ? rect.bottom : rect.top),
          [_cool.withValues(alpha: .42 * show), _cool.withValues(alpha: 0)],
        ),
      );
      // A solid cool line on the safe side of the hot dashed one.
      final ly = y + (safeBelow ? h * .011 : -h * .011);
      c.drawLine(
        Offset(0, ly),
        Offset(clear, ly),
        DragonKit.line(const Color(0xff1f6fa8), h * .009, .45 * show),
      );
      c.drawLine(
        Offset(0, ly),
        Offset(clear, ly),
        DragonKit.line(const Color(0xffa8f0ff), h * .0045, .95 * show),
      );
    }
  }

  /// Interior band edges as (y, whether the safe side is below).
  static List<(double, bool)> _edges(BreathLane lane) => switch (lane) {
    BreathLane.high => const [(DragonBreath.split, true)],
    BreathLane.middle => const [
      (DragonBreath.middleTop, false),
      (DragonBreath.middleBottom, true),
    ],
    BreathLane.low => const [(DragonBreath.split, false)],
  };

  static void _chevrons(
    Canvas c,
    double h,
    BreathLane lane,
    double y0,
    double y1,
    double clear,
    double show,
    double near,
    double t,
    bool reduced,
  ) {
    final size = h * .026;
    final spacing = h * .3;
    // A row's chevrons all share a height and a fade, so a row is one path.
    for (var row = 0; row < 3; row++) {
      final (from, to, down) = switch (lane) {
        BreathLane.high => (y0 + h * .08, y1 - h * .06, true),
        BreathLane.low => (y1 - h * .08, y0 + h * .06, false),
        BreathLane.middle when row.isEven => (
          (y0 + y1) / 2 - h * .02,
          y0 + h * .05,
          false,
        ),
        BreathLane.middle => ((y0 + y1) / 2 + h * .02, y1 - h * .05, true),
      };
      final phase = reduced ? row / 3 : ((t * 1.4 + row / 3) % 1);
      final y = from + (to - from) * phase;
      final alpha = show * math.sin(phase * math.pi) * (.55 + near * .45);
      if (alpha <= .02) continue;
      final dir = down ? 1.0 : -1.0;
      final path = Path();
      for (var x = h * .28; x < clear - h * .2; x += spacing) {
        path
          ..moveTo(x - size, y - dir * size * .5)
          ..lineTo(x, y + dir * size * .5)
          ..lineTo(x + size, y - dir * size * .5);
      }
      c.drawPath(path, DragonKit.line(_p, h * .016, alpha * .5));
      c.drawPath(path, DragonKit.line(_cool, h * .009, alpha));
    }
  }

  /// Over everything: the fire line along each edge and the tag. Drawn
  /// after the flame and the shots so the edge stays crisp.
  static void marks(
    Canvas c,
    Size size,
    SkyBoss boss,
    BossMotion m, {
    required Offset mouth,
    required double seconds,
  }) {
    if (!_sane(size.height, mouth, seconds) || !size.width.isFinite) return;
    final show = markings(boss);
    if (show <= 0) return;
    final h = size.height;
    final t = _cycle(boss);
    final inhale = t < DragonBreath.blastAt;
    final near = inhale ? boss.breathWarning : 1.0;
    final reduced = m.reducedMotion;
    final clear = mouth.dx - h * .1;
    if (clear <= 0) return;
    final blink = reduced
        ? 1.0
        : .65 + .35 * math.cos((t - DragonBreath.warnAt) * (8 + near * 14));
    final dash = h * .045, gap = h * .025;
    final march = reduced ? 0.0 : (seconds * h * .3) % (dash + gap);
    for (final (edge, _) in _edges(boss.breathLane)) {
      final y = edge * h;
      final line = Path();
      for (var x = -dash + march; x < clear; x += dash + gap) {
        line
          ..moveTo(math.max(0, x), y)
          ..lineTo(math.min(clear, x + dash), y);
      }
      final fade = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      c.drawPath(
        line,
        fade
          ..strokeWidth = h * .014
          ..color = _p.withValues(alpha: .55 * show),
      );
      c.drawPath(
        line,
        fade
          ..strokeWidth = h * .007
          ..color = Color.lerp(
            DragonPalette.flameGold,
            DragonPalette.flameCore,
            blink - .6,
          )!.withValues(alpha: show),
      );
      // Little flames stand along the line on its burning side.
      if (inhale) {
        final (_, safeBelow) = _edges(
          boss.breathLane,
        ).firstWhere((e) => e.$1 == edge);
        _flameGlyphs(
          c,
          h,
          [for (var x = h * .42; x < clear - h * .15; x += h * .38) x],
          y + (safeBelow ? -h * .004 : h * .004),
          h * .03 * (.8 + near * .35),
          upward: safeBelow,
          alpha: show,
          seconds: reduced ? null : seconds,
        );
      }
    }
    _tag(c, h, boss, show, near, blink, inhale);
  }

  /// The little flames standing along an edge, at [xs] on the line at [y]:
  /// all alike but for a flicker, so they are three paths in all.
  static void _flameGlyphs(
    Canvas c,
    double h,
    List<double> xs,
    double y,
    double s, {
    required bool upward,
    required double alpha,
    double? seconds,
  }) {
    final dir = upward ? -1.0 : 1.0;
    final outer = Path(), inner = Path();
    void tongue(Path path, double x, double k, double flicker) {
      path
        ..moveTo(x - s * .5 * k, y)
        ..quadraticBezierTo(
          x - s * .55 * k,
          y + dir * s * .6 * k,
          x + flicker * s * .08,
          y + dir * s * 1.25 * k,
        )
        ..quadraticBezierTo(
          x + s * .6 * k,
          y + dir * s * .55 * k,
          x + s * .5 * k,
          y,
        )
        ..close();
    }

    for (final x in xs) {
      final flicker = seconds == null ? 0.0 : math.sin(seconds * 13 + x);
      tongue(outer, x, 1, flicker);
      tongue(inner, x, .55, flicker);
    }
    c.drawPath(outer, DragonKit.line(_p, s * .22, alpha * .8));
    c.drawPath(outer, DragonKit.fill(DragonPalette.flame, alpha));
    c.drawPath(inner, DragonKit.fill(DragonPalette.flameYellow, alpha));
  }

  // (laid out again in a new language's fonts)
  static final _painters = L10n.cache(<String, TextPainter>{});

  static TextPainter _text(String value, double size, Color color) =>
      _painters.putIfAbsent(
        '$value|${size.toStringAsFixed(1)}|${color.toARGB32()}',
        () => TextPainter(
          text: TextSpan(
            text: value,
            style: heading(
              size,
              color: color,
            ).copyWith(letterSpacing: size * .06),
          ),
          // Words run their language's way; the tag stays where it is.
          textDirection: L10n.textDirection,
        )..layout(),
      );

  /// The pips' colours, first to last: gold, orange, red. They light at 4.5,
  /// 5.0 and 5.5 s and burn down through the flame.
  static const _pips = [
    DragonPalette.flameGold,
    DragonPalette.flame,
    Color(0xffff3b48),
  ];

  /// A tag at the left edge, inside the burning band beside its edge: an
  /// arrow toward safety, the dodge spelled out, and three pips filling
  /// until the flame.
  static void _tag(
    Canvas c,
    double h,
    SkyBoss boss,
    double show,
    double near,
    double blink,
    bool inhale,
  ) {
    final lane = boss.breathLane;
    final l = L10n.strings;
    final label = switch (lane) {
      BreathLane.high => l.bossDodgeFlyLow,
      BreathLane.middle => l.bossDodgeClimbOrDive,
      BreathLane.low => l.bossDodgeFlyHigh,
    };
    final pad = h * .016;
    final arrow = h * .04;
    // The tag sits where the bird is, so it keeps clear of the bird's
    // column: a long label is set smaller rather than run under the bird.
    final room = (FlightSimulation.birdX - .085) * h - h * .03;
    var text = _text(label, h * .046, DragonPalette.flameCore);
    final spare = room - (pad * 2 + arrow + pad * .8);
    if (text.width > spare) {
      final fit = (h * .046 * spare / text.width * 10).floorToDouble() / 10;
      text = _text(label, fit, DragonPalette.flameCore);
    }
    final w = pad * 2 + arrow + pad * .8 + text.width;
    // Room under the label for the pips (5 px tall at 360).
    final tall = h * .092;
    final (top, bottom) = DragonBreath.band(lane);
    // Beside the edge the bird must cross, inside the burning band.
    final cy = switch (lane) {
      BreathLane.high => bottom * h - tall * .95,
      BreathLane.low => top * h + tall * .95,
      BreathLane.middle => (top + bottom) / 2 * h,
    };
    final rect = Rect.fromLTWH(h * .03, cy - tall / 2, w, tall);
    final plate = RRect.fromRectAndRadius(rect, Radius.circular(tall * .28));
    c.drawRRect(
      plate.shift(Offset(0, h * .005)),
      DragonKit.fill(_p, .45 * show),
    );
    c.drawRRect(plate, DragonKit.fill(_plate, .94 * show));
    c.drawRRect(
      plate,
      DragonKit.line(
        Color.lerp(DragonPalette.flame, DragonPalette.flameGold, blink)!,
        h * .005,
        show,
      ),
    );
    // The arrow: down, up, or both ways.
    final ax = rect.left + pad + arrow / 2;
    final ay = rect.top + (tall - h * .03) * .5;
    void chevron(double dir, double dy) {
      final p = Path()
        ..moveTo(ax - arrow * .45, ay + dy - dir * arrow * .2)
        ..lineTo(ax, ay + dy + dir * arrow * .25)
        ..lineTo(ax + arrow * .45, ay + dy - dir * arrow * .2);
      c.drawPath(p, DragonKit.line(_cool, h * .008, show));
    }

    switch (lane) {
      case BreathLane.high:
        chevron(1, -arrow * .15);
        chevron(1, arrow * .2);
      case BreathLane.low:
        chevron(-1, arrow * .15);
        chevron(-1, -arrow * .2);
      case BreathLane.middle:
        chevron(-1, -arrow * .28);
        chevron(1, arrow * .28);
    }
    if (show > .5) {
      text.paint(
        c,
        Offset(
          rect.left + pad + arrow + pad * .8,
          ay - text.height / 2 - h * .004,
        ),
      );
    }
    // Three pips fill through the inhale (one per third of it, gold to red)
    // and burn down through the flame.
    final fill = inhale
        ? near
        : 1 -
              BossMotion.ramp(
                (boss.age - boss.arrivalDuration) % DragonBreath.period,
                DragonBreath.blastAt,
                DragonBreath.endAt,
              );
    final pipH = h * .014, gap = h * .008;
    final span = rect.width - pad * 2;
    final pipW = (span - gap * 2) / 3;
    final pipTop = rect.bottom - pad * .7 - pipH;
    for (var i = 0; i < 3; i++) {
      final left = rect.left + pad + i * (pipW + gap);
      final slot = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, pipTop, pipW, pipH),
        Radius.circular(pipH / 2),
      );
      c.drawRRect(slot, DragonKit.fill(_p, .6 * show));
      final part = (fill * 3 - i).clamp(0.0, 1.0);
      if (part <= 0) continue;
      final lit = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, pipTop, math.max(pipH, pipW * part), pipH),
        Radius.circular(pipH / 2),
      );
      c.drawRRect(lit, DragonKit.fill(_pips[i], show));
      // A hot edge along the top of a lit pip.
      c.drawLine(
        Offset(lit.left + pipH * .5, pipTop + pipH * .28),
        Offset(lit.right - pipH * .5, pipTop + pipH * .28),
        DragonKit.line(DragonPalette.flameCore, h * .003, .55 * show),
      );
    }
  }

  // ---------------------------------------------------------------- flame --

  /// The breath itself, from [mouth] (pixels) across the sky over the band.
  ///
  /// Built in flow space: `u` runs downstream from the jaws (screen left)
  /// and `v` across it, so the whole jet is one canvas transform and its
  /// heat ramps are cached gradients in unit space (0 at the jaws, 1 at the
  /// front). Four nested layers (rim, orange, gold, core) each ride a run of
  /// tongues that scroll downstream; the outermost tongues' crests reach the
  /// band's edge and their troughs sit inside it, so the solid fire ends
  /// exactly where the rules do. At most 250 path vertices, no `saveLayer`.
  static void flame(
    Canvas c,
    Size size,
    SkyBoss boss,
    BossMotion m, {
    required Offset mouth,
    required double seconds,
  }) {
    flameVertices = 0;
    if (!_sane(size.height, mouth, seconds) || !size.width.isFinite) return;
    if (!_active(boss)) return;
    final t = _cycle(boss);
    if (t < _lit || t >= _gone) return;
    final h = size.height;
    final reduced = m.reducedMotion;
    final fury = boss.enraged;
    // Flicker runs on the boss clock, so it is the same on every replay.
    final time = reduced ? 0.0 : boss.age;
    final (top, bottom) = DragonBreath.band(boss.breathLane);
    // Screen edges are not edges of the flame: it runs on past them.
    final y0 = top <= 0 ? -h * .1 : top * h;
    final y1 = bottom >= 1 ? h * 1.1 : bottom * h;
    final birdX = FlightSimulation.birdX * h;

    // The front races out so it covers the bird's column exactly as the
    // rules begin to burn, then runs on off the screen at the same speed.
    final reach = birdX - h * .16;
    const dur = DragonBreath.blastAt - _lit;
    final double front;
    if (t < DragonBreath.blastAt) {
      final p = BossMotion.ramp(t, _lit, DragonBreath.blastAt);
      // Kicks out fast, then cruises at the speed it leaves at.
      final g = p + 2.4 * p * math.pow(1 - p, 3);
      front = mouth.dx + (reach - mouth.dx) * g;
    } else {
      final speed = (mouth.dx - reach) / dur;
      front = math.max(-h * .3, reach - speed * (t - DragonBreath.blastAt));
    }
    final len = mouth.dx - front;
    if (len < 3) return;

    // When it ends the stream tears free of the jaws, shrinks and parts
    // into three wisps that blow away.
    final out = BossMotion.ramp(t, DragonBreath.endAt, _gone);
    final tailU = len * .5 * BossMotion.ease(out);
    final shrink = 1 - math.pow(out, 2.2).toDouble();
    final sever = BossMotion.ease(BossMotion.ramp(out, .05, .4));
    final fade = 1 - BossMotion.ramp(out, .8, 1);
    // The ignition kick: a swelling of the jaws' opening for a moment.
    final tau = t - _lit;
    final kick = tau < .3 ? math.pow(1 - tau / .3, 2).toDouble() : 0.0;

    final jet = _Jet(
      h: h,
      len: len,
      tailU: tailU,
      // A young flame leaves along the jaws and swings onto the band as it
      // lengthens, rather than shooting off as a diagonal blade. It is on the
      // band long before it reaches the bird's column (the jaws are never
      // nearer than .47 h to it).
      centre0:
          ((y0 + y1) / 2 - mouth.dy) *
          BossMotion.ease(BossMotion.ramp(len, h * .1, h * .42)),
      bandHalf: (y1 - y0) / 2,
      mouthHalf: h * .028 * (1 + kick * 1.1),
      shrink: shrink,
      sever: sever,
      screenU: mouth.dx,
    );

    if (sceneLight) {
      _sceneLight(c, h, seconds, mouth, front, jet, y0, y1, out, time);
    }
    if (!reduced || tau < .45) {
      _frontSmoke(c, h, boss, mouth, front, jet, t, time, y0, y1);
    }

    // The layers, hot at the jaws and cooling toward the front.
    final ramps = fury ? _Ramps.hot : _Ramps.calm;
    final pen = _Pen();
    final paths = <Path>[];
    for (var i = 0; i < _specs.length; i++) {
      paths.add(_layer(pen, jet, _specs[i], i, time, fury, _budgets[i]));
    }
    c.save();
    c.translate(mouth.dx, mouth.dy);
    c.scale(-len, 1);
    for (var i = 0; i < paths.length; i++) {
      final paint = ramps.paints[i];
      paint.color = DragonPalette.white.withValues(alpha: fade);
      c.drawPath(paths[i], paint);
    }
    if (!reduced) {
      final streaks = _streaks(pen, jet, time, h);
      c.drawPath(streaks, DragonKit.fill(const Color(0xffffffff), .92 * fade));
    }
    // The first frames: a white-hot wedge burns through the core, tapering to
    // a point at the nose and staying well inside the band.
    if (tau < .035) {
      final base = jet.half(len * .3) * .5;
      pen
        ..move(0, jet.centre(0) - base * .5)
        ..line(1, jet.centre(len))
        ..line(0, jet.centre(0) + base * .5)
        ..close();
      c.drawPath(
        pen.take(),
        DragonKit.fill(const Color(0xffffffff), .95 * (1 - tau / .035)),
      );
    }
    c.restore();
    flameVertices = pen.count;

    if (!reduced) _sparks(c, h, mouth, front, jet, time, y0, y1, fury, fade);
    if (!reduced) flameVertices += _shimmer(c, h, mouth, front, y0, time, out);
    _muzzle(c, h, mouth, tau, reduced, out);
  }

  /// The layers, outermost first. `scale` is the layer's crest height as a
  /// fraction of the jet's half height; each layer's crests stay below the
  /// layer outside it, so the rim always encloses the fire. `relief` is how
  /// tall its tongues stand (never more than `cap` screen heights), `period`
  /// and `speed` (in screen heights) how far apart they are and how fast
  /// they ride, `cut` how much shorter than the front the layer stops,
  /// `tongues` the most it may draw per edge.
  ///
  /// The rim is the edge the rules burn at: its crests sit ON the band's
  /// edge and its troughs no more than `.0055 h` (2 px at 360) inside it,
  /// so whoever sees fire beside the bird is hurt and whoever sees clear air
  /// is not. The big licks belong to the orange layer inside it.
  static const _specs = [
    _Spec(
      scale: 1,
      relief: .05,
      period: .2,
      speed: 1.05,
      cut: 0,
      tongues: 5,
      cap: .0055,
    ),
    _Spec(scale: .9, relief: .3, period: .2, speed: 1.2, cut: .03, tongues: 6),
    _Spec(
      scale: .66,
      relief: .3,
      period: .25,
      speed: 1.35,
      cut: .08,
      tongues: 4,
    ),
    _Spec(
      scale: .42,
      relief: .35,
      period: .34,
      speed: 1.5,
      cut: .3,
      tongues: 1,
    ),
  ];

  /// Four bright dashes racing along the gold band (in normalised flow
  /// space), so the flame reads as moving even where a layer is smooth.
  static Path _streaks(_Pen pen, _Jet j, double time, double h) {
    final span = math.min(j.len, j.screenU + h * .1);
    for (var i = 0; i < 4; i++) {
      final speed = h * (1.5 + .5 * DragonKit.hash(i, 31));
      final long = h * (.14 + .1 * DragonKit.hash(i, 35));
      final head = (time * speed + DragonKit.hash(i, 33) * span) % span;
      if (head - long < j.tailU + 6 || head > j.len * .7) continue;
      final w = math.max(1.3, j.half(head) * .03);
      // The gold band lies between the core's crest and the gold's own.
      final lane = (i.isEven ? -1 : 1) * (.53 + .04 * DragonKit.hash(i, 37));
      final v = j.centre(head) + lane * j.half(head);
      Offset n(double u, double dv) => Offset(u / j.len, v + dv);
      final a = n(head - long, 0),
          b = n(head - long * .3, -w),
          c = n(head + long * .05, 0),
          d = n(head - long * .3, w);
      pen.move(a.dx, a.dy);
      pen.line(b.dx, b.dy);
      pen.line(c.dx, c.dy);
      pen.line(d.dx, d.dy);
      pen.close();
    }
    return pen.take();
  }

  /// Path vertices each layer may use (250 in all), bodies first, then as
  /// many tongues as still fit.
  static const _budgets = [66, 76, 54, 26];

  /// One layer in normalised flow space (`u / len`, px across): a smooth
  /// body (the trumpet, the band and a pointed nose) with the layer's
  /// tongues laid over its edges as separate sickle-shaped subpaths. The
  /// tongues all wind the same way as the body, so they union.
  static Path _layer(
    _Pen pen,
    _Jet j,
    _Spec s,
    int index,
    double time,
    bool fury,
    int budget,
  ) {
    final mark = pen.count;
    final startU = j.tailU;
    final endU = j.len * (1 - s.cut);
    // A blunt front on a tall jet looks like a slab: the nose is as long as
    // most of the half height (a young flame is a wedge, all nose). No more
    // than .19 h, so the body is full width at the bird's column by 5.50.
    final nose = math.min(
      (j.half(endU * .5) * s.scale * .62).clamp(j.h * .1, j.h * .19),
      (endU - startU) * .5,
    );
    final bodyEnd = math.max(startU + 1.0, endU - nose);
    final boost = fury ? 1.14 : 1.0;
    final period = s.period * j.h;

    Offset n(Offset p) => Offset(p.dx / j.len, p.dy);
    // A point on the layer's outline at [u]: [out] 0 is the trough line (the
    // body's edge), 1 the crest.
    Offset at(double sign, double u, double out) {
      // The rim's crests sit half a pixel out and its troughs at most
      // .0055 h (2 px) in, so the visible edge reads within ~2 px of the
      // rules' band (a solid-pixel count adds one more of rounding).
      final half = j.half(u);
      final w =
          half * s.scale +
          (s.scale >= 1 ? j.h * .0014 * math.min(1.0, half / (j.h * .05)) : 0);
      final amp = math.min(w * s.relief * boost, j.h * s.cap);
      return Offset(u, j.centre(u) + sign * (w - amp + amp * out));
    }

    // -- the body --
    final cone = j.h * .46;
    List<_Seg> edge(double sign) {
      final segs = <_Seg>[];
      if (j.tailU == 0 && j.sever == 0 && bodyEnd >= cone) {
        // The trumpet as one cubic, then the band as a straight run.
        final p0 = at(sign, startU, 0), pc = at(sign, cone, 0);
        final dv = pc.dy - p0.dy;
        segs.add(
          _Seg(
            p0,
            Offset(cone * .3, p0.dy + dv * .51),
            Offset(cone * .7, pc.dy),
            pc,
          ),
        );
        if (bodyEnd > cone + .5) {
          segs.add(_Seg(pc, null, null, at(sign, bodyEnd, 0)));
        }
      } else {
        // Tearing off (or too short to have a band): a plain polyline, dense
        // enough to shape the wisps, then straight over the gone part.
        final tearing = j.sever > 0 || j.tailU > 0;
        final stopU = j.sever > 0 ? math.min(bodyEnd, j.trainEnd) : bodyEnd;
        final steps = tearing ? 14 : 4;
        var prev = at(sign, startU, 0);
        for (var k = 1; k <= steps; k++) {
          // Dense through the trumpet, where the envelope bends.
          final f = k / steps;
          final u = tearing
              ? startU + (stopU - startU) * (f * f * 0.55 + f * 0.45)
              : startU + (stopU - startU) * f;
          final p = at(sign, u, 0);
          segs.add(_Seg(prev, null, null, p));
          prev = p;
        }
        if (stopU < bodyEnd - .5) {
          segs.add(_Seg(prev, null, null, at(sign, bodyEnd, 0)));
        }
      }
      return segs;
    }

    final top = edge(-1), bot = edge(1);
    final start = n(top.first.from);
    pen.move(start.dx, start.dy);
    for (final seg in top) {
      pen.seg(seg, n);
    }
    // The nose: an ogive, pointed at the tip and flicking a little.
    final wob = time == 0
        ? 0.0
        : math.sin(time * (7.5 + index * 1.7) + index) *
              j.half(bodyEnd) *
              s.scale *
              .07;
    final tip = n(Offset(endU, j.centre(endU) + wob));
    final et = n(top.last.to), eb = n(bot.last.to);
    final nu = nose / j.len;
    pen.cubic(
      et.dx + nu * .5,
      et.dy,
      tip.dx - nu * .45,
      tip.dy + (et.dy - tip.dy) * .18,
      tip.dx,
      tip.dy,
    );
    pen.cubic(
      tip.dx - nu * .45,
      tip.dy + (eb.dy - tip.dy) * .18,
      eb.dx + nu * .5,
      eb.dy,
      eb.dx,
      eb.dy,
    );
    for (final seg in bot.reversed) {
      pen.seg(seg.reversed, n);
    }
    pen.close();

    // -- the tongues --
    // They ride a lattice that scrolls downstream, so each keeps its size
    // and shape as it goes; from the front backward, so a cap drops the
    // smallest, nearest the jaws.
    for (final (sign, salt) in [(-1.0, index * 2), (1.0, index * 2 + 1)]) {
      final phase = time * s.speed * j.h / period + salt * .37;
      final base = phase.floor();
      final frac = phase - base;
      var drawn = 0;
      var k = ((math.min(bodyEnd, j.screenU + j.h * .1)) / period - frac)
          .floor();
      for (
        ;
        drawn < s.tongues &&
            pen.count - mark + 5 <= budget &&
            (k + frac) * period > startU - period;
        k--
      ) {
        final id = k - base;
        final len = period * (.85 + .35 * DragonKit.hash(id, salt + 2));
        final ua = math.max((k + frac) * period, startU);
        final ub = (k + frac) * period + len * .7;
        final tipU = (k + frac) * period + len;
        if (tipU >= bodyEnd || tipU <= startU + 2) continue;
        final flicker = time == 0
            ? 1.0
            : 1 +
                  .1 *
                      math.sin(
                        math.pi *
                            2 *
                            (time * (1.1 + DragonKit.hash(id, salt)) +
                                DragonKit.hash(id, salt + 9)),
                      );
        // Every other tongue stands (all but) full height, its crest on the
        // band's edge; the ones between fall short by a hash. All flick.
        final size = id.isEven
            ? 1 - .06 * (1.1 - flicker.clamp(.9, 1.1)) / .2
            : math.min(
                1.0,
                (.55 + .35 * DragonKit.hash(id, salt + 1)) * flicker,
              );
        // Too small to see: the mouth end, a tail-off pinch.
        if (j.half(tipU) * s.scale * s.relief * size < 1.6) continue;
        final r0 = n(at(sign, ua, 0)), r1 = n(at(sign, ub, 0));
        final tp = n(at(sign, tipU, size));
        // A flick: the lick lies along the flow, then hooks outward.
        final ca = n(at(sign, (k + frac) * period + .5 * len, size * .2));
        final cb = n(at(sign, (k + frac) * period + .68 * len, size * .5));
        // Top tongues wind clockwise from the root's upstream end, bottom
        // ones from its downstream end, so both wind like the body.
        if (sign < 0) {
          pen.move(r0.dx, r0.dy);
          pen.quad(ca.dx, ca.dy, tp.dx, tp.dy);
          pen.quad(cb.dx, cb.dy, r1.dx, r1.dy);
        } else {
          pen.move(r1.dx, r1.dy);
          pen.quad(cb.dx, cb.dy, tp.dx, tp.dy);
          pen.quad(ca.dx, ca.dy, r0.dx, r0.dy);
        }
        pen.close();
        drawn++;
      }
    }
    // Two licks lash forward off the nose (the rim's and the orange's).
    if (index < 2 &&
        j.sever == 0 &&
        j.tailU == 0 &&
        pen.count - mark + 10 <= budget) {
      final b = j.half(bodyEnd) * s.scale;
      for (final sign in const [-1.0, 1.0]) {
        final flick = time == 0
            ? 0.0
            : math.sin(time * (9 + index * 2 + sign * 2) + sign);
        final tip = n(
          Offset(
            endU + nose * (.3 + .1 * flick),
            j.centre(endU) + sign * b * (.3 + .05 * flick),
          ),
        );
        final r0 = n(
          Offset(endU - nose * .75, j.centre(endU) + sign * b * .62),
        );
        final r1 = n(Offset(endU - nose * .3, j.centre(endU) + sign * b * .4));
        final ca = n(Offset(endU - nose * .1, j.centre(endU) + sign * b * .55));
        final cb = n(
          Offset(endU + nose * .05, j.centre(endU) + sign * b * .36),
        );
        if (sign < 0) {
          pen.move(r0.dx, r0.dy);
          pen.quad(ca.dx, ca.dy, tip.dx, tip.dy);
          pen.quad(cb.dx, cb.dy, r1.dx, r1.dy);
        } else {
          pen.move(r1.dx, r1.dy);
          pen.quad(cb.dx, cb.dy, tip.dx, tip.dy);
          pen.quad(ca.dx, ca.dy, r0.dx, r0.dy);
        }
        pen.close();
      }
    }
    return pen.take();
  }

  // ------------------------------------------------------------- lighting --

  /// The fire lights the world it burns through. One soft ellipse over the
  /// flame, drawn twice with no blur and no `saveLayer`: screen (a glow on
  /// dark and mid scenery) and a warm source-over tint (which a bright sky
  /// needs, since screening cannot lighten it).
  static void _sceneLight(
    Canvas c,
    double h,
    double seconds,
    Offset mouth,
    double front,
    _Jet jet,
    double y0,
    double y1,
    double out,
    double time,
  ) {
    final sky = SkyPalette.at(seconds);
    final dark = DragonSkyLight.fromSky(
      top: sky.top,
      horizon: sky.horizon,
      haze: sky.haze,
    ).dark;
    final gain = BossMotion.ramp(mouth.dx - front, 0, h * .3) * (1 - out * out);
    if (gain <= 0) return;
    // A slow shimmer in the light, well inside +-6%.
    final k = gain * (1 + .06 * math.sin(time * 17));
    final xEnd = front - h * .12, xStart = mouth.dx + h * .02;
    final cx = (xEnd + xStart) / 2, rx = (xStart - xEnd) / 2;
    final cy = (y0 + y1) / 2;
    // The light reaches .06 h (22 px at 360) past the band and is flat until
    // its last fifth, so a solid-looking haze (>= 12% opaque) runs no more
    // than about 17 px past the fire's hard edge (it was 36); the rules' edge
    // stays the fire's, not the glow's.
    final ry = (y1 - y0) / 2 + h * .06;
    // One additive pass: dark scenery takes it as a glow, bright scenery
    // (which cannot get brighter) as a warm wash toward yellow-white. Never
    // more than .55 opaque (it is light, not fire: a capture of the flame alone
    // must not read it as solid).
    final night = ((dark - .1) / .6).clamp(0.0, 1.0);
    final strength = (.28 + .22 * night) * k;
    if (strength < .03) return;
    c.save();
    c.translate(cx, cy);
    c.scale(rx, ry);
    _Ramps.light
      ..blendMode = BlendMode.plus
      ..color = DragonPalette.white.withValues(alpha: strength);
    c.drawCircle(Offset.zero, 1, _Ramps.light);
    c.restore();
  }

  /// Dark smoke rolling ahead of the front: three billows that swell as the
  /// jet races out, kept inside the band.
  static void _frontSmoke(
    Canvas c,
    double h,
    SkyBoss boss,
    Offset mouth,
    double front,
    _Jet jet,
    double t,
    double time,
    double y0,
    double y1,
  ) {
    final age = t - _lit;
    if (front < -h * .1 || age > .5) return;
    final grow = BossMotion.ramp(age, 0, .22);
    final gone = 1 - BossMotion.ramp(age, .32, .5);
    final ahead = math.max(0.0, mouth.dx - front);
    // Three billows of soot tuck in behind the front's shoulders, peeking
    // out past the flame's edge.
    for (var i = 0; i < 3; i++) {
      final r = h * (.026 + .006 * i) * grow;
      final u = ahead - h * (.045 + .05 * i);
      if (u < 0) continue;
      final side = i.isEven ? -1.0 : 1.0;
      final edge = jet.half(u) * (1.0 + .12 * grow);
      final base = Offset(
        mouth.dx - u,
        mouth.dy +
            jet.centre(u) +
            side * edge +
            math.sin(time * 4 + i * 2.1) * r * .2,
      );
      final at = Offset(base.dx, base.dy.clamp(y0 + r, y1 - r).toDouble());
      c.drawOval(
        Rect.fromCenter(
          center: at + Offset(-r * .25, r * .12 * side),
          width: r * 2.6,
          height: r * 1.9,
        ),
        DragonKit.fill(const Color(0xff4a2430), .45 * gone),
      );
      c.drawOval(
        Rect.fromCenter(
          center: at + Offset(r * .3, -r * .3 * side),
          width: r * 1.2,
          height: r * .8,
        ),
        DragonKit.fill(const Color(0xffd0683a), .36 * gone),
      );
    }
  }

  /// Embers racing along inside the flame: at most 24 points, white to gold
  /// to orange as they age, drifting up a little and clamped to the band.
  static void _sparks(
    Canvas c,
    double h,
    Offset mouth,
    double front,
    _Jet jet,
    double time,
    double y0,
    double y1,
    bool fury,
    double fade,
  ) {
    final span = math.min(jet.len, mouth.dx + h * .1);
    final white = <Offset>[], gold = <Offset>[], orange = <Offset>[];
    final count = fury ? 24 : 18;
    final lo = math.max(y0, -h * .02) + 3, hi = math.min(y1, h * 1.02) - 3;
    for (var i = 0; i < count; i++) {
      final speed = h * (.9 + DragonKit.hash(i, 5) * .9);
      final u = (time * speed + DragonKit.hash(i, 7) * span) % span;
      if (u < jet.tailU + 4 || u > jet.len - 6) continue;
      final life = u / span;
      final half = jet.half(u);
      final y =
          mouth.dy +
          jet.centre(u) +
          half * (DragonKit.hash(i, 11) * 1.7 - .85) -
          life * h * .035;
      final p = Offset(mouth.dx - u, y.clamp(lo, hi).toDouble());
      (life < .22
              ? white
              : life < .55
              ? gold
              : orange)
          .add(p);
    }
    Paint dot(Color color, double d) => DragonKit.line(color, d, fade);
    c.drawPoints(
      ui.PointMode.points,
      orange,
      dot(const Color(0xffff8a30), h * .009),
    );
    c.drawPoints(
      ui.PointMode.points,
      gold,
      dot(DragonPalette.flameGold, h * .0105),
    );
    c.drawPoints(
      ui.PointMode.points,
      white,
      dot(const Color(0xfffffdf0), h * .012),
    );
  }

  /// Two faint wavy bands rising above the jet's upper edge. Not a
  /// distortion (that would need a layer): just heat you can see. Returns
  /// the vertices it drew.
  static int _shimmer(
    Canvas c,
    double h,
    Offset mouth,
    double front,
    double y0,
    double time,
    double out,
  ) {
    if (y0 < h * .16 || out > .5) return 0;
    var vertices = 0;
    final x0 = math.max(front, h * .05), x1 = mouth.dx - h * .25;
    if (x1 - x0 < h * .3) return 0;
    for (var band = 0; band < 2; band++) {
      final rise = (time * .55 + band * .5) % 1;
      final y = y0 - h * (.035 + .07 * rise);
      final path = Path()..moveTo(x0, y);
      vertices++;
      const steps = 3;
      for (var i = 0; i < steps; i++) {
        final xa = x0 + (x1 - x0) * (i + .5) / steps;
        final xb = x0 + (x1 - x0) * (i + 1) / steps;
        final wave = (i.isEven ? -1 : 1) * h * .008;
        path.quadraticBezierTo(xa, y + wave, xb, y);
        vertices += 2;
      }
      c.drawPath(
        path,
        DragonKit.line(
          DragonPalette.white,
          h * .02,
          .07 * math.sin(rise * math.pi),
        ),
      );
    }
    return vertices;
  }

  /// The muzzle: a bloom and white-hot core over the head that flare at the
  /// ignition and settle to a steady glow at the jaws, one shock ring and a
  /// fan of rays. Screen-blended, so it lights the head it sits on.
  static void _muzzle(
    Canvas c,
    double h,
    Offset mouth,
    double tau,
    bool reduced,
    double out,
  ) {
    // Flare: in over 40 ms, out over 0.36 s; a steady glow stays behind.
    final flare = tau < .04
        ? tau / .04
        : tau < .4
        ? math.pow(1 - (tau - .04) / .36, 2).toDouble()
        : 0.0;
    // The first two or three frames burn brighter and wider still.
    final punch = tau < 0 ? 0.0 : (1 - tau / .05).clamp(0.0, 1.0);
    final steady = (1 - out) * .38;
    final k = math.max(flare, steady);
    final bloom = _Ramps.bloom;
    c.save();
    c.translate(mouth.dx, mouth.dy);
    final r = h * (.06 + .13 * flare + .03 * steady + .07 * punch);
    c.scale(r, r);
    bloom
      ..blendMode = BlendMode.screen
      ..color = DragonPalette.white.withValues(alpha: math.min(1, k * 1.1));
    c.drawCircle(Offset.zero, 1, bloom);
    c.restore();
    if (punch > 0) {
      // A hard white-hot core, only for those frames.
      c.drawCircle(
        mouth,
        h * (.028 + .03 * punch),
        DragonKit.fill(const Color(0xffffffff), .95 * punch),
      );
    }
    if (tau < 0 || tau > .22) return;
    final e = tau / .22;
    // The shock ring.
    c.drawCircle(
      mouth,
      h * (.03 + .14 * (1 - math.pow(1 - e, 2))),
      DragonKit.line(
        DragonPalette.flameCore,
        h * .012 * (1 - e),
        .75 * (1 - e),
      ),
    );
    if (reduced && tau > .08) return;
    // Rays fanning down the jet.
    final rays = Path();
    for (var i = 0; i < 7; i++) {
      final a = math.pi + (i - 3) * .36 + (DragonKit.hash(i, 21) - .5) * .12;
      final length = h * (.09 + .09 * DragonKit.hash(i, 23)) * (1 - e * .6);
      final dir = DragonKit.heading(a);
      final side = Offset(-dir.dy, dir.dx);
      final w = h * .011 * (1 - e);
      final base = mouth + dir * (h * .018);
      rays
        ..moveTo(base.dx + side.dx * w, base.dy + side.dy * w)
        ..lineTo(mouth.dx + dir.dx * length, mouth.dy + dir.dy * length)
        ..lineTo(base.dx - side.dx * w, base.dy - side.dy * w)
        ..close();
    }
    c.drawPath(rays, DragonKit.fill(DragonPalette.flameCore, .9 * (1 - e)));
  }

  // --------------------------------------------------------------- inhale --

  /// The breath drawn in: a funnel of spiralling embers and streaks that
  /// tightens toward the jaws, a white-hot glow gathering in the mouth that
  /// pulses faster as it fills (and twice as fast through the hold), and a
  /// faint dark ring around it so the streaks read on any sky.
  static void inhale(
    Canvas c,
    double h,
    SkyBoss boss,
    BossMotion m, {
    required Offset mouth,
  }) {
    inhaleVertices = 0;
    if (!_sane(h, mouth) || !_active(boss)) return;
    final t = _cycle(boss);
    if (t < DragonBreath.warnAt || t >= _lit + .035) return;
    final reduced = m.reducedMotion;
    // Mirrors the dragon's own inhale: in over 4.0-4.95, held at full
    // through the hold, then the jet takes over.
    final k = BossMotion.ease(
      BossMotion.ramp(t, DragonBreath.warnAt, DragonTimeline.holdAt),
    );
    final hold = t >= DragonTimeline.holdAt && t < DragonTimeline.snapAt;
    final snap = BossMotion.ramp(t, DragonTimeline.snapAt, _lit);
    final exit = 1 - BossMotion.ramp(t, _lit, _lit + .035);
    final level = k * exit;
    if (level <= .004) return;
    final fury = boss.enraged;

    // Pulse phase, integrated so the rate can change without a jump: 3 Hz
    // at the start of the breath, 7 Hz once it is full, doubled in the hold.
    final pulse = reduced ? 0.0 : math.sin(math.pi * 2 * _pulsePhase(t));
    final strength = level * (1 + .12 * pulse * (hold ? 1.4 : 1));

    // A faint dark ring behind everything, so pale skies do not eat it.
    final ring = _Ramps.vignette;
    c.save();
    c.translate(mouth.dx, mouth.dy);
    final rr = h * .3;
    c.scale(rr, rr);
    ring.color = DragonPalette.white.withValues(alpha: .24 * level);
    c.drawCircle(Offset.zero, 1, ring);
    c.restore();

    inhaleVertices = _funnel(c, h, mouth, t, level, snap, reduced, hold);
    _mouthGlow(c, h, mouth, strength, level, hold, fury);
  }

  /// Cycles of the pulse so far.
  static double _pulsePhase(double t) {
    const rise = DragonTimeline.holdAt - DragonBreath.warnAt;
    final x = BossMotion.ramp(t, DragonBreath.warnAt, DragonTimeline.holdAt);
    // Integral of 3 + 4 smoothstep(x) over the ramp, then 7 Hz.
    final ramp =
        3 * (t - DragonBreath.warnAt).clamp(0.0, rise) +
        4 * rise * (x * x * x - x * x * x * x / 2);
    final beyond = math.max(0.0, t - DragonTimeline.holdAt) * 7;
    // The hold pulses twice as fast: extra cycles while it lasts.
    final held =
        (t - DragonTimeline.holdAt).clamp(
          0.0,
          DragonTimeline.snapAt - DragonTimeline.holdAt,
        ) *
        7;
    return ramp + beyond + held;
  }

  /// Ten tapered streaks and fourteen embers falling into the jaws from a
  /// ring .3 screen heights out, each along a shallow spiral that winds a
  /// little tighter as it closes; collapsing arcs mark the intake. Only what
  /// lies left of the jaws is drawn, so nothing ever paints back over the
  /// dragon's face. Returns the vertices drawn.
  static int _funnel(
    Canvas c,
    double h,
    Offset mouth,
    double t,
    double level,
    double snap,
    bool reduced,
    bool hold,
  ) {
    // The funnel opens along the jaws: up while the head rears back, level
    // again as it snaps onto the band.
    final tilt =
        .3 *
        BossMotion.ease(
          BossMotion.ramp(t, DragonTimeline.rearAt, DragonTimeline.holdAt),
        );
    final axis = math.pi + tilt * (1 - snap);
    // Phase of the inflow: steady, with a rush at the snap. Continuous in t.
    final flow = t * 1.5 + 2 * snap * snap;
    const count = 10;
    final r0 = h * .3, rEnd = h * .024;

    // A point [r] out from the jaws on arm [arm] of [count].
    double angle(int arm, double r) {
      final spread = ((arm + .5) / count * 2 - 1) * 1.6;
      final sway = reduced ? 0.0 : .18 * math.sin(t * 2.6 + arm * 1.9);
      return spread + sway + .65 * (1 - r / r0);
    }

    Offset spot(int arm, double r) =>
        mouth + DragonKit.heading(axis + angle(arm, r)) * r;

    // The funnel's own light: a soft half-disc of ember glow in front of the
    // jaws, so the streaks fall through something.
    c.save();
    c.translate(mouth.dx, mouth.dy);
    c.rotate(axis);
    c.scale(r0 * 1.15, r0 * .9);
    final cone = _Ramps.funnel
      ..color = DragonPalette.white.withValues(alpha: level);
    c.drawArc(
      const Rect.fromLTRB(-1, -1, 1, 1),
      -math.pi / 2,
      math.pi,
      true,
      cone,
    );
    c.restore();

    // All ten streaks go into one path (an ink edge, an orange body and a
    // hot line down each): a streak fades by shortening and thinning at the
    // ends of its life rather than by opacity, so they can share paints.
    final bodies = _Pen(), spines = _Pen();
    for (var i = 0; i < count; i++) {
      final life = reduced
          ? .25 + .5 * DragonKit.hash(i, 1)
          : (flow * (.9 + .2 * DragonKit.hash(i, 2)) +
                    DragonKit.hash(i, 3) * 3) %
                1;
      final head = rEnd + (r0 - rEnd) * math.pow(1 - life, 1.4).toDouble();
      final full = h * (.16 + .1 * DragonKit.hash(i, 4));
      final dirX = math.cos(axis + angle(i, head + full / 2));
      final grow =
          ((-dirX - .1) / .4).clamp(0.0, 1.0) *
          BossMotion.ramp(life, 0, .14) *
          (1 - BossMotion.ramp(life, .86, 1));
      if (grow < .2) continue;
      final tail = math.min(r0, head + full * grow);
      final left = <Offset>[], right = <Offset>[];
      const samples = 5;
      for (var k = 0; k < samples; k++) {
        final r = head + (tail - head) * k / (samples - 1);
        final a = spot(i, r), b = spot(i, math.max(rEnd, r - h * .01));
        final dir = DragonKit.unit(a - b);
        final normal = Offset(-dir.dy, dir.dx);
        // A slim comet: a small head, fullest just behind it, thinning to
        // a point at the tail.
        final w =
            h *
            .0105 *
            grow *
            const [.5, 1.0, .74, .4, 0.0][k] *
            math.min(1.0, .35 + head / (h * .1));
        left.add(a + normal * w);
        right.add(a - normal * w);
        if (k == 0) {
          spines.move(a.dx, a.dy);
        } else if (k < samples - 1) {
          spines.line(a.dx, a.dy);
        }
      }
      final poly = <Offset>[...left, ...right.reversed.skip(1)];
      bodies.move(poly.first.dx, poly.first.dy);
      for (final p in poly.skip(1)) {
        bodies.line(p.dx, p.dy);
      }
      bodies.close();
    }
    final bodyPath = bodies.take(), spinePath = spines.take();
    final hot = Color.lerp(
      DragonPalette.flameYellow,
      DragonPalette.flameCore,
      hold ? 1 : .6,
    )!;
    c.drawPath(
      bodyPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * .0075
        ..strokeJoin = StrokeJoin.round
        ..color = _p.withValues(alpha: level * .42),
    );
    c.drawPath(
      bodyPath,
      Paint()..color = DragonPalette.flame.withValues(alpha: level * .95),
    );
    c.drawPath(
      spinePath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = h * .0045
        ..color = hot.withValues(alpha: level),
    );

    // Rings collapse toward the jaws across the forward half only.
    for (var q = 0; q < 2; q++) {
      final life = reduced ? .3 + .35 * q : (flow * .55 + q * .5) % 1;
      final r = rEnd * 2 + (r0 - rEnd * 2) * math.pow(1 - life, 1.6).toDouble();
      final a = level * math.pow(math.sin(math.pi * life), .7) * .8;
      if (a < .03) continue;
      final rect = Rect.fromCircle(center: mouth, radius: r);
      c.drawArc(
        rect,
        axis - 1.25,
        2.5,
        false,
        DragonKit.line(_p, h * .0095, a * .3),
      );
      c.drawArc(
        rect,
        axis - 1.25,
        2.5,
        false,
        DragonKit.line(DragonPalette.flame, h * .0065, a * .8),
      );
      c.drawArc(
        rect,
        axis - 1.1,
        2.2,
        false,
        DragonKit.line(DragonPalette.flameCore, h * .0025, a),
      );
    }

    // Embers ride the same spirals a little ahead of the streaks.
    final warm = <Offset>[], white = <Offset>[];
    for (var e = 0; e < 14; e++) {
      final life = reduced ? (e + .5) / 14 : (flow * 1.25 + e * .381966) % 1;
      final r = rEnd + (r0 - rEnd) * math.pow(1 - life, 1.3).toDouble();
      final arm = (e * 3) % count;
      if (math.cos(axis + angle(arm, r)) > -.2) continue;
      (life > .55 ? white : warm).add(spot(arm, r));
    }
    c.drawPoints(
      ui.PointMode.points,
      warm,
      DragonKit.line(DragonPalette.flameGold, h * .0105, level),
    );
    c.drawPoints(
      ui.PointMode.points,
      white,
      DragonKit.line(const Color(0xfffffdf0), h * .0125, level),
    );
    return bodies.count + spines.count;
  }

  /// Three concentric discs in the jaws: a warm halo, a gold body and a
  /// white-hot core that swell as the breath fills.
  static void _mouthGlow(
    Canvas c,
    double h,
    Offset mouth,
    double strength,
    double level,
    bool hold,
    bool fury,
  ) {
    void disc(double radius, double alpha, Paint paint, BlendMode mode) {
      c.save();
      c.translate(mouth.dx, mouth.dy);
      c.scale(radius, radius);
      paint
        ..blendMode = mode
        ..color = DragonPalette.white.withValues(alpha: alpha.clamp(0.0, 1.0));
      c.drawCircle(Offset.zero, 1, paint);
      c.restore();
    }

    final s = strength;
    disc(h * (.05 + .1 * s), .6 * level, _Ramps.halo, BlendMode.screen);
    disc(h * (.03 + .06 * s), .85 * level, _Ramps.body, BlendMode.srcOver);
    disc(
      h * (.015 + .032 * s),
      (fury || hold ? 1 : .95) * level,
      _Ramps.core,
      BlendMode.srcOver,
    );
  }
}

/// One layer of the jet; see [DragonBreathArt._specs].
final class _Spec {
  const _Spec({
    required this.scale,
    required this.relief,
    required this.period,
    required this.speed,
    required this.cut,
    required this.tongues,
    this.cap = .075,
  });
  final double scale, relief, period, speed, cut, cap;
  final int tongues;
}

/// The jet's envelope in flow space for one frame: [len] from the jaws to the
/// front, [tailU] where the tail has torn free, the band's centre and half
/// height relative to the jaws, and how far it has shrunk and parted.
final class _Jet {
  const _Jet({
    required this.h,
    required this.len,
    required this.tailU,
    required this.centre0,
    required this.bandHalf,
    required this.mouthHalf,
    required this.shrink,
    required this.sever,
    required this.screenU,
  });
  final double h, len, tailU, centre0, bandHalf, mouthHalf, shrink, sever;

  /// Where the screen's left edge lies in flow space (the jaws' x).
  final double screenU;

  /// The tail-off's train of three wisps: where it starts, how long it is
  /// and where its last wisp ends (the jet past it is gone).
  double get train => math.min(len - tailU, h);
  double get trainEnd => tailU + train + h * .12;

  /// The cone from the jaws to the full band, a trumpet: opens quickly, then
  /// eases onto the band.
  double spread(double u) {
    final x = (u / (h * .46)).clamp(0.0, 1.0);
    return 1 - math.pow(1 - x, 1.7).toDouble();
  }

  double centre(double u) => centre0 * spread(u);

  /// The half height of the whole jet at [u] (the outermost crests).
  double half(double u) {
    var w = mouthHalf + (bandHalf - mouthHalf) * spread(u);
    if (tailU > 0) {
      // A torn-off tail rounds off like an ellipse, more the further it
      // has lifted, so the tear-off starts without a pop.
      final cap = h * .12 * math.min(1.0, tailU / (h * .06));
      final x = ((u - tailU) / cap).clamp(0.0, 1.0);
      w *= math.sqrt(1 - (1 - x) * (1 - x));
    }
    if (sever > 0) {
      // It pinches to nothing twice, and ends after the third wisp.
      for (final f in const [.34, .67]) {
        // Each wisp is a teardrop: a round head just upstream of the pinch,
        // a long thin tail downstream of it.
        final d = u - (tailU + train * f);
        final e = d / (train * (d < 0 ? .045 : .16));
        w *= 1 - sever * math.exp(-e * e);
      }
      final x = ((u - (tailU + train)) / (h * .12)).clamp(0.0, 1.0);
      w *= 1 - sever * x * x * (3 - 2 * x);
    }
    return w * shrink;
  }
}

/// A run of an outline: a line, a quadratic (one control) or a cubic (two).
final class _Seg {
  const _Seg(this.from, this.c1, this.c2, this.to);
  final Offset from, to;
  final Offset? c1, c2;

  /// The same run walked backward.
  _Seg get reversed => _Seg(to, c2 ?? c1, c2 == null ? null : c1, from);
}

/// A path that counts the vertices it is given.
// KIT-REQUEST: a vertex-counting path builder in the kit, so the budget test
// can assert path points (the jet's 250-vertex budget) and not only draw ops.
final class _Pen {
  Path _path = Path();
  int count = 0;

  void move(double x, double y) {
    _path.moveTo(x, y);
    count++;
  }

  void line(double x, double y) {
    _path.lineTo(x, y);
    count++;
  }

  void quad(double cx, double cy, double x, double y) {
    _path.quadraticBezierTo(cx, cy, x, y);
    count += 2;
  }

  void cubic(
    double c1x,
    double c1y,
    double c2x,
    double c2y,
    double x,
    double y,
  ) {
    _path.cubicTo(c1x, c1y, c2x, c2y, x, y);
    count += 3;
  }

  void close() => _path.close();

  /// Adds [seg] (walked forward), mapped through [map].
  void seg(_Seg seg, Offset Function(Offset) map) {
    final to = map(seg.to);
    if (seg.c1 == null) {
      line(to.dx, to.dy);
    } else if (seg.c2 == null) {
      final a = map(seg.c1!);
      quad(a.dx, a.dy, to.dx, to.dy);
    } else {
      final a = map(seg.c1!), b = map(seg.c2!);
      cubic(a.dx, a.dy, b.dx, b.dy, to.dx, to.dy);
    }
  }

  /// The finished path; the pen starts a new one (the count carries on).
  Path take() {
    final done = _path;
    _path = Path();
    return done;
  }
}

// KIT-REQUEST: cached unit-space gradients. `DragonKit.linear`/`radial` build a
// shader per call and `DragonKit.cached` hands out one shared paint; the breath
// keeps its own static set, drawn under a transform, until the kit has a
// `unitLinear`/`unitRadial` helper (then this class shrinks to colour lists).
/// The cached, unit-space gradients of the breath. Nothing here is rebuilt
/// per frame: a heat ramp runs 0 (the jaws) to 1 (the front) and is drawn
/// under a transform; the glows are unit discs scaled to size.
final class _Ramps {
  _Ramps._(List<List<Color>> ramps)
    : paints = [
        for (final r in ramps)
          DragonKit.linear(Offset.zero, const Offset(1, 0), r),
      ];

  /// Rim, orange, gold, core: one heat ramp each.
  final List<Paint> paints;

  static final calm = _Ramps._(const [
    [Color(0xffc22c3a), Color(0xffa02240), Color(0xff7a1a3a)],
    [Color(0xffffb23c), Color(0xffff7a2a), Color(0xfff0482a)],
    [Color(0xfffff2b8), Color(0xffffd25a), Color(0xffff9d33)],
    [
      Color(0xffffffff),
      Color(0xfffffbe8),
      Color(0xffffe98a),
      Color(0xffffd45a),
    ],
  ]);

  static final hot = _Ramps._(const [
    [Color(0xffd6344a), Color(0xffb02640), Color(0xff821c3c)],
    [Color(0xffffd25a), Color(0xffffa030), Color(0xffff6a2a)],
    [Color(0xffffffe0), Color(0xfffff09a), Color(0xffffc040)],
    [
      Color(0xffffffff),
      Color(0xffffffff),
      Color(0xfffff6c8),
      Color(0xffffe680),
    ],
  ]);

  /// The scene light: a soft ellipse with a wide flat top.
  static final light = DragonKit.radial(
    Offset.zero,
    1,
    const [Color(0xffff9a48), Color(0xffff8a3a), Color(0x00ff7a30)],
    const [0, .78, 1],
  );

  static final bloom = DragonKit.radial(
    Offset.zero,
    1,
    const [
      Color(0xffffffff),
      Color(0xffffe9a8),
      Color(0xb0ffa040),
      Color(0x00ff7a30),
    ],
    const [0, .22, .55, 1],
  );

  static final halo = DragonKit.radial(
    Offset.zero,
    1,
    const [Color(0xd0ff8a30), Color(0x70ff6a2a), Color(0x00ff5a20)],
    const [0, .45, 1],
  );

  static final body = DragonKit.radial(
    Offset.zero,
    1,
    const [Color(0xffffe9a0), Color(0xd0ffc850), Color(0x00ffb23c)],
    const [0, .5, 1],
  );

  static final core = DragonKit.radial(
    Offset.zero,
    1,
    const [Color(0xffffffff), Color(0xfffffbe8), Color(0x00fff0b0)],
    const [0, .6, 1],
  );

  /// The intake's light: an ember glow that fades out from the jaws.
  static final funnel = DragonKit.radial(
    Offset.zero,
    1,
    const [Color(0x80ff6a2a), Color(0x38ff7a30), Color(0x00ff8a3a)],
    const [0, .5, 1],
  );

  static final vignette = DragonKit.radial(
    Offset.zero,
    1,
    const [
      Color(0x00401020),
      Color(0x00401020),
      Color(0xff40101c),
      Color(0x00401020),
    ],
    const [0, .32, .62, 1],
  );
}
