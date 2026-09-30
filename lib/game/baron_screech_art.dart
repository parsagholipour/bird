import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../domain/game_rules.dart';
import '../ui/theme.dart';
import 'baron_storm_art.dart';
import 'baron_storm_pose.dart';
import 'boss_motion.dart';

/// The upgraded Baron's sonic screech on screen (see [BaronScreech]).
///
/// The warning marks the one safe lane: the sky above and below it hazes
/// over in sonic pink with rolling sound ripples, the lane itself lights up
/// cool and bright between dashed edges, chevrons point into it, and a tag
/// at the left edge, inside the lane, says so while its gauge fills. A
/// ghost of the wall, with its gap, stands at his mouth.
///
/// Then the wall itself: a full-height band of sound whose leading edge is
/// exactly the rules' front and whose opening is exactly the rules' gap,
/// with a waveform running through it and fading echoes behind. It bursts
/// from his mouth as a curved shock front and flattens long before it can
/// reach the bird.
///
/// Everything derives from the boss clock, so pauses, replays and captures
/// repeat exactly; Reduced Motion holds ripples, chevrons and waveforms
/// still but keeps every mark, the wall and the gap in full.
abstract final class BaronScreechArt {
  static const _ink = Color(0xff1d1033), _safe = Color(0xffd9fbff);
  static const _shade = Color(0xff2a1150);
  static const _plate = Color(0xff24133a), _text = Color(0xfffff6e8);

  static bool _active(SkyBoss boss) =>
      boss.screeches && boss.phase == BossPhase.attacking;

  static double _cycle(SkyBoss boss) =>
      (boss.age - boss.arrivalDuration) % BaronScreech.period;

  /// How strongly the marks show: in over the warning's first moments, held
  /// through the sweep, out just after it.
  static double markings(SkyBoss boss) {
    if (!_active(boss)) return 0;
    final t = _cycle(boss);
    if (t < BaronScreech.warnAt) return 0;
    if (t < BaronScreech.screechAt) {
      return BossMotion.ease(
        BossMotion.ramp(t, BaronScreech.warnAt, BaronScreech.warnAt + .2),
      );
    }
    if (t < BaronScreech.endAt) return 1;
    return 1 - BossMotion.ramp(t, BaronScreech.endAt, BaronScreech.endAt + .3);
  }

  // ------------------------------------------------------------ geometry --

  /// The release's shock front has flattened this long after the wall
  /// leaves; the wall can reach no bird sooner than a third of a second.
  static const flatBy = .22;

  /// How far (screen heights per screen height squared) the wall's edge
  /// lags behind at heights away from his mouth, [s] seconds after release.
  static double bend(double s) =>
      .9 * (1 - BossMotion.ease(BossMotion.ramp(s, 0, flatBy)));

  /// The drawn wall's leading edge at screen height [y] (screen heights), or
  /// null when no wall is drawn. [mouthY] is where it left his mouth. Under
  /// Reduced Motion the shock front never bends.
  static double? leadingEdge(
    SkyBoss boss,
    double y, {
    required double mouthY,
    bool reduced = false,
  }) {
    final front = boss.screechFront;
    if (front == null) return null;
    final s = _cycle(boss) - BaronScreech.screechAt;
    final k = reduced ? 0.0 : bend(s);
    return front + k * (y - mouthY) * (y - mouthY);
  }

  /// The opening the drawn wall leaves, (top, bottom) in screen heights.
  static (double, double) opening(SkyBoss boss) => boss.screechOpening;

  /// Where the screech leaves his mouth, in pixels.
  static Offset mouth(SkyBoss boss, BossMotion m, double h) =>
      BaronStormRig.toScreen(boss, m, h, BaronStormRig.mouth);

  // ------------------------------------------------------------- layers --

  /// Under the Baron and his shots: the danger haze, the lit lane, the
  /// chevrons, the ghost wall and the wall itself.
  static void under(Canvas c, Size size, FlightSimulation sim, BossMotion m) {
    final boss = m.boss;
    if (!_active(boss)) return;
    final show = markings(boss);
    if (show <= 0) return;
    final h = size.height;
    final t = _cycle(boss);
    final warning = t < BaronScreech.screechAt;
    final front = boss.screechFront;
    final fury = boss.enraged;
    if (warning || front != null) {
      // Danger runs from the left edge to the wall, or before it leaves, to
      // his mouth.
      final limit = (front ?? boss.screechOriginX) * h;
      final near = warning ? boss.screechWarning : 1.0;
      if (limit > 0) {
        _danger(c, h, boss, m.reducedMotion, limit, show, near, fury);
        _lane(c, h, boss, limit, show);
        _chevrons(c, h, boss, m.reducedMotion, limit, show, near, t);
      }
      if (warning) _ghost(c, h, boss, m.reducedMotion, show, near, t, fury);
    }
    wall(
      c,
      size,
      boss,
      reduced: m.reducedMotion,
      mouthY: mouth(boss, m, h).dy / h,
    );
  }

  /// Over everything: the sound at his mouth, the lane's edges, the tag
  /// and the bird's jolt when the wall catches it.
  static void over(Canvas c, Size size, FlightSimulation sim, BossMotion m) {
    final boss = m.boss;
    if (!boss.screeches) return;
    final h = size.height;
    _voice(c, h, boss, m);
    if (!_active(boss)) return;
    final show = markings(boss);
    if (show > 0) {
      final t = _cycle(boss);
      final warning = t < BaronScreech.screechAt;
      final front = boss.screechFront;
      if (warning || front != null) {
        _edges(
          c,
          h,
          boss,
          m.reducedMotion,
          (front ?? boss.screechOriginX) * h,
          show,
        );
      }
      _tag(c, h, boss, show, warning, t);
    }
    _jolt(c, h, sim, boss, m);
  }

  // ------------------------------------------------------------- warning --

  static void _danger(
    Canvas c,
    double h,
    SkyBoss boss,
    bool reduced,
    double limit,
    double show,
    double near,
    bool fury,
  ) {
    final (top, bottom) = boss.screechOpening;
    final hot = BaronStormArt.sonicOf(fury);
    final zones = [
      Rect.fromLTRB(0, 0, limit, top * h),
      Rect.fromLTRB(0, bottom * h, limit, h),
    ];
    // The sky to be swept darkens (so the lane reads as the light way
    // through on any sky) and takes on the screech's colour.
    final shade = Paint()
      ..color = _shade.withValues(alpha: (.16 + .16 * near) * show);
    final tint = Paint()
      ..color = BaronStormArt.deepOf(
        fury,
      ).withValues(alpha: (.08 + .1 * near) * show);
    // Sound ripples roll left across it.
    final gx = h * .3, gy = h * .2;
    final scroll = reduced ? 0.0 : (boss.age * h * .32) % gx;
    final ripples = Path();
    for (var row = 0; gy * row < h; row++) {
      final y = gy * (row + .5);
      final stagger = row.isOdd ? gx * .5 : 0.0;
      for (var x = stagger - scroll - gx; x < limit; x += gx) {
        for (var k = 0; k < 3; k++) {
          ripples.addArc(
            Rect.fromCircle(
              center: Offset(x + h * .09, y),
              radius: h * (.026 + k * .024),
            ),
            math.pi - .62,
            1.24,
          );
        }
      }
    }
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (final (zone, below) in [(zones[0], false), (zones[1], true)]) {
      if (zone.height < 1) continue;
      c.drawRect(zone, shade);
      c.drawRect(zone, tint);
      // The edge of the lane burns brightest on the danger side.
      final edge = below
          ? Rect.fromLTWH(0, zone.top, limit, math.min(h * .06, zone.height))
          : Rect.fromLTRB(
              0,
              math.max(0, zone.bottom - h * .06),
              limit,
              zone.bottom,
            );
      c.drawRect(
        edge,
        Paint()
          ..shader = LinearGradient(
            begin: below ? Alignment.topCenter : Alignment.bottomCenter,
            end: below ? Alignment.bottomCenter : Alignment.topCenter,
            colors: [
              hot.withValues(alpha: (.3 + .25 * near) * show),
              hot.withValues(alpha: 0),
            ],
          ).createShader(edge),
      );
      c.save();
      c.clipRect(zone);
      c.drawPath(
        ripples,
        stroke
          ..strokeWidth = h * .014
          ..color = _ink.withValues(alpha: .3 * show),
      );
      c.drawPath(
        ripples,
        stroke
          ..strokeWidth = h * .0075
          ..color = Color.lerp(
            hot,
            BaronStormArt.sonicCore,
            .2,
          )!.withValues(alpha: (.5 + .4 * near) * show),
      );
      c.restore();
    }
  }

  /// The safe lane glows cool from its edges inward.
  static void _lane(
    Canvas c,
    double h,
    SkyBoss boss,
    double limit,
    double show,
  ) {
    final (top, bottom) = boss.screechOpening;
    c.drawRect(
      Rect.fromLTRB(0, top * h, limit, bottom * h),
      Paint()..color = _safe.withValues(alpha: .1 * show),
    );
    final depth = h * .1;
    for (final (y, down) in [(top * h, true), (bottom * h, false)]) {
      final rect = down
          ? Rect.fromLTRB(0, y, limit, y + depth)
          : Rect.fromLTRB(0, y - depth, limit, y);
      c.drawRect(
        rect,
        Paint()
          ..shader = LinearGradient(
            begin: down ? Alignment.topCenter : Alignment.bottomCenter,
            end: down ? Alignment.bottomCenter : Alignment.topCenter,
            colors: [
              _safe.withValues(alpha: .55 * show),
              _safe.withValues(alpha: 0),
            ],
          ).createShader(rect),
      );
    }
  }

  /// Chevrons in the sky to be swept, marching into the lane.
  static void _chevrons(
    Canvas c,
    double h,
    SkyBoss boss,
    bool reduced,
    double limit,
    double show,
    double near,
    double t,
  ) {
    final (top, bottom) = boss.screechOpening;
    final size = h * .028;
    final under = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = h * .017;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = h * .009;
    for (var x = h * .2; x < limit - h * .14; x += h * .5) {
      for (final down in [true, false]) {
        final edge = down ? top * h : bottom * h;
        final room = down ? edge : h - edge;
        if (room < h * .14) continue;
        final dir = down ? 1.0 : -1.0;
        final to = edge - dir * h * .045;
        final from = to - dir * math.min(h * .2, room - h * .06);
        for (var row = 0; row < 3; row++) {
          final phase = reduced ? (row + .5) / 3 : (t * 1.3 + row / 3) % 1;
          final y = from + (to - from) * phase;
          final alpha = show * math.sin(phase * math.pi) * (.55 + .45 * near);
          if (alpha <= .02) continue;
          final path = Path()
            ..moveTo(x - size, y - dir * size * .5)
            ..lineTo(x, y + dir * size * .5)
            ..lineTo(x + size, y - dir * size * .5);
          c.drawPath(path, under..color = _ink.withValues(alpha: alpha * .5));
          c.drawPath(path, stroke..color = _safe.withValues(alpha: alpha));
        }
      }
    }
  }

  /// A flickering ghost of the wall, gap and all, gathering at his mouth.
  static void _ghost(
    Canvas c,
    double h,
    SkyBoss boss,
    bool reduced,
    double show,
    double near,
    double t,
    bool fury,
  ) {
    final (top, bottom) = boss.screechOpening;
    final x0 = boss.screechOriginX * h;
    final thick = BaronScreech.thickness * h;
    final blink = reduced
        ? 1.0
        : .75 + .25 * math.cos((t - BaronScreech.warnAt) * (10 + near * 18));
    final alpha = (.3 + .5 * near) * show * blink;
    final body = Paint()
      ..color = BaronStormArt.deepOf(fury).withValues(alpha: alpha * .75);
    final edge = Paint()
      ..color = BaronStormArt.sonicOf(fury).withValues(alpha: alpha);
    final lip = Paint()..color = _safe.withValues(alpha: alpha);
    for (final (y0, y1, gapBelow) in [
      (0.0, top * h, true),
      (bottom * h, h, false),
    ]) {
      if (y1 - y0 < 1) continue;
      c.drawRect(Rect.fromLTRB(x0, y0, x0 + thick, y1), body);
      c.drawRect(Rect.fromLTRB(x0, y0, x0 + h * .01, y1), edge);
      final y = gapBelow ? y1 - h * .008 : y0;
      c.drawRect(Rect.fromLTWH(x0, y, thick, h * .008), lip);
    }
  }

  // ---------------------------------------------------------------- wall --

  /// The wall of sound: a band [BaronScreech.thickness] wide behind the
  /// rules' front, filling the sky but for the rules' gap. [mouthY] (screen
  /// heights) is where it left his mouth.
  static void wall(
    Canvas c,
    Size size,
    SkyBoss boss, {
    required bool reduced,
    required double mouthY,
  }) {
    final front = boss.screechFront;
    if (front == null) return;
    final h = size.height;
    final thick = BaronScreech.thickness * h;
    final xf = front * h;
    final echo = h * .028;
    if (xf + thick + echo * 3 < 0 || xf > size.width + h * .3) return;
    final s = _cycle(boss) - BaronScreech.screechAt;
    final k = reduced ? 0.0 : bend(s);
    final appear = BossMotion.ease(BossMotion.ramp(s, 0, .05));
    final fury = boss.enraged;
    final hot = BaronStormArt.sonicOf(fury), deep = BaronStormArt.deepOf(fury);
    const core = BaronStormArt.sonicCore;
    final (top, bottom) = boss.screechOpening;
    double edgeAt(double y) {
      final d = y / h - mouthY;
      return xf + k * d * d * h;
    }

    List<Offset> run(double y0, double y1, double step, double dx) {
      final points = <Offset>[];
      for (var y = y0; ; y += step) {
        final at = math.min(y, y1);
        points.add(Offset(edgeAt(at) + dx, at));
        if (at >= y1) break;
      }
      return points;
    }

    Path line(List<Offset> points) {
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (final p in points.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      return path;
    }

    final flat = k == 0;
    final body = Paint()
      ..shader = LinearGradient(
        colors: [
          core.withValues(alpha: .96 * appear),
          hot.withValues(alpha: .94 * appear),
          deep.withValues(alpha: .88 * appear),
        ],
        stops: const [0, .3, 1],
      ).createShader(Rect.fromLTRB(xf, 0, xf + thick, h));
    final haze = Paint()
      ..shader = LinearGradient(
        colors: [
          deep.withValues(alpha: .34 * appear),
          deep.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromLTRB(xf + thick, 0, xf + thick + h * .12, h));
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.butt
      ..strokeJoin = StrokeJoin.round;
    final phase = reduced ? 0.0 : boss.age * 26;
    final waveAmp = thick * .28;
    // Screen edges are not the wall's edges: it runs on past them.
    for (final (y0, y1, gapBelow) in [
      (-h * .03, top * h, true),
      (bottom * h, h * 1.03, false),
    ]) {
      if (y1 - y0 < 1) continue;
      if (flat) {
        c.drawRect(
          Rect.fromLTRB(xf + thick, y0, xf + thick + h * .12, y1),
          haze,
        );
      }
      // Fading echoes behind the wall: thinner and fainter, never solid.
      for (var e = 1; e <= 3; e++) {
        final x = xf + thick + echo * e;
        final alpha = [.55, .32, .16][e - 1] * appear;
        final width = h * [.007, .005, .0035][e - 1];
        stroke
          ..strokeWidth = width
          ..color = hot.withValues(alpha: alpha);
        if (flat) {
          c.drawLine(Offset(x, y0), Offset(x, y1), stroke);
        } else {
          c.drawPath(line(run(y0, y1, h * .03, thick + echo * e)), stroke);
        }
      }
      final lead = flat ? null : run(y0, y1, h * .03, 0);
      if (flat) {
        c.drawRect(Rect.fromLTRB(xf, y0, xf + thick, y1), body);
      } else {
        final band = line(lead!);
        for (final p in lead.reversed) {
          band.lineTo(p.dx + thick, p.dy);
        }
        c.drawPath(band..close(), body);
      }
      // A dark hairline closes the band behind.
      if (flat) {
        c.drawRect(
          Rect.fromLTRB(xf + thick - h * .003, y0, xf + thick, y1),
          Paint()..color = _ink.withValues(alpha: .6 * appear),
        );
      }
      // A waveform runs down the band.
      final wave = Path();
      final step = h * .012;
      for (var y = y0; y <= y1; y += step) {
        final x =
            edgeAt(y) + thick * .52 + waveAmp * math.sin(y / h * 44 + phase);
        y == y0 ? wave.moveTo(x, y) : wave.lineTo(x, y);
      }
      stroke
        ..strokeWidth = h * .0045
        ..color = core.withValues(alpha: .9 * appear);
      c.drawPath(wave, stroke);
      // The leading edge: a dark hairline just ahead, then white-hot.
      final ink = _ink.withValues(alpha: .85 * appear);
      if (flat) {
        c.drawRect(
          Rect.fromLTRB(xf - h * .004, y0, xf, y1),
          Paint()..color = ink,
        );
        c.drawRect(
          Rect.fromLTRB(xf, y0, xf + h * .008, y1),
          Paint()..color = core.withValues(alpha: appear),
        );
      } else {
        final path = line(lead!);
        stroke
          ..strokeWidth = h * .008
          ..color = ink;
        c.drawPath(path.shift(Offset(-h * .002, 0)), stroke);
        stroke
          ..strokeWidth = h * .008
          ..color = core.withValues(alpha: appear);
        c.drawPath(path.shift(Offset(h * .004, 0)), stroke);
      }
      // Bright lips where the band opens onto the gap; nothing crosses it.
      final gapEdge = gapBelow ? y1 : y0;
      if (gapEdge > 0 && gapEdge < h) {
        final x = edgeAt(gapEdge);
        final sign = gapBelow ? -1.0 : 1.0;
        c.drawRect(
          Rect.fromPoints(
            Offset(x - h * .004, gapEdge),
            Offset(x + thick, gapEdge + sign * h * .005),
          ),
          Paint()..color = _ink.withValues(alpha: .85 * appear),
        );
        c.drawRect(
          Rect.fromPoints(
            Offset(x, gapEdge + sign * h * .005),
            Offset(x + thick, gapEdge + sign * h * .016),
          ),
          Paint()..color = core.withValues(alpha: appear),
        );
      }
    }
  }

  // --------------------------------------------------------------- voice --

  /// Sound gathering in his jaws through the warning, the burst as the wall
  /// leaves and the ripples he keeps pouring out while it sweeps.
  static void _voice(Canvas c, double h, SkyBoss boss, BossMotion m) {
    if (!_active(boss) && !(boss.screeches && m.roar > 0)) return;
    final pose = BaronStormPose(m);
    final reduced = m.reducedMotion;
    final fury = boss.enraged;
    final hot = BaronStormArt.sonicOf(fury);
    const core = BaronStormArt.sonicCore;
    final at = mouth(boss, m, h);
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final gather = pose.gather;
    if (pose.warning > 0) {
      c.drawCircle(
        at,
        h * (.035 + .06 * gather),
        Paint()
          ..shader =
              RadialGradient(
                colors: [
                  hot.withValues(alpha: .35 + .45 * gather),
                  hot.withValues(alpha: 0),
                ],
              ).createShader(
                Rect.fromCircle(center: at, radius: h * (.035 + .06 * gather)),
              ),
      );
      // Rings drawn inward: the sound is being gathered.
      for (var i = 0; i < 3; i++) {
        final phase = reduced ? (i + .5) / 3 : (boss.age * 1.8 + i / 3) % 1;
        final r = h * (.022 + .11 * (1 - phase));
        final alpha = phase * (.3 + .6 * gather);
        c.drawCircle(
          at,
          r,
          ring
            ..strokeWidth = h * .006
            ..color = _ink.withValues(alpha: alpha * .35),
        );
        c.drawCircle(
          at,
          r,
          ring
            ..strokeWidth = h * .0035
            ..color = Color.lerp(hot, core, .4)!.withValues(alpha: alpha),
        );
      }
      c.drawCircle(at, h * (.006 + .012 * gather), Paint()..color = core);
      _earArcs(c, h, boss, m, pose, gather, hot);
    }
    final s = pose.sinceRelease;
    if (s != null && s < .5) {
      // The burst: rings thrown off his mouth and a white flash.
      final flash = 1 - BossMotion.ramp(s, 0, .16);
      if (flash > 0) {
        c.drawCircle(
          at,
          h * (.03 + .05 * (1 - flash)),
          Paint()..color = core.withValues(alpha: flash * .9),
        );
      }
      for (var i = 0; i < 3; i++) {
        final u = reduced
            ? BossMotion.ramp(s, 0, .5)
            : BossMotion.ramp(s, i * .06, .38 + i * .06);
        if (u <= 0 || u >= 1) continue;
        final e = 1 - (1 - u) * (1 - u) * (1 - u);
        final r = reduced
            ? h * (.07 + i * .045)
            : h * (.04 + e * (.26 + i * .05));
        final fade = 1 - u;
        c.drawCircle(
          at,
          r,
          ring
            ..strokeWidth = h * .014 * (1 - u * .5)
            ..color = _ink.withValues(alpha: fade * .25),
        );
        c.drawCircle(
          at,
          r,
          ring
            ..strokeWidth = h * .008 * (1 - u * .5)
            ..color = (i.isEven ? core : hot).withValues(alpha: fade * .9),
        );
      }
    }
    if (s != null || pose.voice > 0 || (boss.screeches && m.roar > 0)) {
      // Sound keeps pouring out of his jaws toward the bird.
      final pour = math.max(pose.voice, boss.screeches ? m.roar : 0);
      for (var i = 0; i < 3; i++) {
        final phase = reduced ? (i + .5) / 3 : (boss.age * 3.2 + i / 3) % 1;
        final r = h * (.03 + phase * .06);
        final x = at.dx - h * (.01 + phase * .12);
        final alpha = (1 - phase) * .8 * pour;
        if (alpha <= .02) continue;
        c.drawArc(
          Rect.fromCircle(center: Offset(x + r, at.dy), radius: r),
          math.pi - .7,
          1.4,
          false,
          ring
            ..strokeWidth = h * .006
            ..color = Color.lerp(hot, core, .3)!.withValues(alpha: alpha),
        );
      }
    }
  }

  /// Sonar arcs rising off his ear tips through the warning.
  static void _earArcs(
    Canvas c,
    double h,
    SkyBoss boss,
    BossMotion m,
    BaronStormPose pose,
    double gather,
    Color hot,
  ) {
    final tip = BaronStormArt.earTip(pose);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (final side in [-1.0, 1.0]) {
      final at = BaronStormRig.toScreen(
        boss,
        m,
        h,
        Offset(tip.dx * side, tip.dy),
      );
      // Pointing up and out from each ear.
      final angle = -math.pi / 2 + side * .7;
      for (var i = 0; i < 2; i++) {
        final phase = m.reducedMotion
            ? (i + .5) / 2
            : (boss.age * 2.2 + i / 2) % 1;
        final r = h * (.018 + phase * .045);
        final alpha = (1 - phase) * gather * .9;
        if (alpha <= .02) continue;
        c.drawArc(
          Rect.fromCircle(center: at, radius: r),
          angle - .6,
          1.2,
          false,
          paint
            ..strokeWidth = h * .005
            ..color = Color.lerp(
              hot,
              BaronStormArt.sonicCore,
              .35,
            )!.withValues(alpha: alpha),
        );
      }
    }
  }

  // ---------------------------------------------------------------- marks --

  /// Dashed edges along the lane, marching the way the wall will go.
  static void _edges(
    Canvas c,
    double h,
    SkyBoss boss,
    bool reduced,
    double limit,
    double show,
  ) {
    if (limit <= 0) return;
    final (top, bottom) = boss.screechOpening;
    final dash = h * .045, gap = h * .025;
    final march = reduced ? 0.0 : (boss.age * h * .3) % (dash + gap);
    final path = Path();
    for (final edge in [top, bottom]) {
      final y = edge * h;
      for (var x = limit - dash - march + gap; x > -dash; x -= dash + gap) {
        path
          ..moveTo(math.max(0, x), y)
          ..lineTo(math.min(limit, x + dash), y);
      }
    }
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    // A solid sonic line on the danger side, white dashes on the edge.
    final (top2, bottom2) = (top * h - h * .008, bottom * h + h * .008);
    final solid = Paint()
      ..strokeWidth = h * .004
      ..color = BaronStormArt.sonicOf(
        boss.enraged,
      ).withValues(alpha: .9 * show);
    c.drawLine(Offset(0, top2), Offset(limit, top2), solid);
    c.drawLine(Offset(0, bottom2), Offset(limit, bottom2), solid);
    c.drawPath(
      path,
      paint
        ..strokeWidth = h * .015
        ..color = _ink.withValues(alpha: .55 * show),
    );
    c.drawPath(
      path,
      paint
        ..strokeWidth = h * .008
        ..color = _safe.withValues(alpha: show),
    );
  }

  static final _painters = <String, TextPainter>{};

  static TextPainter _label(String value, double size) => _painters.putIfAbsent(
    '$value|${size.toStringAsFixed(1)}',
    () => TextPainter(
      text: TextSpan(
        text: value,
        style: heading(size, color: _text).copyWith(letterSpacing: size * .06),
      ),
      textDirection: TextDirection.ltr,
    )..layout(),
  );

  /// The tag at the left edge, inside the lane: a little wall with its gap
  /// lit, the instruction, and a gauge that fills until the screech and
  /// runs down as the wall sweeps.
  static void _tag(
    Canvas c,
    double h,
    SkyBoss boss,
    double show,
    bool warning,
    double t,
  ) {
    final (top, bottom) = boss.screechOpening;
    final label = warning ? 'FLY TO THE GAP' : 'HOLD THE GAP';
    final pad = h * .016, icon = h * .026;
    // Clear of the bird's column, like the dragon's tag.
    final room = (FlightSimulation.birdX - .085) * h - h * .03;
    final spare = room - (pad * 2 + icon + pad * .8);
    var text = _label(label, h * .044);
    if (text.width > spare) {
      text = _label(
        label,
        (h * .044 * spare / text.width * 10).floorToDouble() / 10,
      );
    }
    final tall = h * .074;
    final w = pad * 2 + icon + pad * .8 + text.width;
    final cy = (top + bottom) / 2 * h;
    final rect = Rect.fromLTWH(h * .03, cy - tall / 2, w, tall);
    final plate = RRect.fromRectAndRadius(rect, Radius.circular(tall * .3));
    c.drawRRect(
      plate.shift(Offset(0, h * .005)),
      Paint()..color = _ink.withValues(alpha: .45 * show),
    );
    c.drawRRect(plate, Paint()..color = _plate.withValues(alpha: .94 * show));
    c.drawRRect(
      plate,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * .005
        ..color = _safe.withValues(alpha: show),
    );
    // The little wall: three slots, the open one lit.
    final fury = boss.enraged;
    final slotH = tall * .2, slotGap = tall * .05;
    final x0 = rect.left + pad, total = slotH * 3 + slotGap * 2;
    for (final gap in ScreechGap.values) {
      final i = gap.index;
      final slot = Rect.fromLTWH(
        x0,
        rect.center.dy - total / 2 + i * (slotH + slotGap),
        icon,
        slotH,
      );
      final r = RRect.fromRectAndRadius(slot, Radius.circular(slotH * .25));
      if (gap == boss.screechGap) {
        c.drawRRect(
          r,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = h * .004
            ..color = _safe.withValues(alpha: show),
        );
      } else {
        c.drawRRect(
          r,
          Paint()..color = BaronStormArt.sonicOf(fury).withValues(alpha: show),
        );
      }
    }
    if (show > .5) {
      text.paint(
        c,
        Offset(
          x0 + icon + pad * .8,
          rect.center.dy - text.height / 2 - h * .004,
        ),
      );
    }
    final fill = warning
        ? boss.screechWarning
        : 1 - BossMotion.ramp(t, BaronScreech.screechAt, BaronScreech.endAt);
    if (fill <= 0) return;
    final gauge = Rect.fromLTWH(
      rect.left + tall * .3,
      rect.bottom - h * .011,
      (rect.width - tall * .6) * fill,
      h * .006,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(gauge, Radius.circular(h * .003)),
      Paint()
        ..color = (warning ? _safe : BaronStormArt.sonicOf(fury)).withValues(
          alpha: show,
        ),
    );
  }

  /// The wall has caught the bird outside the gap: a jolt of sound around
  /// it for as long as the band is on it.
  static void _jolt(
    Canvas c,
    double h,
    FlightSimulation sim,
    SkyBoss boss,
    BossMotion m,
  ) {
    const x = FlightSimulation.birdX, r = FlightSimulation.birdRadius;
    if (!boss.screechHits(x, sim.birdY, r)) return;
    final at = Offset(x * h, sim.birdY * h);
    final hot = BaronStormArt.sonicOf(boss.enraged);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    c.drawCircle(
      at,
      h * .075,
      paint
        ..strokeWidth = h * .012
        ..color = _ink.withValues(alpha: .35),
    );
    c.drawCircle(
      at,
      h * .075,
      paint
        ..strokeWidth = h * .006
        ..color = hot,
    );
    final shake = m.reducedMotion ? 0.0 : math.sin(boss.age * 90) * .15;
    final rays = Path();
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4 + .39 + shake;
      final d = Offset(math.cos(a), math.sin(a));
      final n = Offset(-d.dy, d.dx);
      final p0 = at + d * h * .088;
      final p1 = at + d * h * .1 + n * h * .008;
      final p2 = at + d * h * .112 - n * h * .008;
      final p3 = at + d * h * .124;
      rays
        ..moveTo(p0.dx, p0.dy)
        ..lineTo(p1.dx, p1.dy)
        ..lineTo(p2.dx, p2.dy)
        ..lineTo(p3.dx, p3.dy);
    }
    c.drawPath(
      rays,
      paint
        ..strokeWidth = h * .005
        ..color = BaronStormArt.sonicCore,
    );
  }
}
