import 'dart:math' as math;
import 'dart:ui';

import '../domain/steam_geyser.dart';
import 'steam_geyser_kit.dart';

/// What a steam vent stands on: a brick roof block under limestone coping
/// (the New York gates' own bricks and ink) carrying one of three emitters.
///
/// * a **cast-iron manhole cover** for a short plume (hop vents): stone
///   collar ringed with caution dashes, studs, slots that glow amber;
/// * a **subway grate** for a ride vent: a rectangular iron grille whose bars
///   glow teal, an up-chevron cast into its lip;
/// * a **Con Ed stack** for a tall plume (the rooftop pipe vent): tapering
///   orange and white enamel, guy wires, a flared lip over a throat that
///   glows.
///
/// A little pressure gauge on the block's face swings into the red as the
/// hiss builds. The lid kicks up at the burst and settles; Reduced Motion
/// holds it still.
abstract final class SteamEmitterArt {
  /// Where the coping's top edge sits, and the block's half-width.
  static const slab = .925, half = .19;

  /// How much taller than the rules' mouth a Con Ed stack stands: its lip is
  /// this far above the hit box's bottom edge (the steam shows from the lip;
  /// the hit box itself is the rules').
  static const stackRise = .031;

  /// The y the visible steam leaves a vent's mouth, in pixels.
  static double lipY(SteamVent v, double h) =>
      v.mouth * h - (v.top < SteamCycle.stackBelow ? stackRise * h : 0);

  static Paint _ink(double h, [double w = .0065]) => Paint()
    ..color = SteamTones.ink
    ..style = PaintingStyle.stroke
    ..strokeWidth = h * w
    ..strokeJoin = StrokeJoin.round
    ..strokeCap = StrokeCap.round;

  /// The glow tone of a vent's throat: amber when hot, teal when soft.
  static Color mouthTone(SteamKind kind, SteamBeat b) {
    if (b.billow) return SteamTones.teal;
    if (b.hiss && kind == SteamKind.ride) return SteamTones.teal;
    return SteamTones.amber;
  }

  static void paint(
    Canvas c,
    double h,
    double cx,
    SteamVent v,
    SteamBeat b,
    double clock,
    bool rm,
    int seed,
  ) {
    final tall = v.top < SteamCycle.stackBelow;
    final tone = mouthTone(v.kind, b);
    final lid = (rm ? b.restLid : b.lid) * h;
    final chatter = rm || !b.hiss
        ? 0.0
        : math.sin(clock * 38 + seed) * h * .0025 * b.p * b.p;
    // A sleeping vent keeps a dull ember in its throat and slots.
    final heat = math.max(b.heat, .14);
    _block(c, h, cx, b.heat, seed, tone);
    _gauge(c, h, cx, b);
    _wheel(c, h, cx, b);
    if (tall) {
      _stack(c, h, cx, lipY(v, h), heat, tone, lid + chatter, v.kind);
    } else if (v.kind == SteamKind.ride) {
      _grate(c, h, cx, heat, tone, lid + chatter, b);
    } else {
      _cover(c, h, cx, heat, tone, lid + chatter, seed, b);
    }
    if (_roosts(v)) _pigeon(c, h, cx, b, clock, rm);
  }

  /// Whether a pigeon warms itself on this vent: seeded by the slot, so a
  /// vent keeps its pigeon for the whole flight.
  static bool _roosts(SteamVent v) =>
      SteamMath.hash(v.geyser.slot, 7) < .4 && !(v.top < SteamCycle.stackBelow);

  // ---------------------------------------------------------------------
  // The roof

  static void _block(
    Canvas c,
    double h,
    double cx,
    double heat,
    int seed,
    Color tone,
  ) {
    final top = h * slab, hw = h * half;
    final block = Rect.fromLTRB(cx - hw, top, cx + hw, h + 2);
    final tint = SteamMath.hash(seed, 3);
    c.drawRect(
      block,
      Paint()
        ..color = Color.lerp(SteamTones.brick, SteamTones.brickLit, tint * .3)!,
    );
    c.drawRect(
      Rect.fromLTRB(cx - hw, top, cx + hw, top + h * .014),
      Paint()..color = SteamTones.brickLit,
    );
    c.drawRect(
      Rect.fromLTRB(cx + hw * .55, top + h * .014, cx + hw, h + 2),
      Paint()..color = SteamTones.brickShade.withValues(alpha: .55),
    );
    final courses = Path();
    for (var y = top + h * .03; y < h; y += h * .022) {
      courses
        ..moveTo(cx - hw, y)
        ..lineTo(cx + hw, y);
    }
    // Every other course breaks its joints: short vertical ticks.
    var row = 0;
    for (var y = top + h * .014; y < h; y += h * .022, row++) {
      for (
        var x = cx - hw + h * (row.isEven ? .04 : .07);
        x < cx + hw;
        x += h * .066
      ) {
        courses
          ..moveTo(x, y + h * .004)
          ..lineTo(x, y + h * .02);
      }
    }
    c.drawPath(
      courses,
      Paint()
        ..color = SteamTones.brickShade.withValues(alpha: .5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * .0028,
    );
    // Limestone coping with a shadow line under it.
    final coping = Rect.fromLTRB(
      cx - hw - h * .012,
      top - h * .012,
      cx + hw + h * .012,
      top + h * .004,
    );
    c.drawRect(coping, Paint()..color = SteamTones.stone);
    c.drawRect(
      Rect.fromLTRB(
        coping.left,
        coping.bottom - h * .004,
        coping.right,
        coping.bottom,
      ),
      Paint()..color = SteamTones.stoneShade,
    );
    // The vent's own light washes the coping.
    if (heat > 0) {
      c.drawOval(
        Rect.fromCenter(
          center: Offset(cx, top - h * .006),
          width: h * .30,
          height: h * .02,
        ),
        Paint()..color = tone.withValues(alpha: .34 * heat),
      );
    }
    final ink = _ink(h)..isAntiAlias = true;
    c.drawPath(
      Path()
        ..addRect(coping)
        ..addRect(block),
      ink,
    );
  }

  /// A brass gauge on the block's face: its needle swings into the red zone
  /// as pressure builds, a readable second warning for the careful.
  static void _gauge(Canvas c, double h, double cx, SteamBeat b) {
    final at = Offset(cx - h * half * .55, h * (slab + .040));
    final r = h * .019;
    final pressure = switch (b.phase) {
      SteamPhase.hiss => .12 + .88 * SteamMath.smooth(b.p),
      SteamPhase.burst => 1.0,
      SteamPhase.billow => 1 - .8 * SteamMath.smooth(b.billowT / .6),
      SteamPhase.sleep => .12,
    };
    c.drawCircle(at, r + h * .0035, Paint()..color = SteamTones.ink);
    c.drawCircle(at, r + h * .0008, Paint()..color = SteamTones.brass);
    c.drawCircle(at, r * .8, Paint()..color = SteamTones.dial);
    // The red zone on the right of the dial.
    c.drawArc(
      Rect.fromCircle(center: at, radius: r * .62),
      .05,
      1.05,
      false,
      Paint()
        ..color = SteamTones.ember
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * .0040,
    );
    final a = math.pi * (.80 + 1.4 * pressure);
    c.drawLine(
      at,
      at + Offset(math.cos(a), math.sin(a)) * r * .72,
      Paint()
        ..color = SteamTones.ink
        ..strokeWidth = h * .0032
        ..strokeCap = StrokeCap.round,
    );
  }

  /// A red handwheel on the block's face: it turns as pressure is let in and
  /// stays open through the burst and the billow (state, not decoration, so
  /// Reduced Motion shows it too).
  static void _wheel(Canvas c, double h, double cx, SteamBeat b) {
    final at = Offset(cx + h * half * .55, h * (slab + .040));
    final r = h * .019;
    final turn = switch (b.phase) {
      SteamPhase.hiss => 1.9 * SteamMath.smooth(b.p),
      SteamPhase.sleep => 0.0,
      _ => 1.9,
    };
    c.drawCircle(at, r + h * .0035, Paint()..color = SteamTones.ink);
    c.drawCircle(at, r, Paint()..color = SteamTones.valve);
    c.drawCircle(at, r * .66, Paint()..color = SteamTones.brickShade);
    final spokes = Path();
    for (var i = 0; i < 3; i++) {
      final a = turn + i * math.pi / 3;
      final d = Offset(math.cos(a), math.sin(a)) * r * .92;
      spokes
        ..moveTo(at.dx - d.dx, at.dy - d.dy)
        ..lineTo(at.dx + d.dx, at.dy + d.dy);
    }
    c.drawPath(
      spokes,
      Paint()
        ..color = SteamTones.valve
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * .0034
        ..strokeCap = StrokeCap.round,
    );
  }

  // ---------------------------------------------------------------------
  // Emitters

  /// The hop vent's iron cover on a stone collar.
  static void _cover(
    Canvas c,
    double h,
    double cx,
    double heat,
    Color tone,
    double lid,
    int seed,
    SteamBeat b,
  ) {
    final base = h * slab;
    final collar = Rect.fromCenter(
      center: Offset(cx, base - h * .004),
      width: h * .17,
      height: h * .044,
    );
    c.drawOval(collar, Paint()..color = SteamTones.stoneShade);
    c.drawOval(
      collar.deflate(h * .004).translate(0, -h * .004),
      Paint()..color = SteamTones.stone,
    );
    // Caution dashes around the collar.
    final dashes = Path();
    for (var i = 0; i < 12; i++) {
      final a = i * math.pi * 2 / 12;
      final o = Offset(
        cx + math.cos(a) * h * .0745,
        base - h * .004 + math.sin(a) * h * .0175,
      );
      dashes
        ..moveTo(o.dx - h * .004, o.dy)
        ..lineTo(o.dx + h * .004, o.dy);
    }
    c.drawPath(
      dashes,
      Paint()
        ..color = SteamTones.ember.withValues(alpha: .9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * .0042
        ..strokeCap = StrokeCap.round,
    );
    c.drawOval(collar, _ink(h));
    final disc = Rect.fromCenter(
      center: Offset(cx, base - h * .009 - lid),
      width: h * .135,
      height: h * .032,
    );
    c.drawOval(disc, Paint()..color = SteamTones.iron);
    c.drawOval(
      disc.deflate(h * .009),
      Paint()
        ..color = SteamTones.ironLit
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * .0035,
    );
    final studs = Path();
    for (var i = 0; i < 9; i++) {
      final a = i * math.pi * 2 / 9;
      studs.addOval(
        Rect.fromCircle(
          center:
              disc.center +
              Offset(math.cos(a) * h * .040, math.sin(a) * h * .0085),
          radius: h * .0024,
        ),
      );
    }
    c.drawPath(studs, Paint()..color = SteamTones.ironLit);
    final slots = Path();
    for (var i = -1; i <= 1; i++) {
      final x = cx + i * h * .022;
      slots
        ..moveTo(x, disc.center.dy - h * .0055)
        ..lineTo(x, disc.center.dy + h * .0055);
    }
    c.drawPath(
      slots,
      Paint()
        ..color = Color.lerp(SteamTones.ironLit, SteamTones.hotRoot, heat)!
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * .0055
        ..strokeCap = StrokeCap.round,
    );
    // A rim light along the cover's upper-left edge.
    c.drawArc(
      disc.deflate(h * .0015),
      math.pi * 1.05,
      math.pi * .5,
      false,
      Paint()
        ..color = SteamTones.ironRim
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * .0028
        ..strokeCap = StrokeCap.round,
    );
    c.drawOval(disc, _ink(h, .0055));
  }

  /// The ride vent's subway grate: iron bars over a teal-lit shaft.
  static void _grate(
    Canvas c,
    double h,
    double cx,
    double heat,
    Color tone,
    double lid,
    SteamBeat b,
  ) {
    final base = h * slab;
    final cy = base - h * .010 - lid;
    // The frame: a low trapezoid, wider at the front edge.
    final frame = Path()
      ..moveTo(cx - h * .066, cy - h * .014)
      ..lineTo(cx + h * .066, cy - h * .014)
      ..lineTo(cx + h * .086, cy + h * .014)
      ..lineTo(cx - h * .086, cy + h * .014)
      ..close();
    c.drawPath(
      frame,
      Paint()..color = Color.lerp(SteamTones.stoneShade, SteamTones.teal, .42)!,
    );
    final well = Path()
      ..moveTo(cx - h * .054, cy - h * .009)
      ..lineTo(cx + h * .054, cy - h * .009)
      ..lineTo(cx + h * .071, cy + h * .008)
      ..lineTo(cx - h * .071, cy + h * .008)
      ..close();
    // What the shaft shows between the bars: dark when quiet, teal-lit as
    // the vent breathes.
    c.drawPath(
      well,
      Paint()
        ..color = Color.lerp(
          SteamTones.iron,
          tone == SteamTones.teal ? SteamTones.tealDeep : SteamTones.ember,
          .15 + .75 * heat,
        )!,
    );
    final bars = Path();
    for (var i = -3; i <= 3; i++) {
      bars
        ..moveTo(cx + i * h * .0165, cy - h * .009)
        ..lineTo(cx + i * h * .0215, cy + h * .008);
    }
    c.drawPath(
      bars,
      Paint()
        ..color = Color.lerp(
          SteamTones.ironLit,
          tone == SteamTones.teal ? SteamTones.tealGlow : SteamTones.hotRoot,
          heat * .8,
        )!
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * .0062
        ..strokeCap = StrokeCap.butt,
    );
    c.drawPath(frame, _ink(h, .0055));
    c.drawPath(well, _ink(h, .003));
    // An up chevron cast into the front lip: this one lifts.
    c.drawPath(
      Path()
        ..moveTo(cx - h * .012, cy + h * .0115)
        ..lineTo(cx, cy + h * .0095 - h * .0035)
        ..lineTo(cx + h * .012, cy + h * .0115),
      Paint()
        ..color = SteamTones.teal
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * .003
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  /// The Con Ed stack: orange and white enamel, tapering, guyed to the roof,
  /// with a flared lip over a throat that glows.
  static void _stack(
    Canvas c,
    double h,
    double cx,
    double mouthY,
    double heat,
    Color tone,
    double lid,
    SteamKind kind,
  ) {
    final baseY = h * (slab - .012);
    final bw = h * .034, tw = h * .023, ht = baseY - mouthY;
    double wAt(double y) => tw + (bw - tw) * ((y - mouthY) / ht);
    final body = Path()
      ..moveTo(cx - bw, baseY)
      ..lineTo(cx - tw, mouthY)
      ..lineTo(cx + tw, mouthY)
      ..lineTo(cx + bw, baseY)
      ..close();
    // Guy wires from two thirds up to the coping.
    final guy = Path();
    final gy = mouthY + ht * .30;
    for (final k in [-1.0, 1.0]) {
      guy
        ..moveTo(cx + k * wAt(gy), gy)
        ..lineTo(cx + k * h * .15, h * slab - h * .012);
    }
    c.drawPath(
      guy,
      Paint()
        ..color = SteamTones.ink.withValues(alpha: .75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * .0028,
    );
    c.drawPath(body, Paint()..color = SteamTones.stripeWhite);
    final bands = Path();
    const n = 6;
    for (var i = 0; i < n; i += 2) {
      final y0 = mouthY + ht * i / n, y1 = mouthY + ht * (i + 1) / n;
      const dip = .0035;
      bands
        ..moveTo(cx - wAt(y0), y0)
        ..quadraticBezierTo(cx, y0 + h * dip * 2, cx + wAt(y0), y0)
        ..lineTo(cx + wAt(y1), y1)
        ..quadraticBezierTo(cx, y1 + h * dip * 2, cx - wAt(y1), y1)
        ..close();
    }
    final teal = kind == SteamKind.ride;
    c.drawPath(
      bands,
      Paint()..color = teal ? SteamTones.teal : SteamTones.stripe,
    );
    // Moonlit left, shaded right: a tapered shadow and a gloss line.
    c.drawPath(
      Path()
        ..moveTo(cx + tw * .30, mouthY)
        ..lineTo(cx + tw, mouthY)
        ..lineTo(cx + bw, baseY)
        ..lineTo(cx + bw * .30, baseY)
        ..close(),
      Paint()..color = SteamTones.brickShade.withValues(alpha: .34),
    );
    c.drawLine(
      Offset(cx - tw * .52, mouthY + h * .010),
      Offset(cx - bw * .52, baseY - h * .012),
      Paint()
        ..color = const Color(0xffffffff).withValues(alpha: .75)
        ..strokeWidth = h * .0034
        ..strokeCap = StrokeCap.round,
    );
    c.drawPath(body, _ink(h));
    // Flared lip and a dark throat that glows when hot.
    final lipRect = Rect.fromCenter(
      center: Offset(cx, mouthY - lid),
      width: tw * 2 + h * .03,
      height: h * .016,
    );
    final lip = RRect.fromRectAndRadius(lipRect, Radius.circular(h * .006));
    c.drawRRect(lip, Paint()..color = SteamTones.iron);
    c.drawLine(
      Offset(lipRect.left + h * .006, lipRect.top + h * .0035),
      Offset(lipRect.center.dx - h * .004, lipRect.top + h * .0035),
      Paint()
        ..color = SteamTones.ironRim
        ..strokeWidth = h * .0028
        ..strokeCap = StrokeCap.round,
    );
    c.drawRRect(lip, _ink(h, .0055));
    c.drawOval(
      Rect.fromCenter(
        center: Offset(cx, mouthY - lid - h * .004),
        width: tw * 2 + h * .012,
        height: h * .011,
      ),
      Paint()..color = Color.lerp(SteamTones.iron, tone, heat)!,
    );
  }

  // ---------------------------------------------------------------------
  // A pigeon that warms itself on the vent

  /// It roosts on the coping beside the cover, flaps away as the hiss
  /// builds and flutters back down while the vent sleeps. Cosmetic.
  static void _pigeon(
    Canvas c,
    double h,
    double cx,
    SteamBeat b,
    double clock,
    bool rm,
  ) {
    var gone = switch (b.phase) {
      SteamPhase.hiss => SteamMath.smooth((b.p - .15) / .35),
      SteamPhase.sleep => 1 - SteamMath.smooth((b.t - 1.75) / .65),
      _ => 1.0,
    };
    // With Reduced Motion it is simply there or not: no flight.
    if (rm) gone = gone < .5 ? 0 : 1;
    if (gone >= 1) return;
    final s = h * .020;
    final perch = Offset(cx + h * .118, h * (slab - .012) - s * .55);
    final flap = rm ? 0.0 : math.sin(clock * 24) * .5;
    final o =
        perch + Offset(gone * h * .16, -gone * h * .22 - gone * gone * h * .1);
    final airborne = gone > .02;
    final body = Path()
      ..addOval(Rect.fromCenter(center: o, width: s * 2.3, height: s * 1.5))
      ..addOval(
        Rect.fromCircle(
          center: o + Offset(-s * 1.05, -s * .65),
          radius: s * .62,
        ),
      )
      ..addPath(
        Path()
          ..moveTo(o.dx + s * 1.0, o.dy - s * .15)
          ..lineTo(o.dx + s * 2.0, o.dy + s * (airborne ? .1 : .25))
          ..lineTo(o.dx + s * 1.0, o.dy + s * .5)
          ..close(),
        Offset.zero,
      );
    c.drawPath(body, _ink(h, .007));
    c.drawPath(body, Paint()..color = SteamTones.pigeon);
    // Dark tail feathers and a wing, an iridescent patch on the neck, a beak
    // toward the vent and a bright eye.
    c.drawPath(
      Path()
        ..moveTo(o.dx + s * 1.05, o.dy - s * .05)
        ..lineTo(o.dx + s * 1.95, o.dy + s * (airborne ? .1 : .25))
        ..lineTo(o.dx + s * 1.05, o.dy + s * .42)
        ..close(),
      Paint()..color = SteamTones.pigeonShade,
    );
    if (!airborne) {
      c.drawOval(
        Rect.fromCenter(
          center: o + Offset(s * .2, s * .05),
          width: s * 1.45,
          height: s * .85,
        ),
        Paint()..color = SteamTones.pigeonShade,
      );
    }
    c.drawCircle(
      o + Offset(-s * .78, -s * .3),
      s * .3,
      Paint()..color = SteamTones.neck,
    );
    c.drawPath(
      Path()
        ..moveTo(o.dx - s * 1.6, o.dy - s * .7)
        ..lineTo(o.dx - s * 2.15, o.dy - s * .55)
        ..lineTo(o.dx - s * 1.6, o.dy - s * .45)
        ..close(),
      Paint()..color = SteamTones.beak,
    );
    if (airborne) {
      c.drawPath(
        Path()
          ..moveTo(o.dx + s * .1, o.dy - s * .3)
          ..quadraticBezierTo(
            o.dx + s * .9,
            o.dy - s * (1.4 + flap),
            o.dx + s * 1.6,
            o.dy - s * (.4 + flap),
          ),
        _ink(h, .0045),
      );
    }
    final eye = o + Offset(-s * 1.2, -s * .75);
    c.drawCircle(eye, s * .2, Paint()..color = SteamTones.dial);
    c.drawCircle(
      eye + Offset(-s * .03, 0),
      s * .1,
      Paint()..color = SteamTones.ink,
    );
  }
}
