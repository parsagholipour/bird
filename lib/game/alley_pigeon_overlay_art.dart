import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../domain/game_rules.dart';
import 'star_art.dart';

/// The Alley Pigeon's marks on the world (not on the bird): the gold ring on
/// the star it is about to take and the dashed line of its swoop (the
/// telegraph the player reads), the ring that flashes where a star was
/// snatched, and the halo of a star a rock just freed.
///
/// Everything is a pure function of the simulation clock and the raid state,
/// so a replay or a seek repeats the picture. Each mark is a handful of
/// canvas ops with cached paints: no layers, clips or shaders.
abstract final class AlleyPigeonOverlayArt {
  /// How long a freed star's halo lasts.
  static const haloSeconds = .6;

  /// How long the snatch's expanding ring lasts (the beak kick's length).
  static const snatchSeconds = .28;

  static const _gold = Color(0xffffd45b), _cream = Color(0xfffffbdc);
  static const _ink = Color(0xff18182f);

  static final _ringInk = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  static final _ringGold = Paint()..style = PaintingStyle.stroke;
  static final _dotInk = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  static final _dotCream = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  static final _spark = Paint()..color = _cream;
  static final _sparkInk = Paint()..color = _ink;

  /// A four-point twinkle, unit size.
  static final Path _twinkle = Path()
    ..moveTo(0, -1)
    ..quadraticBezierTo(.16, -.16, 1, 0)
    ..quadraticBezierTo(.16, .16, 0, 1)
    ..quadraticBezierTo(-.16, .16, -1, 0)
    ..quadraticBezierTo(-.16, -.16, 0, -1)
    ..close();

  /// The marks under the pigeons: for every pigeon that is telegraphing or
  /// diving, the ring on its prey and the swoop line; and the snatch's ring
  /// for a thief that has just taken its star. Call after the stars and
  /// before the enemies.
  static void paint(
    Canvas canvas,
    double height,
    FlightSimulation sim, {
    required bool reducedMotion,
  }) {
    if (!sim.supportsAlleyPigeon) return;
    // Nothing trustworthy to draw at no height or on a stopped clock: the
    // marks are decoration, so they skip rather than throw (an infinite
    // value reaches `toInt` and `Offset` assertions below).
    if (!(height.isFinite && height > 0) || !sim.elapsed.isFinite) return;
    final clock = sim.elapsed;
    for (final enemy in sim.enemies) {
      final raid = enemy.pigeon;
      if (raid == null) continue;
      if (!(enemy.age.isFinite &&
          enemy.x.isFinite &&
          enemy.y.isFinite &&
          raid.phaseAt.isFinite)) {
        continue;
      }
      switch (raid.phase) {
        case PigeonPhase.warning:
        case PigeonPhase.dive:
          final prey = raid.prey;
          if (prey == null || prey.collected || prey.missed) continue;
          if (!(prey.x.isFinite && prey.y.isFinite)) continue;
          _swoopLine(canvas, height, enemy, raid, prey, clock, reducedMotion);
          _preyRing(canvas, height, prey, raid, enemy, clock, reducedMotion);
        case PigeonPhase.carry:
          if (!(enemy.x.isFinite && enemy.y.isFinite)) continue;
          _snatchRing(canvas, height, enemy, raid, reducedMotion);
        case PigeonPhase.glide:
        case PigeonPhase.flee:
          break;
      }
    }
  }

  /// The gold ring on the star about to be taken. It closes in as the
  /// warning runs out and pulses; Reduced Motion holds it still.
  static void _preyRing(
    Canvas canvas,
    double h,
    SkyStar prey,
    PigeonFlight raid,
    SkyEnemy enemy,
    double clock,
    bool reducedMotion,
  ) {
    final w = raid.warning(enemy.age);
    final diving = raid.phase == PigeonPhase.dive;
    final base = StarArt.radius * h * 1.55;
    // The ring tightens over the warning and holds while the pigeon dives.
    final close = diving ? 1.0 : 1 - (1 - w) * (1 - w);
    var r = base * (1.55 - .55 * close);
    var alpha = .92;
    if (!reducedMotion) {
      final pulse = math.sin(clock * 13) * .5 + .5;
      r *= 1 + .06 * pulse;
      alpha = .74 + .22 * pulse;
    }
    final c = Offset(prey.x * h, prey.y * h);
    final width = math.max(1.6, h * .0065);
    canvas.drawCircle(
      c,
      r,
      _ringInk
        ..color = _ink.withValues(alpha: .55)
        ..strokeWidth = width + 2.2,
    );
    canvas.drawCircle(
      c,
      r,
      _ringGold
        ..color = _gold.withValues(alpha: alpha)
        ..strokeWidth = width,
    );
  }

  /// The number of dashes on a fresh swoop line.
  static const dots = 8;

  /// The point of the swoop at ellipse angle [theta] (0 at the hover, a
  /// quarter turn at the star), in screen heights: the very path
  /// [AlleyPigeon.dive] flies, since its `u` maps to `theta = pi / 2 * u^1.7`.
  static Offset _swoopAt(PigeonFlight raid, SkyStar prey, double theta) {
    final home = AlleyPigeon.hover(
      slot: raid.slot,
      preyX: prey.x,
      lane: prey.y,
      side: raid.side,
    );
    final u = math.pow(theta.clamp(0.0, math.pi / 2) / (math.pi / 2), 1 / 1.7);
    final p = AlleyPigeon.dive(u.toDouble(), home, (x: prey.x, y: prey.y));
    return Offset(p.x, p.y);
  }

  /// The angles (on the swoop ellipse) of the dashes still ahead of the
  /// pigeon: equal steps of the ellipse's angle, the ones it has passed gone.
  static List<double> _swoopAngles(PigeonFlight raid, double age) {
    final passed = raid.phase == PigeonPhase.dive
        ? math.pi / 2 * math.pow(raid.dive(age), 1.7)
        : 0.0;
    return [
      for (var k = 1; k <= dots; k++)
        if (math.pi / 2 * k / (dots + .6) > passed)
          math.pi / 2 * k / (dots + .6),
    ];
  }

  /// Where the dashes of the swoop line are centred, in screen heights: along
  /// the path the pigeon will really fly (the quarter ellipse of
  /// [AlleyPigeon.dive] from its hover to the star).
  static List<Offset> swoopDots(
    PigeonFlight raid,
    SkyStar prey, {
    required double age,
  }) => !(age.isFinite && prey.x.isFinite && prey.y.isFinite)
      ? const []
      : [
          for (final theta in _swoopAngles(raid, age))
            _swoopAt(raid, prey, theta),
        ];

  /// The dashed line of the swoop: a marching ripple toward the star, steady
  /// in Reduced Motion. Each dash lies along the path.
  static void _swoopLine(
    Canvas canvas,
    double h,
    SkyEnemy enemy,
    PigeonFlight raid,
    SkyStar prey,
    double clock,
    bool reducedMotion,
  ) {
    final angles = _swoopAngles(raid, enemy.age);
    if (angles.isEmpty) return;
    const half = math.pi / 2 / (dots + .6) * .30;
    final tiers = [<Offset>[], <Offset>[], <Offset>[]];
    final all = <Offset>[];
    for (var i = 0; i < angles.length; i++) {
      final a = _swoopAt(raid, prey, angles[i] - half) * h;
      final b = _swoopAt(raid, prey, angles[i] + half) * h;
      all
        ..add(a)
        ..add(b);
      final k = dots - angles.length + i + 1;
      final tier = reducedMotion ? 0 : ((clock * 7 - k).floor() % 3 + 3) % 3;
      tiers[tier]
        ..add(a)
        ..add(b);
    }
    final dash = math.max(3.6, h * .0115);
    _dotInk
      ..color = _ink.withValues(alpha: .5)
      ..strokeWidth = dash + 1.6;
    canvas.drawPoints(ui.PointMode.lines, all, _dotInk);
    if (reducedMotion) {
      _dotCream
        ..color = _cream.withValues(alpha: .92)
        ..strokeWidth = dash;
      canvas.drawPoints(ui.PointMode.lines, all, _dotCream);
      return;
    }
    // The bright tier runs along the line; the others glow softly.
    const alphas = [1.0, .72, .46];
    for (var i = 0; i < 3; i++) {
      if (tiers[i].isEmpty) continue;
      _dotCream
        ..color = _cream.withValues(alpha: alphas[i])
        ..strokeWidth = dash * (i == 0 ? 1.0 : .88);
      canvas.drawPoints(ui.PointMode.lines, tiers[i], _dotCream);
    }
  }

  /// The ring that flashes where the star was snatched, over the beak's kick:
  /// gold with an ink edge (like the ring that marked the prey) and six
  /// sparks, so it reads against steam, rain and a bright sky, and still
  /// reads when a steam burst lands on the same instant. The thief leaves
  /// that spot at the climb's own pace ([AlleyPigeon.flee]), so the spot is
  /// where the pigeon is, less that. Reduced Motion shows the ring only, at a
  /// settled size, fading.
  static void _snatchRing(
    Canvas canvas,
    double h,
    SkyEnemy enemy,
    PigeonFlight raid,
    bool reducedMotion,
  ) {
    final since = enemy.age - raid.snatchedAt;
    if (!since.isFinite || since < 0 || since >= snatchSeconds) return;
    final off = AlleyPigeon.flee(enemy.age - raid.phaseAt, raid.side);
    final at = Offset((enemy.x - off.dx) * h, (enemy.y - off.dy) * h);
    if (!(at.dx.isFinite && at.dy.isFinite)) return;
    final t = since / snatchSeconds;
    final fade = 1 - t;
    final unit = StarArt.radius * h;
    final r = unit * (1.1 + (reducedMotion ? .9 : 2.2 * t));
    final width = math.max(1.8, h * .0072) * (1 - .4 * t);
    canvas.drawCircle(
      at,
      r,
      _ringInk
        ..color = _ink.withValues(alpha: .6 * fade)
        ..strokeWidth = width + 2.4,
    );
    canvas.drawCircle(
      at,
      r,
      _ringGold
        ..color = _gold.withValues(alpha: .95 * fade)
        ..strokeWidth = width,
    );
    if (reducedMotion) return;
    // Six sparks fly out through the ring.
    final sparks = <Offset>[];
    for (var i = 0; i < 6; i++) {
      final a = i * math.pi / 3 + .5;
      final dir = Offset(math.cos(a), math.sin(a));
      sparks
        ..add(at + dir * (r * 1.02))
        ..add(at + dir * (r * 1.02 + unit * (.40 + .35 * (1 - t))));
    }
    _dotInk
      ..color = _ink.withValues(alpha: .5 * fade)
      ..strokeWidth = math.max(2.6, h * .0075) + 1.6;
    canvas.drawPoints(ui.PointMode.lines, sparks, _dotInk);
    _dotCream
      ..color = _cream.withValues(alpha: fade)
      ..strokeWidth = math.max(2.6, h * .0075);
    canvas.drawPoints(ui.PointMode.lines, sparks, _dotCream);
  }

  /// A freed star's halo: a gold ring that opens round it and three
  /// sparkles that fly off. Drawn over the star, which floats back to its
  /// gate line by the rules' `AlleyPigeon.floatY`.
  static void freed(
    Canvas canvas,
    double h,
    SkyStar star,
    double elapsed, {
    required bool reducedMotion,
  }) {
    final at = star.freedAt;
    if (at == null) return;
    final age = elapsed - at;
    if (!age.isFinite || age < 0 || age >= haloSeconds) return;
    if (!(h.isFinite && h > 0 && star.x.isFinite && star.y.isFinite)) return;
    final t = age / haloSeconds;
    final c = Offset(star.x * h, star.y * h);
    final unit = StarArt.radius * h;
    final fade = (1 - t) * (1 - t);
    // The ring opens fast and thins as it goes; Reduced Motion holds it at
    // a settled size and only fades it.
    final open = reducedMotion ? .7 : 1 - math.pow(1 - t, 3).toDouble();
    canvas.drawCircle(
      c,
      unit * (1.2 + 1.3 * open),
      _ringGold
        ..color = _gold.withValues(alpha: .9 * fade)
        ..strokeWidth = math.max(1.4, h * .0065) * (1 - .55 * t),
    );
    if (reducedMotion) return;
    for (var i = 0; i < 3; i++) {
      final a = -math.pi / 2 + i * math.pi * 2 / 3 + .5;
      final reach = unit * (1.3 + 1.6 * open);
      final p = c + Offset(math.cos(a), math.sin(a)) * reach;
      final size = unit * .34 * math.sin(math.pi * math.min(1.0, t * 1.4));
      if (size <= .3) continue;
      canvas.save();
      canvas.translate(p.dx, p.dy);
      canvas.rotate(a + t * 2);
      canvas.scale(size * 1.5);
      canvas.drawPath(_twinkle, _sparkInk);
      canvas.scale(.72);
      canvas.drawPath(_twinkle, _spark);
      canvas.restore();
    }
  }
}
