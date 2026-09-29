import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../domain/sky_boss.dart';
import 'boss_motion.dart';

/// The Pirate Captain's ship: a two-masted brigantine with patched sails, a
/// Jolly Roger, a gilded stern castle and a bronze mortar on the bow deck.
///
/// Authored in the captain's rig units (1 = [SkyBoss.radius]) around his
/// hit circle, but anchored to the sea: the waterline sits [waterline]
/// below the captain and the hull fills the armored box the rules test
/// (rail at [rail], bow at [bow], stern at [stern]). The ship rolls about
/// its waterline on its own, independent of the captain's character
/// motion, and the cannon is always drawn at its exact pivot so the barrel
/// points where the balls come out.
abstract final class PirateShipArt {
  static const waterline = SkyBoss.shipRide / SkyBoss.radius;
  static const rail = SkyBoss.hullTop / SkyBoss.radius;
  static const bow = SkyBoss.hullLeft / SkyBoss.radius;
  static const stern = SkyBoss.hullRight / SkyBoss.radius;
  static const keel = waterline + .62;
  static const pivot = Offset(
    SkyBoss.cannonPivot.$1 / SkyBoss.radius,
    SkyBoss.cannonPivot.$2 / SkyBoss.radius,
  );
  static const barrel = SkyBoss.cannonLength / SkyBoss.radius;

  /// Everything the ship can reach, masts, flag and bowsprit included.
  static const bounds = Rect.fromLTRB(-4.1, -5.1, 3.8, 2.6);

  static const ink = Color(0xff2a1a1e);
  static const _wood = Color(0xff7a4630), _woodLit = Color(0xffa8683f);
  static const _woodDeep = Color(0xff3f2119), _woodDark = Color(0xff55301f);
  static const _plank = Color(0xff2e1914), _ochre = Color(0xffd9a441);
  static const _ochreDeep = Color(0xff9d6a24), _gold = Color(0xffffcf5c);
  static const _goldLight = Color(0xfffff0b4), _goldDeep = Color(0xffc9862b);
  static const _red = Color(0xffb8404a), _redDeep = Color(0xff762431);
  static const _copper = Color(0xffc0703f), _patina = Color(0xff5fae95);
  static const _mast = Color(0xff8c5a38), _mastLit = Color(0xffc58a58);
  static const _mastDark = Color(0xff5a3423);
  static const _sail = Color(0xfff4e6c8), _sailShade = Color(0xffd9c09a);
  static const _sailDeep = Color(0xffb69870), _seam = Color(0xffc4a77d);
  static const _rope = Color(0xff4f3527), _flag = Color(0xff1f1b27);
  static const _bone = Color(0xfffff4dd), _fury = Color(0xffc8313f);
  static const _bronze = Color(0xffbd843c), _bronzeLit = Color(0xfff4cf85);
  static const _bronzeDeep = Color(0xff6d4420), _iron = Color(0xff454a58);
  static const _ironLit = Color(0xff8d95a8), _glow = Color(0xffffd36b);
  static const _window = Color(0xffffe39a), _windowHot = Color(0xffff8a4a);
  static const _deck = Color(0xff24161a);

  static Paint _fill(Color color) => Paint()..color = color;
  static Paint _line(Color color, double width) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  static Paint _vertical(Rect rect, List<Color> colors, [List<double>? stops]) =>
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
          stops: stops,
        ).createShader(rect);

  // ---------------------------------------------------------------- pose --

  /// The ship's roll about its waterline: a gentle swell, a lurch when the
  /// cannon fires, a pitch while it sails in and while the tide surges.
  static double roll(SkyBoss boss, BossMotion m) {
    if (m.reducedMotion) return 0;
    final t = boss.age;
    var roll = math.sin(t * 1.15) * .014 + math.sin(t * 2.7 + 1) * .005;
    roll -= m.recoil * .022;
    if (m.arriving) {
      final sailing = 1 - BossMotion.ramp(t, 2.4, 3.2);
      roll += math.sin(t * 2.6) * .03 * sailing;
    }
    // The bow lifts as a surge comes in under it and dips as it drains.
    final cycle = (t - boss.arrivalDuration) % SkyBoss.tidePeriod;
    if (boss.phase == BossPhase.attacking) {
      roll += BossMotion.pulse(cycle - SkyBoss.tideRiseAt, .9) * .035;
      roll -= BossMotion.pulse(cycle - SkyBoss.tideFallAt, 1.1) * .025;
    }
    return roll;
  }

  static void _rolled(Canvas c, double angle) {
    if (angle == 0) return;
    c.translate(0, waterline);
    c.rotate(angle);
    c.translate(0, -waterline);
  }

  /// How far below the sea the wreck has settled, in rig units.
  static double sunk(BossMotion m) {
    if (!m.defeated) return 0;
    final k = BossMotion.ramp(m.death, SkyBoss.burstAt + .25, 3.3);
    return k * k * 8.5;
  }

  /// The broken halves' tilt after the defeat.
  static double _tilt(BossMotion m) {
    if (!m.defeated || m.reducedMotion) return 0;
    final k = BossMotion.ramp(m.death, SkyBoss.burstAt, SkyBoss.burstAt + 1.6);
    return BossMotion.ease(k) * .42 + BossMotion.pulse(m.death - SkyBoss.burstAt, .3) * .05;
  }

  static bool _broken(BossMotion m) =>
      m.defeated && !m.reducedMotion && m.death >= SkyBoss.burstAt;

  /// Where the halves part, and the point on the keel each one tips about.
  static const _seamX = .95;
  static final _seam = [
    const Offset(.9, -6),
    const Offset(.98, -1.9),
    const Offset(.86, -1.2),
    const Offset(1.02, -.2),
    const Offset(.86, .5),
    const Offset(1.04, .98),
    const Offset(.88, 1.34),
    const Offset(1.02, 1.72),
    const Offset(.9, 2.1),
    const Offset(.96, 3),
  ];

  static Path _half({required bool left}) {
    final edge = left ? -8.0 : 8.0;
    return Path()
      ..moveTo(edge, -6)
      ..addPolygon([Offset(edge, -6), ..._seam, Offset(edge, 3)], true);
  }

  /// Runs [draw] once, or once per broken half after the defeat.
  static void _pieces(
    Canvas c,
    SkyBoss boss,
    BossMotion m,
    void Function(Canvas c, {required bool bowHalf}) draw,
  ) {
    final sink = sunk(m);
    if (!_broken(m)) {
      c.save();
      c.translate(0, sink);
      _rolled(c, roll(boss, m));
      draw(c, bowHalf: true);
      c.restore();
      return;
    }
    final tilt = _tilt(m);
    for (final left in [false, true]) {
      c.save();
      c.translate(left ? -tilt * .5 : tilt * .5, sink);
      c.translate(_seamX, keel);
      c.rotate(left ? tilt : -tilt * .8);
      c.translate(-_seamX, -keel);
      c.clipPath(_half(left: left));
      draw(c, bowHalf: left);
      c.restore();
    }
  }

  // ---------------------------------------------------------------- back --

  /// Masts, sails, rigging and flags, drawn behind the captain.
  static void back(Canvas c, SkyBoss boss, BossMotion m) {
    _pieces(c, boss, m, (c, {required bowHalf}) => _rigging(c, boss, m));
  }

  static double _time(SkyBoss boss, BossMotion m) =>
      m.reducedMotion ? 0.0 : boss.age;

  static void _rigging(Canvas c, SkyBoss boss, BossMotion m) {
    final t = _time(boss, m);
    final fury = boss.enraged && !m.defeated;
    // Sails fill as the ship sails in and luff for a beat after each shot.
    final fill = m.reducedMotion
        ? 1.0
        : (m.arriving ? .55 + .45 * BossMotion.ramp(boss.age, .9, 2.6) : 1.0) -
              m.recoil * .25;
    final breeze = math.sin(t * 1.7) * .04;
    // Stays and the bunting line run from the bowsprit to the masthead.
    const bowsprit = Offset(-3.72, .3);
    const masthead = Offset(.3, -3.46), topmast = Offset(.3, -4.2);
    for (final (from, to) in const [
      (bowsprit, masthead),
      (bowsprit, topmast),
      (Offset(.3, -4.2), Offset(2.42, -2.7)),
      (Offset(2.42, -2.7), Offset(3.2, .12)),
    ]) {
      c.drawLine(from, to, _line(_rope, .035));
    }
    _bunting(c, bowsprit, topmast, t);
    _mizzen(c, t, fill, breeze, fury);
    // Mainmast with its yards.
    _spar(c, const Offset(.3, 1.2), const Offset(.3, -4.36), .22, .12);
    _sailPanel(
      c,
      top: -1.66,
      left: -1.22,
      right: 1.86,
      bottom: .34,
      spread: .18,
      fill: fill,
      breeze: breeze,
      patches: true,
    );
    _yard(c, -1.72, -1.34, 1.98);
    _sailPanel(
      c,
      top: -3.0,
      left: -.8,
      right: 1.4,
      bottom: -1.92,
      spread: .14,
      fill: fill,
      breeze: -breeze,
      emblem: true,
      fury: fury,
    );
    _yard(c, -3.06, -.9, 1.5);
    _crowsNest(c);
    _flagOn(c, const Offset(.3, -4.3), t, fury: fury, width: 1.3, height: .78);
    // Shrouds with ratlines climb from the rail to the crow's nest.
    for (final (a, b, top) in const [
      (Offset(-.62, .9), Offset(-.32, .9), Offset(.12, -3.12)),
      (Offset(.98, .9), Offset(1.28, .9), Offset(.5, -3.12)),
    ]) {
      final shroud = _line(_rope, .03);
      c.drawLine(a, top, shroud);
      c.drawLine(b, top, shroud);
      for (var i = 1; i < 11; i++) {
        final k = i / 11;
        c.drawLine(
          Offset.lerp(a, top, k)!,
          Offset.lerp(b, top, k)!,
          _line(_rope.withValues(alpha: .8), .018),
        );
      }
    }
    // Sheets pull the mainsail's corners down to the rail.
    c.drawLine(const Offset(-1.4, .36), const Offset(-2.1, .9), _line(_rope, .03));
    c.drawLine(const Offset(2.04, .36), const Offset(2.5, .34), _line(_rope, .03));
  }

  static void _mizzen(
    Canvas c,
    double t,
    double fill,
    double breeze,
    bool fury,
  ) {
    _spar(c, const Offset(2.42, .5), const Offset(2.42, -2.76), .15, .09);
    _sailPanel(
      c,
      top: -2.18,
      left: 1.82,
      right: 3.0,
      bottom: -.92,
      spread: .12,
      fill: fill,
      breeze: breeze * .8,
    );
    _yard(c, -2.24, 1.72, 3.12);
    // A long pennant streams from the mizzen top.
    final wave = math.sin(t * 5.2);
    final pennant = Path()..moveTo(2.46, -2.72);
    const steps = 10;
    final top = <Offset>[], bottom = <Offset>[];
    for (var i = 0; i <= steps; i++) {
      final k = i / steps;
      final x = 2.46 + k * 1.25;
      final y = -2.72 + math.sin(k * 5 - t * 6.5) * .07 * k + k * .12;
      final half = .09 * (1 - k * .8);
      top.add(Offset(x, y - half));
      bottom.add(Offset(x, y + half));
    }
    pennant.addPolygon([...top, ...bottom.reversed], true);
    c.drawPath(pennant, _line(ink, .05));
    c.drawPath(pennant, _fill(fury ? _fury : _red));
    c.drawPath(
      Path()..addPolygon(top.take(6).toList(), false),
      _line(_bone.withValues(alpha: .5 + wave * .1), .02),
    );
  }

  static void _spar(Canvas c, Offset foot, Offset head, double w0, double w1) {
    final dx = (w0 - w1) / 2;
    final mast = Path()
      ..moveTo(foot.dx - w0 / 2, foot.dy)
      ..lineTo(head.dx - w1 / 2, head.dy)
      ..lineTo(head.dx + w1 / 2, head.dy)
      ..lineTo(foot.dx + w0 / 2, foot.dy)
      ..close();
    c.drawPath(mast, _line(ink, .06));
    c.drawPath(
      mast,
      Paint()
        ..shader = LinearGradient(
          colors: const [_mastLit, _mast, _mastDark],
          stops: const [0, .45, 1],
        ).createShader(
          Rect.fromLTRB(foot.dx - w0 / 2, head.dy, foot.dx + w0 / 2, foot.dy),
        ),
    );
    // Iron bands.
    for (var k = .18; k < 1; k += .21) {
      final y = foot.dy + (head.dy - foot.dy) * k;
      final half = (w0 + (w1 - w0) * k) / 2 + .01;
      c.drawLine(
        Offset(foot.dx - half, y),
        Offset(foot.dx + half, y),
        _line(ink.withValues(alpha: .75), .035),
      );
    }
    c.drawCircle(head, w1 * .75, _fill(ink));
    c.drawCircle(head, w1 * .5, _fill(_gold));
    c.drawLine(
      Offset(foot.dx - w0 / 2 + dx + .03, foot.dy),
      Offset(head.dx - w1 / 2 + .025, head.dy),
      _line(_mastLit.withValues(alpha: .7), .02),
    );
  }

  static void _yard(Canvas c, double y, double left, double right) {
    final yard = Path()
      ..moveTo(left, y)
      ..quadraticBezierTo((left + right) / 2, y + .05, right, y);
    c.drawPath(yard, _line(ink, .15));
    c.drawPath(yard, _line(_mast, .09));
    c.drawPath(
      Path()
        ..moveTo(left + .05, y - .025)
        ..quadraticBezierTo((left + right) / 2, y + .02, right - .05, y - .025),
      _line(_mastLit.withValues(alpha: .8), .025),
    );
    for (final x in [left, right]) {
      c.drawCircle(Offset(x, y), .06, _fill(ink));
    }
  }

  /// A square sail hanging from its yard, billowing with [fill].
  static void _sailPanel(
    Canvas c, {
    required double top,
    required double left,
    required double right,
    required double bottom,
    required double spread,
    required double fill,
    required double breeze,
    bool patches = false,
    bool emblem = false,
    bool fury = false,
  }) {
    final belly = (bottom - top) * .12 * fill;
    final bl = Offset(left - spread * fill, bottom);
    final br = Offset(right + spread * fill, bottom);
    final sail = Path()
      ..moveTo(left, top)
      ..quadraticBezierTo((left + right) / 2, top + .08, right, top)
      ..quadraticBezierTo(
        right + spread * 1.6 * fill,
        (top + bottom) / 2 + breeze,
        br.dx,
        br.dy,
      )
      ..quadraticBezierTo(
        (left + right) / 2,
        bottom + belly,
        bl.dx,
        bl.dy,
      )
      ..quadraticBezierTo(
        left - spread * 1.6 * fill,
        (top + bottom) / 2 - breeze,
        left,
        top,
      )
      ..close();
    final rect = Rect.fromLTRB(bl.dx, top, br.dx, bottom + belly);
    c.drawPath(sail, _line(ink, .08));
    c.drawPath(
      sail,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-.3, -.35),
          radius: 1.05,
          colors: const [_sail, _sail, _sailShade, _sailDeep],
          stops: const [0, .35, .8, 1],
        ).createShader(rect),
    );
    c.save();
    c.clipPath(sail);
    // Stitched cloths run top to bottom, bowing with the wind.
    final cloths = ((right - left) / .36).round();
    for (var i = 1; i < cloths; i++) {
      final x = left + (right - left) * i / cloths;
      final bow = (x - (left + right) / 2) * .12 * fill;
      c.drawPath(
        Path()
          ..moveTo(x, top)
          ..quadraticBezierTo(x + bow * 2, (top + bottom) / 2, x + bow * 3, bottom + belly),
        _line(_seam.withValues(alpha: .75), .022),
      );
    }
    // A reef band across the upper third.
    final reef = top + (bottom - top) * .22;
    c.drawPath(
      Path()
        ..moveTo(left - .3, reef)
        ..quadraticBezierTo((left + right) / 2, reef + .1, right + .3, reef),
      _line(_sailShade, .05),
    );
    for (var x = left + .12; x < right; x += .22) {
      c.drawLine(Offset(x, reef - .03), Offset(x, reef + .07), _line(_rope, .02));
    }
    if (patches) {
      _patch(c, Rect.fromLTWH(right - .66, top + .5, .34, .3), const Color(0xffa9bcc0), -.08);
      _patch(c, Rect.fromLTWH(left + .14, bottom - .72, .3, .36), const Color(0xffd6b98c), .1);
      // A stitched rip near the foot.
      final rip = Path()
        ..moveTo(right - .5, bottom - .4)
        ..lineTo(right - .36, bottom - .22)
        ..lineTo(right - .44, bottom - .08);
      c.drawPath(rip, _line(_sailDeep, .05));
      for (var i = 0; i < 3; i++) {
        final at = Offset(right - .47 + i * .03, bottom - .34 + i * .1);
        c.drawLine(at + const Offset(-.05, 0), at + const Offset(.05, 0), _line(_rope, .015));
      }
    }
    if (emblem) {
      _skull(
        c,
        Offset((left + right) / 2 + .05, (top + bottom) / 2 + .03),
        .34,
        color: fury ? _fury : const Color(0xff3a2830),
        eyes: _sail,
      );
    }
    // The shaded underside of the billow.
    c.drawPath(
      Path()
        ..moveTo(bl.dx + .1, bottom - .06)
        ..quadraticBezierTo((left + right) / 2, bottom + belly - .08, br.dx - .1, bottom - .06),
      _line(_sailDeep.withValues(alpha: .6), .08),
    );
    c.restore();
    // Bolt rope along the foot, tattered at one corner.
    c.drawPath(
      Path()
        ..moveTo(bl.dx, bl.dy)
        ..quadraticBezierTo((left + right) / 2, bottom + belly, br.dx, br.dy),
      _line(_sailDeep, .03),
    );
  }

  static void _patch(Canvas c, Rect r, Color color, double turn) {
    c.save();
    c.translate(r.center.dx, r.center.dy);
    c.rotate(turn);
    final patch = Rect.fromCenter(center: Offset.zero, width: r.width, height: r.height);
    c.drawRect(patch, _fill(color));
    final stitch = _line(ink.withValues(alpha: .7), .014);
    for (var x = patch.left + .04; x < patch.right; x += .07) {
      c.drawLine(Offset(x, patch.top - .02), Offset(x, patch.top + .02), stitch);
      c.drawLine(Offset(x, patch.bottom - .02), Offset(x, patch.bottom + .02), stitch);
    }
    for (var y = patch.top + .05; y < patch.bottom; y += .07) {
      c.drawLine(Offset(patch.left - .02, y), Offset(patch.left + .02, y), stitch);
      c.drawLine(Offset(patch.right - .02, y), Offset(patch.right + .02, y), stitch);
    }
    c.restore();
  }

  static void _crowsNest(Canvas c) {
    final nest = Path()
      ..moveTo(-.08, -3.46)
      ..lineTo(.68, -3.46)
      ..lineTo(.6, -3.08)
      ..quadraticBezierTo(.3, -3.02, 0, -3.08)
      ..close();
    c.drawPath(nest, _line(ink, .07));
    c.drawPath(
      nest,
      Paint()
        ..shader = const LinearGradient(
          colors: [_woodLit, _wood, _woodDeep],
        ).createShader(const Rect.fromLTRB(-.08, -3.46, .68, -3.04)),
    );
    for (final y in const [-3.36, -3.16]) {
      c.drawLine(Offset(-.06, y), Offset(.66, y), _line(_iron, .035));
    }
    for (var x = .08; x < .6; x += .14) {
      c.drawLine(Offset(x, -3.44), Offset(x, -3.1), _line(_plank.withValues(alpha: .5), .015));
    }
    c.drawLine(const Offset(-.12, -3.47), const Offset(.72, -3.47), _line(ink, .09));
    c.drawLine(const Offset(-.1, -3.47), const Offset(.7, -3.47), _line(_ochre, .04));
  }

  /// The Jolly Roger on its halyard at [at]; it turns red in fury.
  static void _flagOn(
    Canvas c,
    Offset at,
    double t, {
    required bool fury,
    required double width,
    required double height,
  }) {
    const steps = 12;
    final top = <Offset>[], bottom = <Offset>[];
    for (var i = 0; i <= steps; i++) {
      final k = i / steps;
      final wave = math.sin(k * 4.2 - t * 5.4) * .1 * k;
      top.add(at + Offset(k * width, wave + k * .06));
      bottom.add(at + Offset(k * width * .96, height + wave * 1.2 + k * .08));
    }
    // A ragged fly end.
    final fly = [
      top.last,
      top.last + const Offset(-.08, .18),
      top.last + const Offset(.02, .32),
      bottom.last + const Offset(-.1, -.2),
      bottom.last,
    ];
    final flag = Path()..addPolygon([...top, ...fly.skip(1), ...bottom.reversed], true);
    c.drawPath(flag, _line(ink, .07));
    c.drawPath(flag, _fill(fury ? _fury : _flag));
    c.drawPath(
      Path()..addPolygon(top, false),
      _line((fury ? const Color(0xffff7a7a) : const Color(0xff4a4458)).withValues(alpha: .8), .03),
    );
    final mid = (top[5] + bottom[5]) / 2;
    _skull(c, mid, .26, color: _bone, eyes: fury ? _fury : _flag);
  }

  /// Skull and crossbones in a single [color], eyes cut in [eyes].
  static void _skull(
    Canvas c,
    Offset at,
    double r, {
    required Color color,
    required Color eyes,
  }) {
    c.save();
    c.translate(at.dx, at.dy);
    c.scale(r);
    final bones = Path()
      ..moveTo(-1, -.6)
      ..lineTo(1, .8)
      ..moveTo(1, -.6)
      ..lineTo(-1, .8);
    c.drawPath(bones, _line(color, .28));
    for (final end in const [
      Offset(-1, -.6),
      Offset(1, .8),
      Offset(1, -.6),
      Offset(-1, .8),
    ]) {
      c.drawCircle(end + const Offset(-.08, 0), .15, _fill(color));
      c.drawCircle(end + const Offset(.08, .06), .15, _fill(color));
    }
    c.drawOval(const Rect.fromLTRB(-.62, -.8, .62, .36), _fill(color));
    c.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTRB(-.36, .05, .36, .6), const Radius.circular(.12)),
      _fill(color),
    );
    for (final x in const [-.25, .25]) {
      c.drawOval(Rect.fromCenter(center: Offset(x, -.18), width: .32, height: .34), _fill(eyes));
    }
    c.drawPath(
      Path()
        ..moveTo(0, .04)
        ..lineTo(-.08, .18)
        ..lineTo(.08, .18)
        ..close(),
      _fill(eyes),
    );
    for (final x in const [-.14, 0.0, .14]) {
      c.drawLine(Offset(x, .36), Offset(x, .56), _line(eyes, .06));
    }
    c.restore();
  }

  static void _bunting(Canvas c, Offset from, Offset to, double t) {
    const colors = [Color(0xffe8465a), _gold, Color(0xff4fd1c5), _bone];
    for (var i = 1; i < 11; i++) {
      final k = i / 11;
      final at = Offset.lerp(from, to, k)!;
      final sway = math.sin(t * 3 + i) * .04;
      final flag = Path()
        ..moveTo(at.dx - .09, at.dy - .07)
        ..lineTo(at.dx + .09, at.dy + .07)
        ..lineTo(at.dx + sway + .06, at.dy + .26)
        ..close();
      c.drawPath(flag, _line(ink, .035));
      c.drawPath(flag, _fill(colors[i % colors.length]));
    }
  }

  // --------------------------------------------------------------- front --

  /// The hull, bowsprit, stern castle and the cannon, drawn in front of the
  /// captain. [aim] is the barrel angle from [SkyBoss.cannonShot].
  static void front(Canvas c, SkyBoss boss, BossMotion m, {required double aim}) {
    _pieces(c, boss, m, (c, {required bowHalf}) {
      _hull(c, boss, m);
      if (_broken(m) && bowHalf) {
        _cannon(c, boss, m, aim, carriageRoll: 0);
      }
    });
    if (!_broken(m)) {
      // Drawn unrolled at its exact pivot; only the carriage follows the roll.
      c.save();
      c.translate(0, sunk(m));
      _cannon(c, boss, m, aim, carriageRoll: roll(boss, m));
      c.restore();
    }
  }

  static final _hullPath = Path()
    ..moveTo(bow, rail - .08)
    ..quadraticBezierTo(-1.6, rail + .03, -.2, rail)
    ..lineTo(1.56, rail)
    ..lineTo(1.66, .34)
    ..quadraticBezierTo(2.4, .3, stern + .1, .2)
    ..lineTo(stern + .16, .3)
    ..cubicTo(stern + .1, .9, stern, 1.4, stern - .22, waterline)
    ..cubicTo(stern - .42, keel - .05, stern - .8, keel, stern - 1.3, keel)
    ..lineTo(-1.7, keel)
    ..cubicTo(-2.2, keel, -2.42, waterline + .25, -2.5, waterline - .12)
    ..cubicTo(-2.56, 1.3, -2.62, 1.06, bow, rail - .08)
    ..close();

  static void _hull(Canvas c, SkyBoss boss, BossMotion m) {
    final fury = boss.enraged && !m.defeated;
    _bowsprit(c);
    final hull = _hullPath;
    const box = Rect.fromLTRB(bow, .2, stern + .2, keel);
    c.drawPath(hull.shift(const Offset(.05, .06)), _fill(ink.withValues(alpha: .35)));
    c.drawPath(hull, _line(ink, .16));
    c.drawPath(
      hull,
      _vertical(box, const [_woodLit, _wood, _woodDark, _woodDeep], const [0, .35, .7, 1]),
    );
    c.save();
    c.clipPath(hull);
    // Planks follow the sheer; butt joints stagger along each strake.
    for (var y = rail + .3; y < keel; y += .17) {
      final plank = Path()
        ..moveTo(bow - .2, y - .05)
        ..quadraticBezierTo(0, y + .03, stern + .3, y - .06);
      c.drawPath(plank, _line(_plank.withValues(alpha: .5), .025));
      final row = ((y - rail) / .17).round();
      for (var x = bow + .3 + (row % 3) * .45; x < stern; x += 1.35) {
        c.drawLine(Offset(x, y - .02), Offset(x, y + .12), _line(_plank.withValues(alpha: .35), .018));
      }
    }
    // The bulwark: a lighter strake under a gold-capped rail.
    c.drawPath(
      Path()
        ..moveTo(bow - .2, rail - .1)
        ..quadraticBezierTo(-1.6, rail + .02, -.2, rail - .01)
        ..lineTo(1.6, rail - .01)
        ..lineTo(1.6, rail + .22)
        ..lineTo(-.2, rail + .22)
        ..quadraticBezierTo(-1.6, rail + .25, bow - .2, rail + .12)
        ..close(),
      _fill(_woodLit.withValues(alpha: .45)),
    );
    // The stern castle's paneled side.
    c.drawRect(
      const Rect.fromLTRB(1.62, .2, 3.4, rail + .05),
      _vertical(const Rect.fromLTRB(1.6, .2, 3.4, 1), [_woodDark, _wood]),
    );
    for (final x in const [1.64, 2.24, 2.84]) {
      c.drawLine(Offset(x, .32), Offset(x, rail + .05), _line(_plank.withValues(alpha: .55), .03));
    }
    // A painted wale with gun ports.
    final wale = Path()
      ..moveTo(bow - .2, 1.02)
      ..quadraticBezierTo(0, 1.08, stern + .3, 1.0)
      ..lineTo(stern + .3, 1.28)
      ..quadraticBezierTo(0, 1.36, bow - .2, 1.3)
      ..close();
    c.drawPath(wale, _vertical(const Rect.fromLTRB(-3, 1, 3, 1.34), [_ochre, _ochreDeep]));
    for (final y in const [1.04, 1.29]) {
      c.drawPath(
        Path()
          ..moveTo(bow - .2, y + (y > 1.1 ? .02 : 0))
          ..quadraticBezierTo(0, y + .06, stern + .3, y - .02),
        _line(ink, .035),
      );
    }
    for (final x in const [-2.0, -.38, .56, 1.5, 2.44]) {
      _gunPort(c, Offset(x, 1.17), fury);
    }
    // Copper sheathing below the waterline, green with age.
    final copper = Path()
      ..moveTo(bow - .2, waterline - .06)
      ..quadraticBezierTo(0, waterline + .02, stern + .3, waterline - .08)
      ..lineTo(stern + .3, keel + .2)
      ..lineTo(bow - .2, keel + .2)
      ..close();
    c.drawPath(copper, _vertical(const Rect.fromLTRB(-3, 1.6, 3, 2.4), const [_copper, Color(0xff8a4a2c)]));
    for (var x = bow; x < stern; x += .32) {
      c.drawLine(Offset(x, waterline), Offset(x + .02, keel), _line(ink.withValues(alpha: .25), .02));
    }
    for (final (x, y, r) in const [(-1.6, 1.95, .16), (.3, 2.05, .2), (2.1, 1.92, .14)]) {
      c.drawOval(Rect.fromCenter(center: Offset(x, y), width: r * 3, height: r), _fill(_patina.withValues(alpha: .55)));
    }
    c.drawPath(
      Path()
        ..moveTo(bow - .2, waterline - .06)
        ..quadraticBezierTo(0, waterline + .02, stern + .3, waterline - .08),
      _line(_bone.withValues(alpha: .8), .04),
    );
    // Stern windows and the quarter gallery glow from inside.
    for (final x in const [1.92, 2.3]) {
      _window(c, Rect.fromLTWH(x, .44, .24, .28), fury);
    }
    _gallery(c, fury);
    // Warm highlight along the upper strake.
    c.drawPath(
      Path()
        ..moveTo(bow + .1, rail + .05)
        ..quadraticBezierTo(-1.6, rail + .11, -.2, rail + .08)
        ..lineTo(1.5, rail + .08),
      _line(_woodLit.withValues(alpha: .8), .03),
    );
    c.restore();
    // The cannon's embrasure: a gap in the bulwark over the bow deck.
    final notch = RRect.fromRectAndCorners(
      const Rect.fromLTRB(-1.7, rail - .06, -.78, 1.16),
      bottomLeft: const Radius.circular(.12),
      bottomRight: const Radius.circular(.12),
    );
    c.drawRRect(notch, _fill(_deck));
    c.drawLine(const Offset(-1.66, 1.1), const Offset(-.82, 1.1), _line(_woodLit.withValues(alpha: .35), .03));
    // Gold rail caps, broken by the embrasure.
    for (final cap in [
      Path()
        ..moveTo(bow, rail - .08)
        ..quadraticBezierTo(-2.1, rail - .03, -1.7, rail - .01),
      Path()
        ..moveTo(-.78, rail)
        ..lineTo(1.56, rail),
      Path()
        ..moveTo(1.66, .34)
        ..quadraticBezierTo(2.4, .3, stern + .1, .2),
    ]) {
      c.drawPath(cap, _line(ink, .12));
      c.drawPath(cap, _line(_ochre, .06));
      c.drawPath(cap, _line(_goldLight.withValues(alpha: .7), .018));
    }
    _balustrade(c);
    _anchor(c);
    _figurehead(c);
    _lantern(c, const Offset(3.2, -.36), fury, t: _time(boss, m));
    // Trim down the stern post.
    c.drawPath(
      Path()
        ..moveTo(stern + .16, .3)
        ..cubicTo(stern + .1, .9, stern, 1.4, stern - .22, waterline),
      _line(_gold, .05),
    );
  }

  static void _gunPort(Canvas c, Offset at, bool fury) {
    final port = Rect.fromCenter(center: at, width: .22, height: .19);
    c.drawRect(port.inflate(.03), _fill(ink));
    c.drawRect(port, _fill(fury ? const Color(0xff4a1414) : const Color(0xff1a0f10)));
    // A bronze muzzle peeks out.
    c.drawCircle(at + const Offset(-.02, .01), .06, _fill(_bronzeDeep));
    c.drawCircle(at + const Offset(-.02, .01), .035, _fill(ink));
    // The red lid hinged open above the port.
    final lid = Path()
      ..moveTo(port.left - .02, port.top - .02)
      ..lineTo(port.right + .02, port.top - .02)
      ..lineTo(port.right - .01, port.top - .13)
      ..lineTo(port.left + .01, port.top - .13)
      ..close();
    c.drawPath(lid, _fill(_red));
    c.drawPath(lid, _line(ink, .025));
  }

  static void _window(Canvas c, Rect r, bool fury) {
    final arch = RRect.fromRectAndCorners(
      r,
      topLeft: Radius.circular(r.width / 2),
      topRight: Radius.circular(r.width / 2),
    );
    c.drawRRect(arch.inflate(.04), _fill(ink));
    c.drawRRect(arch.inflate(.02), _fill(_goldDeep));
    c.drawRRect(
      arch,
      _vertical(r, [fury ? _windowHot : _window, fury ? const Color(0xffd6452f) : _glow]),
    );
    c.drawLine(Offset(r.center.dx, r.top), Offset(r.center.dx, r.bottom), _line(ink, .025));
    c.drawLine(Offset(r.left, r.center.dy), Offset(r.right, r.center.dy), _line(ink, .025));
  }

  static void _gallery(Canvas c, bool fury) {
    final box = Path()
      ..moveTo(2.66, .3)
      ..lineTo(3.12, .3)
      ..quadraticBezierTo(3.2, .7, 3.04, 1.08)
      ..quadraticBezierTo(2.86, 1.2, 2.72, 1.06)
      ..close();
    c.drawPath(box, _line(ink, .06));
    c.drawPath(box, _vertical(const Rect.fromLTRB(2.6, .3, 3.2, 1.2), [_woodLit, _woodDark]));
    _window(c, const Rect.fromLTWH(2.78, .42, .2, .3), fury);
    c.drawPath(
      Path()
        ..moveTo(2.7, .86)
        ..quadraticBezierTo(2.92, .96, 3.1, .82),
      _line(_gold, .045),
    );
    c.drawCircle(const Offset(2.9, 1.04), .05, _fill(_gold));
  }

  static void _balustrade(Canvas c) {
    // Turned posts along the quarterdeck.
    final post = _line(ink, .07);
    final wood = _line(_woodLit, .035);
    for (var x = 1.76; x < stern; x += .2) {
      final y = .33 - (x - 1.66) * .1 / 1.4;
      c.drawLine(Offset(x, y), Offset(x, y - .22), post);
      c.drawLine(Offset(x, y), Offset(x, y - .22), wood);
    }
    final top = Path()
      ..moveTo(1.66, .1)
      ..quadraticBezierTo(2.4, .06, stern + .1, -.04);
    c.drawPath(top, _line(ink, .1));
    c.drawPath(top, _line(_ochre, .05));
  }

  static void _bowsprit(Canvas c) {
    final spar = Path()
      ..moveTo(-2.1, .98)
      ..lineTo(-2.3, .76)
      ..lineTo(-3.8, .27)
      ..lineTo(-3.76, .36)
      ..close();
    c.drawPath(spar, _line(ink, .1));
    c.drawPath(spar, _fill(_mast));
    c.drawLine(const Offset(-2.3, .8), const Offset(-3.74, .31), _line(_mastLit.withValues(alpha: .7), .025));
    for (final x in const [-2.9, -3.35]) {
      final y = .76 + (x + 2.3) * .325;
      c.drawLine(Offset(x, y - .08), Offset(x + .04, y + .08), _line(_iron, .04));
    }
  }

  static void _figurehead(Canvas c) {
    // A gilded scroll and a carved skull on the bow.
    const at = Offset(-2.5, .98);
    final scroll = Path()
      ..moveTo(at.dx + .3, at.dy - .12)
      ..quadraticBezierTo(at.dx - .08, at.dy - .2, at.dx - .12, at.dy + .06)
      ..quadraticBezierTo(at.dx - .1, at.dy + .22, at.dx + .06, at.dy + .16)
      ..quadraticBezierTo(at.dx + .1, at.dy + .02, at.dx - .02, at.dy + .04);
    c.drawPath(scroll, _line(ink, .1));
    c.drawPath(scroll, _line(_gold, .05));
    _skull(c, const Offset(-2.0, 1.44), .16, color: _goldLight, eyes: ink);
    c.drawPath(
      Path()
        ..moveTo(-2.36, 1.36)
        ..quadraticBezierTo(-2.2, 1.5, -2.26, 1.62)
        ..moveTo(-1.64, 1.36)
        ..quadraticBezierTo(-1.8, 1.5, -1.74, 1.62),
      _line(_gold, .035),
    );
  }

  static void _anchor(Canvas c) {
    const top = Offset(-1.94, .98);
    c.drawLine(const Offset(-1.9, rail + .02), top, _line(_iron, .05));
    final anchor = Path()
      ..moveTo(top.dx, top.dy)
      ..lineTo(top.dx, top.dy + .5)
      ..moveTo(top.dx - .12, top.dy + .1)
      ..lineTo(top.dx + .12, top.dy + .1)
      ..moveTo(top.dx - .2, top.dy + .34)
      ..quadraticBezierTo(top.dx - .18, top.dy + .52, top.dx, top.dy + .52)
      ..quadraticBezierTo(top.dx + .18, top.dy + .52, top.dx + .2, top.dy + .34);
    c.drawPath(anchor, _line(ink, .1));
    c.drawPath(anchor, _line(_iron, .055));
    c.drawPath(anchor, _line(_ironLit.withValues(alpha: .6), .015));
    c.drawCircle(top, .05, _line(ink, .04));
    for (final x in const [-.2, .2]) {
      c.drawPath(
        Path()
          ..moveTo(top.dx + x, top.dy + .34)
          ..lineTo(top.dx + x * 1.15, top.dy + .26)
          ..lineTo(top.dx + x * .8, top.dy + .3)
          ..close(),
        _fill(_iron),
      );
    }
  }

  static void _lantern(Canvas c, Offset at, bool fury, {required double t}) {
    // An ornate stern lantern on a curled bracket.
    c.drawPath(
      Path()
        ..moveTo(stern + .02, .25)
        ..quadraticBezierTo(at.dx + .02, .2, at.dx, at.dy + .2),
      _line(ink, .07),
    );
    final body = Path()
      ..moveTo(at.dx - .1, at.dy - .14)
      ..lineTo(at.dx + .1, at.dy - .14)
      ..lineTo(at.dx + .13, at.dy + .12)
      ..lineTo(at.dx + .06, at.dy + .2)
      ..lineTo(at.dx - .06, at.dy + .2)
      ..lineTo(at.dx - .13, at.dy + .12)
      ..close();
    final flicker = t == 0 ? 0.0 : math.sin(t * 9) * .04 + math.sin(t * 23) * .03;
    c.drawPath(body, _line(ink, .06));
    c.drawPath(
      body,
      _vertical(body.getBounds(), [
        _bone,
        Color.lerp(fury ? _windowHot : _window, _bone, .2 + flicker)!,
        fury ? const Color(0xffd6452f) : _glow,
      ]),
    );
    c.drawLine(Offset(at.dx, at.dy - .14), Offset(at.dx, at.dy + .2), _line(_goldDeep, .03));
    final cap = Path()
      ..moveTo(at.dx - .15, at.dy - .13)
      ..lineTo(at.dx, at.dy - .3)
      ..lineTo(at.dx + .15, at.dy - .13)
      ..close();
    c.drawPath(cap, _line(ink, .05));
    c.drawPath(cap, _fill(_gold));
    c.drawCircle(Offset(at.dx, at.dy - .34), .05, _line(ink, .03));
    c.drawLine(
      Offset(at.dx - .08, at.dy + .22),
      Offset(at.dx + .08, at.dy + .22),
      _line(_goldDeep, .05),
    );
  }

  /// Warm light from the lanterns and stern windows, drawn over the ship
  /// (and over its silhouette as it sails in out of the dusk).
  static void lights(Canvas c, SkyBoss boss, BossMotion m, {double alpha = 1}) {
    if (alpha <= 0 || (m.defeated && m.death > SkyBoss.burstAt)) return;
    final fury = boss.enraged && !m.defeated;
    final t = _time(boss, m);
    final flicker = t == 0 ? 0.0 : math.sin(t * 9) * .06 + math.sin(t * 23) * .04;
    final color = fury ? _windowHot : _glow;
    c.save();
    c.translate(0, sunk(m));
    _rolled(c, roll(boss, m));
    for (final (at, r, a) in const [
      (Offset(3.2, -.36), .75, .42),
      (Offset(2.14, .58), .5, .22),
      (Offset(2.88, .58), .42, .22),
    ]) {
      final glow = Rect.fromCircle(center: at, radius: r * (1 + flicker));
      c.drawCircle(
        at,
        glow.width / 2,
        Paint()
          ..shader = RadialGradient(
            colors: [
              color.withValues(alpha: a * alpha),
              color.withValues(alpha: a * .35 * alpha),
              color.withValues(alpha: 0),
            ],
            stops: const [0, .35, 1],
          ).createShader(glow),
      );
    }
    c.restore();
  }

  // -------------------------------------------------------------- cannon --

  /// Where the wick meets the breech and where its tip curls, in rig
  /// units, for a barrel at [aim].
  static (Offset hole, Offset tip) fuse(double aim) {
    final d = Offset(math.cos(aim), math.sin(aim));
    final n = Offset(-math.sin(aim), math.cos(aim));
    final hole = pivot + d * -.14 + n * .26;
    return (hole, hole + const Offset(.06, -.36));
  }

  static void _cannon(
    Canvas c,
    SkyBoss boss,
    BossMotion m,
    double aim, {
    required double carriageRoll,
  }) {
    final kick = m.reducedMotion ? 0.0 : m.recoil;
    final fury = boss.enraged && !m.defeated;
    // Far cheek of the bed, then the barrel, then the near cheek over the
    // breech.
    c.save();
    c.translate(pivot.dx + kick * .06, pivot.dy);
    c.rotate(carriageRoll);
    c.translate(-pivot.dx, -pivot.dy);
    _bed(c, far: true);
    c.restore();
    c.save();
    c.translate(pivot.dx, pivot.dy);
    c.rotate(aim);
    c.scale(1, -1);
    c.translate(-kick * .13, 0);
    _barrel(c, boss, m, fury);
    c.restore();
    c.save();
    c.translate(pivot.dx + kick * .06, pivot.dy);
    c.rotate(carriageRoll);
    c.translate(-pivot.dx, -pivot.dy);
    _bed(c, far: false);
    c.restore();
    // The trunnion cap.
    c.drawCircle(pivot, .1, _fill(ink));
    c.drawCircle(pivot, .07, _fill(_iron));
    c.drawCircle(pivot, .035, _fill(_gold));
    _wick(c, boss, m, aim);
  }

  static void _bed(Canvas c, {required bool far}) {
    if (far) {
      final cheek = Path()
        ..moveTo(-1.62, 1.14)
        ..lineTo(-1.55, .86)
        ..quadraticBezierTo(-1.4, .66, -1.12, .72)
        ..quadraticBezierTo(-.92, .78, -.84, .98)
        ..lineTo(-.82, 1.14)
        ..close();
      c.drawPath(cheek, _fill(_redDeep));
      c.drawPath(cheek, _line(ink, .06));
      return;
    }
    // Wheels (trucks) under the near cheek.
    for (final x in const [-1.46, -.98]) {
      c.drawCircle(Offset(x, 1.05), .12, _fill(ink));
      c.drawCircle(Offset(x, 1.05), .085, _fill(_woodDark));
      c.drawCircle(Offset(x, 1.05), .03, _fill(_iron));
    }
    final cheek = Path()
      ..moveTo(-1.6, 1.02)
      ..lineTo(-1.56, .9)
      ..lineTo(-1.34, .9)
      ..lineTo(-1.3, .8)
      ..lineTo(-1.04, .8)
      ..quadraticBezierTo(-.86, .82, -.84, 1.02)
      ..close();
    c.drawPath(cheek, _line(ink, .07));
    c.drawPath(cheek, _vertical(cheek.getBounds(), const [Color(0xffd65a5a), _red, _redDeep]));
    c.drawLine(const Offset(-1.56, .96), const Offset(-.86, .96), _line(_iron, .035));
    for (final x in const [-1.46, -1.18, -.96]) {
      c.drawCircle(Offset(x, .96), .025, _fill(_ironLit));
    }
  }

  static void _barrel(Canvas c, SkyBoss boss, BossMotion m, bool fury) {
    // Local frame: +x toward the muzzle, -y the barrel's sky side.
    const len = barrel;
    final body = Path()
      ..moveTo(-.4, -.27)
      ..lineTo(len - .16, -.22)
      ..lineTo(len - .12, -.29)
      ..lineTo(len, -.29)
      ..lineTo(len, .29)
      ..lineTo(len - .12, .29)
      ..lineTo(len - .16, .22)
      ..lineTo(-.4, .27)
      ..quadraticBezierTo(-.52, 0, -.4, -.27)
      ..close();
    c.drawCircle(const Offset(-.56, 0), .1, _fill(ink));
    c.drawCircle(const Offset(-.56, 0), .065, _fill(_bronze));
    c.drawLine(const Offset(-.56, 0), const Offset(-.44, 0), _line(ink, .1));
    c.drawPath(body, _line(ink, .1));
    final heat = fury ? .35 : 0.0;
    c.drawPath(
      body,
      _vertical(const Rect.fromLTRB(-.5, -.3, .7, .3), [
        _bronzeLit,
        Color.lerp(_bronze, _windowHot, heat)!,
        _bronzeDeep,
      ], const [.1, .45, 1]),
    );
    // Reinforcing rings and a sky-side gleam.
    for (final x in const [-.3, .08, .34]) {
      c.drawLine(Offset(x, -.27), Offset(x, .27), _line(ink, .06));
      c.drawLine(Offset(x + .03, -.26), Offset(x + .03, .26), _line(_bronzeLit.withValues(alpha: .7), .025));
    }
    c.drawLine(const Offset(-.36, -.16), Offset(len - .2, -.13), _line(_bronzeLit.withValues(alpha: .85), .05));
    // The bore: a dark mouth big enough for the ball.
    final bore = Rect.fromCenter(center: const Offset(len - .015, 0), width: .1, height: .44);
    c.drawOval(bore, _fill(ink));
    c.drawOval(bore.deflate(.02), _fill(const Color(0xff120c0e)));
    if (fury) {
      c.drawOval(bore.deflate(.05), _fill(_windowHot.withValues(alpha: .6)));
    }
  }

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
    c.drawPath(wick, _line(ink, .07));
    c.drawPath(wick, _line(const Color(0xffd8b27a), .035));
    if (boss.charge <= 0) return;
    final spark = along(left);
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
    final glow = Rect.fromCircle(center: spark, radius: .32);
    c.drawCircle(
      spark,
      .32,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xffffe08a).withValues(alpha: .7),
            const Color(0xffff8a3a).withValues(alpha: 0),
          ],
        ).createShader(glow),
    );
    for (var i = 0; i < 6; i++) {
      final a = i * math.pi / 3 + t * 7;
      final r = (.1 + (i.isEven ? .07 : .02)) * flare;
      c.drawLine(
        spark,
        spark + Offset(math.cos(a), math.sin(a)) * r,
        _line(const Color(0xffffd05a), .025),
      );
    }
    c.drawCircle(spark, .05 * flare, _fill(const Color(0xfffff6d8)));
  }

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
    final broadside = boss.enraged && boss.volleys % 3 == 0 && boss.volleys > 0;
    final big = broadside ? 1.35 : 1.0;
    final d = Offset(math.cos(aim), math.sin(aim));
    // Smoke: overlapping puffs roll out along the barrel, rise and thin.
    final k = BossMotion.ramp(since, 0, 1.3);
    final fade = 1 - BossMotion.ease(BossMotion.ramp(since, .5, 1.3));
    if (fade > 0) {
      final grow = m.reducedMotion ? .7 : 1 - math.pow(1 - k, 3).toDouble();
      final puffs = <(Offset, double)>[];
      for (var i = 0; i < 7; i++) {
        final spread = (i - 3) * .12;
        final out = .25 + (i % 3) * .3;
        final dir = Offset(
          d.dx * math.cos(spread) - d.dy * math.sin(spread),
          d.dx * math.sin(spread) + d.dy * math.cos(spread),
        );
        final rise = m.reducedMotion ? 0.0 : k * k * .6;
        final at = muzzle + (dir * out * grow + Offset(0, -rise)) * unit * big;
        puffs.add((at, unit * big * (.16 + (i % 2) * .08) * (.5 + grow * .8)));
      }
      final rim = _fill(const Color(0xff4b4a57).withValues(alpha: .55 * fade));
      for (final (at, r) in puffs) {
        c.drawCircle(at, r + unit * .04, rim);
      }
      for (final (at, r) in puffs) {
        c.drawCircle(at, r, _fill(const Color(0xffb9bcc6).withValues(alpha: fade)));
      }
      for (final (at, r) in puffs) {
        c.drawCircle(
          at + Offset(-r * .18, -r * .2),
          r * .68,
          _fill(const Color(0xfff2f0ea).withValues(alpha: fade)),
        );
      }
    }
    // The flash: a hot star thrown along the barrel for a few frames.
    final flash = BossMotion.ramp(since, 0, m.reducedMotion ? .2 : .14);
    if (flash < 1) {
      final size = unit * .62 * big * (m.reducedMotion ? 1 : 1 - flash * .5);
      final shape = Path();
      for (var i = 0; i < 16; i++) {
        final a = aim + i * math.pi / 8;
        final along = math.cos(a - aim);
        final reach = (i.isEven ? 1.0 : .45) * (.7 + .5 * math.max(0, along));
        final p = muzzle + d * size * .35 + Offset(math.cos(a), math.sin(a)) * size * reach;
        i == 0 ? shape.moveTo(p.dx, p.dy) : shape.lineTo(p.dx, p.dy);
      }
      shape.close();
      final alpha = 1 - flash;
      c.drawPath(shape, _line(const Color(0xffd75e4f).withValues(alpha: alpha), unit * .06));
      c.drawPath(shape, _fill(const Color(0xffffd45b).withValues(alpha: alpha)));
      c.drawCircle(
        muzzle + d * size * .3,
        size * .38,
        _fill(const Color(0xfffff6d8).withValues(alpha: alpha)),
      );
    }
  }
}
