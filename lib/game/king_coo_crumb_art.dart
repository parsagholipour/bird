import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../domain/sky_boss.dart';
import 'boss_motion.dart';
import 'king_coo_kit.dart';
import 'king_coo_layout.dart';
import 'king_coo_pose.dart';

/// King Coo's crumb bombs on screen: the stale roll in his hand and in the
/// air, the target RING that marks where it will burst, the fury BRACKET
/// (two rings and the safe corridor between them), the crumb CLOUD that hurts
/// for one second and the harmless sprinkle that follows.
///
/// WHAT THE RULES SAY (the art must agree; `king_coo_crumb_test` measures it):
///  * a ring LOCKS on the bird's height (`CrumbLob.lockX/lockY`) and stays
///    until the burst, 2.2 s later; the bomb leaves his hand 0.8 s after the
///    lock and flies 1.4 s;
///  * the cloud stands at the ring for 1.0 s: radius `lob.cloudRadius(age)`
///    (grows .12 s, holds, shrinks over the last .15 s), and it hurts the bird
///    while the bird's centre is within that radius plus the bird's .038;
///  * fury drops two clouds at `lockY -+ .30` (one centred outside .12 .. .88
///    is dropped), so the height between them is a .30 corridor;
///  * the bomb itself is harmless: only the cloud hurts.
///
/// WHAT IS DRAWN (heights are screen heights, `h` the screen height in px):
///  * the ring's outer edge is the cloud's full radius `KingCoo.cloudRadius`
///    (.11 h) from the first instant and never grows past it, so the area it
///    marks is the area that will hurt; a gold target fills toward impact (a
///    disc that reaches the rim at the burst, eight pips light one by one),
///    four corner brackets lock in, the last .3 s turn solid red;
///  * the cloud's outermost pixel is its hurt radius: every puff, flake and
///    crumb lives INSIDE it, the soft look comes from overlapping puffs and a
///    scalloped edge that never leaves the circle (nothing is blurred and no
///    layer is saved);
///  * the corridor's two brackets sit on the bird's centre-safe limits
///    (`lockY -+ (.30 - .11 - .038)`), exactly where the rules start to hurt;
///  * the bomb in flight is the roll of the hand ([KingCooLayout.bombRadius])
///    growing a little as it comes down; the arc is ballistic, gravity
///    [KingCoo.bombGravity], from the hand at the toss to the ring's centre
///    at the burst, so the bomb lands on the ring's middle on the very frame
///    the cloud begins.
///
/// WHERE IT GOES: [under] paints in the BACKDROP slot (before the stars, the
/// enemies and the bird: the cloud and the ring never hide them) and
/// [flight] in the boss's pass (after the stars, over the figure, before the
/// bird).
///
/// Everything is a pure function of the boss's clock. Reduced Motion keeps
/// every state (ring fill, pips, red, the flight along its arc, the cloud's
/// size, the fade, the sprinkle) and drops the spin, the marching dashes, the
/// lock-in slide, the drifting puffs and the pulse. Nothing here saves a
/// layer, blurs, builds a `Path` for a static shape or draws a random number.
abstract final class KingCooCrumbArt {
  // ---------------------------------------------------------------- tuning --

  /// The ring's and the cloud's full radius, in screen heights.
  static const radius = KingCoo.cloudRadius;

  /// The last stretch before the burst in which the ring goes red.
  static const urgentSeconds = .3;

  /// The ring hands over to the cloud's own edge over the cloud's growth.
  static const ringOut = KingCoo.cloudGrow;

  /// The cloud dims over its last [dimSeconds] to [dimFloor] (still clearly a
  /// hazard) and turns chalky: the safe moment is coming.
  static const dimSeconds = .3, dimFloor = .62;

  /// The bomb in flight grows from the hand's size to this many rig units.
  static const flightRadius = .36;

  /// The spin (radians per second) of the roll in the air, and the spin it
  /// carries out of the hand: the rig turns the held roll `u * 6`, `u` being
  /// 1 at the toss.
  static const spinRate = 11.0, handSpin = 6.0;

  /// Reduced Motion's tilt for the roll: the held roll's own (it does not
  /// turn), so the toss hands over without a jump.
  static const stillTilt = 0.0;

  // ------------------------------------------------------------- palette --

  static const _ink = KingCooPalette.ink;
  static const _gold = KingCooPalette.gold;
  static const _hot = KingCooPalette.stop;
  static const _hotCore = Color(0xffffe9e9);
  static const _go = KingCooPalette.go;
  static const _cream = KingCooPalette.cream;
  static const _white = KingCooPalette.white;
  static const _amber = KingCooPalette.crustDeep;
  static const _burnt = Color(0xffb8571f);

  // ---------------------------------------------------------------- caches --

  static final _Kit _k = _Kit();

  /// Builds every shader and path the effects need (a [bomb] call does it
  /// too): so no frame of the fight builds one.
  static void prewarm() => _k.touch();

  // --------------------------------------------------------------- the roll --

  /// The roll in its own frame: half length 1.30 by half height .90, a little
  /// blunter at the left end, so it reads as a stale dinner roll and never as
  /// a ball or a log.
  static final Path _rollBody = Path()
    ..moveTo(-1.30, .02)
    ..cubicTo(-1.24, -.52, -.78, -.90, -.05, -.90)
    ..cubicTo(.72, -.90, 1.24, -.50, 1.30, -.02)
    ..cubicTo(1.24, .52, .70, .90, -.05, .90)
    ..cubicTo(-.78, .90, -1.24, .56, -1.30, .02)
    ..close();

  /// The underside's shade: a crescent along the bottom.
  static final Path _rollShade = Path()
    ..moveTo(-1.22, .30)
    ..cubicTo(-.90, .84, -.30, .96, .30, .90)
    ..cubicTo(.92, .84, 1.24, .46, 1.26, .12)
    ..cubicTo(1.10, .50, .70, .68, .05, .70)
    ..cubicTo(-.55, .72, -1.00, .60, -1.22, .30)
    ..close();

  /// Three score cuts, pale inside where the crust split.
  static final Path _rollCuts = Path()
    ..moveTo(-.76, -.64)
    ..quadraticBezierTo(-.40, -.04, -.78, .54)
    ..quadraticBezierTo(-.64, -.02, -.76, -.64)
    ..moveTo(-.10, -.80)
    ..quadraticBezierTo(.28, -.04, -.12, .74)
    ..quadraticBezierTo(-.02, -.02, -.10, -.80)
    ..moveTo(.56, -.68)
    ..quadraticBezierTo(.94, -.06, .54, .56)
    ..quadraticBezierTo(.66, -.04, .56, -.68)
    ..close();
  static final Path _rollCutLines = Path()
    ..moveTo(-.76, -.64)
    ..quadraticBezierTo(-.64, -.02, -.78, .54)
    ..moveTo(-.10, -.80)
    ..quadraticBezierTo(-.02, -.02, -.12, .74)
    ..moveTo(.56, -.68)
    ..quadraticBezierTo(.66, -.04, .54, .56);
  static const _specks = <Offset>[
    Offset(-1.02, -.18),
    Offset(-.38, .42),
    Offset(.30, -.50),
    Offset(.30, .40),
    Offset(.98, .16),
    Offset(-.40, -.50),
  ];

  /// The glaze's hard glint, on the side the moon lights (upper right).
  static final Path _glint = Path()
    ..moveTo(.12, -.74)
    ..quadraticBezierTo(.56, -.74, .84, -.40);

  /// The bomb at [at] (rig units; [radius] is the roll's half-height, the
  /// hand holds [KingCooLayout.bombRadius]), turned by [spin]; [alpha] fades
  /// it. The body, the cuts and the ink turn with [spin]; the hard white
  /// glint on the glaze stays put (the light does not spin with the roll),
  /// and it always lies on the body, so the roll never loses its shine.
  static void bomb(
    Canvas c,
    Offset at,
    double radius, {
    double spin = 0,
    double alpha = 1,
  }) {
    if (!(radius.isFinite && radius > 0 && at.dx.isFinite && at.dy.isFinite)) {
      return;
    }
    final a = (alpha.isFinite ? alpha : 1.0).clamp(0.0, 1.0).toDouble();
    if (a <= 0) return;
    final k = _k;
    final s = radius / .9;
    final px = KingCooLayout.inkPart / s;
    c.save();
    c.translate(at.dx, at.dy);
    c.scale(s);
    c.save();
    c.rotate(spin.isFinite ? spin : 0);
    c.drawPath(_rollBody, _shaded(k.rollBody, a));
    c.drawPath(_rollShade, _fill(KingCooPalette.crustDeep, .55 * a));
    c.drawPath(_rollCuts, _fill(KingCooPalette.patch, .92 * a));
    c.drawPath(_rollCutLines, _line(_amber, .08, .85 * a));
    c.drawPoints(ui.PointMode.points, _specks, _line(_amber, .12, .8 * a));
    c.drawPath(_rollBody, _line(_ink, px, a));
    c.restore();
    c.drawPath(_glint, _line(_white, .15, .95 * a));
    c.drawPoints(ui.PointMode.points, const [
      Offset(.98, -.12),
    ], _line(_white, .13, .9 * a));
    c.restore();
  }

  // ------------------------------------------------------------- geometry --

  /// Where the roll is [f] (0 at the toss, 1 at the burst) of the way along
  /// its lob from [from] to [to], in screen heights: ballistic, with gravity
  /// [KingCoo.bombGravity] over [KingCoo.lobFlight]. It is exactly [from] at 0
  /// and exactly [to] at 1.
  static Offset arc(Offset from, Offset to, double f) {
    final u = f.clamp(0.0, 1.0);
    const t = KingCoo.lobFlight, g = KingCoo.bombGravity;
    final vy = (to.dy - from.dy - .5 * g * t * t) / t;
    final s = u * t;
    return Offset(
      from.dx + (to.dx - from.dx) * u,
      u >= 1 ? to.dy : from.dy + vy * s + .5 * g * s * s,
    );
  }

  /// Where the roll leaves his hand (screen heights): the near wing's tip in
  /// the pose at the toss, carried by the rules' own hover. At the toss that
  /// is [KingCooLayout.lobRelease] within the contract's .12 units.
  static Offset release(SkyBoss boss, BossMotion m, CrumbLob lob) {
    final pose = KingCooPose(boss, m, at: lob.launchAt);
    final hand = pose.toRig(pose.handAt);
    return Offset(
          boss.x,
          KingCooLayout.hoverY(lob.launchAt - boss.arrivalDuration),
        ) +
        hand * SkyBoss.radius;
  }

  /// The bomb's radius in rig units [f] of the way through its flight: the
  /// hand's, easing up to [flightRadius] as it comes down.
  static double flightSize(double f) =>
      KingCooLayout.bombRadius +
      (flightRadius - KingCooLayout.bombRadius) * KingCooKit.ease(f);

  /// The corridor between a fury lob's two clouds, as the bird's CENTRE may
  /// use it: from the lower edge of the upper cloud (plus the bird's radius)
  /// to the upper edge of the lower one; null unless both clouds stand.
  static (double, double)? corridor(CrumbLob lob) {
    final ys = lob.cloudHeights;
    if (ys.length < 2) return null;
    const reach = KingCoo.cloudRadius + KingCoo.birdRadius;
    return (ys.first + reach, ys.last - reach);
  }

  /// The cloud's dimming at [s] seconds after the burst: 1 until the last
  /// [dimSeconds], then easing to [dimFloor].
  static double dim(double s) => 1 - (1 - dimFloor) * chalk(s);

  /// How chalky (settled) the cloud looks at [s]: 0 until the last
  /// [dimSeconds], then 1.
  static double chalk(double s) =>
      KingCooKit.ease((s - (KingCoo.cloudSeconds - dimSeconds)) / dimSeconds);

  // ---------------------------------------------------- motion channels --

  /// The motion in the effects, each a function of the clock that Reduced
  /// Motion holds still: the ring's marching dashes (radians), the corner
  /// brackets' slide-in (0 to 1; 1 at once when reduced), the red ring's
  /// pulse (a factor on the brightness), the roll's spin (radians: out of the
  /// hand's own spin, the twin of a fury pair a little apart) and the cloud's
  /// drift (seconds of drift).
  static double march(double t, bool reduced) => reduced ? 0 : t * .9;
  static double slide(double t, bool reduced) =>
      reduced ? 1 : 1 - math.pow(1 - KingCooKit.ramp(t, 0, .26), 3).toDouble();
  static double pulse(double t, bool reduced) =>
      reduced ? 1 : .84 + .16 * math.sin(t * 2 * math.pi * 7);
  static double spinAt(double s, bool reduced, {int twin = 0}) =>
      reduced ? stillTilt - twin * .9 : handSpin + spinRate * s + twin * 2.1;
  static double drift(double s, bool reduced) => reduced ? 0 : s;

  // ------------------------------------------------------------ the effects --

  static bool _sane(CrumbLob lob) =>
      lob.lockedAt.isFinite && lob.lockX.isFinite && lob.lockY.isFinite;

  /// Rings, corridors, clouds and sprinkles of every live bomb, for the
  /// BACKDROP slot (before the stars, the enemies and the bird).
  static void under(Canvas c, Size size, SkyBoss boss, BossMotion m) {
    final h = size.height, age = boss.age;
    if (!(h.isFinite && h > 0 && age.isFinite && size.width.isFinite)) return;
    final lobs = boss.liveLobs;
    if (lobs.isEmpty) return;
    final reduced = m.reducedMotion;
    // The ground first (clouds, sprinkles), then what must stay readable
    // over it (corridors, rings).
    for (final lob in lobs) {
      if (!_sane(lob) || age < lob.burstAt) continue;
      final at = lob.cloudHeights;
      for (var i = 0; i < at.length; i++) {
        final centre = Offset(lob.lockX * h, at[i] * h);
        final seed = _seed(lob, i);
        if (age < lob.cloudEndsAt) {
          cloud(c, h, centre, age - lob.burstAt, seed: seed, reduced: reduced);
        } else {
          sprinkle(
            c,
            h,
            centre,
            age - lob.cloudEndsAt,
            seed: seed,
            reduced: reduced,
          );
        }
      }
    }
    for (final lob in lobs) {
      if (!_sane(lob) || age < lob.lockedAt || age >= lob.cloudEndsAt) continue;
      final t = age - lob.lockedAt;
      if (age < lob.burstAt + ringOut) {
        for (final y in lob.cloudHeights) {
          ring(c, h, Offset(lob.lockX * h, y * h), t, reduced: reduced);
        }
      }
      final lane = corridor(lob);
      if (lane != null) {
        bracket(
          c,
          h,
          lob.lockX * h,
          lane.$1 * h,
          lane.$2 * h,
          t,
          reduced: reduced,
        );
      }
    }
    // The rolls that are clear of him fly here, over the rings and under
    // everything the player plays with.
    rolls(c, size, boss, m, near: false);
  }

  /// The rolls in the air, their dotted arcs and their crumb trails, for the
  /// boss's pass (after the stars, over the figure, before the bird): only
  /// the ones still near him, right after the toss, so a roll leaves his
  /// wing over the figure and never behind it. Once a roll is clear of him
  /// ([nearKing] rig units from his chest) [under] draws it, below the stars,
  /// the enemies and the bird: a flying roll never hides what the player
  /// plays with.
  static void flight(Canvas c, Size size, SkyBoss boss, BossMotion m) =>
      rolls(c, size, boss, m, near: true);

  /// How far from his chest (rig units) a roll counts as near him: past his
  /// beak (the envelope's left is -2.80) and the roll's own size.
  static const nearKing = 3.4;

  /// The rolls of [boss] that are near him ([near]) or clear of him: what
  /// [flight] and [under] each draw. Exposed so a staging (or a test) can ask
  /// for one half.
  static void rolls(
    Canvas c,
    Size size,
    SkyBoss boss,
    BossMotion m, {
    required bool near,
  }) {
    final h = size.height, age = boss.age;
    if (!(h.isFinite && h > 0 && age.isFinite && size.width.isFinite)) return;
    if (!boss.x.isFinite) return;
    final lobs = boss.liveLobs;
    if (lobs.isEmpty) return;
    final reduced = m.reducedMotion;
    for (final lob in lobs) {
      if (!_sane(lob) || age < lob.launchAt || age >= lob.burstAt) continue;
      final from = release(boss, m, lob);
      final s = age - lob.launchAt;
      // One roll to each cloud: in fury the toss throws a pair, one to the
      // ring above the bird and one to the ring below.
      final at = lob.cloudHeights;
      for (var i = 0; i < at.length; i++) {
        final to = Offset(lob.lockX, at[i]);
        final where = arc(from, to, s / KingCoo.lobFlight);
        final close = boss.x - where.dx < nearKing * SkyBoss.radius;
        if (close != near) continue;
        roll(c, h, from, to, s, reduced: reduced, seed: _seed(lob, i), twin: i);
      }
    }
  }

  static int _seed(CrumbLob lob, int i) =>
      (((lob.lockedAt * 10).round().abs() % 97) * 3 + i) & 0xffff;

  // ------------------------------------------------- the roll in the air --

  /// One roll [s] seconds after the toss, from [from] to [to] (screen
  /// heights): the dotted arc still to fly, the crumbs it sheds, the grains
  /// kicked off the wing, and the roll itself.
  static void roll(
    Canvas c,
    double h,
    Offset from,
    Offset to,
    double s, {
    required bool reduced,
    int seed = 0,
    int twin = 0,
    bool trail = true,
  }) {
    if (!(s.isFinite &&
        h.isFinite &&
        from.dx.isFinite &&
        from.dy.isFinite &&
        to.dx.isFinite &&
        to.dy.isFinite)) {
      return;
    }
    final f = (s / KingCoo.lobFlight).clamp(0.0, 1.0);
    final at = arc(from, to, f);
    if (trail) _trail(c, h, from, to, s, f, reduced, seed);
    // The roll: the hand's size, easing up as it comes down. It turns on
    // out of the hand's own spin.
    final spin = spinAt(s, reduced, twin: twin);
    c.save();
    c.translate(at.dx * h, at.dy * h);
    c.scale(h * SkyBoss.radius);
    bomb(c, Offset.zero, flightSize(f), spin: spin);
    c.restore();
  }

  /// The dotted arc still to fly, the crumbs shed behind the roll and the
  /// grains kicked off the wing, [s] seconds into the flight ([f] of the way).
  static void _trail(
    Canvas c,
    double h,
    Offset from,
    Offset to,
    double s,
    double f,
    bool reduced,
    int seed,
  ) {
    // The arc still to fly, as dots (the ring marks where it ends).
    if (f < .95) {
      final fade = 1 - .5 * f;
      final dots = <Offset>[
        for (var i = 1; i <= 9; i++) arc(from, to, f + (1 - f) * i / 9) * h,
      ];
      c.drawPoints(
        ui.PointMode.points,
        dots,
        _line(_ink, h * .0150, .55 * fade),
      );
      c.drawPoints(
        ui.PointMode.points,
        dots,
        _line(_cream, h * .0086, .9 * fade),
      );
    }
    // Crumbs shed behind it: born along the arc, they hang and fall.
    const shed = 12, every = .06, life = .5;
    final young = <Offset>[], mid = <Offset>[], old = <Offset>[];
    for (var i = 0; i < shed; i++) {
      final born = s - (i + 1) * every;
      if (born < 0) break;
      final age = s - born;
      if (age > life) continue;
      final p = arc(from, to, born / KingCoo.lobFlight);
      final jx = (KingCooKit.hash(i, seed) - .5) * .02;
      final jy = KingCooKit.hash(i, seed + 5) * .014;
      final fall = .5 * KingCoo.bombGravity * age * age * .55;
      final q = Offset(p.dx + jx * age * 4, p.dy + jy * age * 4 + fall) * h;
      (age < life * .33
              ? young
              : age < life * .66
              ? mid
              : old)
          .add(q);
    }
    if (young.isNotEmpty) {
      c.drawPoints(ui.PointMode.points, young, _line(_amber, h * .0135, .9));
      c.drawPoints(
        ui.PointMode.points,
        young,
        _line(KingCooPalette.crumb, h * .0095),
      );
    }
    if (mid.isNotEmpty) {
      c.drawPoints(
        ui.PointMode.points,
        mid,
        _line(KingCooPalette.crumb, h * .0078, .75),
      );
    }
    if (old.isNotEmpty) {
      c.drawPoints(
        ui.PointMode.points,
        old,
        _line(KingCooPalette.crumbHi, h * .0058, .5),
      );
    }
    // The toss: a few grains kicked off the wing.
    if (s < .3 && !reduced) {
      final k = s / .3;
      final grains = <Offset>[
        for (var i = 0; i < 7; i++)
          from * h +
              Offset(
                    (KingCooKit.hash(i, seed + 11) - .35) * .13,
                    (KingCooKit.hash(i, seed + 13) - .85) * .10 + .12 * k * k,
                  ) *
                  h *
                  k,
      ];
      c.drawPoints(
        ui.PointMode.points,
        grains,
        _line(KingCooPalette.crumbHi, h * .008, 1 - k),
      );
    }
  }

  // ------------------------------------------------------------- the ring --

  static const _pips = 8;

  /// The telegraph ring at [centre] (px), [t] seconds after the lock. Its
  /// outer edge is the cloud's radius from the first frame, whatever [t].
  static void ring(
    Canvas c,
    double h,
    Offset centre,
    double t, {
    required bool reduced,
  }) {
    if (!(t.isFinite &&
        t >= 0 &&
        h.isFinite &&
        centre.dx.isFinite &&
        centre.dy.isFinite)) {
      return;
    }
    final r = radius * h;
    if (r < 4) return;
    final k = _k;
    const burst = KingCoo.telegraph;
    final u = (t / burst).clamp(0.0, 1.0);
    final urgent = t >= burst - urgentSeconds;
    // After the burst only the rim stays, white-hot, while the cloud blooms
    // inside it.
    final handover = t > burst ? ((t - burst) / ringOut).clamp(0.0, 1.0) : 0.0;
    final a = KingCooKit.ramp(t, 0, .12) * (1 - handover);
    if (a <= .01) return;
    final pulse_ = urgent ? pulse(t, reduced) : 1.0;
    final main = urgent ? _hot : _gold;
    final core = handover > 0
        ? _white
        : urgent
        ? _hotCore
        : _cream;

    c.save();
    c.translate(centre.dx, centre.dy);
    if (handover == 0) {
      // A dark floor round the rim (clear in the middle), so the ring reads
      // over lit windows and the pale haze alike.
      c.save();
      c.scale(r);
      c.drawCircle(Offset.zero, 1, _shaded(k.floor, a));
      c.restore();
      // The target fills toward impact: a disc that reaches the rim at the
      // burst.
      if (u > .04) {
        c.save();
        c.scale(r * u);
        c.drawCircle(
          Offset.zero,
          1,
          _shaded(urgent ? k.fillHot : k.fillGold, a * pulse_),
        );
        c.restore();
        // The fill's edge is a line drawn inward from the fill's radius, so
        // the ring never pokes past the cloud's radius.
        final edge = h * .0046;
        c.drawCircle(
          Offset.zero,
          math.max(0.0, r * u - edge / 2),
          _line(core, edge, .95 * a),
        );
      }
    }
    // The rim: dashes marching round (solid and red in the last .3 s), an ink
    // edge under a bright core, the outer edge exactly the cloud's radius.
    final ink = h * .0165, bright = h * .0095;
    final rho = r - ink / 2;
    if (urgent) {
      c.drawCircle(Offset.zero, rho, _line(_ink, ink, .88 * a));
      c.drawCircle(Offset.zero, rho, _line(main, bright, a * pulse_));
      c.drawCircle(Offset.zero, rho, _line(core, bright * .34, .95 * a));
    } else {
      c.save();
      c.rotate(march(t, reduced));
      c.scale(rho);
      c.drawPath(k.dashes, _line(_ink, ink / rho, .88 * a));
      c.drawPath(k.dashes, _line(main, bright / rho, a));
      c.drawPath(k.dashes, _line(core, bright * .32 / rho, .9 * a));
      c.restore();
    }
    // The hard white glint of a glossy rim, on the moon's side (upper right):
    // it stays put while the dashes march past it.
    if (handover == 0) {
      c.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: rho - bright * .15),
        -1.1,
        .42,
        false,
        _line(_white, bright * .5, .95 * a),
      );
    }
    if (handover == 0) {
      // Pips: eight, lit one by one, the last on the burst.
      final lit = (u * _pips).floor();
      final r1 = rho - ink * .95, r2 = r1 - h * .028;
      for (var pass = 0; pass < 2; pass++) {
        final path = Path();
        for (var i = 0; i < _pips; i++) {
          if ((i < lit) != (pass == 1)) continue;
          final ang = -math.pi / 2 + (i + .5) * 2 * math.pi / _pips;
          final dir = Offset(math.cos(ang), math.sin(ang));
          path
            ..moveTo(dir.dx * r1, dir.dy * r1)
            ..lineTo(dir.dx * r2, dir.dy * r2);
        }
        if (pass == 0) {
          c.drawPath(path, _line(_ink, h * .0115, .7 * a));
          c.drawPath(path, _line(_cream, h * .0062, .78 * a));
        } else {
          c.drawPath(path, _line(_ink, h * .0115, .88 * a));
          c.drawPath(path, _line(main, h * .0070, a));
        }
      }
      // The brackets lock in: four corners slide in from the rim and settle.
      final slid = slide(t, reduced);
      final at = .98 - .36 * slid;
      c.save();
      c.rotate((1 - slid) * .7);
      c.scale(r * at);
      c.drawPath(k.corners, _line(_ink, h * .0135 / (r * at), .88 * a));
      c.drawPath(k.corners, _line(core, h * .0072 / (r * at), a * pulse_));
      c.restore();
      // The centre: where it will land.
      c.drawCircle(Offset.zero, h * .0078, _fill(_ink, .85 * a));
      c.drawCircle(Offset.zero, h * .0048, _fill(core, a));
    }
    c.restore();
  }

  // ----------------------------------------------------------- the bracket --

  /// The fury corridor at screen x [x] (px), from [top] to [bottom] (px, the
  /// bird's centre-safe limits), [t] seconds after the lock.
  static void bracket(
    Canvas c,
    double h,
    double x,
    double top,
    double bottom,
    double t, {
    required bool reduced,
  }) {
    if (!(x.isFinite && top.isFinite && bottom.isFinite && h.isFinite) ||
        bottom <= top) {
      return;
    }
    const lifetime = KingCoo.telegraph + KingCoo.cloudSeconds;
    final a =
        KingCooKit.ramp(t, 0, .2) *
        (1 - KingCooKit.ramp(t, lifetime - .3, lifetime));
    if (a <= .01) return;
    final half = h * .05, hook = h * .03;
    final w = half * (1 + .6 * (1 - slide(t, reduced)));
    final lane = Path()
      ..moveTo(x - w, top + hook)
      ..lineTo(x - w, top)
      ..lineTo(x + w, top)
      ..lineTo(x + w, top + hook)
      ..moveTo(x - w, bottom - hook)
      ..lineTo(x - w, bottom)
      ..lineTo(x + w, bottom)
      ..lineTo(x + w, bottom - hook);
    c.drawRect(Rect.fromLTRB(x - w, top, x + w, bottom), _fill(_go, .1 * a));
    c.drawPath(lane, _line(_ink, h * .0135, .85 * a));
    c.drawPath(lane, _line(_go, h * .0075, a));
    // Chevrons point into the corridor's middle.
    final cv = h * .014;
    final chev = Path()
      ..moveTo(x - cv * 1.4, top + hook * 1.9 - cv)
      ..lineTo(x, top + hook * 1.9 + cv * .2)
      ..lineTo(x + cv * 1.4, top + hook * 1.9 - cv)
      ..moveTo(x - cv * 1.4, bottom - hook * 1.9 + cv)
      ..lineTo(x, bottom - hook * 1.9 - cv * .2)
      ..lineTo(x + cv * 1.4, bottom - hook * 1.9 + cv);
    c.drawPath(chev, _line(_ink, h * .0115, .75 * a));
    c.drawPath(chev, _line(_go, h * .0062, .95 * a));
  }

  // ------------------------------------------------------------- the cloud --

  /// The cloud at [centre] (px), [s] seconds after the burst. Its outermost
  /// pixel is `KingCoo.cloudRadiusAt(s) * h`: the radius that hurts.
  ///
  /// A scalloped silhouette of ten rim puffs round a disc (the scallops'
  /// peaks touch the radius, the valleys sit [_baseU] of the way out), each
  /// puff lit from the moon's side; soft lighter puffs and flecks of crumb
  /// inside, a warm brown edge, a hard white glint. About 26 draws.
  static void cloud(
    Canvas c,
    double h,
    Offset centre,
    double s, {
    required int seed,
    required bool reduced,
  }) {
    if (!(h.isFinite && centre.dx.isFinite && centre.dy.isFinite)) return;
    final r = KingCoo.cloudRadiusAt(s) * h;
    if (!(r >= 3)) return;
    final k = _k;
    final a = dim(s);
    final pale = chalk(s);
    final t = drift(s, reduced);
    final variant = seed & 3;
    final turn = variant * .55;
    c.save();
    c.translate(centre.dx, centre.dy);
    c.scale(r);
    c.rotate(turn);
    // Silhouette: the amber edge, then the haze and the puffs over it.
    c.drawCircle(Offset.zero, 1, _shaded(k.shadow, a));
    c.drawPath(k.silhouette, _fill(_burnt, .9 * a));
    c.drawCircle(Offset.zero, _baseU, _shaded(k.base, a * .66));
    for (var i = 0; i < k.puffs.length; i++) {
      final (at, size) = k.puffs[i];
      c.save();
      c.translate(at.dx, at.dy);
      c.rotate(-turn);
      c.scale(size - _edge);
      c.drawCircle(Offset.zero, 1, _shaded(k.puffLit, a * .86));
      c.restore();
    }
    // Layers inside, each lighter than the one behind: they drift slowly
    // against one another and breathe.
    for (var i = 0; i < _inner.length; i++) {
      final (ang, dist, size, layer) = _inner[i];
      final tt = ang + t * (i.isEven ? .55 : -.42) * (1 + layer * .35);
      final breathe = 1 + (reduced ? 0 : .05 * math.sin(s * 5 + i * 1.7));
      c.save();
      c.translate(math.cos(tt) * dist, math.sin(tt) * dist);
      c.rotate(-turn);
      c.scale(size * breathe);
      c.drawCircle(
        Offset.zero,
        1,
        _shaded(
          layer == 0 ? k.puffMid : k.puffHi,
          a * (layer == 0 ? .82 : .78),
        ),
      );
      c.restore();
    }
    // Flecks of crumb: chunks (square), grains, flour; all inside.
    // Their sizes are pixels, capped in unit radii so that while the cloud is
    // still small they stay inside it.
    final big = _line(_amber, math.min(h * .0098 / r, .11), .85 * a)
      ..strokeCap = StrokeCap.square;
    c.drawPoints(ui.PointMode.points, k.chunks, big);
    c.drawPoints(
      ui.PointMode.points,
      k.grains,
      _line(KingCooPalette.crust, math.min(h * .0074 / r, .09), .9 * a),
    );
    c.drawPoints(
      ui.PointMode.points,
      k.flour,
      _line(_white, math.min(h * .0056 / r, .07), .8 * a),
    );
    // Chalky when it is about to settle.
    if (pale > .01) {
      c.drawCircle(Offset.zero, _baseU - _edge, _fill(_cream, .3 * pale));
    }
    c.rotate(-turn);
    // The moon's hard white glints on the tops of the puffs on its side.
    c.drawPath(
      k.lights[variant],
      _line(_white, math.min(h * .0066 / r, .06), .92 * a),
    );
    // The burst: a flash that is gone in a quarter second.
    if (s < .26) {
      final k0 = s / .26;
      c.save();
      c.scale(.35 + .5 * KingCooKit.ease(k0));
      c.drawPath(k.star, _fill(_white, .9 * (1 - k0)));
      c.restore();
    }
    c.restore();
  }

  /// The base disc's radius (its edge is the valleys between the puffs) and
  /// the thickness of the amber edge, both in unit radii.
  static const _baseU = .88, _edge = .06;

  /// Puffs inside: (angle, distance, size, layer); layer 0 is the middle
  /// ring, 1 the bright core. Every one lies inside the base disc:
  /// `distance + size <= .9`.
  static const _inner = <(double, double, double, int)>[
    (.2, .52, .31, 0),
    (1.2, .50, .27, 0),
    (2.2, .53, .30, 0),
    (3.2, .50, .28, 0),
    (4.2, .54, .30, 0),
    (5.2, .50, .27, 0),
    (.9, .20, .34, 1),
    (3.0, .22, .32, 1),
    (5.0, .18, .33, 1),
  ];

  // ----------------------------------------------------------- the sprinkle --

  /// The harmless crumbs after the cloud, [s] seconds after it ended (they
  /// last [KingCoo.crumbSeconds]): grains and chunks falling from where it
  /// stood. Sparse and small, nothing like the cloud.
  static void sprinkle(
    Canvas c,
    double h,
    Offset centre,
    double s, {
    required int seed,
    required bool reduced,
  }) {
    if (!(h.isFinite && centre.dx.isFinite && centre.dy.isFinite)) return;
    final left = 1 - s / KingCoo.crumbSeconds;
    if (!(left > 0 && s >= 0)) return;
    final k = reduced ? .5 : s / KingCoo.crumbSeconds;
    final secs = k * KingCoo.crumbSeconds;
    final fall = .5 * KingCoo.bombGravity * secs * secs;
    final chunks = <Offset>[], grains = <Offset>[], flour = <Offset>[];
    for (var i = 0; i < 24; i++) {
      final dir = Offset.fromDirection(
        i * 2.399963 + seed,
        .35 + .65 * math.sqrt((i + .5) / 24),
      );
      final spread = (.05 + KingCooKit.hash(i, seed) * .10) * k;
      final drop = fall * (.7 + KingCooKit.hash(i, seed + 3) * .6);
      final p =
          centre +
          Offset(dir.dx * spread * 1.5, dir.dy * spread * .8 - .02 * k + drop) *
              h;
      (i % 3 == 0
              ? chunks
              : i % 3 == 1
              ? grains
              : flour)
          .add(p);
    }
    c.drawPoints(
      ui.PointMode.points,
      chunks,
      _line(_amber, h * .0170, .85 * left)..strokeCap = StrokeCap.square,
    );
    c.drawPoints(
      ui.PointMode.points,
      chunks,
      _line(KingCooPalette.crumb, h * .0100, left)
        ..strokeCap = StrokeCap.square,
    );
    c.drawPoints(
      ui.PointMode.points,
      grains,
      _line(_amber, h * .0128, .8 * left),
    );
    c.drawPoints(
      ui.PointMode.points,
      grains,
      _line(KingCooPalette.crumbHi, h * .0082, left),
    );
    c.drawPoints(
      ui.PointMode.points,
      flour,
      _line(_white, h * .0068, .85 * left),
    );
  }

  // ---------------------------------------------------------------- paints --

  static Paint _fill(Color color, [double alpha = 1]) =>
      KingCooKit.fill(color, alpha);
  static Paint _line(Color color, double width, [double alpha = 1]) =>
      KingCooKit.line(color, width, alpha);
  static Paint _shaded(ui.Shader shader, double alpha) => Paint()
    ..shader = shader
    ..color = Color.fromRGBO(255, 255, 255, alpha.clamp(0.0, 1.0));
}

/// Everything the effects need that does not depend on the clock: shaders in
/// unit space and static paths, built together on first use.
class _Kit {
  _Kit() {
    touch();
  }

  /// Builds every shader and path now (they are `late final`, so they would
  /// otherwise wait for the first frame that needs each): the first `bomb`
  /// call (the rig's `prewarm` makes one) builds the lot.
  void touch() {
    rollBody;
    base;
    shadow;
    puffLit;
    puffMid;
    puffHi;
    floor;
    fillGold;
    fillHot;
    dashes;
    corners;
    star;
    silhouette;
    lights;
    puffs;
    chunks;
    grains;
    flour;
  }

  ui.Shader _radial(
    List<Color> colors,
    List<double> stops, [
    Offset centre = Offset.zero,
    double radius = 1,
  ]) => KingCooKit.radial(centre, radius, colors, stops).shader!;

  /// The roll: glaze highlight at its upper right (the moon's side), golden
  /// crust, a deep brown rim where it turns away.
  late final ui.Shader rollBody = _radial(
    const [
      KingCooPalette.crumbHi,
      KingCooPalette.crumb,
      KingCooPalette.crust,
      Color(0xffb26d2d),
    ],
    const [0, .34, .72, 1],
    const Offset(.42, -.46),
    1.75,
  );

  /// The cloud's body: a flat warm tan, a little lighter on the moon's side;
  /// each rim puff is lit the same way (a unit radial, lit upper right).
  late final ui.Shader base = _radial(
    const [Color(0xfffbe8bd), Color(0xffecc283), Color(0xffd89a50)],
    const [0, .62, 1],
    const Offset(.28, -.32),
    1.4,
  );
  late final ui.Shader puffLit = _radial(
    const [Color(0xfffff6dc), Color(0xfff3cf86), Color(0xffd0904a)],
    const [0, .55, 1],
    const Offset(.34, -.38),
    1.25,
  );
  late final ui.Shader shadow = _radial(
    const [Color(0x00381a0c), Color(0x00381a0c), Color(0x66381a0c)],
    const [0, .55, 1],
  );
  late final ui.Shader puffMid = _radial(
    const [Color(0xfffff8e2), Color(0xfff7d994), Color(0xffe3ac5e)],
    const [0, .55, 1],
    const Offset(.34, -.38),
    1.25,
  );
  late final ui.Shader puffHi = _radial(
    const [Color(0xffffffff), Color(0xfffff0c8), Color(0xfff6d488)],
    const [0, .5, 1],
    const Offset(.3, -.34),
    1.2,
  );

  /// The ring's floor (clear in the middle, dark at the rim) and its fills.
  late final ui.Shader floor = _radial(
    [_navy(0), _navy(.06), _navy(.38)],
    const [0, .6, 1],
  );
  late final ui.Shader fillGold = _radial(
    const [Color(0x44ffd25a), Color(0x8cffc83f), Color(0xcaffb82c)],
    const [0, .75, 1],
  );
  late final ui.Shader fillHot = _radial(
    const [Color(0x58ff4a5c), Color(0xa0ff4a5c), Color(0xd0ff5666)],
    const [0, .75, 1],
  );

  static Color _navy(double a) => Color.fromRGBO(20, 20, 47, a);

  /// Sixteen dashes round a unit circle.
  late final Path dashes = () {
    final p = Path();
    const n = 16;
    for (var i = 0; i < n; i++) {
      p.addArc(
        Rect.fromCircle(center: Offset.zero, radius: 1),
        i * 2 * math.pi / n,
        2 * math.pi / n * .56,
      );
    }
    return p;
  }();

  /// Four corner brackets on the diagonals of a unit circle.
  late final Path corners = () {
    final p = Path();
    const leg = .30, d = .70710678;
    for (var i = 0; i < 4; i++) {
      final sx = i.isEven ? -1.0 : 1.0, sy = i < 2 ? -1.0 : 1.0;
      p
        ..moveTo((sx * d) - sx * leg, sy * d)
        ..lineTo(sx * d, sy * d)
        ..lineTo(sx * d, (sy * d) - sy * leg);
    }
    return p;
  }();

  /// The burst's star: eight points, long and short in turn.
  late final Path star = () {
    final p = Path();
    for (var i = 0; i < 16; i++) {
      final a = i * math.pi / 8;
      final r = i.isEven ? 1.0 : .52;
      final pt = Offset(math.cos(a), math.sin(a)) * r;
      i == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
    }
    return p..close();
  }();

  /// The rim puffs of the cloud: (centre, outer radius), eleven of different
  /// sizes (a cloud, not a pie crust) packed round the unit circle so every
  /// puff touches it from inside (`|centre| + radius = 1`: the outermost point
  /// of the cloud is exactly the radius that hurts) and each overlaps its
  /// neighbours a little. The overlap is solved so they close the circle.
  late final List<(Offset, double)> puffs = () {
    const radii = [.30, .21, .27, .19, .29, .23, .20, .28, .22, .26, .24];
    final n = radii.length;
    double step(int i, double f) {
      final d1 = 1 - radii[i], d2 = 1 - radii[(i + 1) % n];
      final dist = f * (radii[i] + radii[(i + 1) % n]);
      final cos = (d1 * d1 + d2 * d2 - dist * dist) / (2 * d1 * d2);
      return math.acos(cos.clamp(-1.0, 1.0));
    }

    var lo = .3, hi = 1.6;
    for (var it = 0; it < 40; it++) {
      final mid = (lo + hi) / 2;
      var total = 0.0;
      for (var i = 0; i < n; i++) {
        total += step(i, mid);
      }
      // A bigger overlap factor spreads the puffs further apart.
      if (total > 2 * math.pi) {
        hi = mid;
      } else {
        lo = mid;
      }
    }
    final f = (lo + hi) / 2;
    var angle = -.4;
    return [
      for (var i = 0; i < n; i++)
        () {
          final at = Offset.fromDirection(angle, 1 - radii[i]);
          angle += step(i, f);
          return (at, radii[i]);
        }(),
    ];
  }();

  /// The silhouette: every puff at its full radius, as one path.
  late final Path silhouette = () {
    final p = Path();
    for (final (at, size) in puffs) {
      p.addOval(Rect.fromCircle(center: at, radius: size));
    }
    return p;
  }();

  /// Where the moon's light touches: on each puff on its side (upper right,
  /// after the cloud's own turn), a short hard arc near its crown. One path
  /// for each of the four turns a cloud can have.
  late final List<Path> lights = [
    for (var v = 0; v < 4; v++)
      () {
        final p = Path();
        final turn = v * .55;
        for (final (at, size) in puffs) {
          final c = Offset.fromDirection(at.direction + turn, at.distance);
          // Upper right of the cloud: x > 0 and y < 0 after the turn.
          if (c.dx < .1 || c.dy > -.1) continue;
          p.addArc(
            Rect.fromCircle(center: c, radius: (size - .05) * .62),
            -1.25,
            .75,
          );
        }
        return p;
      }(),
  ];

  /// Crumb flecks inside the disc (golden-spiral scatter, within .80).
  late final List<Offset> chunks = _scatter(8, .76, 1);
  late final List<Offset> grains = _scatter(11, .80, 2);
  late final List<Offset> flour = _scatter(14, .82, 3);

  static List<Offset> _scatter(int n, double reach, int salt) => [
    for (var i = 0; i < n; i++)
      Offset.fromDirection(
        i * 2.399963 + salt * 1.7,
        reach * math.sqrt((i + .6 + KingCooKit.hash(i, salt) * .3) / (n + .6)),
      ),
  ];
}
