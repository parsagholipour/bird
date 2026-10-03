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
    // Soft steam is teal from first to last: a ride vent never turns hot.
    if (kind == SteamKind.ride || b.billow) return SteamTones.teal;
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
      _grate(c, h, cx, heat, tone, lid + chatter, b, clock, rm);
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

  static final _brickCache = <int, (Path, Path)>{};

  /// The block's bricks as two paths (ordinary, darker), centred on x = 0 and
  /// cached: they never change for a given size and vent.
  static (Path, Path) _bricks(double h, int seed) {
    final key = (h * 8).round() * 100003 + seed;
    final hit = _brickCache[key];
    if (hit != null) return hit;
    if (_brickCache.length > 24) _brickCache.clear();
    final top = h * slab, hw = h * half;
    final mid = Path(), dark = Path();
    for (var row = 0; row < 3; row++) {
      final y0 = top + h * (.0165 + row * .0205);
      for (var col = -1; col < 8; col++) {
        final x0 = -hw + (row.isOdd ? h * .026 : 0) + col * h * .0525;
        final l = math.max(x0 + h * .0015, -hw + h * .0015);
        final r = math.min(x0 + h * .0525 - h * .0015, hw - h * .0015);
        if (r - l < h * .01) continue;
        final t = SteamMath.hash(seed + row * 7 + col, 3);
        (t < .86 ? mid : dark).addRect(Rect.fromLTRB(l, y0, r, y0 + h * .0185));
      }
    }
    return _brickCache[key] = (mid, dark);
  }

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
    // Mortar first; the bricks sit on it with a hair of gap between them.
    c.drawRect(block, Paint()..color = SteamTones.mortar);
    // The bricks are built once per size and seed, centred on x = 0.
    final (mid, dark) = _bricks(h, seed);
    c.save();
    c.translate(cx, 0);
    c.drawPath(mid, Paint()..color = SteamTones.brick);
    c.drawPath(
      dark,
      Paint()
        ..color = Color.lerp(SteamTones.brick, SteamTones.brickShade, .55)!,
    );
    c.restore();
    // The right face turns from the moon: a shaded band.
    c.drawRect(
      Rect.fromLTRB(cx + hw * .62, top + h * .014, cx + hw, h + 2),
      Paint()..color = SteamTones.ink.withValues(alpha: .16),
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
    // The vent's own light washes the coping and the bricks under it.
    if (heat > 0) {
      c.drawOval(
        Rect.fromCenter(
          center: Offset(cx, top - h * .006),
          width: h * .34,
          height: h * .022,
        ),
        Paint()..color = tone.withValues(alpha: .34 * heat),
      );
      for (final (w, a) in const [(.28, .08), (.12, .14)]) {
        c.drawRect(
          Rect.fromCenter(
            center: Offset(cx, top + h * .020),
            width: h * w,
            height: h * .040,
          ).intersect(block),
          Paint()..color = tone.withValues(alpha: a * heat),
        );
      }
    }
    // A darker contact band where the emitter stands, and a parapet drain
    // (scupper) with a rust stain on the block's face.
    c.drawRect(
      Rect.fromCenter(
        center: Offset(cx, top - h * .004),
        width: h * .205,
        height: h * .009,
      ),
      Paint()..color = SteamTones.ink.withValues(alpha: .30),
    );
    final scupper = Rect.fromLTWH(
      cx - hw + h * .020,
      top + h * .046,
      h * .030,
      h * .014,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(scupper, Radius.circular(h * .003)),
      Paint()..color = SteamTones.ironDeep,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(scupper, Radius.circular(h * .003)),
      _ink(h, .0035),
    );
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

  /// The hop vent's cast-iron cover in its frame: a raised lip with caution
  /// dashes and bolts, studs and glowing slots in the lid, a slit of light
  /// under it when it kicks up.
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
    final cy = base - h * .005;
    // Contact shadow on the coping.
    c.drawOval(
      Rect.fromCenter(
        center: Offset(cx + h * .004, base),
        width: h * .190,
        height: h * .024,
      ),
      Paint()..color = SteamTones.ink.withValues(alpha: .42),
    );
    // A raised concrete curb with hazard stripes down its front: the lid sits
    // on a recognisable object, not flat on the coping.
    final riser = h * .021;
    final cw = h * .164;
    final topE = Rect.fromCenter(
      center: Offset(cx, cy - riser),
      width: cw,
      height: h * .040,
    );
    final topCy = topE.center.dy, halfW = cw / 2, halfH = topE.height / 2;
    double arcY(double x) =>
        topCy +
        halfH * math.sqrt(math.max(0.0, 1 - math.pow((x - cx) / halfW, 2)));
    final face = Path()..moveTo(cx - halfW, topCy);
    for (var i = 0; i <= 12; i++) {
      final x = cx - halfW + cw * i / 12;
      face.lineTo(x, arcY(x) + riser);
    }
    face.lineTo(cx + halfW, topCy);
    for (var i = 12; i >= 0; i--) {
      final x = cx - halfW + cw * i / 12;
      face.lineTo(x, arcY(x));
    }
    face.close();
    c.drawPath(face, Paint()..color = SteamTones.stone);
    final stripes = Path();
    for (var x = cx - halfW + h * .004; x < cx + halfW - riser; x += h * .026) {
      final x2 = x + riser * .8;
      stripes
        ..moveTo(x, arcY(x) + h * .001)
        ..lineTo(x2, arcY(x2) + riser - h * .001);
    }
    c.drawPath(
      stripes,
      Paint()
        ..color = SteamTones.ember
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * .0090,
    );
    // The right side turns from the light.
    c.drawPath(
      Path()
        ..moveTo(cx + halfW * .55, arcY(cx + halfW * .55))
        ..lineTo(cx + halfW * .55, arcY(cx + halfW * .55) + riser)
        ..lineTo(cx + halfW, topCy + riser)
        ..lineTo(cx + halfW, topCy)
        ..close(),
      Paint()..color = SteamTones.ink.withValues(alpha: .22),
    );
    c.drawPath(face, _ink(h, .0050));
    // The iron ring on top of the curb, bolted down.
    final frame = topE;
    c.drawOval(frame, Paint()..color = SteamTones.ironLit);
    final bolts = Path();
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi * 2 / 8 + .4;
      bolts.addOval(
        Rect.fromCircle(
          center: Offset(
            cx + math.cos(a) * h * .0690,
            topCy + math.sin(a) * h * .0160,
          ),
          radius: h * .0021,
        ),
      );
    }
    c.drawOval(frame, _ink(h, .0045));
    // The slit of light the lid leaves when it kicks up.
    final disc = Rect.fromCenter(
      center: Offset(cx, topCy - h * .002 - lid),
      width: h * .124,
      height: h * .031,
    );
    if (heat > .2 && lid > h * .0006) {
      c.drawOval(
        Rect.fromCenter(
          center: Offset(cx, topCy),
          width: h * .124,
          height: h * .031,
        ),
        Paint()..color = SteamTones.hotRoot.withValues(alpha: .95),
      );
    }
    c.drawOval(
      disc.shift(Offset(0, h * .005)),
      Paint()..color = SteamTones.ironDeep,
    );
    c.drawOval(disc, Paint()..color = SteamTones.ironLit);
    c.drawOval(disc.deflate(h * .0035), Paint()..color = SteamTones.iron);
    // Cast ring, studs, glowing slots, a boss in the middle.
    final studs = Path();
    for (var i = 0; i < 10; i++) {
      final a = i * math.pi * 2 / 10;
      studs.addOval(
        Rect.fromCircle(
          center:
              disc.center +
              Offset(math.cos(a) * h * .047, math.sin(a) * h * .0105),
          radius: h * .0020,
        ),
      );
    }
    studs.addPath(bolts, Offset.zero);
    c.drawPath(studs, Paint()..color = SteamTones.ironRim);
    final slots = Path();
    for (var i = 0; i < 7; i++) {
      final a = i * math.pi * 2 / 7 + .45;
      Offset at(double k) =>
          disc.center +
          Offset(math.cos(a) * h * .060 * k, math.sin(a) * h * .0132 * k);
      slots
        ..moveTo(at(.30).dx, at(.30).dy)
        ..lineTo(at(.62).dx, at(.62).dy);
    }
    c.drawPath(
      slots,
      Paint()
        ..color = Color.lerp(SteamTones.ironLit, SteamTones.hotRoot, heat)!
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * .0042
        ..strokeCap = StrokeCap.round,
    );
    // A rim light along the lid's upper-left edge and a spot of wet sheen.
    c.drawArc(
      disc.deflate(h * .0012),
      math.pi * 1.05,
      math.pi * .5,
      false,
      Paint()
        ..color = SteamTones.ironRim
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * .0028
        ..strokeCap = StrokeCap.round,
    );
    c.drawOval(disc, _ink(h, .0052));
  }

  /// The ride vent's subway grate: a steel frame on a raised lip, bars over a
  /// teal-lit shaft, a newspaper page that lifts in the draught.
  static void _grate(
    Canvas c,
    double h,
    double cx,
    double heat,
    Color tone,
    double lid,
    SteamBeat b,
    double clock,
    bool rm,
  ) {
    final base = h * slab;
    final cy = base - h * .012 - lid;
    c.drawOval(
      Rect.fromCenter(
        center: Offset(cx + h * .004, base),
        width: h * .200,
        height: h * .022,
      ),
      Paint()..color = SteamTones.ink.withValues(alpha: .42),
    );
    // The frame: a low trapezoid, wider at the front edge, with a lip.
    final frame = Path()
      ..moveTo(cx - h * .068, cy - h * .014)
      ..lineTo(cx + h * .068, cy - h * .014)
      ..lineTo(cx + h * .088, cy + h * .014)
      ..lineTo(cx - h * .088, cy + h * .014)
      ..close();
    final lip = Path()
      ..moveTo(cx - h * .088, cy + h * .014)
      ..lineTo(cx + h * .088, cy + h * .014)
      ..lineTo(cx + h * .088, cy + h * .021)
      ..lineTo(cx - h * .088, cy + h * .021)
      ..close();
    c.drawPath(lip, Paint()..color = SteamTones.ironDeep);
    c.drawPath(
      frame,
      Paint()..color = Color.lerp(SteamTones.ironLit, SteamTones.teal, .42)!,
    );
    final well = Path()
      ..moveTo(cx - h * .056, cy - h * .009)
      ..lineTo(cx + h * .056, cy - h * .009)
      ..lineTo(cx + h * .073, cy + h * .008)
      ..lineTo(cx - h * .073, cy + h * .008)
      ..close();
    final cool = tone == SteamTones.teal;
    c.drawPath(
      well,
      Paint()
        ..color = Color.lerp(
          SteamTones.ironDeep,
          cool ? SteamTones.tealDeep : SteamTones.ember,
          .15 + .75 * heat,
        )!,
    );
    // Bars, each with a lit top edge; two cross ties.
    final bars = Path(), tops = Path();
    for (var i = -3; i <= 3; i++) {
      bars
        ..moveTo(cx + i * h * .0165, cy - h * .009)
        ..lineTo(cx + i * h * .0215, cy + h * .008);
      tops
        ..moveTo(cx + i * h * .0165 - h * .0016, cy - h * .009)
        ..lineTo(cx + i * h * .0215 - h * .0016, cy + h * .008);
    }
    // The slot field lights up with the pressure: the grate's own clock.
    final slits = Path();
    for (var i = -3; i < 3; i++) {
      slits
        ..moveTo(cx + (i + .5) * h * .0165, cy - h * .008)
        ..lineTo(cx + (i + .5) * h * .0215, cy + h * .007);
    }
    c.drawPath(
      slits,
      Paint()
        ..color = SteamTones.tealGlow.withValues(
          alpha: math.min(1.0, .10 + 1.1 * heat),
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * .0058,
    );
    c.drawPath(
      bars,
      Paint()
        ..color = SteamTones.ironDeep
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * .0068
        ..strokeCap = StrokeCap.butt,
    );
    c.drawPath(
      tops,
      Paint()
        ..color = Color.lerp(
          SteamTones.ironRim,
          cool ? SteamTones.tealGlow : SteamTones.hotRoot,
          heat * .85,
        )!
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * .0030
        ..strokeCap = StrokeCap.butt,
    );
    c.drawPath(
      Path()
        ..moveTo(cx - h * .0645, cy - h * .002)
        ..lineTo(cx + h * .0645, cy - h * .002),
      Paint()
        ..color = SteamTones.ironDeep
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * .0034,
    );
    c.drawPath(frame, _ink(h, .0055));
    c.drawPath(lip, _ink(h, .0040));
    c.drawPath(well, _ink(h, .003));
    // An up chevron cast into the front lip: this one lifts.
    c.drawPath(
      Path()
        ..moveTo(cx - h * .012, cy + h * .0120)
        ..lineTo(cx, cy + h * .0095 - h * .0035)
        ..lineTo(cx + h * .012, cy + h * .0120),
      Paint()
        ..color = SteamTones.tealGlow
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * .0030
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    _page(c, h, cx, cy, b, clock, rm);
  }

  /// A newspaper page on the grate: it lies there asleep, stirs and lifts as
  /// the hiss builds and rides the billow up (a New York grate must have one).
  static void _page(
    Canvas c,
    double h,
    double cx,
    double cy,
    SteamBeat b,
    double clock,
    bool rm,
  ) {
    final lift = switch (b.phase) {
      SteamPhase.sleep => 0.0,
      SteamPhase.hiss => .02 * SteamMath.smooth((b.p - .35) / .6),
      SteamPhase.burst => .02 + .02 * b.p,
      SteamPhase.billow => .04 + .13 * SteamMath.smooth(b.billowT / 1.0),
    };
    final out = switch (b.phase) {
      SteamPhase.sleep => 0.0,
      SteamPhase.hiss => 0.0,
      SteamPhase.burst => .01 * b.p,
      SteamPhase.billow => .01 + .05 * SteamMath.smooth(b.billowT / 1.0),
    };
    if (b.phase == SteamPhase.billow && b.billowT > 1.05) return;
    final flutter = rm ? .3 : math.sin(clock * 11) * (.2 + 3.2 * lift);
    final o = Offset(cx + h * (.036 + out), cy - h * (.002 + lift));
    final w = h * .017, d = h * .008;
    final ca = math.cos(flutter), sa = math.sin(flutter);
    Offset q(double x, double y) =>
        o + Offset(x * ca - y * sa, x * sa + y * ca);
    final page = Path()
      ..moveTo(q(-w, -d).dx, q(-w, -d).dy)
      ..lineTo(q(w, -d * .6).dx, q(w, -d * .6).dy)
      ..lineTo(q(w * .8, d).dx, q(w * .8, d).dy)
      ..lineTo(q(-w * .9, d * .8).dx, q(-w * .9, d * .8).dy)
      ..close();
    final fade = b.phase == SteamPhase.billow
        ? 1 - SteamMath.smooth((b.billowT - .8) / .25)
        : 1.0;
    c.drawPath(
      page,
      Paint()..color = SteamTones.stripeWhite.withValues(alpha: fade),
    );
    c.drawPath(
      page,
      Paint()
        ..color = SteamTones.ink.withValues(alpha: .85 * fade)
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * .0028
        ..strokeJoin = StrokeJoin.round,
    );
    c.drawLine(
      q(-w * .55, -d * .1),
      q(w * .5, d * .05),
      Paint()
        ..color = SteamTones.ink.withValues(alpha: .45 * fade)
        ..strokeWidth = h * .0022,
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
    // Seams between the enamel bands, and a bolted flange at the foot.
    final seams = Path();
    for (var i = 1; i < n; i++) {
      final y = mouthY + ht * i / n;
      seams
        ..moveTo(cx - wAt(y), y)
        ..quadraticBezierTo(cx, y + h * .007, cx + wAt(y), y);
    }
    c.drawPath(
      seams,
      Paint()
        ..color = SteamTones.ink.withValues(alpha: .38)
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * .0026,
    );
    final flange = RRect.fromLTRBR(
      cx - bw * 1.45,
      baseY - h * .007,
      cx + bw * 1.45,
      baseY + h * .004,
      Radius.circular(h * .003),
    );
    c.drawRRect(flange, Paint()..color = SteamTones.iron);
    c.drawRRect(flange, _ink(h, .0045));
    final flangeBolts = Path();
    for (final k in const [-1.15, -.55, 0.0, .55, 1.15]) {
      flangeBolts.addOval(
        Rect.fromCircle(
          center: Offset(cx + bw * k, baseY - h * .0015),
          radius: h * .0017,
        ),
      );
    }
    c.drawPath(flangeBolts, Paint()..color = SteamTones.ironRim);
    // Rust runs down from the lip.
    c.drawPath(
      Path()
        ..moveTo(cx + tw * .35, mouthY + h * .010)
        ..lineTo(cx + tw * .35, mouthY + h * .034)
        ..moveTo(cx - tw * .15, mouthY + h * .010)
        ..lineTo(cx - tw * .15, mouthY + h * .022),
      Paint()
        ..color = SteamTones.stripeDeep.withValues(alpha: .6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * .0030
        ..strokeCap = StrokeCap.round,
    );
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
