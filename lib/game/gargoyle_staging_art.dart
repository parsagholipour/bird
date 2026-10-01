import 'dart:math' as math;

import 'package:flutter/painting.dart';

import 'boss_motion.dart';
import 'gargoyle_kit.dart';
import 'gargoyle_layout.dart';
import 'gargoyle_pose.dart';

/// The Searchlight Gargoyle's stage: the tower he is bolted to, and the small
/// things that live on it.
///
/// A stepped Art Deco tower top seen from the side. The ledge he grips is the
/// cornice (a limestone slab with a brass band and a chevron frieze), held up
/// by three corbels that step in as they come down to the tower's shaft, which
/// carries a few lit windows to the bottom of the screen. Behind him the pier
/// rises in three setbacks off the top of the screen. At the cornice's left
/// end the weather-vane mount stands empty (a brass base, a rod, a compass
/// cross and a pivot pin: the courier's delivery will fill it, see [vane]),
/// and beside it the pigeons' twig nest, one pigeon dozing in it.
///
/// Everything is in rig units around the chest lamp and a pure function of
/// the pose (so of the boss clock): the rig paints [ledge] first in its
/// z-order, so the tower is lit and greyed by the same tone as the creature
/// (the dormant stone greys it with him). The ledge and pier are NOT inside
/// the creature's envelope: the pier and the shaft run off the screen on
/// purpose.
///
/// Budget (counting canvas, `gargoyle_budget_test` and `gargoyle_staging_test`):
/// the tower and its nest at most 60 ops, 2 shaders, 1 clip.
abstract final class GargoyleStagingArt {
  static Offset _o(double x, double y) => Offset(x, y);
  static const _y = GargoyleLayout.ledgeY;
  static const _left = GargoyleLayout.ledgeLip;
  static const _right = 4.75;

  // ----------------------------------------------------------- the tower --

  /// How far up the pier runs, in rig units above the lamp: off the top of the
  /// screen in the fight (it is 4.35 there), and off the top of the story
  /// stage, whose figure stands lower.
  static const pierTopY = 9.0;

  /// The pier behind him: three setbacks, each narrower than the one below,
  /// off the top of the screen (the topmost starts at [GargoyleLayout.pierX]).
  static final _pierLow = GargoyleKit.poly([_o(3.0, 1.2), _o(_right, 1.2), _o(_right, _y), _o(3.0, _y)]);
  static final _pierMid = GargoyleKit.poly([_o(3.3, -1.0), _o(_right, -1.0), _o(_right, 1.2), _o(3.3, 1.2)]);
  static final _pierTop = GargoyleKit.poly([
    _o(GargoyleLayout.pierX, -pierTopY),
    _o(_right, -pierTopY),
    _o(_right, -1.0),
    _o(GargoyleLayout.pierX, -1.0),
  ]);

  /// The shaft under the cornice, to the bottom of the screen (and past it).
  static final _shaft = GargoyleKit.poly([_o(-.8, 3.32), _o(_right, 3.32), _o(_right, 4.9), _o(-.8, 4.9)]);

  /// The cornice (the ledge's lip) and the three corbels that step in under it.
  /// The lip's lower left corner is chamfered.
  static final _lip = GargoyleKit.poly([
    _o(_left, _y),
    _o(_right, _y),
    _o(_right, 3.32),
    _o(_left + .16, 3.32),
    _o(_left, 3.16),
  ]);
  static final _corbels = [
    GargoyleKit.poly([_o(-2.5, 3.32), _o(-.45, 3.32), _o(-.45, 3.68), _o(-2.5, 3.68)]),
    GargoyleKit.poly([_o(-1.9, 3.68), _o(-.45, 3.68), _o(-.45, 4.04), _o(-1.9, 4.04)]),
    GargoyleKit.poly([_o(-1.3, 4.04), _o(-.45, 4.04), _o(-.45, 4.9), _o(-1.3, 4.9)]),
  ];

  /// The deep shadow each overhang throws on the step below (one wash).
  static final _under = () {
    final p = Path();
    for (final (x, y) in const [(-2.5, 3.32), (-1.9, 3.68), (-1.3, 4.04)]) {
      p.addRect(Rect.fromLTRB(x, y, -.45, y + .1));
    }
    return p;
  }();

  /// Deco chevron frieze along the cornice's front, in two runs that leave the
  /// talons' own stretch plain (their claws hang over this face).
  static final _frieze = () {
    final p = Path();
    void run(double from, double to) {
      for (var x = from; x + .5 <= to + 1e-9; x += .5) {
        p
          ..moveTo(x, 3.05)
          ..lineTo(x + .25, 3.24)
          ..lineTo(x + .5, 3.05);
      }
    }

    run(_left + .3, -1.6);
    run(1.0, 4.5);
    return p;
  }();

  /// The pier's flutes and the shaft's pilasters (long vertical lines).
  static final _flutes = () {
    final p = Path();
    for (var i = 0; i < 4; i++) {
      p
        ..moveTo(3.8 + i * .22, -pierTopY + .2)
        ..lineTo(3.8 + i * .22, -1.15);
    }
    for (var i = 0; i < 3; i++) {
      p
        ..moveTo(3.5 + i * .25, -.85)
        ..lineTo(3.5 + i * .25, 1.05);
    }
    return p;
  }();
  static final _pilasters = () {
    final p = Path();
    for (var i = 0; i < 6; i++) {
      final x = .05 + i * 1.0;
      p
        ..moveTo(x, 3.74)
        ..lineTo(x, 4.9);
    }
    return p;
  }();

  /// Lit and dark windows: tall narrow Deco slits on the shaft, two on the pier.
  static const _windows = <(double, double, double, double, bool)>[
    (.3, 3.56, .26, .72, true),
    (1.3, 3.56, .26, .72, true),
    (2.3, 3.56, .26, .72, false),
    (3.3, 3.56, .26, .72, true),
    (3.95, -3.9, .24, .46, true),
    (3.95, -3.1, .24, .46, false),
  ];
  static final _litPanes = () {
    final p = Path();
    for (final (x, y, w, h, lit) in _windows) {
      if (lit) p.addRect(Rect.fromLTWH(x, y, w, h));
    }
    return p;
  }();
  static final _darkPanes = () {
    final p = Path();
    for (final (x, y, w, h, lit) in _windows) {
      if (!lit) p.addRect(Rect.fromLTWH(x, y, w, h));
    }
    return p;
  }();
  static final _frames = () {
    final p = Path();
    for (final (x, y, w, h, _) in _windows) {
      p
        ..addRect(Rect.fromLTWH(x, y, w, h))
        ..moveTo(x, y + h * .5)
        ..lineTo(x + w, y + h * .5);
    }
    return p;
  }();

  /// The moon's cool crescent on the top edges of the cornice and the setbacks.
  static final _rim = Path()
    ..moveTo(_left + .06, _y + .03)
    ..lineTo(_right, _y + .03)
    ..moveTo(3.0, 1.23)
    ..lineTo(_right, 1.23)
    ..moveTo(3.3, -.97)
    ..lineTo(_right, -.97)
    ..moveTo(GargoyleLayout.pierX, -pierTopY + .03)
    ..lineTo(_right, -pierTopY + .03);

  /// The cornice's chamfer and the brass band along the cornice's foot.
  static final _band = Path()
    ..moveTo(_left + .2, 3.3)
    ..lineTo(_right, 3.3);

  /// The stone's rain streaks: a few dark runs down the shaft and the corbels.
  static final _streaks = Path()
    ..moveTo(.7, 3.8)
    ..lineTo(.72, 4.5)
    ..moveTo(1.9, 3.74)
    ..lineTo(1.86, 4.6)
    ..moveTo(3.1, 3.78)
    ..lineTo(3.14, 4.3);

  // ---------------------------------------------------------- the paints --

  /// The cornice's ONE limestone gradient (lit lip at the top, deep corbels
  /// below) and the tower's own: lit by his lamp next to him, going dark with
  /// distance (the pier, the far shaft).
  static Paint _stone() => GargoyleKit.cached(
    'stage.stone',
    () => GargoyleKit.linear(
      const Offset(0, _y),
      const Offset(0, GargoyleLayout.corbelBottom),
      const [GargoylePalette.limeSheen, GargoylePalette.lime, GargoylePalette.limeShade, GargoylePalette.limeDeep],
      const [0, .25, .65, 1],
    ),
  );
  static Paint _tower() => GargoyleKit.cached(
    'stage.pier',
    () => GargoyleKit.linear(
      const Offset(-.8, 0),
      const Offset(_right, 0),
      const [GargoylePalette.pierLit, GargoylePalette.pier, GargoylePalette.limeCore],
      const [0, .55, 1],
    ),
  );

  static void _block(Canvas c, Path path, Paint paint, GargoyleTone tone, [double ink = GargoyleLayout.inkHero]) {
    c.drawPath(path, GargoyleKit.toned(paint, tone));
    c.drawPath(path, GargoyleKit.line(GargoylePalette.ink, ink));
  }

  // -------------------------------------------------------- the ledge --

  /// The tower top, the vane mount and the nest, for [pose]'s tone and clock
  /// (the dormant stone greys it with the creature; the nest pigeon sleeps,
  /// wakes, startles and takes flight on the boss clock).
  static void ledge(Canvas c, GargoylePose pose) {
    // His hit flash bleaches HIM, not the tower he stands on: the tower takes
    // every other look (the dormant stone, the sky's darkness, his heat).
    final own = pose.tone;
    final t = own.flash <= 0
        ? own
        : GargoyleTone(fury: own.fury, heat: own.heat, dark: own.dark, sky: own.sky, stone: own.stone);
    final stone = _stone(), tower = _tower();
    // The tower first: the pier's three setbacks, then the shaft.
    _block(c, _pierLow, tower, t, GargoyleLayout.inkMajor);
    _block(c, _pierMid, tower, t, GargoyleLayout.inkMajor);
    _block(c, _pierTop, tower, t, GargoyleLayout.inkMajor);
    c.drawPath(_flutes, GargoyleKit.line(t.lit(GargoylePalette.limeCore), .05, .75));
    _block(c, _shaft, tower, t, GargoyleLayout.inkMajor);
    c.drawPath(_pilasters, GargoyleKit.line(t.lit(GargoylePalette.limeCore), .06, .8));
    // Windows (the night city is lit): amber panes (the dormant stone dims
    // them with everything else), dark ones, and their frames.
    c.drawPath(_litPanes, GargoyleKit.fill(t.lit(GargoylePalette.lampAmber), .72 - .5 * pose.stone));
    c.drawPath(_darkPanes, GargoyleKit.fill(t.lit(GargoylePalette.steelCore), .9));
    c.drawPath(_frames, GargoyleKit.line(GargoylePalette.ink, .045));
    c.drawPath(_streaks, GargoyleKit.line(t.lit(GargoylePalette.limeCore), .05, .55));
    // The cornice and the three corbels (stepped, narrower as they come down).
    for (var i = _corbels.length - 1; i >= 0; i--) {
      _block(c, _corbels[i], stone, t);
    }
    c.drawPath(_under, GargoyleKit.fill(t.lit(GargoylePalette.limeCore), .55));
    _block(c, _lip, stone, t);
    c.drawPath(_frieze, GargoyleKit.line(t.lit(GargoylePalette.brassDeep), .06, .8));
    c.drawPath(_band, GargoyleKit.line(t.lit(GargoylePalette.brass), .07));
    // The moon's rim, a hair inside the top edges.
    c.drawPath(_rim, GargoyleKit.line(GargoylePalette.moon, .05, math.min(1.0, t.moonRim * .9)));
    _vaneMount(c, t);
    _nest(c, pose, t);
  }

  // ---------------------------------------------------- the vane mount --

  /// The empty weather-vane mount at the cornice's left end: a brass base on a
  /// stepped plinth, a steel rod up to [GargoyleLayout.vaneTop], the compass
  /// cross (its E and W arms: seen from the side) and a pivot pin with a ball.
  /// The lightning of the arrival strikes the pin ([pinTip]).
  static void _vaneMount(Canvas c, GargoyleTone t) {
    final at = GargoyleLayout.vaneMount;
    final plinth = GargoyleKit.poly([
      _o(at.dx - .36, _y),
      _o(at.dx - .28, _y - .13),
      _o(at.dx + .28, _y - .13),
      _o(at.dx + .36, _y),
    ]);
    c.drawPath(plinth, GargoyleKit.fill(t.lit(GargoylePalette.brassDeep)));
    c.drawPath(plinth, GargoyleKit.line(GargoylePalette.ink, .05));
    final rod = GargoyleKit.line(t.lit(GargoylePalette.steel), .09);
    final top = Offset(at.dx, GargoyleLayout.vaneTop);
    c.drawLine(Offset(at.dx, _y - .12), top, GargoyleKit.line(GargoylePalette.ink, .15));
    c.drawLine(Offset(at.dx, _y - .12), top, rod);
    // The compass cross: one bar with ball ends and a lozenge at the middle.
    const crossY = 2.2;
    final cross = Path()
      ..moveTo(at.dx - .5, crossY)
      ..lineTo(at.dx + .5, crossY)
      ..moveTo(at.dx, crossY - .18)
      ..lineTo(at.dx + .13, crossY)
      ..lineTo(at.dx, crossY + .18)
      ..lineTo(at.dx - .13, crossY)
      ..close();
    c.drawPath(cross, GargoyleKit.line(GargoylePalette.ink, .13));
    c.drawPath(cross, GargoyleKit.line(t.lit(GargoylePalette.brass), .07));
    // Ball ends (E, W) and the pivot ball on top: one path, one fill.
    final balls = Path()
      ..addOval(Rect.fromCircle(center: Offset(at.dx - .5, crossY), radius: .1))
      ..addOval(Rect.fromCircle(center: Offset(at.dx + .5, crossY), radius: .1))
      ..addOval(Rect.fromCircle(center: top, radius: .1));
    c.drawPath(balls, GargoyleKit.fill(t.lit(GargoylePalette.brassLit)));
    c.drawPath(balls, GargoyleKit.line(GargoylePalette.ink, .04));
  }

  /// Where the rod ends (the pin's tip), in rig units: the lightning's target.
  static const pinTip = Offset(-2.0, GargoyleLayout.vaneTop - .1);

  /// The weather vane the courier delivers (the story scenes after the fall
  /// fill the empty mount with it): a brass arrow with a Deco-fletched tail
  /// and a ball, drawn about its pivot (the origin), pointing left (into the
  /// wind), turned by [turn] radians. Three ops.
  static void vane(Canvas c, {GargoyleTone tone = const GargoyleTone(), double turn = 0}) {
    final arrow = GargoyleKit.poly(const [
      Offset(-1.05, 0), Offset(-.66, -.2), Offset(-.66, -.07), Offset(.55, -.07), Offset(.8, -.34),
      Offset(1.12, -.34), Offset(.98, 0), Offset(1.12, .34), Offset(.8, .34), Offset(.55, .07),
      Offset(-.66, .07), Offset(-.66, .2),
    ]);
    c.save();
    c.rotate(turn);
    c.drawPath(arrow, GargoyleKit.fill(tone.lit(GargoylePalette.brass)));
    c.drawPath(arrow, GargoyleKit.line(GargoylePalette.ink, .06));
    c.drawLine(const Offset(-.7, -.02), const Offset(.5, -.02), GargoyleKit.line(tone.lit(GargoylePalette.brassLit), .035, .9));
    c.restore();
    c.drawCircle(Offset.zero, .12, GargoyleKit.fill(tone.lit(GargoylePalette.brassLit)));
    c.drawCircle(Offset.zero, .12, GargoyleKit.line(GargoylePalette.ink, .045));
  }

  // ---------------------------------------------------------- the nest --

  static const _nestAt = Offset(-2.68, _y);

  /// The nest's bowl and twigs (static) and the pigeon in it.
  static final _bowl = Path()
    ..moveTo(_nestAt.dx - .5, _nestAt.dy - .24)
    ..quadraticBezierTo(_nestAt.dx - .52, _nestAt.dy, _nestAt.dx - .2, _nestAt.dy)
    ..lineTo(_nestAt.dx + .2, _nestAt.dy)
    ..quadraticBezierTo(_nestAt.dx + .52, _nestAt.dy, _nestAt.dx + .5, _nestAt.dy - .24)
    ..close();
  static final _twigs = () {
    final p = Path();
    const sticks = <(double, double, double, double)>[
      (-.5, -.2, -.66, -.34), (-.34, -.1, -.5, -.3), (-.1, -.2, -.2, -.38), (.12, -.18, .22, -.36),
      (.32, -.12, .5, -.32), (.5, -.2, .64, -.3), (-.45, -.05, -.3, -.2), (.1, -.08, .38, -.2),
    ];
    for (final (a, b, c, d) in sticks) {
      p
        ..moveTo(_nestAt.dx + a, _nestAt.dy + b)
        ..lineTo(_nestAt.dx + c, _nestAt.dy + d);
    }
    return p;
  }();
  static const _twig = Color(0xff9a7447), _twigDark = Color(0xff5b4326);

  static void _nest(Canvas c, GargoylePose pose, GargoyleTone t) {
    c.drawPath(_bowl, GargoyleKit.fill(t.lit(_twigDark)));
    c.drawPath(_twigs, GargoyleKit.line(GargoylePalette.ink, .12));
    c.drawPath(_twigs, GargoyleKit.line(t.lit(_twig), .07));
    _pigeon(c, pose, t);
    // The bowl's rim is in front of the pigeon.
    c.drawPath(_bowl, GargoyleKit.line(GargoylePalette.ink, .05));
    c.drawLine(
      Offset(_nestAt.dx - .42, _nestAt.dy - .2),
      Offset(_nestAt.dx + .42, _nestAt.dy - .2),
      GargoyleKit.line(t.lit(_twig), .06, .9),
    );
  }

  static const _pigeonBody = Color(0xffa9abc8), _pigeonWing = Color(0xff6c7199), _pigeonBeak = Color(0xffff8f63);
  static const _pigeonNeck = Color(0xff7fcfbf);

  /// How the nest pigeon stands at [pose]'s clock: asleep until the stone wakes
  /// (2.0 s of the arrival), then awake with a peck every 2.3 s, puffed up
  /// for the roar (the arrival's and the fury's), gone when he is killed. All
  /// are states but the peck and the breath (motion: still under Reduced
  /// Motion, where it sits awake).
  static ({double sleep, double peck, double puff, double breath, double flight, double alpha}) pigeonState(GargoylePose pose) {
    final reduced = pose.reduced;
    final death = pose.defeated ? pose.death : -1.0;
    // Asleep (1) until the stone wakes, then it lifts its head over .3 s.
    final sleep = pose.arriving && !reduced ? 1 - BossMotion.ease(BossMotion.ramp(pose.age, 2.0, 2.3)) : 0.0;
    final asleep = sleep > .5;
    final time = pose.time;
    final peck = reduced || asleep || death >= 0 ? 0.0 : BossMotion.pulse((time % 2.3) - 1.9, .26);
    final breath = reduced ? 0.0 : math.sin(time * 2.4);
    final puff = math.max(pose.roar, pose.rage) * (death >= 0 ? 0 : 1);
    // The killing blow startles it into the air: it climbs away up and left
    // (a state under Reduced Motion: it just goes, fading over .25 s).
    final flight = death < 0 || reduced ? 0.0 : (death - .05).clamp(0.0, 9.0);
    final alpha = death < 0 ? 1.0 : (reduced ? 1 - BossMotion.ramp(death, .05, .3) : 1 - BossMotion.ramp(death, 1.05, 1.15));
    return (sleep: sleep, peck: peck, puff: puff, breath: breath, flight: flight, alpha: alpha);
  }

  /// The nest pigeon for [pose]: seated, or (the kill) climbing away.
  static void _pigeon(Canvas c, GargoylePose pose, GargoyleTone t) {
    final s = pigeonState(pose);
    if (s.alpha <= 0) return;
    var at = _nestAt + const Offset(.02, -.3);
    var size = .62 * (1 + .1 * s.puff + .012 * s.breath);
    var tilt = 0.0;
    var wingUp = false;
    if (s.flight > 0) {
      final f = s.flight;
      at += Offset(-3.6 * f - math.sin(f * 9) * .12, -6.9 * f + 2.2 * f * f * f);
      tilt = -.45;
      wingUp = math.sin(f * 40) > 0;
      size *= 1 + .25 * math.min(1.0, f * 3);
    }
    sitting(c, at, size, tone: t, tilt: tilt, wingUp: wingUp, sleep: s.sleep, peck: s.peck, alpha: s.alpha);
  }

  /// A pigeon facing left (toward the bird), body [size] rig units long, centred
  /// on [at]: round grey body with the iridescent neck patch, folded wing (or,
  /// with [wingUp], beating), orange beak, an eye (a closed line when [asleep])
  /// and a [peck] (0 .. 1: the head dips); [sleep] (0 .. 1) tucks the head. Used by the nest, the story poses
  /// (a pigeon on the beaten statue's crest) and anything else that perches.
  static void sitting(
    Canvas c,
    Offset at,
    double size, {
    GargoyleTone tone = const GargoyleTone(),
    double tilt = 0,
    bool wingUp = false,
    double sleep = 0,
    double peck = 0,
    double alpha = 1,
  }) {
    final t = tone, a = alpha;
    final asleep = sleep > .5;
    c.save();
    c.translate(at.dx, at.dy);
    c.rotate(tilt);
    c.scale(size);
    final body = Path()
      ..addOval(Rect.fromCenter(center: const Offset(.02, .02), width: 1.0, height: .74))
      ..moveTo(.36, -.02)
      ..lineTo(.86, -.12)
      ..lineTo(.8, .12)
      ..close();
    final head = Offset(-.38 + .12 * sleep - peck * .1, -.33 + .2 * sleep + peck * .24);
    final inkWidth = .09 / size.clamp(.4, 1.5);
    final ink = GargoyleKit.line(GargoylePalette.ink, inkWidth, a);
    c.drawPath(body, ink);
    c.drawCircle(head, .22, ink);
    c.drawPath(body, GargoyleKit.fill(t.lit(_pigeonBody), a));
    c.drawCircle(head, .22, GargoyleKit.fill(t.lit(_pigeonBody), a));
    // The iridescent neck patch, the folded wing (or the beating one), the beak.
    c.drawOval(Rect.fromCenter(center: head + const Offset(.2, .2), width: .34, height: .22), GargoyleKit.fill(t.lit(_pigeonNeck), a * .8));
    final wing = Path()
      ..moveTo(-.18, -.12)
      ..quadraticBezierTo(wingUp ? -.1 : .3, wingUp ? -.95 : .38, wingUp ? .5 : .62, wingUp ? -.55 : .02)
      ..quadraticBezierTo(.16, wingUp ? -.4 : .06, -.18, -.12)
      ..close();
    c.drawPath(wing, GargoyleKit.fill(t.lit(_pigeonWing), a));
    c.drawPath(wing, GargoyleKit.line(GargoylePalette.ink, inkWidth * .67, a));
    c.drawPath(
      Path()
        ..moveTo(head.dx - .2, head.dy + .02)
        ..lineTo(head.dx - .42, head.dy + .08 + peck * .06)
        ..lineTo(head.dx - .2, head.dy + .12),
      GargoyleKit.fill(t.lit(_pigeonBeak), a),
    );
    if (asleep) {
      c.drawLine(head + const Offset(-.1, -.03), head + const Offset(-.02, -.03), GargoyleKit.line(GargoylePalette.ink, .04, a));
    } else {
      c.drawCircle(head + const Offset(-.08, -.04), .035, GargoyleKit.fill(GargoylePalette.ink, a));
    }
    c.restore();
  }

  /// The nest pigeon's (x, y) in rig units for [pose] (tests and the staging's
  /// own placement of the flush).
  static Offset get nestAt => _nestAt;

  // ------------------------------------------------------- the lightning --

  /// A bolt from the top of the screen down to [to] (px) on a screen [h] high:
  /// a jagged polyline (the same for the same [seed]), a wide cool glow, a
  /// mid stroke and a white core, each [alpha]. [reach] is how much of it has
  /// been struck (0 .. 1, from the top). Three ops (four with a branch).
  static void bolt(Canvas c, Offset to, double h, double alpha, {double reach = 1, int seed = 7, double lean = -.44}) {
    if (!(alpha > 0) || !to.dx.isFinite || !to.dy.isFinite || !h.isFinite || !(reach > 0)) return;
    final path = Path()..moveTo(to.dx + h * lean, -h * .06);
    const n = 8;
    final span = to.dy + h * .06;
    var branch = Offset.zero;
    for (var i = 1; i <= n; i++) {
      final k = i / n;
      if (k > reach) break;
      // A staircase of deterministic jags that converge on the target.
      final sway = (GargoyleKit.hash(i, seed) - .5) * h * .16 * (1 - k);
      final p = Offset(to.dx + h * lean * (1 - k) + sway, -h * .06 + span * k);
      path.lineTo(i == n ? to.dx : p.dx, i == n ? to.dy : p.dy);
      if (i == 4) branch = p;
    }
    c.drawPath(path, GargoyleKit.line(const Color(0xff7f9bff), h * .05, alpha * .3));
    c.drawPath(path, GargoyleKit.line(const Color(0xffcfe0ff), h * .018, alpha * .85));
    c.drawPath(path, GargoyleKit.line(GargoylePalette.white, h * .007, alpha));
    if (reach > .55 && branch != Offset.zero) {
      c.drawPath(
        Path()
          ..moveTo(branch.dx, branch.dy)
          ..lineTo(branch.dx - h * .07, branch.dy + h * .04)
          ..lineTo(branch.dx - h * .05, branch.dy + h * .1),
        GargoyleKit.line(const Color(0xffcfe0ff), h * .009, alpha * .7),
      );
    }
  }
}
