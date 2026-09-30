import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../domain/sky_boss.dart';
import 'boss_motion.dart';

/// The Pirate Captain's gun and the whole firing story: a hammered-bronze
/// mortar on a red iron-banded carriage, a fuse that burns down while the
/// charge builds (bore and breech warming as it does), a snapping recoil,
/// and the muzzle blast: flash, fire tongue, sparks and
/// rolling gunsmoke.
///
/// Authored in the captain's rig units (1 = [SkyBoss.radius]) at the exact
/// pivot the rules launch from, so the barrel always points where the balls
/// come out; the blast is drawn in screen pixels from the real muzzle. Every
/// motion derives from the boss clock (no particle state), so pause and
/// replay seeking stay exact, and Reduced Motion keeps the states but none
/// of the movement.
abstract final class PirateArtillery {
  static final pivot = Offset(
    SkyBoss.cannonPivot.$1 / SkyBoss.radius,
    SkyBoss.cannonPivot.$2 / SkyBoss.radius,
  );
  static const barrel = SkyBoss.cannonLength / SkyBoss.radius;

  static const _ink = Color(0xff2a1a1e);
  static const _bronze = Color(0xffbd843c), _bronzeLit = Color(0xfff4cf85);
  static const _bronzeDeep = Color(0xff6d4420);
  static const _bronzeShade = Color(0xff4a2b15);
  static const _iron = Color(0xff454a58), _ironLit = Color(0xff8d95a8);
  static const _ironDeep = Color(0xff2b2e39);
  static const _gold = Color(0xffffcf5c), _goldLight = Color(0xfffff0b4);
  static const _red = Color(0xffb8404a), _redLit = Color(0xffd65a5a);
  static const _redDeep = Color(0xff762431), _redDark = Color(0xff521a26);
  static const _woodDark = Color(0xff55301f), _patina = Color(0xff5fae95);
  static const _ropeDeep = Color(0xff7c5634);
  static const _hot = Color(0xffff8a3a), _fire = Color(0xffffd45b);
  static const _core = Color(0xfffff6d8), _flame = Color(0xffd8432f);
  static const _smoke = Color(0xffc3c6d0), _smokeRim = Color(0xff474653);
  static const _smokeShade = Color(0xff8b8e9e), _smokeCream = Color(0xfff4f2ec);

  static Paint _fill(Color color) => Paint()..color = color;
  static Paint _line(Color color, double width) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  static double _hash(int a, [int b = 0]) {
    final v = math.sin(a * 12.9898 + b * 78.233) * 43758.5453;
    return v - v.floorToDouble();
  }

  // ------------------------------------------------------------- shared --

  /// The vent stands this far above the barrel's axis, along its sky-side
  /// normal, at [_ventBack] behind the pivot.
  static const _ventRise = .39, _ventBack = .14;

  /// Where the wick meets the breech and where its tip curls, in rig units,
  /// for a barrel at [aim]. The captain's torch dips to the tip, so the tip
  /// stays where his pose expects it.
  static (Offset hole, Offset tip) fuse(double aim) {
    final d = Offset(math.cos(aim), math.sin(aim));
    final n = Offset(-math.sin(aim), math.cos(aim));
    final base = pivot + d * -_ventBack;
    return (base + n * _ventRise, base + n * .26 + const Offset(.06, -.36));
  }

  /// The barrel's snap back along its axis: fast out, easing home.
  static double _kick(double since) {
    if (!since.isFinite || since < 0 || since > .55) return 0;
    if (since < .045) return since / .045;
    final t = (since - .045) / .505;
    return (1 - t) * (1 - t);
  }

  // ---------------------------------------------------------------- gun --

  static void paint(
    Canvas c,
    SkyBoss boss,
    BossMotion m,
    double aim, {
    required double carriageRoll,
  }) {
    final rested = m.reducedMotion;
    final kick = rested ? 0.0 : _kick(boss.age - boss.lastVolleyAt);
    final fury = boss.enraged && !m.defeated;
    final charge = m.defeated ? 0.0 : boss.charge;
    // The breech warms as the fuse burns; the mouth glows for the last
    // stretch, so the moment of firing can be read from the muzzle alone.
    final breech = BossMotion.ramp(charge, .1, .85);
    final mouth = BossMotion.ramp(charge, .4, 1);
    final t = rested ? 0.0 : boss.age;
    final tremble = BossMotion.ramp(charge, .55, 1);
    final shake = rested
        ? Offset.zero
        : Offset(
            math.sin(t * 61) * .011 * tremble * tremble,
            math.cos(t * 73) * .011 * tremble * tremble,
          );

    void carriage(void Function() draw) {
      c.save();
      c.translate(pivot.dx + kick * .07, pivot.dy);
      c.rotate(carriageRoll);
      c.translate(-pivot.dx, -pivot.dy);
      draw();
      c.restore();
    }

    carriage(() => _farCheek(c));
    c.save();
    // The breech sinks through the deck at steep elevations.
    c.clipRect(Rect.fromLTRB(pivot.dx - 3, pivot.dy - 3, pivot.dx + 3, 1.1));
    c.translate(pivot.dx + kick * .07, pivot.dy);
    c.rotate(aim);
    c.scale(1, -1);
    c.translate(-kick * .12 + shake.dx, shake.dy);
    _barrel(c, fury: fury, breech: breech, mouth: mouth);
    c.restore();
    carriage(() => _nearCheek(c, fury: fury, breech: breech));
    _wick(c, boss, m, aim);
  }

  // ------------------------------------------------------------ carriage --

  static final _cheekFar = Path()
    ..moveTo(-1.6, 1.12)
    ..lineTo(-1.6, .9)
    ..lineTo(-1.5, .88)
    ..lineTo(-1.5, .76)
    ..lineTo(-1.36, .72)
    ..lineTo(-1.06, .72)
    ..lineTo(-1.02, .84)
    ..lineTo(-.86, .92)
    ..lineTo(-.82, 1.12)
    ..close();

  static void _farCheek(Canvas c) {
    c.drawPath(_cheekFar, _line(_ink, .07));
    c.drawPath(_cheekFar, _fill(_redDark));
    // The far wheel peeks out beyond the near one.
    for (final x in const [-1.42, -.94]) {
      c.drawCircle(Offset(x, 1.03), .12, _fill(_ink));
      c.drawCircle(Offset(x, 1.03), .085, _fill(_woodDark));
    }
  }

  static final _cheekNear = Path()
    ..moveTo(-1.62, 1.1)
    ..lineTo(-1.62, .96)
    ..quadraticBezierTo(-1.62, .93, -1.6, .91)
    ..lineTo(-1.47, .8)
    ..quadraticBezierTo(-1.44, .77, -1.4, .77)
    ..lineTo(-1.06, .77)
    ..quadraticBezierTo(-1.02, .77, -1, .8)
    ..lineTo(-.9, .93)
    ..quadraticBezierTo(-.87, .96, -.83, .96)
    ..lineTo(-.83, 1.1)
    ..close();
  static const _cheekBox = Rect.fromLTRB(-1.62, .77, -.83, 1.1);
  static final _cheekPaint = Paint()
    ..shader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [_redLit, _red, _redDeep],
      stops: [0, .45, 1],
    ).createShader(_cheekBox);

  static void _nearCheek(
    Canvas c, {
    required bool fury,
    required double breech,
  }) {
    // Contact shadow on the deck, then the wooden cheek.
    c.drawOval(
      const Rect.fromLTRB(-1.68, 1.12, -.78, 1.22),
      _fill(_ink.withValues(alpha: .35)),
    );
    c.drawPath(_cheekNear, _line(_ink, .085));
    c.drawPath(_cheekNear, _cheekPaint);
    c.save();
    c.clipPath(_cheekNear);
    // Wood grain and a lit top edge.
    for (final (y, from, to) in const [
      (.93, -1.6, -1.12),
      (1.0, -1.5, -.86),
      (.84, -1.34, -1.1),
    ]) {
      c.drawLine(
        Offset(from, y),
        Offset(to, y - .012),
        _line(_redDeep.withValues(alpha: .55), .022),
      );
    }
    c.drawPath(
      Path()
        ..moveTo(-1.6, .925)
        ..lineTo(-1.47, .815)
        ..quadraticBezierTo(-1.44, .785, -1.4, .785)
        ..lineTo(-1.06, .785)
        ..quadraticBezierTo(-1.02, .785, -1.0, .815)
        ..lineTo(-.9, .945)
        ..quadraticBezierTo(-.87, .975, -.83, .975),
      _line(_redLit.withValues(alpha: .95), .03),
    );
    // Iron banding: a strap along the cheek and two upright straps.
    const strap = Rect.fromLTRB(-1.62, .965, -.83, 1.02);
    c.drawRect(strap, _fill(_ironDeep));
    c.drawLine(
      const Offset(-1.62, .975),
      const Offset(-.83, .975),
      _line(_ironLit.withValues(alpha: .7), .014),
    );
    for (final x in const [-1.5, -.93]) {
      final post = Rect.fromLTRB(x - .035, .82, x + .035, 1.1);
      c.drawRect(post, _fill(_ironDeep));
      c.drawLine(
        Offset(x - .015, .84),
        Offset(x - .015, 1.09),
        _line(_ironLit.withValues(alpha: .6), .012),
      );
    }
    c.restore();
    for (final x in const [-1.5, -1.22, -.93]) {
      c.drawCircle(Offset(x, .992), .022, _fill(_ironLit));
    }
    // The capsquare: an iron strap bolted over the trunnion.
    final cap = RRect.fromLTRBR(
      -1.33,
      .655,
      -1.105,
      .83,
      const Radius.circular(.07),
    );
    c.drawRRect(cap, _line(_ink, .07));
    c.drawRRect(cap, _fill(_iron));
    c.drawLine(
      const Offset(-1.29, .69),
      const Offset(-1.15, .69),
      _line(_ironLit.withValues(alpha: .8), .02),
    );
    for (final x in const [-1.3, -1.135]) {
      c.drawCircle(Offset(x, .805), .02, _fill(_ironLit));
    }
    // The trunnion itself, glinting gold.
    c.drawCircle(pivot, .105, _fill(_ink));
    c.drawCircle(pivot, .075, _fill(_ironLit));
    c.drawCircle(pivot, .06, _fill(_iron));
    c.drawCircle(pivot, .034, _fill(_gold));
    c.drawCircle(pivot + const Offset(-.012, -.014), .012, _fill(_goldLight));
    // Wheels: solid oak trucks with iron hubs.
    for (final x in const [-1.46, -.98]) {
      const y = 1.055;
      c.drawCircle(Offset(x, y), .14, _fill(_ink));
      c.drawCircle(Offset(x, y), .105, _fill(_woodDark));
      c.drawArc(
        Rect.fromCircle(center: Offset(x, y), radius: .085),
        -2.6,
        1.5,
        false,
        _line(const Color(0xffa8683f), .03),
      );
      for (var i = 0; i < 4; i++) {
        final a = i * math.pi / 2 + .5;
        c.drawLine(
          Offset(x, y),
          Offset(x + math.cos(a) * .09, y + math.sin(a) * .09),
          _line(_ink.withValues(alpha: .55), .02),
        );
      }
      c.drawCircle(Offset(x, y), .04, _fill(_iron));
      c.drawCircle(Offset(x, y), .018, _fill(_gold));
    }
  }

  // -------------------------------------------------------------- barrel --

  static const _len = barrel;

  /// Local frame: +x toward the muzzle, -y the barrel's sky side. A domed
  /// breech tapers through the chase to a swelling muzzle, one silhouette.
  static final _body = Path()
    ..moveTo(-.5, 0)
    ..cubicTo(-.5, -.24, -.42, -.36, -.26, -.36)
    ..cubicTo(-.12, -.36, -.04, -.33, .1, -.31)
    ..cubicTo(.2, -.29, .3, -.27, .44, -.245)
    ..cubicTo(.5, -.24, .52, -.24, .55, -.275)
    ..cubicTo(.58, -.31, .6, -.33, _len, -.33)
    ..lineTo(_len, .33)
    ..cubicTo(.6, .33, .58, .31, .55, .275)
    ..cubicTo(.52, .24, .5, .24, .44, .245)
    ..cubicTo(.3, .27, .2, .29, .1, .31)
    ..cubicTo(-.04, .33, -.12, .36, -.26, .36)
    ..cubicTo(-.42, .36, -.5, .24, -.5, 0)
    ..close();
  static const _box = Rect.fromLTRB(-.5, -.37, .66, .37);
  static final _bronzePaint = Paint()
    ..shader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xffe6a24a), Color(0xffa9652b), Color(0xff58321a)],
      stops: [.02, .42, 1],
    ).createShader(_box);
  static final _ringPaint = Paint()
    ..shader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xffffe28e), Color(0xffe6aa3e), Color(0xff9a5f24)],
      stops: [0, .45, 1],
    ).createShader(_box);
  static final _heatPaint = Paint()
    ..shader = const LinearGradient(
      colors: [Color(0xffff6a2a), Color(0x00ff6a2a)],
    ).createShader(const Rect.fromLTRB(-.5, -.37, .28, .37));
  static final _glowPaint = Paint()
    ..shader = const RadialGradient(
      colors: [Color(0xffffe08a), Color(0x88ff8a3a), Color(0x00ff8a3a)],
      stops: [0, .5, 1],
    ).createShader(Rect.fromCircle(center: Offset.zero, radius: 1));
  static final _handle = Path()
    ..moveTo(.41, -.245)
    ..cubicTo(.4, -.4, .5, -.4, .49, -.25);

  static void _barrel(
    Canvas c, {
    required bool fury,
    required double breech,
    required double mouth,
  }) {
    // The cascabel knob behind the breech.
    c.drawLine(const Offset(-.62, 0), const Offset(-.45, 0), _line(_ink, .17));
    c.drawLine(
      const Offset(-.62, 0),
      const Offset(-.45, 0),
      _line(_bronzeDeep, .095),
    );
    c.drawCircle(const Offset(-.68, 0), .115, _fill(_ink));
    c.drawCircle(const Offset(-.68, 0), .085, _fill(_bronze));
    c.drawCircle(const Offset(-.705, -.028), .028, _fill(_bronzeLit));
    // The silhouette: an inked bronze body.
    c.drawPath(_body, _line(_ink, .12));
    c.drawPath(_body, _bronzePaint);
    c.save();
    c.clipPath(_body);
    // A deep underside, verdigris in the recesses, hammer marks.
    c.drawRect(
      const Rect.fromLTRB(-.5, .2, .7, .4),
      _fill(_bronzeShade.withValues(alpha: .28)),
    );
    for (final (x, y, rx, ry) in const [
      (.2, .22, .06, .022),
      (.47, .16, .05, .02),
      (-.2, .3, .07, .022),
      (.14, -.24, .04, .016),
    ]) {
      c.drawOval(
        Rect.fromCenter(center: Offset(x, y), width: rx * 2, height: ry * 2),
        _fill(_patina.withValues(alpha: .5)),
      );
    }
    for (var i = 0; i < 9; i++) {
      final x = -.42 + _hash(i, 3) * .95, y = (_hash(i, 5) - .5) * .5;
      c.drawArc(
        Rect.fromCircle(center: Offset(x, y), radius: .03),
        -2.8,
        1.6,
        false,
        _line(_bronzeLit.withValues(alpha: .5), .014),
      );
    }
    // Warmth builds in the breech as the fuse burns down.
    final warm = math.max(breech * .8, fury ? .28 : 0.0);
    if (warm > 0) {
      c.drawRect(
        _box,
        Paint()
          ..shader = _heatPaint.shader
          ..color = Color.fromRGBO(0, 0, 0, warm),
      );
    }
    // A long sky-side gleam, a bright dash, and a cool bounce along the belly.
    c.drawLine(
      const Offset(-.34, -.24),
      const Offset(.36, -.18),
      _line(_goldLight.withValues(alpha: .85), .05),
    );
    c.drawLine(
      const Offset(-.3, -.285),
      const Offset(-.16, -.28),
      _line(const Color(0xffffffff).withValues(alpha: .8), .03),
    );
    c.drawLine(
      const Offset(-.36, .3),
      const Offset(.3, .25),
      _line(const Color(0xff8fe3dc).withValues(alpha: .28), .03),
    );
    c.restore();
    // Raised reinforcing rings, the muzzle astragal and the lip.
    for (final (x0, x1, r) in const [
      (.02, .1, .355),
      (.3, .37, .31),
      (.535, .58, .345),
      (.615, _len, .375),
    ]) {
      final ring = RRect.fromLTRBR(x0, -r, x1, r, const Radius.circular(.03));
      c.drawRRect(ring, _line(_ink, .065));
      c.drawRRect(ring, _ringPaint);
      c.drawLine(
        Offset(x0 + .02, -r + .04),
        Offset(x0 + .02, r - .05),
        _line(const Color(0xffffffff).withValues(alpha: .55), .02),
      );
    }
    // A carrying loop cast over the neck of the chase.
    c.drawPath(_handle, _line(_ink, .125));
    c.drawPath(_handle, _line(const Color(0xffe0a23c), .075));
    c.drawPath(_handle, _line(_goldLight.withValues(alpha: .9), .024));
    // The vent: a raised boss with the touch-hole the fuse is set in.
    final vent = RRect.fromLTRBR(
      -.19,
      -.4,
      -.09,
      -.3,
      const Radius.circular(.035),
    );
    c.drawRRect(vent, _line(_ink, .06));
    c.drawRRect(vent, _fill(_bronze));
    c.drawLine(
      const Offset(-.175, -.385),
      const Offset(-.105, -.385),
      _line(_bronzeLit, .022),
    );
    c.drawCircle(const Offset(-.14, -.385), .026, _fill(_ink));
    // The muzzle: a lit lip around a dark bore, hot at the moment of firing.
    final face = Rect.fromCenter(
      center: const Offset(_len - .005, 0),
      width: .13,
      height: .75,
    );
    c.drawOval(face, _line(_ink, .06));
    c.drawOval(face, _ringPaint);
    final bore = Rect.fromCenter(
      center: const Offset(_len + .005, 0),
      width: .09,
      height: .54,
    );
    final heat = math.max(mouth, fury ? .3 : 0.0);
    c.drawOval(bore, _fill(_ink));
    c.drawOval(
      bore.deflate(.02),
      _fill(
        heat < .5
            ? Color.lerp(const Color(0xff120c0e), _flame, heat * 2)!
            : Color.lerp(_flame, _fire, (heat - .5) * 2)!,
      ),
    );
    if (heat > .6) {
      c.drawOval(
        bore.deflate(.06),
        _fill(_core.withValues(alpha: (heat - .6) / .4)),
      );
    }
    c.drawArc(face.deflate(.012), -2.3, 1.5, false, _line(_goldLight, .022));
    if (mouth > 0) {
      c.save();
      c.translate(_len + .03, 0);
      c.scale(.45 + mouth * .25);
      c.drawCircle(
        Offset.zero,
        1,
        Paint()
          ..shader = _glowPaint.shader
          ..color = Color.fromRGBO(0, 0, 0, mouth * .85),
      );
      c.restore();
    }
  }

  // ---------------------------------------------------------------- wick --

  /// The fuse: a spark burns down it from the tip while the charge builds,
  /// and a fresh one is set after each shot.
  static void _wick(Canvas c, SkyBoss boss, BossMotion m, double aim) {
    if (m.defeated) return;
    final (hole, tip) = fuse(aim);
    final since = boss.age - boss.lastVolleyAt;
    final fresh = since.isFinite ? BossMotion.ramp(since, .35, .6) : 1.0;
    final burn = BossMotion.ramp(boss.charge, .12, 1);
    final left = boss.charge > 0 ? 1 - burn : fresh;
    if (left <= .02) return;
    final bend = Offset.lerp(hole, tip, .5)! + const Offset(-.1, 0);
    Offset along(double k) {
      final u = 1 - k;
      return hole * (u * u) + bend * (2 * u * k) + tip * (k * k);
    }

    final wick = Path()..moveTo(hole.dx, hole.dy);
    for (var i = 1; i <= 12; i++) {
      final at = along(i / 12 * left);
      wick.lineTo(at.dx, at.dy);
    }
    c.drawPath(wick, _line(_ink, .085));
    c.drawPath(wick, _line(const Color(0xffe2c08a), .048));
    // Twisted cord: little cross-ticks along it.
    for (var i = 1; i <= 4; i++) {
      final k = i / 5 * left;
      final a = along(k), b = along(math.min(1, k + .04));
      final dir = b - a;
      final len = dir.distance;
      if (len == 0) continue;
      final p = Offset(-dir.dy, dir.dx) / len * .03;
      c.drawLine(a - p, a + p, _line(_ropeDeep.withValues(alpha: .8), .016));
    }
    // A little knot where it enters the vent.
    c.drawCircle(hole, .034, _fill(_ink));
    c.drawCircle(hole, .022, _fill(const Color(0xffe2c08a)));
    if (boss.charge <= 0) return;
    final spark = along(left);
    // The burnt stub trailing the flame.
    final stub = Path()..moveTo(spark.dx, spark.dy);
    for (var i = 1; i <= 3; i++) {
      final at = along(math.min(1, left + i * .04));
      stub.lineTo(at.dx, at.dy);
    }
    c.drawPath(stub, _line(_ink, .07));
    c.drawPath(stub, _line(const Color(0xff5a4a44), .035));
    final t = m.reducedMotion ? 0.0 : boss.age;
    final flare = .8 + .2 * math.sin(t * 40);
    // Smoke curls up off the burning end.
    for (var i = 0; i < 3; i++) {
      final life = m.reducedMotion ? .4 + i * .2 : (t * 1.6 + i / 3) % 1;
      c.drawCircle(
        spark + Offset(.05 + life * .1, -.1 - life * .45),
        .05 + life * .08,
        _fill(const Color(0xffd9d3cc).withValues(alpha: (1 - life) * .6)),
      );
    }
    final glow = Rect.fromCircle(center: spark, radius: .46);
    c.drawCircle(
      spark,
      .46,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xffffe08a).withValues(alpha: .8),
            const Color(0xffff8a3a).withValues(alpha: 0),
          ],
        ).createShader(glow),
    );
    // A spitting star of sparks, brighter as the flame nears the powder.
    final hot = .8 + burn * .5;
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4 + t * 7;
      final r = (.14 + (i.isEven ? .11 : .035)) * flare * hot;
      c.drawLine(
        spark,
        spark + Offset(math.cos(a), math.sin(a)) * r,
        _line(_ink.withValues(alpha: .5), .055),
      );
      c.drawLine(
        spark,
        spark + Offset(math.cos(a), math.sin(a)) * r,
        _line(const Color(0xffffd05a), .032),
      );
    }
    // Embers thrown off, arcing under their own weight.
    if (!m.reducedMotion) {
      for (var i = 0; i < 4; i++) {
        final life = (t * 2.6 + i * .27) % 1;
        final a = -math.pi / 2 + (_hash(i, 9) - .5) * 2.2;
        final v = .12 + _hash(i, 4) * .18;
        c.drawCircle(
          spark +
              Offset(
                math.cos(a) * v * life * 2,
                math.sin(a) * v * life * 2 + life * life * .22,
              ),
          .022 * (1 - life),
          _fill(const Color(0xffffb13d).withValues(alpha: 1 - life)),
        );
      }
    }
    c.drawCircle(spark, .08 * flare * hot, _fill(_hot));
    c.drawCircle(spark, .048 * flare * hot, _fill(_core));
  }

  // --------------------------------------------------------------- blast --

  /// The muzzle blast and a gunsmoke cloud after each shot, in screen
  /// pixels from the real muzzle.
  static void blast(
    Canvas c,
    double h,
    SkyBoss boss,
    BossMotion m, {
    required Offset muzzle,
    required double aim,
  }) {
    if (m.defeated) return;
    final since = boss.age - boss.lastVolleyAt;
    if (!since.isFinite || since < 0 || since > 1.3) return;
    final unit = h * SkyBoss.radius;
    final fury = boss.enraged;
    final broadside = fury && boss.volleys % 3 == 0 && boss.volleys > 0;
    final big = broadside ? 1.35 : 1.0;
    final rested = m.reducedMotion;
    final d = Offset(math.cos(aim), math.sin(aim));
    final n = Offset(-math.sin(aim), math.cos(aim));
    // The vent breathes a little smoke as the charge catches.
    if (!rested) _ventPuff(c, unit, muzzle, aim, since);
    final k = BossMotion.ramp(since, 0, 1.3);
    final fade = 1 - BossMotion.ease(BossMotion.ramp(since, .5, 1.3));
    final grow = rested ? .7 : 1 - math.pow(1 - k, 3).toDouble();
    final rise = rested ? 0.0 : k * k * .7;
    final warm = 1 - BossMotion.ramp(since, .04, .4);
    if (fade > 0) {
      final puffs = <(Offset, double, double)>[];
      // The plume rolls out along the barrel, rising and thinning.
      for (var i = 0; i < 6; i++) {
        final out = (.12 + i * .3) * (.55 + grow * .6);
        final drift = Offset(k * .28 * (i / 5 + .3), -rise * (.4 + i * .12));
        final wob = (_hash(i, 1) - .5) * (.16 + .6 * grow);
        final at = muzzle + (d * out + n * wob + drift) * unit * big;
        final r =
            unit *
            big *
            (.15 +
                math.sin((i + .6) / 5.6 * math.pi) * .16 +
                _hash(i, 2) * .05) *
            (.5 + grow * .75);
        puffs.add((at, r, warm * (i < 3 ? 1 : .3)));
      }
      // A smoke ring seen at an angle, spinning off the muzzle.
      final ringGrow = rested ? .55 : BossMotion.ramp(since, .06, .9);
      if (ringGrow > 0) {
        final centre =
            d * (.55 + 1.35 * BossMotion.ease(ringGrow)) - Offset(0, rise * .4);
        final radius = .26 + .34 * BossMotion.ease(ringGrow);
        for (var i = 0; i < 8; i++) {
          final a = i * math.pi / 4 + .4;
          final at =
              muzzle +
              (centre +
                      n * (math.cos(a) * radius) +
                      d * (math.sin(a) * radius * .42)) *
                  unit *
                  big;
          final r =
              unit * big * (.075 + _hash(i, 6) * .03) * (.7 + ringGrow * .6);
          puffs.add((at, r, 0));
        }
      }
      _cloud(c, puffs, fade, unit, fury);
    }
    // The flash: sparks, a jagged star, a fire tongue and a white-hot core.
    final flash = BossMotion.ramp(since, 0, rested ? .2 : .16);
    if (flash >= 1) return;
    final alpha = 1 - flash;
    _sparks(c, unit * big, muzzle, aim, since, fury, rested);
    final shrink = rested ? 1.0 : 1 - flash * .45;
    final size = unit * .58 * big * shrink;
    // A soft bloom behind the burst.
    c.save();
    c.translate(muzzle.dx + d.dx * size * .35, muzzle.dy + d.dy * size * .35);
    c.scale(size * 1.5);
    c.drawCircle(
      Offset.zero,
      1,
      Paint()
        ..shader = _glowPaint.shader
        ..color = Color.fromRGBO(0, 0, 0, alpha),
    );
    c.restore();
    final star = Path();
    for (var i = 0; i < 20; i++) {
      final a = aim + i * math.pi / 10;
      final along = math.cos(a - aim);
      final jag = .8 + .35 * _hash(i, 8);
      final reach =
          (i.isEven ? 1.0 : .48) * (.62 + .5 * math.max(0, along)) * jag;
      final p =
          muzzle +
          d * size * .3 +
          Offset(math.cos(a), math.sin(a)) * size * reach;
      i == 0 ? star.moveTo(p.dx, p.dy) : star.lineTo(p.dx, p.dy);
    }
    star.close();
    c.drawPath(
      star,
      _line(
        (fury ? _flame : const Color(0xffd75e4f)).withValues(alpha: alpha),
        unit * .065,
      ),
    );
    c.drawPath(star, _fill((fury ? _hot : _fire).withValues(alpha: alpha)));
    // The tongue of fire pointing where the ball goes.
    final lick = rested ? 0.0 : math.sin(since * 120) * .06;
    final tongue = unit * big * (1.15 + lick) * (1 - flash * .35);
    final w = unit * big * .21 * (1 - flash * .3);
    final tongueShape = Path()
      ..moveTo(muzzle.dx + n.dx * w * .5, muzzle.dy + n.dy * w * .5)
      ..quadraticBezierTo(
        muzzle.dx + d.dx * tongue * .4 + n.dx * w,
        muzzle.dy + d.dy * tongue * .4 + n.dy * w,
        muzzle.dx + d.dx * tongue * .8 + n.dx * w * .35 + d.dx * lick * unit,
        muzzle.dy + d.dy * tongue * .8 + n.dy * w * .35,
      )
      ..lineTo(muzzle.dx + d.dx * tongue, muzzle.dy + d.dy * tongue)
      ..lineTo(
        muzzle.dx + d.dx * tongue * .8 - n.dx * w * .35,
        muzzle.dy + d.dy * tongue * .8 - n.dy * w * .35,
      )
      ..quadraticBezierTo(
        muzzle.dx + d.dx * tongue * .4 - n.dx * w,
        muzzle.dy + d.dy * tongue * .4 - n.dy * w,
        muzzle.dx - n.dx * w * .5,
        muzzle.dy - n.dy * w * .5,
      )
      ..close();
    c.drawPath(
      tongueShape,
      _line(_flame.withValues(alpha: alpha * .85), unit * .05),
    );
    c.drawPath(
      tongueShape,
      _fill((fury ? _hot : _fire).withValues(alpha: alpha)),
    );
    c.save();
    c.translate(muzzle.dx, muzzle.dy);
    c.scale(.62, .62);
    c.translate(-muzzle.dx, -muzzle.dy);
    c.drawPath(tongueShape, _fill(_core.withValues(alpha: alpha * .9)));
    c.restore();
    c.drawCircle(
      muzzle + d * size * .3,
      size * .27,
      _fill(_core.withValues(alpha: alpha)),
    );
    c.drawCircle(
      muzzle + d * size * .3,
      size * .13,
      _fill(const Color(0xffffffff).withValues(alpha: alpha)),
    );
  }

  static void _sparks(
    Canvas c,
    double unit,
    Offset muzzle,
    double aim,
    double since,
    bool fury,
    bool rested,
  ) {
    final travel = rested
        ? .45
        : BossMotion.ease(BossMotion.ramp(since, 0, .38));
    final fade = 1 - BossMotion.ramp(since, .16, .4);
    if (fade <= 0) return;
    for (var i = 0; i < 10; i++) {
      final a = aim + (_hash(i, 12) - .5) * 1.5;
      final dir = Offset(math.cos(a), math.sin(a));
      final reach = (.55 + _hash(i, 13) * .95) * unit * travel;
      final head =
          muzzle +
          dir * (unit * .2 + reach) +
          Offset(0, travel * travel * unit * .18);
      final tail = head - dir * unit * (.05 + .13 * (1 - travel));
      c.drawLine(
        tail,
        head,
        _line(_flame.withValues(alpha: fade * .8), unit * .05),
      );
      c.drawLine(
        tail,
        head,
        _line((fury ? _hot : _fire).withValues(alpha: fade), unit * .028),
      );
    }
  }

  static void _ventPuff(
    Canvas c,
    double unit,
    Offset muzzle,
    double aim,
    double since,
  ) {
    final life = BossMotion.ramp(since, 0, .45);
    if (life >= 1) return;
    final d = Offset(math.cos(aim), math.sin(aim));
    final n = Offset(-math.sin(aim), math.cos(aim));
    final pivotAt = muzzle - d * (SkyBoss.cannonLength * unit / SkyBoss.radius);
    final hole = pivotAt + (d * -_ventBack + n * _ventRise) * unit;
    final at = hole + Offset(unit * .08 * life, -unit * (.1 + life * .35));
    _cloud(
      c,
      [
        (at, unit * (.06 + life * .08), 0),
        (
          at + Offset(unit * .07, -unit * .09) * (.5 + life),
          unit * (.045 + life * .06),
          0,
        ),
      ],
      (1 - life) * .85,
      unit,
      false,
    );
    if (life < .25) {
      c.drawCircle(
        hole,
        unit * .09 * (1 - life * 4),
        _fill(_core.withValues(alpha: 1 - life * 4)),
      );
    }
  }

  /// Cartoon gunsmoke: each puff is a cauliflower of lobes with one inked
  /// rim, a shaded body and a lit crown, first lit warm by the flash.
  static void _cloud(
    Canvas c,
    List<(Offset, double, double)> puffs,
    double fade,
    double unit,
    bool fury,
  ) {
    final lobes = <(Offset, double)>[];
    for (var i = 0; i < puffs.length; i++) {
      final (at, r, _) = puffs[i];
      lobes.add((at, r));
      if (r < unit * .12) continue;
      for (var j = 0; j < 3; j++) {
        final a = (_hash(i, j + 20) + j / 3) * math.pi * 2;
        lobes.add((at + Offset(math.cos(a), math.sin(a)) * r * .7, r * .55));
      }
    }
    final rim = _fill(_smokeRim.withValues(alpha: .62 * fade));
    for (final (at, r) in lobes) {
      c.drawCircle(at, r + unit * .04, rim);
    }
    final shade = _fill(_smokeShade.withValues(alpha: fade));
    for (final (at, r) in lobes) {
      c.drawCircle(at, r, shade);
    }
    final body = _fill(_smoke.withValues(alpha: fade));
    for (final (at, r) in lobes) {
      c.drawCircle(at + Offset(-r * .1, -r * .14), r * .84, body);
    }
    for (final (at, r, warm) in puffs) {
      if (warm <= 0) continue;
      c.drawCircle(
        at,
        r * 1.1,
        _fill((fury ? _flame : _hot).withValues(alpha: warm * fade * .42)),
      );
    }
    final crown = _fill(_smokeCream.withValues(alpha: fade * .5));
    for (final (at, r, _) in puffs) {
      if (r < unit * .15) continue;
      c.drawCircle(at + Offset(-r * .3, -r * .36), r * .3, crown);
    }
  }
}
