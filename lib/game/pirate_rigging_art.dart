import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../domain/sky_boss.dart';
import 'boss_motion.dart';
import 'pirate_ship_art.dart';

/// The wind and wear this frame: every sail, flag and line reads from one.
class _Wind {
  const _Wind({
    required this.t,
    required this.fill,
    required this.breeze,
    required this.fury,
    required this.torn,
    required this.wear,
    required this.whip,
    required this.slack,
    required this.duck,
    required this.still,
  });

  /// Seconds of sway (0 under Reduced Motion).
  final double t;

  /// How full the sails are, 1 = drawing, less = luffing.
  final double fill;

  /// A slow lateral push on the sail edges.
  final double breeze;

  /// 0 to 1 and beyond: how hard the flags snap.
  final double whip;

  /// 0 to 1: the wreck's sails and flags going slack.
  final double slack;

  /// 0 to 1: how far the lookout has ducked below the rim.
  final double duck;
  final bool fury, still;

  /// The sails are ripped open: from half health on, even in defeat.
  final bool torn;

  /// 0 to 1: how much damage the ship has taken; shot holes appear as it
  /// climbs, well before the sails tear.
  final double wear;
}

class _Patch {
  const _Patch(this.x, this.y, this.w, this.h, this.turn, this.color);
  final double x, y, w, h, turn;
  final Color color;
}

/// A ragged bite out of a sail's foot, [from] to [to] as fractions of it.
class _Bite {
  const _Bite(this.from, this.to, this.depth);
  final double from, to, depth;
}

/// A slit or stitched rip from [from] to [to], [width] across at its widest.
class _Tear {
  const _Tear(this.from, this.to, this.width);
  final Offset from, to;
  final double width;
}

class _Sail {
  const _Sail({
    required this.top,
    required this.left,
    required this.right,
    required this.bottom,
    this.spread = .16,
    this.panels = 6,
    this.reef = .24,
    this.patches = const [],
    this.mends = const [],
    this.holes = const [],
    this.bites = const [],
    this.furyBites = const [],
    this.furyTears = const [],
    this.wounds = const [],
    this.emblem = false,
    this.umbra = false,
  });

  final double top, left, right, bottom, spread, reef;
  final int panels;
  final List<_Patch> patches;
  final List<_Tear> mends, furyTears;
  final List<Offset> holes;

  /// Shot holes that open once the ship has taken this much damage.
  final List<(Offset, double)> wounds;
  final List<_Bite> bites, furyBites;

  /// A painted Jolly Roger in the middle of the cloth.
  final bool emblem;

  /// The captain stands in front of this sail: darken the cloth behind him.
  final bool umbra;
}

/// The Pirate Captain's masts, sails, rigging and flags: a brigantine with a
/// square-rigged foremast and a gaff-rigged main, patched canvas that tears
/// wider in fury, ratlines, blocks, a lookout in the crow's nest, a Jolly
/// Roger that ripples like cloth and a swallowtail pennant.
///
/// Authored in the captain's rig units (1 = [SkyBoss.radius]) like
/// [PirateShipArt], which calls [paint] once behind the captain. Pure and
/// seekable: everything derives from the boss and [BossMotion].
abstract final class PirateRiggingArt {
  static const _ink = PirateShipArt.ink;

  // Canvas, warm and weathered: lower in value than the captain's dark hat.
  static const _cloth = Color(0xffeedab0), _clothLit = Color(0xfffcefd2);
  static const _clothShade = Color(0xffd6ba8a), _clothDeep = Color(0xffaa8558);
  static const _stitch = Color(0xff9c7b52), _boltRope = Color(0xffbf9a66);
  static const _hole = Color(0xff2b1d24), _singe = Color(0xff5c3a28);
  // Timber and iron.
  static const _wood = Color(0xff8c5a38), _woodLit = Color(0xffc58a58);
  static const _woodDark = Color(0xff5a3423), _woodDeep = Color(0xff3f2119);
  static const _iron = Color(0xff454a58), _ironLit = Color(0xff8d95a8);
  static const _rope = Color(0xff56392a), _ropeLit = Color(0xffa98258);
  static const _gold = Color(0xffffcf5c), _goldLight = Color(0xfffff0b4);
  static const _ochre = Color(0xffd9a441), _bronze = Color(0xffbd843c);
  // Flags.
  static const _bone = Color(0xfffff4dd), _boneShade = Color(0xffd6c6a4);
  static const _blackDeep = Color(0xff15121b);
  static const _blood = Color(0xffc22f3f), _bloodDeep = Color(0xff7c1526);
  static const _red = Color(0xffb8404a), _ember = Color(0xffff8a4a);
  static const _teal = Color(0xff3fbdb2), _skin = Color(0xffc98a58);

  static Paint _fill(Color color) => Paint()..color = color;
  static Paint _line(Color color, double width) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  /// Unit soft light and shade, drawn scaled and moved to place them.
  static final _glow = Paint()
    ..shader = const RadialGradient(
      colors: [Color(0xb8fff6dc), Color(0x00fff6dc)],
    ).createShader(const Rect.fromLTWH(-1, -1, 2, 2));
  static final _stainPaint = Paint()
    ..shader = const RadialGradient(
      colors: [Color(0x4d7a5230), Color(0x007a5230)],
    ).createShader(const Rect.fromLTWH(-1, -1, 2, 2));
  static final _umbraPaint = Paint()
    ..shader = const RadialGradient(
      colors: [Color(0x8c6c4a2c), Color(0x006c4a2c)],
      stops: [.15, 1],
    ).createShader(const Rect.fromLTWH(-1, -1, 2, 2));

  /// Deterministic 0..1 variation from an integer.
  static double _h(int n) =>
      (math.sin(n * 12.9898 + 4.1414) * 43758.5453).abs() % 1;

  static void _soft(Canvas c, Paint paint, Offset at, double rx, double ry) {
    c.save();
    c.translate(at.dx, at.dy);
    c.scale(rx, ry);
    c.drawCircle(Offset.zero, 1, paint);
    c.restore();
  }

  // ---------------------------------------------------------------- data --

  static const _course = _Sail(
    top: -1.66,
    left: -1.22,
    right: 1.86,
    bottom: .34,
    spread: .18,
    panels: 7,
    umbra: true,
    patches: [
      _Patch(1.56, -1.06, .38, .34, -.08, Color(0xffa3b9bf)),
      _Patch(-.9, -1.02, .32, .36, .1, Color(0xffd0ae7a)),
      _Patch(1.62, -.5, .26, .3, .14, Color(0xffb96a5c)),
    ],
    mends: [_Tear(Offset(1.64, .0), Offset(1.74, .24), .05)],
    bites: [_Bite(.84, .95, .13), _Bite(.1, .17, .07)],
    furyBites: [
      _Bite(.72, .97, .36),
      _Bite(.06, .3, .27),
      _Bite(.44, .55, .16),
    ],
    furyTears: [
      _Tear(Offset(1.42, .3), Offset(1.08, -.72), .36),
      _Tear(Offset(-.72, .3), Offset(-.42, -.62), .26),
    ],
    wounds: [(Offset(-.98, -.56), .28), (Offset(1.3, -1.42), .38)],
  );

  static const _topsail = _Sail(
    top: -3.0,
    left: -.8,
    right: 1.4,
    bottom: -1.92,
    spread: .14,
    panels: 5,
    reef: .26,
    emblem: true,
    patches: [_Patch(1.12, -2.28, .26, .26, .09, Color(0xffc9a878))],
    mends: [_Tear(Offset(-.56, -2.16), Offset(-.46, -1.98), .04)],
    holes: [Offset(-.5, -2.66)],
    bites: [_Bite(.04, .13, .08)],
    furyBites: [_Bite(.58, .82, .24), _Bite(.05, .22, .18)],
    furyTears: [_Tear(Offset(1.2, -1.94), Offset(.98, -2.6), .26)],
    wounds: [(Offset(1.12, -2.72), .12)],
  );

  // ---------------------------------------------------------------- paint --

  /// Masts, sails, rigging and flags, behind the captain.
  static void paint(Canvas c, SkyBoss boss, BossMotion m) {
    final still = m.reducedMotion;
    final t = still ? 0.0 : boss.age;
    final fury = boss.enraged && !m.defeated;
    // Sails fill as the ship sails in, luff for a beat after each shot and go
    // slack once she is beaten.
    final slack = m.defeated && !still
        ? BossMotion.ease(BossMotion.ramp(m.death, 0, .5))
        : 0.0;
    final fill = still
        ? 1.0
        : (m.arriving ? .55 + .45 * BossMotion.ramp(boss.age, .9, 2.6) : 1.0) -
              m.recoil * .25 -
              slack * .5 +
              math.sin(t * 1.25 + .6) * .03;
    final sailing = m.arriving && !still
        ? 1 - BossMotion.ramp(boss.age, 2.4, 3.2)
        : 0.0;
    final w = _Wind(
      t: t,
      fill: fill,
      // A gentle swell of wind, and a shudder when a shot lands.
      breeze:
          math.sin(t * 1.7) * .04 +
          math.sin(t * 3.3 + 1) * .012 +
          (still ? 0.0 : m.hit * math.sin(t * 38) * .03),
      fury: fury,
      torn: boss.enraged,
      wear: (1 - boss.hp / boss.maxHp).clamp(0.0, 1.0),
      whip:
          (fury ? 1.0 : 0.0) +
          (still
              ? 0.0
              : m.rage * .8 + sailing * .5 + m.recoil * .6 + m.hit * .5),
      slack: slack,
      duck: m.defeated
          ? 1.0
          : still
          ? 0.0
          : m.recoil * .6,
      still: still,
    );
    _stays(c, w);
    _gaffRig(c, w);
    // Lower mast, the square sails and their yards.
    _beam(c, const Offset(.3, 1.2), const Offset(.3, -3.3), .22, .15);
    _bands(c, const Offset(.3, 1.2), const Offset(.3, -3.3), .22, .15);
    _square(c, _course, w, sway: w.breeze);
    _yard(c, -1.72, -1.34, 1.98);
    _streamer(c, const Offset(2.0, -1.72), w, const Color(0xffe8465a));
    _square(c, _topsail, w, sway: -w.breeze);
    _yard(c, -3.06, -.9, 1.5);
    _streamer(c, const Offset(1.52, -3.06), w, _teal, length: .4, seed: 4);
    _ladders(c);
    _tackle(c, w);
    _nest(c, w);
    _topmast(c, w);
    _wheel(c, w);
  }

  // ---------------------------------------------------------- stays, lines --

  static const _bowsprit = Offset(-3.72, .3);
  static const _topHead = Offset(.3, -4.22);

  /// A rope from [a] to [b] with a little droop.
  static void _cord(
    Canvas c,
    Offset a,
    Offset b, {
    double sag = 0,
    double width = .03,
    bool heavy = false,
  }) {
    final mid = Offset.lerp(a, b, .5)! + Offset(0, sag);
    final path = Path()
      ..moveTo(a.dx, a.dy)
      ..quadraticBezierTo(mid.dx, mid.dy, b.dx, b.dy);
    if (heavy) {
      c.drawPath(path, _line(_ink.withValues(alpha: .55), width + .026));
    }
    c.drawPath(path, _line(_rope, width));
  }

  static void _stays(Canvas c, _Wind w) {
    // The forestays run from the bowsprit to the masthead; the bunting hangs
    // from the upper one. The main stay carries on to the aft mast.
    _cord(c, _bowsprit, const Offset(.14, -3.42), sag: .05, heavy: true);
    _cord(c, _bowsprit, _topHead, sag: .06, width: .034, heavy: true);
    _cord(c, _topHead, const Offset(2.42, -3.06), sag: .05, heavy: true);
    _bunting(c, w);
  }

  static void _bunting(Canvas c, _Wind w) {
    const colors = [Color(0xffe8465a), _gold, _teal, _bone];
    final mid = Offset.lerp(_bowsprit, _topHead, .5)! + const Offset(0, .06);
    Offset at(double u) {
      final v = 1 - u;
      return _bowsprit * (v * v) + mid * (2 * u * v) + _topHead * (u * u);
    }

    final fills = List.generate(colors.length, (_) => Path());
    final outline = Path(), shade = Path();
    for (var i = 0; i < 9; i++) {
      final u = .08 + i * .088;
      final p = at(u), q = at(u + .02);
      final d = (q - p) / (q - p).distance;
      final left = p - d * .09, right = p + d * .09;
      final sway = math.sin(w.t * 3.1 + i * 1.3) * .05 + .03;
      final tip = p + Offset(sway, .27 + (i.isEven ? .02 : 0));
      final flag = Path()
        ..moveTo(left.dx, left.dy)
        ..lineTo(right.dx, right.dy)
        ..lineTo(tip.dx, tip.dy)
        ..close();
      fills[i % colors.length].addPath(flag, Offset.zero);
      outline.addPath(flag, Offset.zero);
      shade
        ..moveTo(right.dx, right.dy)
        ..lineTo(tip.dx, tip.dy)
        ..lineTo(p.dx + .01, p.dy + .05)
        ..close();
    }
    for (var i = 0; i < colors.length; i++) {
      c.drawPath(fills[i], _fill(colors[i]));
    }
    c.drawPath(shade, _fill(_ink.withValues(alpha: .2)));
    c.drawPath(outline, _line(_ink, .035));
  }

  /// A small wooden block with a sheave, turned by [turn].
  static void _block(Canvas c, Offset at, {double turn = 0, double size = 1}) {
    c.save();
    c.translate(at.dx, at.dy);
    c.rotate(turn);
    c.scale(size);
    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: .1, height: .17),
      const Radius.circular(.04),
    );
    c.drawRRect(body.inflate(.02), _fill(_ink));
    c.drawRRect(body, _fill(_woodLit));
    c.drawCircle(Offset.zero, .028, _fill(_woodDeep));
    c.drawCircle(Offset.zero, .012, _fill(_gold));
    c.restore();
  }

  /// A ribbon whipping from a yardarm.
  static void _streamer(
    Canvas c,
    Offset from,
    _Wind w,
    Color color, {
    double length = .5,
    int seed = 0,
  }) {
    const steps = 7;
    final top = <Offset>[], bottom = <Offset>[];
    final speed = 7 + w.whip * 2;
    for (var i = 0; i <= steps; i++) {
      final k = i / steps;
      final wave =
          math.sin(k * 6 - w.t * speed + seed) *
          (.012 + .045 * k) *
          (1 + w.whip * .5);
      final p =
          from +
          Offset(
            k * length * (1 - w.slack * .3),
            wave + k * (.03 + w.slack * .2),
          );
      final half = .03 * (1 - k * .5);
      top.add(p + Offset(0, -half));
      bottom.add(p + Offset(0, half));
    }
    final ribbon = Path()..addPolygon([...top, ...bottom.reversed], true);
    c.drawPath(ribbon, _line(_ink, .03));
    c.drawPath(ribbon, _fill(color));
  }

  /// Lifts, braces and sheets from the yards and sail corners.
  static void _tackle(Canvas c, _Wind w) {
    final flare = _course.spread * w.fill;
    final clewL = Offset(_course.left - flare, _course.bottom);
    final clewR = Offset(_course.right + flare, _course.bottom);
    // Lifts hold the course yard up to the crow's nest.
    _cord(
      c,
      const Offset(-1.34, -1.72),
      const Offset(-.08, -3.28),
      width: .026,
    );
    _cord(c, const Offset(1.98, -1.72), const Offset(.68, -3.28), width: .026);
    // The brace runs from the yardarm across to the aft mast.
    _cord(c, const Offset(1.98, -1.72), const Offset(2.42, -1.36), width: .03);
    _block(c, const Offset(1.98, -1.66), turn: .3);
    _block(c, const Offset(-1.34, -1.66), turn: -.3);
    // Sheets pull the corners of the course down to the rail.
    _cord(c, clewL, const Offset(-2.1, .9), sag: .03, width: .03);
    _cord(c, clewR, const Offset(2.5, .34), sag: .03, width: .03);
    _block(c, clewL + const Offset(0, .06), turn: .5);
    _block(c, clewR + const Offset(0, .06), turn: -.5);
  }

  /// Shrouds and ratlines climb from the rail to the crow's nest, one ladder
  /// each side of the painted emblem: a pair of shrouds and their rungs.
  static const _shrouds = [
    (Offset(-1.16, .92), Offset(-.8, .92), Offset(-.02, -3.12)),
    (Offset(1.4, .92), Offset(1.76, .92), Offset(.62, -3.12)),
  ];
  static final _ladderLines = () {
    final p = Path();
    for (final (a, b, top) in _shrouds) {
      p
        ..moveTo(a.dx, a.dy)
        ..lineTo(top.dx, top.dy)
        ..moveTo(b.dx, b.dy)
        ..lineTo(top.dx, top.dy);
    }
    return p;
  }();
  static final _ratlines = () {
    final p = Path();
    for (final (a, b, top) in _shrouds) {
      for (var i = 1; i < 11; i++) {
        final k = i / 11;
        final l = Offset.lerp(a, top, k)!, r = Offset.lerp(b, top, k)!;
        p
          ..moveTo(l.dx, l.dy)
          ..lineTo(r.dx, r.dy);
      }
    }
    return p;
  }();

  /// Seized knots where each rung meets a shroud.
  static final _ratlineKnots = () {
    final p = Path();
    for (final (a, b, top) in _shrouds) {
      for (var i = 1; i < 11; i++) {
        final k = i / 11;
        for (final end in [a, b]) {
          p.addOval(
            Rect.fromCircle(center: Offset.lerp(end, top, k)!, radius: .021),
          );
        }
      }
    }
    return p;
  }();

  static void _ladders(Canvas c) {
    c.drawPath(_ratlines, _line(_rope.withValues(alpha: .85), .022));
    c.drawPath(_ladderLines, _line(_rope, .028));
    c.drawPath(_ratlineKnots, _fill(_ink.withValues(alpha: .75)));
  }

  // ---------------------------------------------------------------- spars --

  /// A tapered timber from [a] (width [wa]) to [b] (width [wb]), lit on the
  /// side facing the light, with a belly, iron-shod ends and grain.
  static void _beam(
    Canvas c,
    Offset a,
    Offset b,
    double wa,
    double wb, {
    double belly = 0,
  }) {
    final d = b - a;
    var n = Offset(-d.dy, d.dx) / d.distance;
    if (n.dx * -.6 + n.dy * -.8 < 0) n = -n;
    final m = Offset.lerp(a, b, .5)!;
    final k = (wa + wb) / 2 + belly - (wa + wb) / 4;
    final a1 = a + n * (wa / 2), a2 = a - n * (wa / 2);
    final b1 = b + n * (wb / 2), b2 = b - n * (wb / 2);
    final c1 = m + n * k, c2 = m - n * k;
    final body = Path()
      ..moveTo(a1.dx, a1.dy)
      ..quadraticBezierTo(c1.dx, c1.dy, b1.dx, b1.dy)
      ..lineTo(b2.dx, b2.dy)
      ..quadraticBezierTo(c2.dx, c2.dy, a2.dx, a2.dy)
      ..close();
    c.drawPath(body, _line(_ink, .06));
    c.drawPath(body, _fill(_wood));
    // Cel light and shade: a lit strip, a dark strip, a few grain streaks.
    c.drawLine(
      a + n * (wa * .24),
      b + n * (wb * .24),
      _line(_woodLit.withValues(alpha: .9), math.min(wa, wb) * .3),
    );
    c.drawLine(
      a - n * (wa * .26),
      b - n * (wb * .26),
      _line(_woodDark.withValues(alpha: .85), math.min(wa, wb) * .34),
    );
    final grain = _line(_woodDeep.withValues(alpha: .4), .012);
    final length = d.distance;
    for (var i = 0; i < 3 + length ~/ 1.5; i++) {
      final u0 = _h(i * 5 + (a.dx * 10).round()) * .85;
      final u1 = math.min(1.0, u0 + .1 + _h(i * 3 + 1) * .2);
      final off = (_h(i * 11 + 2) - .5) * .5;
      final along = (wa + (wb - wa) * u0) * off;
      c.drawLine(
        Offset.lerp(a, b, u0)! + n * along,
        Offset.lerp(a, b, u1)! + n * (along * .9),
        grain,
      );
    }
  }

  /// Iron hoops along a mast.
  static void _bands(Canvas c, Offset foot, Offset head, double w0, double w1) {
    for (var k = .18; k < .95; k += .22) {
      final p = Offset.lerp(foot, head, k)!;
      final half = (w0 + (w1 - w0) * k) / 2 + .015;
      c.drawLine(
        p + Offset(-half, 0),
        p + Offset(half, 0),
        _line(_ink.withValues(alpha: .85), .045),
      );
      c.drawLine(
        p + Offset(-half + .01, -.008),
        p + Offset(half - .02, -.008),
        _line(_ironLit.withValues(alpha: .55), .012),
      );
    }
  }

  /// A yard across the mast: a spindle of timber with gasket lashings.
  static void _yard(Canvas c, double y, double left, double right) {
    _beam(c, Offset(left, y), Offset(right, y), .06, .06, belly: .06);
    // Lashings that bend the sail to the yard.
    final lash = Path(), lashLit = Path();
    for (var x = left + .16; x < right - .1; x += .3) {
      lash
        ..moveTo(x, y - .06)
        ..lineTo(x + .012, y + .07);
      lashLit
        ..moveTo(x - .006, y - .05)
        ..lineTo(x + .006, y + .06);
    }
    c.drawPath(lash, _line(_ink, .05));
    c.drawPath(lash, _line(_ropeLit, .028));
    c.drawPath(lashLit, _line(_clothLit.withValues(alpha: .5), .01));
    // Iron caps on the yardarms with a gold stud.
    for (final (x, dir) in [(left, 1.0), (right, -1.0)]) {
      c.drawLine(
        Offset(x + dir * .05, y - .07),
        Offset(x + dir * .05, y + .07),
        _line(_ink, .06),
      );
      c.drawLine(
        Offset(x + dir * .05, y - .06),
        Offset(x + dir * .05, y + .06),
        _line(_iron, .032),
      );
      c.drawCircle(Offset(x, y), .05, _fill(_ink));
      c.drawCircle(Offset(x, y), .03, _fill(_gold));
    }
    // The parrel: an iron collar hugging the mast.
    final collar = Rect.fromCenter(
      center: Offset(.3, y),
      width: .27,
      height: .11,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(collar, const Radius.circular(.03)),
      _fill(_ink),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(collar.deflate(.018), const Radius.circular(.02)),
      _fill(_iron),
    );
    c.drawLine(
      Offset(collar.left + .04, y - .02),
      Offset(collar.right - .04, y - .02),
      _line(_ironLit.withValues(alpha: .6), .012),
    );
  }

  // ---------------------------------------------------------------- sails --

  /// A square sail bent to its yard: an arched foot with the clews hauled
  /// down, billow shading, pillowed cloths and seams, a reef band, patches,
  /// mends and shot holes, ragged where it has been torn.
  static void _square(Canvas c, _Sail s, _Wind w, {required double sway}) {
    final flare = s.spread * w.fill;
    final wide = s.right - s.left, high = s.bottom - s.top;
    final mid = (s.left + s.right) / 2;
    // The foot arches up in the middle and the clews are pulled down.
    final arch = .1 * w.fill + .02;
    final bl = s.left - flare, br = s.right + flare;
    final bites = w.torn ? [...s.bites, ...s.furyBites] : s.bites;
    const n = 34;
    final foot = <Offset>[];
    double footY(double u) => s.bottom - arch * 4 * u * (1 - u);
    for (var i = 0; i <= n; i++) {
      final u = i / n;
      var y = footY(u);
      for (var b = 0; b < bites.length; b++) {
        final bite = bites[b];
        if (u <= bite.from || u >= bite.to) continue;
        final v = (u - bite.from) / (bite.to - bite.from);
        y -=
            bite.depth *
            (1 - (2 * v - 1).abs()) *
            (.7 + .3 * _h(i * 7 + b * 13));
      }
      foot.add(Offset(bl + (br - bl) * u, y));
    }
    final rightEdge = Path()
      ..moveTo(s.right, s.top)
      ..quadraticBezierTo(
        s.right + flare * 1.8,
        s.top + high * .5 + sway,
        br,
        s.bottom,
      );
    final leftEdge = Path()
      ..moveTo(bl, s.bottom)
      ..quadraticBezierTo(
        s.left - flare * 1.8,
        s.top + high * .5 - sway,
        s.left,
        s.top,
      );
    final outline = Path()
      ..moveTo(s.left, s.top)
      ..quadraticBezierTo(mid, s.top + .14, s.right, s.top)
      ..quadraticBezierTo(
        s.right + flare * 1.8,
        s.top + high * .5 + sway,
        br,
        s.bottom,
      );
    for (var i = n; i >= 0; i--) {
      outline.lineTo(foot[i].dx, foot[i].dy);
    }
    outline
      ..quadraticBezierTo(
        s.left - flare * 1.8,
        s.top + high * .5 - sway,
        s.left,
        s.top,
      )
      ..close();
    final rect = Rect.fromLTRB(bl, s.top, br, s.bottom);
    c.drawPath(
      outline,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_clothLit, _cloth, _clothShade],
          stops: [0, .45, 1],
        ).createShader(rect),
    );
    c.save();
    c.clipPath(outline);
    // Under the yard the cloth bunches into shadow.
    c.drawRect(
      Rect.fromLTRB(bl - .3, s.top, br + .3, s.top + .2),
      _fill(_clothDeep.withValues(alpha: .2)),
    );
    c.drawRect(
      Rect.fromLTRB(bl - .3, s.top, br + .3, s.top + .09),
      _fill(_clothDeep.withValues(alpha: .22)),
    );
    // The underside of the billow, the shaded leech and the lit luff.
    final footLine = Path()..addPolygon(foot, false);
    c.drawPath(footLine, _line(_clothDeep.withValues(alpha: .3), .6));
    c.drawPath(footLine, _line(_clothDeep.withValues(alpha: .26), .3));
    c.drawPath(rightEdge, _line(_clothDeep.withValues(alpha: .3), .52));
    c.drawPath(rightEdge, _line(_clothDeep.withValues(alpha: .22), .26));
    c.drawPath(leftEdge, _line(_clothLit.withValues(alpha: .4), .3));
    _soft(
      c,
      _glow,
      Offset(s.left + wide * .34 + sway * 4, s.top + high * .34),
      wide * .3,
      high * .3,
    );
    // Salt and soot stains, worst toward the foot.
    for (var k = 0; k < 3; k++) {
      final at = Offset(
        s.left + wide * (.12 + .76 * _h(k * 4 + s.panels)),
        s.top + high * (.4 + .5 * _h(k * 4 + 7 + s.panels)),
      );
      _soft(c, _stainPaint, at, .22 + .2 * _h(k + 11), .12 + .1 * _h(k + 13));
    }
    if (s.umbra) {
      // The captain's shadow on the cloth makes him pop.
      _soft(c, _umbraPaint, const Offset(0, .02), 1.7, 1.6);
    }
    // Stitched cloths bow with the wind: a pillowed light along the middle
    // of each panel, a shadow and a thread at every seam.
    final puffA = Path(), puffB = Path(), seams = Path();
    for (var i = 0; i < s.panels; i++) {
      final u = (i + .4) / s.panels;
      final xh = s.left + wide * u, xf = bl + (br - bl) * u;
      final bulge = (u - .5) * flare * 1.5 + sway * .4;
      (i.isEven ? puffA : puffB)
        ..moveTo(xh, s.top + .05)
        ..quadraticBezierTo(
          (xh + xf) / 2 + bulge,
          s.top + high * .5,
          xf,
          footY(u) - .04,
        );
      if (i == 0) continue;
      final us = i / s.panels;
      final sh = s.left + wide * us, sf = bl + (br - bl) * us;
      final sb = (us - .5) * flare * 1.5 + sway * .4;
      seams
        ..moveTo(sh, s.top + .05)
        ..quadraticBezierTo(
          (sh + sf) / 2 + sb,
          s.top + high * .5,
          sf,
          footY(us) + .05,
        );
    }
    final panelWide = wide / s.panels;
    c.drawPath(puffA, _line(_clothLit.withValues(alpha: .2), panelWide * .6));
    c.drawPath(puffA, _line(_clothLit.withValues(alpha: .2), panelWide * .26));
    c.drawPath(puffB, _line(_clothLit.withValues(alpha: .13), panelWide * .42));
    // Tension creases fan out from the clews where the sheets haul.
    final creases = Path();
    for (final (corner, dir) in [
      (Offset(bl, s.bottom - .02), 1.0),
      (Offset(br, s.bottom - .02), -1.0),
    ]) {
      for (var k = 0; k < 3; k++) {
        final a = (.42 + k * .42) * (1 + (dir > 0 ? 0 : .1));
        final len = .5 + (k == 1 ? .28 : 0) + sway * dir;
        final end = corner + Offset(dir * math.cos(a), -math.sin(a)) * len;
        final ctrl = Offset.lerp(corner, end, .5)! + Offset(0, .05 * dir);
        creases
          ..moveTo(corner.dx + dir * .05, corner.dy - .04)
          ..quadraticBezierTo(ctrl.dx, ctrl.dy, end.dx, end.dy);
      }
    }
    c.drawPath(creases, _line(_clothDeep.withValues(alpha: .2), .04));
    c.drawPath(seams, _line(_clothDeep.withValues(alpha: .18), .09));
    c.drawPath(seams, _line(_stitch.withValues(alpha: .9), .02));
    // Faint creases where the sail was folded in the locker.
    final folds = Path();
    for (final f in const [.5, .74]) {
      final y = s.top + high * f;
      folds
        ..moveTo(bl - .2, y + .03)
        ..quadraticBezierTo(mid + sway * .5, y + .12, br + .2, y + .03);
    }
    c.drawPath(folds, _line(_clothDeep.withValues(alpha: .14), .04));
    c.drawPath(
      folds.shift(const Offset(0, .04)),
      _line(_clothLit.withValues(alpha: .18), .025),
    );
    // A reef band with its points.
    final ry = s.top + high * s.reef;
    final band = Path()
      ..moveTo(bl - .2, ry - .01)
      ..quadraticBezierTo(mid + sway * .3, ry + .13, br + .2, ry - .01);
    c.drawPath(band, _line(_clothDeep.withValues(alpha: .34), .15));
    c.drawPath(band.shift(const Offset(0, -.075)), _line(_stitch, .018));
    c.drawPath(band.shift(const Offset(0, .075)), _line(_stitch, .018));
    final points = Path(), eyes = Path();
    var i = 0;
    for (var x = s.left + .1; x < s.right; x += .21, i++) {
      final tt = (x - (bl - .2)) / (br + .2 - (bl - .2));
      final y = ry - .01 + 2 * tt * (1 - tt) * .13;
      points
        ..moveTo(x, y + .04)
        ..lineTo(x + .012, y + .13 + (i.isEven ? .05 : 0));
      eyes.addOval(Rect.fromCircle(center: Offset(x, y), radius: .02));
    }
    c.drawPath(points, _line(_ink.withValues(alpha: .6), .034));
    c.drawPath(points, _line(_ropeLit, .02));
    c.drawPath(eyes, _fill(_ink.withValues(alpha: .7)));
    for (final p in s.patches) {
      _patch(c, p);
    }
    for (final t in s.mends) {
      _mend(c, t);
    }
    for (final h in s.holes) {
      _burnHole(c, h, w);
    }
    for (final (at, from) in s.wounds) {
      if (w.wear >= from) _burnHole(c, at, w);
    }
    if (w.torn) {
      for (final t in s.furyTears) {
        _tear(c, t, w);
      }
    }
    if (s.emblem) {
      _roger(
        c,
        Offset(mid + .05, (s.top + s.bottom) / 2 + .02),
        .36,
        skull: w.fury ? _bloodDeep : const Color(0xff3a2830),
        socket: _cloth,
        patch: w.fury ? _bloodDeep : const Color(0xff3a2830),
        blade: w.fury ? _bloodDeep : const Color(0xff3a2830),
        guard: w.fury ? _blood : const Color(0xff3a2830),
        painted: true,
        eyeGlow: null,
      );
    }
    // The bolt rope sewn around the edge.
    c.drawPath(outline, _line(_boltRope.withValues(alpha: .85), .1));
    c.drawPath(outline, _line(_clothDeep.withValues(alpha: .5), .02));
    c.restore();
    c.drawPath(outline, _line(_ink, .075));
    // Cringles at the corners where the sheets and lashings tie on.
    for (final p in [Offset(bl, s.bottom - .02), Offset(br, s.bottom - .02)]) {
      c.drawCircle(p, .06, _fill(_ink));
      c.drawCircle(p, .04, _fill(_ropeLit));
      c.drawCircle(p, .02, _fill(_ink));
    }
  }

  static void _patch(Canvas c, _Patch p, {Color? thread}) {
    c.save();
    c.translate(p.x, p.y);
    c.rotate(p.turn);
    final r = Rect.fromCenter(center: Offset.zero, width: p.w, height: p.h);
    c.drawRect(
      r.shift(const Offset(.02, .03)),
      _fill(_ink.withValues(alpha: .18)),
    );
    c.drawRect(r, _fill(p.color));
    // A cel of shade along the lower edge and a dog-eared fold at one corner.
    c.drawRect(
      Rect.fromLTRB(r.left, r.bottom - p.h * .28, r.right, r.bottom),
      _fill(_ink.withValues(alpha: .1)),
    );
    c.drawPath(
      Path()
        ..moveTo(r.right, r.top)
        ..lineTo(r.right - p.w * .26, r.top)
        ..lineTo(r.right, r.top + p.h * .26)
        ..close(),
      _fill(_clothLit.withValues(alpha: .5)),
    );
    c.drawRect(r, _line(_ink.withValues(alpha: .4), .022));
    // Blanket stitches along every side.
    final stitch = Path();
    for (var x = r.left + .04; x < r.right; x += .07) {
      stitch
        ..moveTo(x, r.top - .02)
        ..lineTo(x, r.top + .03)
        ..moveTo(x, r.bottom - .03)
        ..lineTo(x, r.bottom + .02);
    }
    for (var y = r.top + .05; y < r.bottom; y += .07) {
      stitch
        ..moveTo(r.left - .02, y)
        ..lineTo(r.left + .03, y)
        ..moveTo(r.right - .03, y)
        ..lineTo(r.right + .02, y);
    }
    c.drawPath(stitch, _line(thread ?? _ink.withValues(alpha: .7), .014));
    c.restore();
  }

  /// A ripped seam sewn shut: a dark crack held by cross stitches.
  static void _mend(Canvas c, _Tear t) {
    final d = t.to - t.from;
    final n = Offset(-d.dy, d.dx) / d.distance;
    final crack = Path()..moveTo(t.from.dx, t.from.dy);
    final ticks = Path();
    const steps = 6;
    for (var i = 1; i <= steps; i++) {
      final k = i / steps;
      final jag = (i.isEven ? 1 : -1) * t.width * .5;
      final p = Offset.lerp(t.from, t.to, k)! + n * jag;
      crack.lineTo(p.dx, p.dy);
      ticks
        ..moveTo(p.dx - n.dx * .07, p.dy - n.dy * .07)
        ..lineTo(p.dx + n.dx * .07, p.dy + n.dy * .07);
    }
    c.drawPath(crack, _line(_clothDeep, .06));
    c.drawPath(crack, _line(_ink.withValues(alpha: .45), .02));
    c.drawPath(ticks, _line(_ink.withValues(alpha: .75), .016));
  }

  /// An open rip with frayed lips: the sail torn wider in fury, glowing where
  /// it is still burning.
  static void _tear(Canvas c, _Tear t, _Wind w) {
    final d = t.to - t.from;
    final n = Offset(-d.dy, d.dx) / d.distance;
    const steps = 11;
    final upper = <Offset>[], lower = <Offset>[];
    final seed = (t.from.dx * 7 + t.to.dy * 5).round();
    for (var i = 0; i <= steps; i++) {
      final k = i / steps;
      final taper = math.pow(math.sin(k * math.pi), .8).toDouble();
      // Alternating teeth make the lips ragged.
      final up = i.isEven ? 1.0 : .5 + .25 * _h(i + seed);
      final down = i.isOdd ? 1.0 : .5 + .25 * _h(i + seed + 40);
      final base = Offset.lerp(t.from, t.to, k)!;
      upper.add(base + n * (t.width / 2 * taper * up));
      lower.add(base - n * (t.width / 2 * taper * down));
    }
    final rip = Path()..addPolygon([...upper, ...lower.reversed], true);
    c.drawPath(rip, _line(_clothDeep, .08));
    c.drawPath(rip, _fill(_hole));
    c.drawPath(rip, _line(_singe, .03));
    final flick = w.still ? 0.0 : math.sin(w.t * 9 + t.from.dx * 5) * .12;
    c.drawPath(
      Path()..addPolygon(upper, false),
      _line(_ember.withValues(alpha: .75 + flick), .02),
    );
    c.drawPath(
      Path()..addPolygon(lower, false),
      _line(_ember.withValues(alpha: .4 + flick), .014),
    );
    // Frayed threads on the lips and loose ones across the gap.
    final threads = Path();
    for (var i = 1; i < steps; i++) {
      final out = i.isOdd ? upper[i] : lower[i];
      final dir = i.isOdd ? n : -n;
      threads
        ..moveTo(out.dx, out.dy)
        ..lineTo(out.dx + dir.dx * .07 + d.dx * .02, out.dy + dir.dy * .07);
    }
    for (var i = 3; i < steps - 2; i += 3) {
      threads
        ..moveTo(upper[i].dx, upper[i].dy)
        ..lineTo(
          (upper[i].dx + lower[i].dx) / 2 + .02,
          (upper[i].dy + lower[i].dy) / 2,
        );
    }
    c.drawPath(threads, _line(_clothShade, .016));
  }

  /// A cannon shot went clean through: a scorched, frayed hole.
  static void _burnHole(Canvas c, Offset at, _Wind w) {
    final rip = Path();
    for (var i = 0; i < 14; i++) {
      final a = i * math.pi / 7;
      final r = (i.isEven ? .12 : .078) * (1 + (i % 3) * .1);
      final p = at + Offset(math.cos(a), math.sin(a) * .9) * r;
      i == 0 ? rip.moveTo(p.dx, p.dy) : rip.lineTo(p.dx, p.dy);
    }
    rip.close();
    c.drawPath(rip, _line(_clothDeep, .11));
    c.drawPath(rip, _line(_singe.withValues(alpha: .9), .06));
    c.drawPath(rip, _fill(_hole));
    c.drawPath(
      rip.shift(const Offset(-.01, -.012)),
      _line(_ember.withValues(alpha: w.fury ? .8 : .4), .014),
    );
    // Soot flicks around the rim.
    final soot = Path();
    for (var i = 0; i < 5; i++) {
      final a = i * 1.3 + .4;
      soot
        ..moveTo(at.dx + math.cos(a) * .17, at.dy + math.sin(a) * .15)
        ..lineTo(at.dx + math.cos(a) * .23, at.dy + math.sin(a) * .2);
    }
    c.drawPath(soot, _line(_singe.withValues(alpha: .6), .022));
  }

  // ----------------------------------------------------------- gaff rig --

  /// The aft mast, its gaff and boom, the gaff sail and the pennant.
  static void _gaffRig(Canvas c, _Wind w) {
    final f = w.fill;
    final sway = w.breeze;
    final throat = const Offset(2.47, -2.06);
    final tack = const Offset(2.47, -1.0);
    final peak = Offset(3.42 + sway * .5, -2.54);
    final clew = Offset(3.5 + sway, -1.18);
    // The leech flutters where the wind spills off it.
    final flutter = w.fury ? .028 : .014;
    final leech = <Offset>[];
    const n = 10;
    for (var i = 0; i <= n; i++) {
      final k = i / n;
      final belly = math.sin(k * math.pi) * (.16 * f + sway);
      final shake = w.still
          ? 0.0
          : math.sin(w.t * 8 + i * 1.7) * flutter * math.sin(k * math.pi);
      final base = Offset.lerp(peak, clew, k)!;
      leech.add(base + Offset(belly + shake, 0));
    }
    final sail = Path()
      ..moveTo(throat.dx, throat.dy)
      ..quadraticBezierTo(2.98, -2.36 + .1, peak.dx, peak.dy);
    for (final p in leech.skip(1)) {
      sail.lineTo(p.dx, p.dy);
    }
    sail
      ..quadraticBezierTo(2.98, -1.02 + .04, tack.dx, tack.dy)
      ..close();
    final rect = Rect.fromLTRB(2.4, -2.6, 3.7, -.96);
    c.drawPath(
      sail,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_clothLit, _cloth, _clothShade],
          stops: [0, .45, 1],
        ).createShader(rect),
    );
    c.save();
    c.clipPath(sail);
    final leechLine = Path()..addPolygon(leech, false);
    c.drawPath(leechLine, _line(_clothDeep.withValues(alpha: .32), .5));
    c.drawPath(leechLine, _line(_clothDeep.withValues(alpha: .24), .24));
    c.drawPath(
      Path()
        ..moveTo(tack.dx, tack.dy)
        ..quadraticBezierTo(2.98, -1.0, clew.dx, clew.dy),
      _line(_clothDeep.withValues(alpha: .3), .34),
    );
    _soft(c, _glow, Offset(2.85 + sway, -1.85), .5, .55);
    // Seams run parallel to the leech.
    final seams = Path();
    for (var i = 1; i < 4; i++) {
      final k = i / 4;
      final top = Offset.lerp(throat, peak, k)! + Offset(0, -.02);
      final foot = Offset.lerp(tack, clew, k)! + const Offset(0, .02);
      seams
        ..moveTo(top.dx, top.dy)
        ..quadraticBezierTo(
          (top.dx + foot.dx) / 2 + k * (.08 * f + sway * .6),
          (top.dy + foot.dy) / 2,
          foot.dx,
          foot.dy,
        );
    }
    c.drawPath(seams, _line(_clothDeep.withValues(alpha: .16), .08));
    c.drawPath(seams, _line(_stitch.withValues(alpha: .9), .02));
    // Reef points along a band above the boom.
    final band = Path()
      ..moveTo(2.44, -1.42)
      ..quadraticBezierTo(2.98, -1.36, 3.5 + sway, -1.5);
    c.drawPath(band, _line(_clothDeep.withValues(alpha: .34), .13));
    c.drawPath(band.shift(const Offset(0, -.065)), _line(_stitch, .016));
    c.drawPath(band.shift(const Offset(0, .065)), _line(_stitch, .016));
    final points = Path();
    for (var i = 0; i < 5; i++) {
      final x = 2.62 + i * .19;
      final y = -1.42 + 2 * ((x - 2.44) / 1.06) * (1 - (x - 2.44) / 1.06) * .03;
      points
        ..moveTo(x, y + .04)
        ..lineTo(x + .012, y + .12 + (i.isEven ? .04 : 0));
    }
    c.drawPath(points, _line(_ink.withValues(alpha: .6), .032));
    c.drawPath(points, _line(_ropeLit, .018));
    _patch(c, const _Patch(3.06, -2.0, .3, .26, -.12, Color(0xffb96a5c)));
    _burnHole(c, const Offset(3.08, -1.34), w);
    _mend(c, const _Tear(Offset(3.3, -2.0), Offset(3.34, -1.72), .05));
    if (w.wear >= .2) _burnHole(c, const Offset(2.84, -1.78), w);
    if (w.torn) {
      _tear(c, const _Tear(Offset(3.5, -1.16), Offset(3.1, -2.2), .2), w);
    }
    c.drawPath(sail, _line(_boltRope.withValues(alpha: .85), .1));
    c.restore();
    c.drawPath(sail, _line(_ink, .07));
    // Mast, boom and gaff over the sail's edges.
    _beam(c, const Offset(2.42, .5), const Offset(2.42, -3.1), .15, .09);
    _bands(c, const Offset(2.42, .5), const Offset(2.42, -3.1), .15, .09);
    _beam(c, const Offset(2.4, -.98), const Offset(3.6, -1.2), .08, .06);
    _beam(c, const Offset(2.4, -2.04), const Offset(3.48, -2.56), .07, .05);
    for (final p in const [Offset(3.6, -1.2), Offset(3.48, -2.56)]) {
      c.drawCircle(p, .045, _fill(_ink));
      c.drawCircle(p, .026, _fill(_gold));
    }
    // Rope hoops lash the luff to the mast.
    for (final y in const [-1.2, -1.56, -1.92]) {
      final hoop = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(2.43, y), width: .24, height: .06),
        const Radius.circular(.03),
      );
      c.drawRRect(hoop, _line(_ink, .045));
      c.drawRRect(hoop, _line(_ropeLit, .024));
    }
    // Crosstrees and knees at the masthead.
    _beam(c, const Offset(2.2, -2.74), const Offset(2.64, -2.74), .06, .05);
    _beam(c, const Offset(2.28, -2.74), const Offset(2.4, -2.54), .045, .04);
    _beam(c, const Offset(2.56, -2.74), const Offset(2.44, -2.54), .045, .04);
    // The peak halyard and the boom's topping lift.
    _cord(c, const Offset(3.42, -2.56), const Offset(2.46, -3.0), width: .024);
    _block(c, const Offset(2.99, -2.76), turn: -.4, size: .8);
    // Truck at the masthead, and the pennant.
    c.drawCircle(const Offset(2.42, -3.14), .07, _fill(_ink));
    c.drawCircle(const Offset(2.42, -3.14), .048, _fill(_gold));
    c.drawCircle(const Offset(2.4, -3.16), .016, _fill(_goldLight));
    _pennant(c, const Offset(2.46, -3.0), w);
  }

  /// A long swallowtail pennant streaming from the aft masthead.
  static void _pennant(Canvas c, Offset at, _Wind w) {
    const steps = 12;
    const length = 1.3;
    final top = <Offset>[], bottom = <Offset>[], centre = <Offset>[];
    final speed = 6.2 + w.whip * 2;
    final amp = 1 + w.whip * .5;
    for (var i = 0; i <= steps; i++) {
      final k = i / steps;
      final wave =
          math.sin(k * 5.2 - w.t * speed) *
          (.04 + .1 * k) *
          amp *
          (1 - w.slack * .7);
      final x = at.dx + k * length * (1 - w.slack * .3);
      final y = at.dy + wave + k * (.1 + w.slack * .35);
      final half = .12 * (1 - k * .3);
      top.add(Offset(x, y - half));
      bottom.add(Offset(x, y + half));
      centre.add(Offset(x, y));
    }
    final notch = centre.last + const Offset(-.34, 0);
    final flag = Path()..addPolygon([...top, notch, ...bottom.reversed], true);
    c.drawPath(flag, _line(_ink, .06));
    c.drawPath(
      flag,
      Paint()
        ..shader =
            LinearGradient(
              colors: w.fury
                  ? const [_blood, _bloodDeep]
                  : const [Color(0xffd0505a), _red, Color(0xff96303c)],
            ).createShader(
              Rect.fromLTRB(at.dx, at.dy - .3, at.dx + length, at.dy + .4),
            ),
    );
    // Folds and a cream stripe with a lit top edge.
    final folds = Path();
    for (var i = 2; i < steps - 1; i += 3) {
      folds
        ..moveTo(top[i].dx, top[i].dy + .02)
        ..lineTo(bottom[i].dx, bottom[i].dy - .02);
    }
    c.drawPath(folds, _line(_ink.withValues(alpha: .22), .04));
    c.drawPath(
      Path()..addPolygon(centre.sublist(2, 9), false),
      _line(w.fury ? _ember : _bone, .05),
    );
    c.drawPath(
      Path()..addPolygon(top.take(steps - 1).toList(), false),
      _line(_bone.withValues(alpha: .45), .02),
    );
  }

  // ---------------------------------------------------------------- flags --

  /// A cloth strip whose fold shading follows a travelling wave: [slope]
  /// gives -1..1 across 0..1 along the strip.
  static Paint _folds(
    Rect rect,
    int cols,
    double Function(double u) slope,
    Color lit,
    int darkAlpha,
    int litAlpha,
  ) {
    final colors = <Color>[], stops = <double>[];
    for (var i = 0; i <= cols; i++) {
      final u = i / cols;
      final s = slope(u);
      colors.add(
        s >= 0
            ? Color.fromARGB((s * darkAlpha).round(), 0, 0, 0)
            : lit.withAlpha((-s * litAlpha).round()),
      );
      stops.add(u);
    }
    return Paint()
      ..shader = LinearGradient(
        colors: colors,
        stops: stops,
      ).createShader(rect);
  }

  /// The Jolly Roger on its halyard: cloth that ripples, a hemmed edge, a
  /// sleeve tied to the mast and a ragged fly; it turns blood-red in fury.
  static void _flag(Canvas c, Offset hoist, _Wind w) {
    const cols = 14;
    const wide = 1.5, tall = .9;
    final speed = 5.4 + w.whip * 1.6;
    final amp = (.1 + w.whip * .05) * (1 - w.slack * .75);
    final top = <Offset>[], bottom = <Offset>[];
    double phase(double u) => u * 4.4 - w.t * speed;
    for (var i = 0; i <= cols; i++) {
      final u = i / cols;
      final a = amp * (.3 + .9 * u);
      final wave = math.sin(phase(u)) + .2 * math.sin(phase(u) * 2.3 + 1);
      final x = u * wide * (1 - .05 * wave.abs() * u - w.slack * .3 * u);
      top.add(
        hoist + Offset(x, wave * a + u * u * (.05 + w.slack * .7) + u * .02),
      );
      bottom.add(
        hoist +
            Offset(
              x * .985,
              tall +
                  (math.sin(phase(u) - .5) +
                          .2 * math.sin(phase(u) * 2.3 + .4)) *
                      a *
                      1.15 +
                  u * u * (.07 + w.slack * .85) +
                  u * .02,
            ),
      );
    }
    // A ragged fly: notches that snap in the wind.
    final ft = top.last, fb = bottom.last;
    const notches = [
      (.14, .03),
      (.26, -.17),
      (.37, .02),
      (.5, .05),
      (.62, -.22),
      (.73, .0),
      (.86, .03),
    ];
    final fly = <Offset>[];
    for (var i = 0; i < notches.length; i++) {
      final (f, dx) = notches[i];
      final snap = w.still
          ? 0.0
          : math.sin(w.t * 9 + i * 1.7) * .035 * (1 + w.whip);
      final deep = dx < -.1 ? (w.fury ? 1.35 : 1.0) * (1 + w.wear * .4) : 1.0;
      fly.add(Offset.lerp(ft, fb, f)! + Offset(dx * deep + snap, 0));
    }
    final flag = Path()..addPolygon([...top, ...fly, ...bottom.reversed], true);
    final rect = Rect.fromLTRB(
      hoist.dx,
      hoist.dy - .3,
      hoist.dx + wide,
      hoist.dy + tall + .3,
    );
    c.drawPath(flag, _line(_ink, .075));
    c.drawPath(
      flag,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: w.fury
              ? const [_blood, _bloodDeep]
              : const [Color(0xff302b3c), _blackDeep],
        ).createShader(rect),
    );
    c.drawPath(
      flag,
      _folds(
        rect,
        cols,
        (u) => math.cos(phase(u) - .2),
        w.fury ? const Color(0xffff9a8a) : const Color(0xffbdb3e0),
        w.fury ? 110 : 96,
        w.fury ? 60 : 46,
      ),
    );
    // Hemmed edge along the top, stitched along the bottom.
    c.drawPath(
      Path()..addPolygon(top, false),
      _line(
        (w.fury ? const Color(0xffff8f80) : const Color(0xff5d5675)).withValues(
          alpha: .85,
        ),
        .032,
      ),
    );
    final hem = Path();
    for (var i = 0; i < cols; i += 2) {
      final a = bottom[i] + const Offset(0, -.045);
      final b = bottom[i + 1] + const Offset(0, -.045);
      hem
        ..moveTo(a.dx, a.dy)
        ..lineTo(b.dx, b.dy);
    }
    c.drawPath(
      hem,
      _line(
        (w.fury ? const Color(0xffff8f80) : const Color(0xff5d5675)).withValues(
          alpha: .6,
        ),
        .018,
      ),
    );
    // The hoist sleeve, tied to the mast with cord.
    final sleeve = Path()
      ..moveTo(top[0].dx, top[0].dy)
      ..lineTo(top[1].dx, top[1].dy)
      ..lineTo(bottom[1].dx, bottom[1].dy)
      ..lineTo(bottom[0].dx, bottom[0].dy)
      ..close();
    c.drawPath(sleeve, _fill(_ink.withValues(alpha: .35)));
    for (final f in const [.14, .5, .86]) {
      final p = Offset.lerp(top[0], bottom[0], f)!;
      c.drawLine(
        p + const Offset(-.07, 0),
        p + const Offset(.12, .01),
        _line(_ink, .05),
      );
      c.drawLine(
        p + const Offset(-.07, 0),
        p + const Offset(.12, .01),
        _line(_ropeLit, .026),
      );
    }
    // The emblem rides the fold at the middle of the cloth.
    final mid = (top[7] + bottom[7]) / 2;
    final tilt = math.atan2(top[8].dy - top[6].dy, top[8].dx - top[6].dx);
    c.save();
    c.translate(mid.dx, mid.dy);
    c.rotate(tilt * .55);
    c.scale(1 - .14 * math.sin(tilt).abs(), 1);
    _roger(
      c,
      Offset.zero,
      .31,
      skull: _bone,
      socket: w.fury ? _bloodDeep : _blackDeep,
      patch: w.fury ? _bloodDeep : _blackDeep,
      blade: const Color(0xffe4ecf5),
      guard: _gold,
      painted: false,
      eyeGlow: w.fury ? _ember : null,
    );
    c.restore();
    // A mended patch near the fly, sewn on with pale thread.
    final at = (top[11] + bottom[11]) / 2 + const Offset(0, .2);
    final lean = math.atan2(top[12].dy - top[10].dy, top[12].dx - top[10].dx);
    c.save();
    c.translate(at.dx, at.dy);
    c.rotate(lean * .6 + .06);
    _patch(
      c,
      _Patch(
        0,
        0,
        .22,
        .18,
        0,
        w.fury ? const Color(0xff9a2333) : const Color(0xff3d3858),
      ),
      thread: (w.fury ? const Color(0xffff9a8a) : const Color(0xffa8a1c6))
          .withValues(alpha: .8),
    );
    c.restore();
  }

  /// One cutlass in unit space: hilt low outside, blade curving to the far
  /// top corner. Mirror it for the second.
  static final _blade = () {
    const guard = Offset(-.62, .84), tip = Offset(1.12, -.06);
    final d = tip - guard;
    final n = Offset(-d.dy, d.dx) / d.distance * -1;
    final m = Offset.lerp(guard, tip, .5)!;
    final a = guard + n * .12, b = guard - n * .12;
    final s = m + n * .3, e = m - n * .03;
    return Path()
      ..moveTo(a.dx, a.dy)
      ..quadraticBezierTo(s.dx, s.dy, tip.dx, tip.dy)
      ..quadraticBezierTo(e.dx, e.dy, b.dx, b.dy)
      ..close();
  }();
  static final _fuller = () {
    const guard = Offset(-.5, .76), tip = Offset(.94, .0);
    final d = tip - guard;
    final n = Offset(-d.dy, d.dx) / d.distance * -1;
    final m = Offset.lerp(guard, tip, .5)!;
    final s = m + n * .12;
    return Path()
      ..moveTo(guard.dx, guard.dy)
      ..quadraticBezierTo(s.dx, s.dy, tip.dx, tip.dy);
  }();

  /// A skull in an eyepatch above two crossed cutlasses, in unit space
  /// (about 2 wide). On the sail it is painted in one colour; on the flag the
  /// hilts are gilt and the good eye burns in fury.
  static void _roger(
    Canvas c,
    Offset at,
    double r, {
    required Color skull,
    required Color socket,
    required Color patch,
    required Color blade,
    required Color guard,
    required bool painted,
    required Color? eyeGlow,
  }) {
    c.save();
    c.translate(at.dx, at.dy);
    c.scale(r);
    c.translate(0, -.1);
    // Cutlasses, crossed under the skull.
    for (final flip in const [1.0, -1.0]) {
      c.save();
      c.scale(flip, 1);
      c.drawPath(_blade, _fill(blade));
      if (!painted) {
        // A fuller down the blade, and a dark edge to part it from the skull.
        c.drawPath(_fuller, _line(Color.lerp(blade, _ink, .3)!, .045));
      }
      // Guard, grip and pommel.
      c.drawLine(
        const Offset(-.72, .64),
        const Offset(-.52, 1.03),
        _line(guard, .13),
      );
      c.drawLine(
        const Offset(-.62, .84),
        const Offset(-.98, 1.02),
        _line(painted ? guard : _woodDark, .1),
      );
      c.drawCircle(const Offset(-1.0, 1.04), .105, _fill(guard));
      c.restore();
    }
    // The skull sits over the blades with a gap around it.
    c.translate(0, -.17);
    c.scale(.74);
    final head = Path()
      ..addOval(const Rect.fromLTRB(-.6, -.9, .6, .22))
      ..addRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTRB(-.36, -.02, .36, .64),
          const Radius.circular(.14),
        ),
      )
      ..addRect(const Rect.fromLTRB(-.48, -.12, .48, .3));
    c.drawPath(head, _line(painted ? _cloth : socket, .17));
    c.drawPath(head, _fill(skull));
    if (!painted) {
      // Shade under the cheekbones and a crack in the crown.
      c.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTRB(-.36, .34, .36, .64),
          const Radius.circular(.14),
        ),
        _fill(_boneShade.withValues(alpha: .7)),
      );
      c.drawPath(
        Path()
          ..moveTo(.14, -.9)
          ..lineTo(.24, -.66)
          ..lineTo(.13, -.54)
          ..lineTo(.2, -.4),
        _line(socket.withValues(alpha: .8), .035),
      );
    }
    // Sockets, slanted for a scowl; the right one is patched.
    for (final (x, tilt) in const [(-.27, .3), (.27, -.3)]) {
      c.save();
      c.translate(x, -.26);
      c.rotate(tilt);
      c.drawOval(
        Rect.fromCenter(center: Offset.zero, width: .34, height: .36),
        _fill(socket),
      );
      c.restore();
    }
    if (eyeGlow != null) {
      c.drawCircle(const Offset(-.27, -.26), .12, _fill(eyeGlow));
      c.drawCircle(const Offset(-.27, -.26), .05, _fill(_goldLight));
    }
    // The patch and its strap across the brow.
    final strap = _line(painted ? socket : patch, .07);
    c.drawLine(const Offset(.12, -.5), const Offset(-.56, -.64), strap);
    c.drawLine(const Offset(.42, -.46), const Offset(.6, -.4), strap);
    c.save();
    c.translate(.27, -.26);
    c.rotate(-.3);
    c.drawOval(
      Rect.fromCenter(center: Offset.zero, width: .44, height: .46),
      _fill(patch),
    );
    if (painted) {
      c.drawOval(
        Rect.fromCenter(center: Offset.zero, width: .3, height: .32),
        _line(socket, .05),
      );
    }
    c.restore();
    // Nose, teeth and a gold tooth.
    c.drawPath(
      Path()
        ..moveTo(0, .0)
        ..lineTo(-.1, .2)
        ..lineTo(.1, .2)
        ..close(),
      _fill(socket),
    );
    final teeth = Path()
      ..moveTo(-.28, .36)
      ..lineTo(.28, .36);
    for (final x in const [-.16, -.0, .16]) {
      teeth
        ..moveTo(x, .36)
        ..lineTo(x, .6);
    }
    c.drawPath(teeth, _line(socket, .05));
    if (!painted) {
      c.drawRect(const Rect.fromLTRB(.02, .39, .13, .56), _fill(_gold));
    } else {
      // Paint drips run down from the jaw.
      for (final (x, len) in const [(-.22, .22), (.06, .14), (.24, .3)]) {
        c.drawLine(Offset(x, .62), Offset(x, .62 + len), _line(skull, .06));
        c.drawCircle(Offset(x, .64 + len), .055, _fill(skull));
      }
    }
    c.restore();
  }

  // -------------------------------------------------------- crow's nest --

  /// The lookout: a mate in a teal bandana, spyglass to his eye, sweeping the
  /// sky for the bird and ducking behind the rim at every shot.
  static void _lookout(Canvas c, _Wind w) {
    final dip = w.duck * .42;
    final head = Offset(.08, -3.7 + dip);
    final scan = math.sin(w.t * .9) * .1;
    final angle = math.pi - .34 + scan + w.duck * .5;
    final dir = Offset(math.cos(angle), math.sin(angle));
    final eye = head + const Offset(-.035, -.02);
    // Spyglass in three telescoping tubes, lens glinting.
    final tube = [
      (0.0, .2, .062, _bronze),
      (.2, .36, .078, _gold),
      (.36, .52, .095, _bronze),
    ];
    for (final (from, to, width, color) in tube) {
      final a = eye + dir * from, b = eye + dir * to;
      c.drawLine(a, b, _line(_ink, width + .04));
      c.drawLine(a, b, _line(color, width));
      c.drawLine(
        a + const Offset(0, -.014),
        b + const Offset(0, -.014),
        _line(_goldLight.withValues(alpha: .7), .014),
      );
    }
    final glint = w.still ? .8 : .6 + .4 * math.sin(w.t * 3.2);
    final lens = eye + dir * .53;
    c.drawCircle(lens, .045, _fill(_ink));
    c.drawCircle(lens, .03, _fill(const Color(0xffbfe9ff)));
    c.drawCircle(lens, .012 + .02 * glint, _fill(_bone));
    // Head, ear and a hand on the tube.
    c.drawCircle(head, .17, _fill(_ink));
    c.drawCircle(head, .14, _fill(_skin));
    c.drawCircle(
      head + const Offset(.12, .02),
      .035,
      _fill(const Color(0xffa8683f)),
    );
    c.drawCircle(head + const Offset(-.13, .03), .045, _fill(_skin));
    c.drawCircle(head + const Offset(-.13, .03), .045, _line(_ink, .02));
    c.drawCircle(eye + dir * .3 + const Offset(0, .035), .04, _fill(_skin));
    c.drawCircle(eye + dir * .3 + const Offset(0, .035), .04, _line(_ink, .02));
    // Bandana over the crown with two flapping tails.
    final cap = Path()
      ..moveTo(head.dx - .15, head.dy - .03)
      ..quadraticBezierTo(
        head.dx - .1,
        head.dy - .21,
        head.dx + .04,
        head.dy - .2,
      )
      ..quadraticBezierTo(
        head.dx + .17,
        head.dy - .18,
        head.dx + .16,
        head.dy - .04,
      )
      ..quadraticBezierTo(head.dx, head.dy - .09, head.dx - .15, head.dy - .03)
      ..close();
    final knot = head + const Offset(.16, -.09);
    final flap = w.still ? 0.0 : math.sin(w.t * 7) * .04;
    final tails = Path()
      ..moveTo(knot.dx, knot.dy)
      ..lineTo(knot.dx + .19, knot.dy + .01 + flap)
      ..lineTo(knot.dx + .13, knot.dy + .06 + flap)
      ..lineTo(knot.dx + .21, knot.dy + .1 + flap)
      ..lineTo(knot.dx, knot.dy + .04)
      ..close();
    c.drawPath(tails, _line(_ink, .035));
    c.drawPath(tails, _fill(_teal));
    c.drawPath(cap, _line(_ink, .04));
    c.drawPath(cap, _fill(_teal));
    c.drawLine(
      head + const Offset(-.13, -.09),
      head + const Offset(.14, -.13),
      _line(_bone.withValues(alpha: .8), .022),
    );
    // A glaring eye; in fury he bellows.
    c.drawCircle(eye + const Offset(.01, .012), .026, _fill(_ink));
    if (w.fury) {
      c.drawOval(
        Rect.fromCenter(
          center: head + const Offset(-.05, .1),
          width: .07,
          height: .06,
        ),
        _fill(_ink),
      );
    }
    // A gold hoop in the ear.
    c.drawCircle(head + const Offset(.12, .07), .025, _line(_gold, .016));
  }

  /// The crow's nest: a barrel with a gilded rim and riveted iron hoops,
  /// holding the lookout, on top of the mast.
  static final _barrel = () {
    const top = -3.5, bottom = -3.06;
    const mid = (top + bottom) / 2;
    return Path()
      ..moveTo(-.14, top)
      ..quadraticBezierTo(-.34, mid, -.02, bottom)
      ..lineTo(.62, bottom)
      ..quadraticBezierTo(.94, mid, .74, top)
      ..close();
  }();
  static final _barrelPaint = Paint()
    ..shader = const LinearGradient(
      colors: [_woodLit, _wood, _woodDark, _woodDeep],
      stops: [0, .35, .75, 1],
    ).createShader(const Rect.fromLTRB(-.2, -3.5, .8, -3.06));
  static final _staves = () {
    final p = Path();
    for (var i = 1; i < 5; i++) {
      final k = i / 5;
      final topX = -.14 + .88 * k, botX = -.02 + .64 * k;
      final bulge = (k - .5) * .16;
      p
        ..moveTo(topX, -3.49)
        ..quadraticBezierTo(
          topX + bulge * 1.4 - (k - .5) * .02,
          -3.28,
          botX,
          -3.07,
        );
    }
    return p;
  }();

  static void _nest(Canvas c, _Wind w) {
    _lookout(c, w);
    c.drawPath(_barrel, _line(_ink, .07));
    c.drawPath(_barrel, _barrelPaint);
    c.drawPath(_staves, _line(_woodDeep.withValues(alpha: .5), .018));
    // Iron hoops, riveted, arching like the barrel's belly.
    for (final (y, l, r) in const [(-3.4, -.19, .8), (-3.15, -.13, .74)]) {
      final hoop = Path()
        ..moveTo(l, y)
        ..quadraticBezierTo(.3, y + .06, r, y);
      c.drawPath(hoop, _line(_ink, .06));
      c.drawPath(hoop, _line(_iron, .036));
      c.drawPath(
        hoop.shift(const Offset(0, -.01)),
        _line(_ironLit.withValues(alpha: .6), .012),
      );
      for (var x = l + .12; x < r - .05; x += .17) {
        c.drawCircle(Offset(x, y + .03), .014, _fill(_ironLit));
      }
    }
    // The rim: a gilded lip all round the top.
    final rim = Path()
      ..moveTo(-.2, -3.5)
      ..quadraticBezierTo(.3, -3.46, .8, -3.5);
    c.drawPath(rim, _line(_ink, .12));
    c.drawPath(rim, _line(_ochre, .07));
    c.drawPath(
      rim.shift(const Offset(0, -.015)),
      _line(_goldLight.withValues(alpha: .7), .018),
    );
  }

  /// The topmast above the nest, the gilt truck and the Jolly Roger.
  static void _topmast(Canvas c, _Wind w) {
    _beam(c, const Offset(.3, -3.44), const Offset(.3, -4.4), .11, .075);
    // A cap and collar where the topmast leaves the nest.
    final cap = Rect.fromCenter(
      center: const Offset(.3, -3.56),
      width: .22,
      height: .09,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(cap, const Radius.circular(.03)),
      _fill(_ink),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(cap.deflate(.018), const Radius.circular(.02)),
      _fill(_iron),
    );
    c.drawLine(
      Offset(cap.left + .04, cap.top + .028),
      Offset(cap.right - .04, cap.top + .028),
      _line(_ironLit.withValues(alpha: .6), .012),
    );
    c.drawCircle(const Offset(.3, -4.44), .075, _fill(_ink));
    c.drawCircle(const Offset(.3, -4.44), .052, _fill(_gold));
    c.drawCircle(const Offset(.28, -4.46), .018, _fill(_goldLight));
    _flag(c, const Offset(.34, -4.32), w);
  }

  // --------------------------------------------------------------- wheel --

  /// The ship's wheel stands on the quarterdeck behind the balustrade.
  static void _wheel(Canvas c, _Wind w) {
    const at = Offset(2.08, -.04);
    final turn = w.still ? 0.0 : math.sin(w.t * .8) * .25;
    c.drawLine(at, const Offset(2.1, .36), _line(_ink, .12));
    c.drawLine(at, const Offset(2.1, .36), _line(_woodDark, .07));
    // Spokes run out into turned handles.
    for (var i = 0; i < 8; i++) {
      final a = turn + i * math.pi / 4;
      final d = Offset(math.cos(a), math.sin(a));
      c.drawLine(at, at + d * .3, _line(_ink, .07));
      c.drawLine(at, at + d * .3, _line(_woodLit, .032));
      c.drawCircle(at + d * .32, .045, _fill(_ink));
      c.drawCircle(at + d * .32, .03, _fill(_woodLit));
    }
    c.drawCircle(at, .2, _line(_ink, .1));
    c.drawCircle(at, .2, _line(_wood, .056));
    c.drawArc(
      Rect.fromCircle(center: at, radius: .2),
      math.pi * .9,
      math.pi * .6,
      false,
      _line(_woodLit.withValues(alpha: .85), .02),
    );
    c.drawCircle(at, .085, _fill(_ink));
    c.drawCircle(at, .06, _fill(_gold));
    c.drawCircle(at + const Offset(-.015, -.015), .02, _fill(_goldLight));
  }
}
