import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../domain/sky_boss.dart';
import 'boss_motion.dart';
import 'dragon_kit.dart';

/// The Ember Dragon's shots, drawn in hit-radius units travelling along +x:
/// a molten fireball trailing a layered comet tail and a few sparks, the
/// small embers a fury fireball bursts into, the orb that forms in the jaws
/// and the muzzle burst as it leaves.
///
/// The solid, ink-rimmed body ends exactly on the hit circle, so a dodge
/// that looks clean is clean; the halo, the tail and every flash may reach
/// further. A fireball about to split cracks into a dark crust round three
/// swelling embers and a tightening heat ring, then its embers are born in a
/// flash with a fan ray each, so the burst never comes out of nowhere.
///
/// Every motion follows simulation time (or, for the charge, the charge
/// itself); Reduced Motion freezes it to one pose that keeps every state
/// (charging, splitting, the muzzle ring) readable.
abstract final class DragonFireballArt {
  static const _ink = DragonPalette.ink;

  /// Fury's hotter rim: oxblood-crimson where the plain ball goes to
  /// [DragonPalette.flameDark].
  static const _furyRim = Color(0xffc21f4a);

  /// A burst is over this long after the split.
  static const burstSeconds = .36;

  // ------------------------------------------------------------ caches --
  // Everything that only depends on the palette is built once, in unit space
  // (the ball's radius is 1, it flies along +x, its tail streams to -x) and
  // drawn under a transform. Alpha is the paint's own, so one shader serves
  // every shot however faint.

  static ui.Shader _radial(
    List<Color> colors,
    List<double> stops, [
    Offset center = Offset.zero,
    double radius = 1,
  ]) => ui.Gradient.radial(center, radius, colors, stops);

  /// A soft glow of [color] for a disc of radius 1: solid to 35%.
  static ui.Shader _glow(Color color, double alpha) => _radial(
    [
      color.withValues(alpha: alpha),
      color.withValues(alpha: alpha * .4),
      color.withValues(alpha: 0),
    ],
    const [.35, .6, 1],
  );

  static final _haloShader = _glow(DragonPalette.flame, .5);
  static final _haloFuryShader = _glow(DragonPalette.flameGold, .7);
  static final _emberGlowShader = _radial(
    [
      DragonPalette.flameGold.withValues(alpha: .8),
      DragonPalette.flame.withValues(alpha: .32),
      DragonPalette.flame.withValues(alpha: 0),
    ],
    const [.2, .55, 1],
  );

  // The molten body: white-cream at its hot heart, cooling through yellow
  // and gold to a dark rim that the ink then closes.
  static final _bodyShader = _radial(
    const [
      DragonPalette.flameCore,
      DragonPalette.flameYellow,
      DragonPalette.flameGold,
      DragonPalette.flame,
      DragonPalette.flameDark,
    ],
    const [0, .26, .52, .78, 1],
    const Offset(.3, -.2),
  );
  static final _bodyFuryShader = _radial(
    const [
      DragonPalette.white,
      DragonPalette.flameCore,
      DragonPalette.flameYellow,
      DragonPalette.flame,
      _furyRim,
    ],
    const [0, .3, .55, .8, 1],
    const Offset(.3, -.2),
  );

  /// A dark crust that closes over the body as a split nears: clear at the
  /// heart, oxblood at the rim.
  static final _crustShader = _radial(
    [
      DragonPalette.flameDark.withValues(alpha: 0),
      DragonPalette.flameDark.withValues(alpha: .55),
      DragonPalette.soot.withValues(alpha: .9),
    ],
    const [.32, .72, 1],
  );

  // The birth flash and the muzzle flare.
  static final _flashShader = _radial(
    const [DragonPalette.white, DragonPalette.flameCore, Color(0x00ffe066)],
    const [.15, .5, 1],
  );

  /// A plume of flame streaming back from the ball, in its own space: the
  /// root at x = 0 hugging the ball's poles, [width] half-widths across
  /// there, tapering to a tip at x = -1 and shedding [licks] tongues per
  /// flank that rise [ragged] out of the edge. Drawn under `scale(len, 1)`;
  /// [seed] picks one of the flicker poses.
  static Path _plume(int seed, double width, int licks, double ragged) {
    double edge(double s) => width * math.pow(1 - s, .82);
    List<Offset> flank(double side, int salt) {
      final pts = <Offset>[Offset(.06, side * width)];
      for (var j = 0; j < licks; j++) {
        final at =
            (j + .3 + .4 * DragonKit.hash(j, seed * 7 + salt)) / (licks + .6);
        final reach =
            (.2 + .16 * DragonKit.hash(j, seed * 11 + salt + 3)) *
            (1 - at * .45);
        final rise = ragged * (.5 + .5 * DragonKit.hash(j, seed * 13 + salt));
        // The notch behind the last tongue, then this tongue's tip.
        pts.add(Offset(-at, side * edge(at) * .84));
        pts.add(Offset(-(at + reach), side * (edge(at + reach * .5) + rise)));
      }
      return pts;
    }

    final top = flank(-1, 1), bottom = flank(1, 5);
    final pts = <Offset>[...top, const Offset(-1, 0), ...bottom.reversed];
    // The tongues' tips (and the plume's own) stay sharp; the notches between
    // them are smooth.
    final sharp = <int>{
      for (var i = 2; i < top.length; i += 2) i,
      top.length,
      for (var i = 2; i < bottom.length; i += 2)
        top.length + 1 + (bottom.length - 1 - i),
    };
    return DragonKit.spline(pts, sharp: sharp, tension: .9);
  }

  /// The four layers' half-widths, tongues per flank and ragged rise.
  static const _plumeSpec = [
    (.95, 3, .34),
    (.76, 3, .26),
    (.52, 2, .2),
    (.3, 1, .12),
  ];

  /// How far each layer streams, as a share of the tail.
  static const _plumeReach = [1.0, .84, .62, .42];

  static const _poses = 6;
  static final List<List<Path>> _plumes = [
    for (final (width, licks, ragged) in _plumeSpec)
      [for (var v = 0; v < _poses; v++) _plume(v, width, licks, ragged)],
  ];

  /// The three curled tongues that roll inside the ball.
  static final Path _swirl = () {
    final p = Path();
    for (var i = 0; i < 3; i++) {
      final a = i * math.pi * 2 / 3;
      final from = DragonKit.heading(a) * .2;
      final mid = DragonKit.heading(a + .9) * .55;
      final to = DragonKit.heading(a + 1.7) * .74;
      p
        ..moveTo(from.dx, from.dy)
        ..quadraticBezierTo(mid.dx * 1.3, mid.dy * 1.3, to.dx, to.dy);
    }
    return p;
  }();

  /// A comet-shaped streak or fan ray, blunt head at 0 and tail at -1.
  static final Path _streak = Path()
    ..moveTo(0, -1)
    ..cubicTo(.55, -1, .55, 1, 0, 1)
    ..cubicTo(-.4, .7, -.75, .25, -1, 0)
    ..cubicTo(-.75, -.25, -.4, -.7, 0, -1)
    ..close();

  /// A charge streak, bright at the head that leads it into the orb.
  static final _streakShader = ui.Gradient.linear(
    Offset.zero,
    const Offset(-1, 0),
    [
      DragonPalette.flameCore,
      DragonPalette.flameGold,
      DragonPalette.flame.withValues(alpha: 0),
    ],
    const [0, .4, 1],
  );
  static final _streakFuryShader = ui.Gradient.linear(
    Offset.zero,
    const Offset(-1, 0),
    [
      DragonPalette.white,
      DragonPalette.flameYellow,
      DragonPalette.flame.withValues(alpha: 0),
    ],
    const [0, .4, 1],
  );

  /// The muzzle star: six spikes, long and short in turn, from a hollow
  /// centre (the shot leaves through it) out to unit radius.
  static final Path _star = () {
    final p = Path();
    for (var i = 0; i < 6; i++) {
      final a = i * math.pi / 3 + math.pi / 6;
      final tip = i.isEven ? 1.0 : .66;
      p
        ..moveTo(math.cos(a - .24) * .4, math.sin(a - .24) * .4)
        ..lineTo(math.cos(a) * tip, math.sin(a) * tip)
        ..lineTo(math.cos(a + .24) * .4, math.sin(a + .24) * .4)
        ..close();
    }
    return p;
  }();

  /// Smoke: a soft dark-violet puff, solid in the middle.
  static final _smokeShader = _radial(
    [
      DragonPalette.ash.withValues(alpha: .7),
      DragonPalette.ash.withValues(alpha: .35),
      DragonPalette.ash.withValues(alpha: 0),
    ],
    const [.1, .55, 1],
  );

  /// The muzzle flare: a ring of white-hot light with a clear middle.
  static final _flareShader = _radial(
    const [
      Color(0x00ffffff),
      Color(0x00ffffff),
      DragonPalette.white,
      Color(0xccfff6d2),
      Color(0x00ffe066),
    ],
    const [0, .34, .46, .62, 1],
  );

  /// A fan ray: a kite from its tail at 0 to its point at 1, white-hot
  /// toward the ember it leads.
  static final Path _ray = Path()
    ..moveTo(0, 0)
    ..lineTo(.34, -1)
    ..lineTo(1, 0)
    ..lineTo(.34, 1)
    ..close();
  static final _rayShader = ui.Gradient.linear(
    Offset.zero,
    const Offset(1, 0),
    [
      DragonPalette.flame.withValues(alpha: 0),
      DragonPalette.flame,
      DragonPalette.flameYellow,
      DragonPalette.white,
    ],
    const [0, .3, .72, 1],
  );

  /// One layer of the comet tail: hot where it leaves the ball and cooling
  /// to nothing at the tip, so the tail dissolves instead of ending.
  static ui.Shader _layerShader(Color hot, Color cool) => ui.Gradient.linear(
    Offset.zero,
    const Offset(-1, 0),
    [hot, cool.withValues(alpha: .85), cool.withValues(alpha: 0)],
    const [.12, .5, 1],
  );

  static final _layerShaders = [
    // Plain: oxblood rim, orange, gold, cream-hot core.
    _layerShader(DragonPalette.flameDark, DragonPalette.flameDark),
    _layerShader(DragonPalette.flame, DragonPalette.flame),
    _layerShader(DragonPalette.flameGold, DragonPalette.flameGold),
    _layerShader(DragonPalette.flameCore, DragonPalette.flameYellow),
  ];
  static final _layerShadersFury = [
    _layerShader(_furyRim, _furyRim),
    _layerShader(DragonPalette.flame, DragonPalette.flame),
    _layerShader(DragonPalette.flameYellow, DragonPalette.flameGold),
    _layerShader(DragonPalette.white, DragonPalette.flameCore),
  ];

  /// The alpha each of three identical layers needs so that together they
  /// composite to [total]: the embers each lay a third of the shared flash.
  static double _third(double total) =>
      1 - math.pow(1 - total.clamp(0.0, 1.0), 1 / 3).toDouble();

  static Paint _shaded(
    ui.Shader shader, [
    double alpha = 1,
    BlendMode blend = BlendMode.srcOver,
  ]) => Paint()
    ..shader = shader
    ..blendMode = blend
    ..color = Color.fromRGBO(255, 255, 255, alpha.clamp(0.0, 1.0));

  /// A radial [shader] (built on the unit circle) filling a disc of [radius]
  /// at [at], [alpha] deep. Light is added with [BlendMode.screen], so a glow
  /// brightens a pale sky instead of muddying it.
  static void _disc(
    Canvas c,
    Offset at,
    double radius,
    ui.Shader shader,
    double alpha, {
    BlendMode blend = BlendMode.srcOver,
  }) {
    if (alpha <= 0 || radius <= 0) return;
    c.save();
    c.translate(at.dx, at.dy);
    c.scale(radius);
    c.drawCircle(Offset.zero, 1, _shaded(shader, alpha, blend));
    c.restore();
  }

  static final _bodyPaint = Paint()..shader = _bodyShader;
  static final _bodyFuryPaint = Paint()..shader = _bodyFuryShader;

  // ------------------------------------------------------------- hooks --

  /// The fireball forming in the jaws at [mouth] (pixels), [charge] 0 to 1
  /// over the 0.65 s before launch; [h] is the screen height in pixels.
  ///
  /// HOOK owned by the fireball builder (B6): `BossEncounterArt` calls this
  /// instead of drawing the orb inline. A hot heart swells with the charge
  /// while six spark streaks spiral in from a funnel 4.6 shot-radii out and
  /// are eaten by it; from charge .85 (the last tenth of a second) the orb
  /// holds perfectly still, white-hot, ringed by a corona. The solid orb
  /// never exceeds the shot's own radius (it is exactly the launched ball's
  /// size at full charge) and the corona stays inside 1.5x, so it ends as
  /// the ball on the mouth anchor and never hides the bird.
  ///
  /// The streaks follow [charge] alone (a state channel), so Reduced Motion
  /// shows the same gathering as a still frame; only the flicker uses
  /// [seconds].
  static void charge(
    Canvas c, {
    required Offset mouth,
    required double h,
    required double charge,
    required double seconds,
    required bool reducedMotion,
    required bool fury,
  }) {
    if (!(charge > 0) ||
        !h.isFinite ||
        h <= 0 ||
        !mouth.dx.isFinite ||
        !mouth.dy.isFinite) {
      return;
    }
    final k = charge.clamp(0.0, 1.0);
    // The last tenth of a second holds still: the hold is what makes the
    // launch read as a release.
    final hold = BossMotion.ramp(k, .82, .86);
    final live = !reducedMotion && seconds.isFinite && hold < 1;
    final shot = h * BossAmmo.fireballRadius;
    final grow = 1 - math.pow(1 - math.min(k / .9, 1.0), 3);
    final flicker = live ? math.sin(seconds * 46) * .035 : 0.0;
    final rr = (.3 + .7 * grow) * (1 + flicker);
    c.save();
    c.translate(mouth.dx, mouth.dy);
    c.scale(shot);
    // The heat gathering round the jaws.
    _disc(
      c,
      Offset.zero,
      (fury ? 3.0 : 2.6) * rr,
      fury ? _haloFuryShader : _haloShader,
      (.35 + .65 * k) * (fury ? 1 : .9),
      blend: BlendMode.screen,
    );
    _streaks(c, k, rr, fury);
    c.scale(rr);
    _ball(
      c,
      live ? seconds * .8 : 0.0,
      math.max(.13, 1.8 / (shot * rr)),
      fury,
      shot * rr >= 14,
      null,
    );
    if (hold > 0) {
      // White-hot and ready: a bright heart and a corona inside 1.5x.
      c.drawCircle(
        const Offset(.1, -.05),
        .5,
        DragonKit.fill(DragonPalette.white, .8 * hold),
      );
      c.drawCircle(
        Offset.zero,
        1.42 / rr,
        DragonKit.line(
          fury ? DragonPalette.white : DragonPalette.flameCore,
          .1 / rr,
          .6 * hold,
        ),
      );
    }
    c.restore();
  }

  /// Six streaks spiral into the orb; each is born faint on the 4.6-radius
  /// funnel, brightens as it closes and dies inside the orb. Units are the
  /// shot's radius.
  static void _streaks(Canvas c, double k, double rr, bool fury) {
    // A still frame's phase: the charge itself, frozen at the hold.
    final drive = math.min(k, .84);
    final gain = BossMotion.ramp(k, 0, .12);
    final shader = fury ? _streakFuryShader : _streakShader;
    for (var i = 0; i < 6; i++) {
      final p = (drive * 2.6 + i / 6) % 1;
      final reach = 4.6 - (4.6 - rr * 1.05) * p * p;
      // A funnel opening in front of the jaws, never over the face.
      final twist = math.pi + (i / 5 - .5) * 2.3 + (1 - p) * .4;
      final dir = DragonKit.heading(twist);
      final alpha = math.sin(math.pi * math.pow(p, .6)) * gain;
      if (alpha <= .02) continue;
      c.save();
      c.translate(dir.dx * reach, dir.dy * reach);
      // The streak points the way it is going: in at the orb, bent a little
      // by the spiral.
      c.rotate(twist + math.pi + .3);
      c.scale(1.2 + 1.6 * (1 - p) + .4 * k, .26 + .14 * p);
      // A wide dim underlay, so the streak holds on a pale sky, then its core.
      c.save();
      c.scale(1.05, 1.9);
      c.drawPath(
        _streak,
        DragonKit.fill(DragonPalette.flame, math.min(1.0, alpha) * .32),
      );
      c.restore();
      c.drawPath(_streak, _shaded(shader, math.min(1.0, alpha * 1.25)));
      c.restore();
    }
  }

  /// The burst as a fireball leaves the jaws at [mouth] (pixels), [tau]
  /// seconds after launch (0 to about .35); [direction] is where the shot
  /// flies (radians; the jaws face left).
  ///
  /// [mouth] is where the shot was BORN: pass the rules' mouth point
  /// (`Offset(boss.mouthX * h, boss.mouthY * h)`, where the ball is at
  /// tau = 0), not the jaws' anchor, which recoils the instant the shot
  /// leaves and would leave the burst behind the ball.
  ///
  /// HOOK owned by the fireball builder (B6): a hot flare and a six-point
  /// white star (2.4 shot-radii, gone in .09 s), the gold ring (as before),
  /// a fast inner ring, a few sparks thrown wide of the shot's line and one
  /// puff of smoke rising off the snout. The rules launch the ball at tau = 0;
  /// the star is spikes only, so nothing here hides it or the bird. Under
  /// Reduced Motion the flare and ring are held where they would be a tenth
  /// of a second in and fade in place.
  static void muzzle(
    Canvas c, {
    required Offset mouth,
    required double h,
    required double tau,
    required bool reducedMotion,
    required bool fury,
    double direction = math.pi,
  }) {
    if (!tau.isFinite ||
        !h.isFinite ||
        h <= 0 ||
        !mouth.dx.isFinite ||
        !mouth.dy.isFinite) {
      return;
    }
    final shot = BossMotion.ramp(tau, 0, .3);
    if (tau < 0 || shot >= 1) return;
    final r = h * BossAmmo.fireballRadius;
    c.save();
    c.translate(mouth.dx, mouth.dy);
    // The hot flare and star: the instant of launch.
    final blast = 1 - BossMotion.ramp(tau, 0, .09);
    if (blast > 0 && !reducedMotion) {
      final grow = .55 + .45 * BossMotion.ramp(tau, 0, .03);
      c.save();
      c.scale(r * 2.8 * grow);
      c.drawCircle(
        Offset.zero,
        1,
        _shaded(_flareShader, blast, BlendMode.screen),
      );
      c.rotate(direction);
      c.drawPath(
        _star,
        DragonKit.fill(
          fury ? DragonPalette.white : DragonPalette.flameCore,
          blast,
        ),
      );
      c.restore();
    } else if (reducedMotion) {
      _disc(
        c,
        Offset.zero,
        r * 2.4,
        _flareShader,
        (1 - BossMotion.ramp(tau, 0, .3)) * .9,
        blend: BlendMode.screen,
      );
    }
    // The ring of heat the jaws breathe out, as it always was, over a darker
    // one so it holds on a pale sky.
    final ring = reducedMotion ? BossMotion.ramp(tau, 0, .3) * .35 + .2 : shot;
    final ringR = h * (.022 + ring * .075);
    c.drawCircle(
      Offset.zero,
      ringR,
      DragonKit.line(
        DragonPalette.flameDark,
        h * .0095 * (1 - shot),
        (1 - shot) * .55,
      ),
    );
    c.drawCircle(
      Offset.zero,
      ringR,
      DragonKit.line(
        fury ? DragonPalette.flameYellow : DragonPalette.flameGold,
        h * .0055 * (1 - shot),
        1 - shot,
      ),
    );
    if (!reducedMotion) {
      final inner = BossMotion.ramp(tau, 0, .18);
      if (inner < 1) {
        c.drawCircle(
          Offset.zero,
          h * (.012 + inner * .05),
          DragonKit.line(
            DragonPalette.white,
            h * .0035 * (1 - inner),
            1 - inner,
          ),
        );
      }
      // Sparks thrown wide of the shot's line, never along it.
      final glow = 1 - BossMotion.ramp(tau, .04, .22);
      for (var i = 0; glow > 0 && i < (fury ? 6 : 4); i++) {
        final side = i.isEven ? 1.0 : -1.0;
        final d = DragonKit.heading(
          direction + side * (.75 + .3 * (i ~/ 2) + .08 * (i % 3)),
        );
        final travel = h * (.05 + .014 * (i % 3)) * (.35 + tau * 3.2);
        c.drawLine(
          d * travel,
          d * (travel + h * .015 * glow),
          DragonKit.line(
            i % 3 == 0 ? DragonPalette.flameCore : DragonPalette.flameGold,
            h * .0038,
            glow,
          ),
        );
      }
      // One puff of smoke rising off the snout, drifting on along the shot.
      final rise = BossMotion.ramp(tau, 0, .34);
      final puff = math.sin(math.pi * math.pow(rise, .6));
      if (puff > 0) {
        final at =
            DragonKit.heading(direction) * (h * (.02 + .045 * rise)) +
            Offset(0, -h * (.022 + .05 * rise));
        final pr = h * (.02 + .034 * rise);
        _disc(c, at, pr, _smokeShader, puff * .85);
        _disc(
          c,
          at + Offset(pr * .55, -pr * .45),
          pr * .6,
          _smokeShader,
          puff * .6,
        );
      }
    }
    c.restore();
  }

  /// How long ago (seconds) [ammo], an ember, was born in a split: the rules
  /// keep no age for embers, but the split is the single fireball of the
  /// dragon's last volley bursting [SkyBoss.emberSplitAfter] after it left the
  /// jaws. Null when [ammo] is no fresh ember, or the last volley was a
  /// pair (nothing of that volley splits) and the ember is an old one.
  static double? sinceSplit(BossAmmo ammo, SkyBoss boss) {
    if (!ammo.ember || boss.volleys.isEven) return null;
    final since = boss.age - boss.lastVolleyAt - SkyBoss.emberSplitAfter;
    return since >= 0 && since < burstSeconds ? since : null;
  }

  /// One in-flight shot at its simulated position. A fresh ember also draws
  /// its share of the split's burst ([sinceSplit] when the caller knows it,
  /// else worked out from [boss]).
  static void shot(
    Canvas c,
    double height,
    BossAmmo ammo,
    SkyBoss boss, {
    required double seconds,
    required bool reducedMotion,
    double? sinceSplit,
  }) {
    final after = ammo.splitAfter;
    final speed = math.sqrt(ammo.vx * ammo.vx + ammo.vy * ammo.vy) * height;
    paint(
      c,
      center: Offset(ammo.x * height, ammo.y * height),
      radius: ammo.radius * height,
      direction: math.atan2(ammo.vy, ammo.vx),
      seconds: seconds,
      reducedMotion: reducedMotion,
      fury: boss.enraged,
      ember: ammo.ember,
      split: after == null ? null : (ammo.age / after).clamp(0.0, 1.0),
      sinceSplit: ammo.ember
          ? (sinceSplit ?? DragonFireballArt.sinceSplit(ammo, boss))
          : null,
      speed: speed,
    );
  }

  /// Draws a shot centred on its hit circle of [radius] pixels, heading
  /// [direction]. [split] is how near a splitting fireball is to bursting
  /// (0 to 1), or null for one that never splits. [showTrail] false draws
  /// just the ball, as it forms in the jaws. [sinceSplit] is the age of an
  /// ember in seconds (the burst's flash, ring and fan ray belong to the
  /// first [burstSeconds]) and [speed] its speed in pixels per second, which
  /// places the split behind it.
  static void paint(
    Canvas c, {
    required Offset center,
    required double radius,
    required double direction,
    required double seconds,
    required bool reducedMotion,
    bool fury = false,
    bool ember = false,
    double? split,
    bool showTrail = true,
    double? sinceSplit,
    double speed = 0,
  }) {
    if (!radius.isFinite || radius <= 0 || !direction.isFinite) return;
    final time = reducedMotion || !seconds.isFinite
        ? 0.0
        : seconds + direction * .41;
    c.save();
    c.translate(center.dx, center.dy);
    c.rotate(direction);
    if (math.cos(direction) < 0) c.scale(1, -1);
    c.scale(radius);
    unit(
      c,
      time: time,
      edge: math.max(.13, 1.8 / radius),
      fine: radius >= 14,
      fury: fury,
      ember: ember,
      split: split,
      trail: showTrail,
      born: sinceSplit,
      back: speed.isFinite ? speed * (sinceSplit ?? 0) / radius : 0,
    );
    c.restore();
  }

  /// The shot in its own unit space (radius 1, heading +x), for callers that
  /// have already placed it. [edge] is the ink rim's width in those units;
  /// [time] 0 is the still pose. An ember [born] this many seconds ago also
  /// draws the split that made it, [back] radii behind it.
  static void unit(
    Canvas c, {
    required double time,
    required double edge,
    required bool fine,
    bool fury = false,
    bool ember = false,
    double? split,
    bool trail = true,
    double? born,
    double back = 0,
  }) {
    if (ember) {
      _ember(c, time, edge, trail, fury, born, back);
      return;
    }
    _disc(
      c,
      Offset.zero,
      fury ? 3.0 : 2.6,
      fury ? _haloFuryShader : _haloShader,
      1,
      blend: BlendMode.screen,
    );
    if (trail) _wake(c, time, fury);
    _ball(c, time, edge, fury, fine, split);
  }

  // -------------------------------------------------------------- tail --

  /// The comet: four layers of flame (oxblood, orange, gold, cream-hot)
  /// streaming from the ball's back, each flickering through its own poses,
  /// and sparks shaken loose.
  static void _wake(Canvas c, double time, bool fury) {
    final len = fury ? 5.6 : 4.8;
    final shaders = fury ? _layerShadersFury : _layerShaders;
    for (var layer = 0; layer < _plumes.length; layer++) {
      // Each layer changes pose on its own beat, so the flame never moves
      // as one.
      final step = (time * (8.5 + layer * .8) + layer * .37).floor();
      final pose = time == 0
          ? layer * 2 % _poses
          : (DragonKit.hash(step, layer) * _poses).floor() % _poses;
      final flick = math.sin(time * 13 + layer * 1.7);
      c.save();
      c.translate(-.06, 0);
      c.rotate(flick * .02);
      c.scale(len * _plumeReach[layer] * (.95 + .05 * flick), 1);
      c.drawPath(_plumes[layer][pose], Paint()..shader = shaders[layer]);
      c.restore();
    }
    final count = fury ? 7 : 5;
    for (var i = 0; i < count; i++) {
      final life = (time * 1.7 + i / count) % 1;
      final side = i.isEven ? -1.0 : 1.0;
      c.drawCircle(
        Offset(
          -1.5 - life * (len - 1.2),
          side * (.55 + life * 1.0 + (i % 3) * .12),
        ),
        .24 * (1 - life * .5),
        DragonKit.fill(
          Color.lerp(DragonPalette.flameYellow, DragonPalette.flame, life)!,
          math.min(1.0, 1.7 * math.sin(life * math.pi)),
        ),
      );
    }
  }

  // -------------------------------------------------------------- ball --

  static void _ball(
    Canvas c,
    double time,
    double edge,
    bool fury,
    bool fine,
    double? split,
  ) {
    final body = 1 - edge / 2;
    c.drawCircle(Offset.zero, body, fury ? _bodyFuryPaint : _bodyPaint);
    if (split != null) {
      c.drawCircle(
        Offset.zero,
        body,
        _shaded(_crustShader, BossMotion.ramp(split, .1, .95)),
      );
    }
    // Rolling fire: curled tongues turning inside the ball.
    c.save();
    c.rotate(-time * (fury ? 7 : 5));
    c.drawPath(
      _swirl,
      DragonKit.line(
        fury ? DragonPalette.flameCore : DragonPalette.flameYellow,
        fine ? .14 : .2,
        split == null ? .55 : .55 * (1 - BossMotion.ramp(split, .3, .9)),
      ),
    );
    c.restore();
    if (split != null) _seeds(c, time, split, body);
    c.drawCircle(Offset.zero, body, DragonKit.line(_ink, edge));
    _glint(c, dot: true);
  }

  /// The same hard white pill glint the other bosses' shots carry, on the
  /// leading brow, sky-lit from above: a crisp specular, not a smear.
  static void _glint(Canvas c, {bool dot = false}) {
    c.save();
    c.translate(.26, -.55);
    c.rotate(.42);
    c.scale(.36, .36);
    c.drawPath(_pill, DragonKit.fill(DragonPalette.white, .96));
    c.restore();
    if (dot) {
      c.drawCircle(
        const Offset(-.12, -.7),
        .075,
        DragonKit.fill(DragonPalette.white, .9),
      );
    }
  }

  /// A pill, unit half-length.
  static final Path _pill = Path()
    ..addRRect(RRect.fromLTRBR(-1, -.42, 1, .42, const Radius.circular(.42)));

  /// The split's warning: three embers glow and swell inside, circling, a
  /// ring of heat closes in as the burst nears and, over the last tenth of
  /// the fireball's life, the whole ball shudders: the seeds jitter and a
  /// corona of heat pulses just outside the hit circle (the solid body stays
  /// exactly on it).
  static void _seeds(Canvas c, double time, double split, double body) {
    final live = time != 0;
    final shudder = BossMotion.ramp(split, .78, 1);
    final swell = .1 + split * .12 + shudder * .05;
    final jitter = live ? shudder * .05 : 0.0;
    final at = [
      for (var i = 0; i < 3; i++)
        DragonKit.heading(time * 9 + i * math.pi * 2 / 3) * (body * .48) +
            Offset(
              math.sin(time * 127 + i * 2.1) * jitter,
              math.cos(time * 113 + i * 1.3) * jitter,
            ),
    ];
    // All three seeds in three strokes: a dark rim, the glow, the white core.
    for (final (radius, color, alpha) in [
      (swell * 1.8, DragonPalette.flameDark, .7),
      (swell * 1.25, DragonPalette.flameYellow, 1.0),
      (swell * .6, DragonPalette.white, 1.0),
    ]) {
      c.drawPoints(
        ui.PointMode.points,
        at,
        DragonKit.line(color, radius * 2, alpha),
      );
    }
    final ring = 2.3 - split * 1.05;
    c.drawCircle(
      Offset.zero,
      ring,
      DragonKit.line(
        DragonPalette.flameGold,
        .22 + split * .1,
        .3 + split * .5,
      ),
    );
    c.drawCircle(
      Offset.zero,
      ring,
      DragonKit.line(
        DragonPalette.flameCore,
        .08 + split * .06,
        .4 + split * .6,
      ),
    );
    if (shudder > 0) {
      final beat = live ? .5 + .5 * math.sin(time * 2 * math.pi * 20) : .5;
      c.drawCircle(
        Offset.zero,
        1.1 + .2 * beat * shudder,
        DragonKit.line(DragonPalette.flameCore, .12, .65 * shudder),
      );
    }
  }

  // ------------------------------------------------------------- ember --

  /// An ember: a small fireball of the same make (hit circle, ink, hot heart)
  /// with a short two-layer tail and no wide halo, so three of them read as
  /// the fireball's children.
  static void _ember(
    Canvas c,
    double time,
    double edge,
    bool trail,
    bool fury,
    double? born,
    double back,
  ) {
    final age = born ?? 1;
    final glow = 1 + .3 * (1 - BossMotion.ramp(age, 0, .2));
    _disc(
      c,
      Offset.zero,
      2.5 * glow,
      _emberGlowShader,
      .95,
      blend: BlendMode.screen,
    );
    if (born != null) _burst(c, born, back, fury);
    if (trail) {
      final shaders = fury ? _layerShadersFury : _layerShaders;
      final flick = math.sin(time * 20);
      final step = time == 0 ? 1 : (time * 12).floor().abs();
      for (final (layer, length, width) in const [
        (1, 3.6, .8),
        (3, 2.3, .55),
      ]) {
        c.save();
        c.translate(-.1, 0);
        c.scale(length * (.95 + .05 * flick), width);
        c.drawPath(
          _plumes[layer][(step + layer * 2) % _poses],
          Paint()..shader = shaders[layer],
        );
        c.restore();
      }
    }
    // Born a little smaller so three of them stay three for the first tenth
    // of a second (the glow carries the heat, and they are far from the bird
    // for as long); the ink still closes on the hit circle from then on.
    final body = (1 - edge / 2) * (.58 + .42 * BossMotion.ramp(age, .05, .2));
    c.save();
    c.scale(body);
    c.drawCircle(Offset.zero, 1, fury ? _bodyFuryPaint : _bodyPaint);
    c.drawCircle(Offset.zero, 1, DragonKit.line(_ink, edge / body));
    _glint(c);
    c.restore();
  }

  /// This ember's share of the split it was born in, in the ember's own
  /// unit space with the split [back] radii behind it: a flash and a ring
  /// (each of the three lays a third, so together they are one), a fan ray
  /// along its heading and three sparks thrown off it. The pieces are all
  /// gone by [burstSeconds]; the flash and ring are what Reduced Motion
  /// keeps.
  static void _burst(Canvas c, double age, double back, bool fury) {
    final at = Offset(-back, 0);
    // The split ball was 1.5625 embers across; the flash is 2.2 of those.
    final flash = math.pow(1 - BossMotion.ramp(age, 0, .12), 2).toDouble();
    if (flash > 0) {
      _disc(
        c,
        at,
        3.44 * (1.1 - .3 * flash),
        _flashShader,
        _third(.95 * flash),
        blend: BlendMode.screen,
      );
    }
    // A starburst behind the ember: 18 spikes from the three embers' six.
    final star = 1 - BossMotion.ramp(age, 0, .1);
    if (star > 0) {
      c.save();
      c.translate(at.dx, at.dy);
      c.scale(4.6 * (.6 + .4 * (1 - star)));
      c.drawPath(
        _star,
        DragonKit.fill(
          fury ? DragonPalette.white : DragonPalette.flameCore,
          _third(star),
        ),
      );
      c.restore();
    }
    final ring = BossMotion.ramp(age, 0, .2);
    if (ring < 1) {
      final open = 1 - math.pow(1 - ring, 2);
      c.drawCircle(
        at,
        1 + 3.7 * open,
        DragonKit.line(
          fury ? DragonPalette.white : DragonPalette.flameCore,
          .26 * (1 - ring) + .06,
          _third(.9 * (1 - ring)),
        ),
      );
    }
    final ray = 1 - BossMotion.ramp(age, .06, .18);
    if (ray > 0) {
      c.save();
      c.translate(at.dx, at.dy);
      c.scale(back + 3.6, .36);
      c.drawPath(_ray, _shaded(_rayShader, math.sqrt(ray)));
      c.restore();
    }
    final spark = 1 - BossMotion.ramp(age, 0, .3);
    for (var i = 0; spark > 0 && i < 3; i++) {
      final d = DragonKit.heading((i - 1) * .95 + .25 * i);
      final travel = (10 + 9 * i) * age + 1.2;
      c.drawCircle(
        at + d * travel,
        .32 * spark + .05,
        DragonKit.fill(
          i == 1 ? DragonPalette.white : DragonPalette.flameYellow,
          spark,
        ),
      );
    }
  }
}
