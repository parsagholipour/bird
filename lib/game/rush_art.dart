import 'dart:math' as math;
import 'package:flutter/painting.dart';
import '../domain/game_rules.dart';
import '../l10n/l10n.dart';
import '../l10n/text/boss_text.dart';
import '../ui/theme.dart';
import 'enemy_defeat_art.dart';
import 'gale_art.dart';
import 'sky_scenery.dart';

class _Stone {
  const _Stone(this.light, this.mid, this.dark, this.crack, this.soot);

  /// [crack] is the seam colour that fires up while the bird is ramming;
  /// [soot] is the mortar packed between the blocks.
  final Color light, mid, dark, crack, soot;

  /// A barrier that already cost the bird a heart keeps standing but turns
  /// chalky and its seams go out, so a spent one never invites another run.
  _Stone get spent => _Stone(
    Color.lerp(light, SkyColors.cream, .5)!,
    Color.lerp(mid, SkyColors.cream, .5)!,
    Color.lerp(dark, SkyColors.cream, .36)!,
    Color.lerp(crack, SkyColors.cream, .55)!,
    Color.lerp(soot, SkyColors.cream, .26)!,
  );
}

/// Rush paths read at speed: the sky glows from the side the danger comes
/// from, sprint rings glow on the racing line, and everything a ring sprint
/// touches bursts apart. Every effect follows the simulation clock.
abstract final class RushArt {
  static const _deep = Color(0xffc9412c), _ember = Color(0xffff7b3a);
  static const _flame = Color(0xffffb347), _core = Color(0xfffff0b5);
  static const _smoke = Color(0xff5a3434);
  static const _rock = Color(0xff5b4a6b), _rockLight = Color(0xff9486b3);
  static const _magma = Color(0xff7d1d18), _basalt = Color(0xff2b2226);
  static const _dusk = Color(0xff333a73);
  static const _materials = [
    // Wildfire: sun-baked sandstone, ember seams, soot in the mortar.
    _Stone(
      Color(0xfff2d3a4),
      Color(0xffd0985e),
      Color(0xff7d4a34),
      Color(0xffff9a3c),
      Color(0xff573a33),
    ),
    // Skyfall: violet sky-stone veined with cold crystal.
    _Stone(
      Color(0xffe6ddf9),
      Color(0xffa18fcf),
      Color(0xff54487b),
      Color(0xff74e6d2),
      Color(0xff3a3163),
    ),
    // Eruption: warm cooled basalt split by molten seams.
    _Stone(
      Color(0xffcdb6b4),
      Color(0xff947a7f),
      Color(0xff5a4852),
      Color(0xffff7a33),
      Color(0xff3b2c33),
    ),
    // Swarm: mossy cave slate lit by lantern gold.
    _Stone(
      Color(0xffcbe4d9),
      Color(0xff74a093),
      Color(0xff365a5c),
      Color(0xfff2b241),
      Color(0xff20353a),
    ),
  ];
  static const _wall = _Stone(
    SkyColors.cream,
    SkyColors.sand,
    SkyColors.rock,
    SkyColors.yellow,
    SkyColors.muted,
  );
  static const debrisSeconds = 1.0;

  static double _hash(int a, int b) {
    final v = math.sin(a * 12.9898 + b * 78.233) * 43758.5453;
    return v - v.floorToDouble();
  }

  static double _smooth(double t) {
    final x = t.clamp(0.0, 1.0);
    return x * x * (3 - 2 * x);
  }

  static RushPathKind _kindOf(Obstacle o) =>
      RushPathKind.values[(o.appearance ~/ 3).clamp(
        0,
        RushPathKind.values.length - 1,
      )];

  /// 0 before the warning, 1 while running, fading as the danger burns out.
  static double intensity(FlightSimulation sim) {
    final path = sim.rushPath;
    if (path == null) return 0;
    return switch (path.phase) {
      RushPhase.approach => _smooth(
        1 -
            (path.startDistance - sim.distance - FlightSimulation.birdX) /
                Rush.warningLead,
      ),
      RushPhase.running => 1,
      RushPhase.escaped =>
        1 - _smooth((sim.elapsed - path.escapedAt!) / Rush.burnOutSeconds),
    };
  }

  /// Colours the sky behind the course, so the whole run feels dangerous
  /// without covering anything the bird can hit.
  static void backdrop(
    Canvas canvas,
    Size size,
    FlightSimulation sim, {
    required bool reducedMotion,
  }) {
    final t = intensity(sim);
    final path = sim.rushPath;
    if (t <= 0 || path == null) return;
    final w = size.width, h = size.height;
    final bounds = Offset.zero & size;
    if (path.kind == RushPathKind.eruption) {
      canvas.drawRect(
        bounds,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              _deep.withValues(alpha: .52 * t),
              _ember.withValues(alpha: .20 * t),
              _smoke.withValues(alpha: .10 * t),
              _smoke.withValues(alpha: 0),
            ],
            stops: const [0, .26, .58, 1],
          ).createShader(bounds),
      );
      // A lava field burning somewhere past the bottom edge, under the ash
      // it has pushed across the top of the sky.
      final field = Rect.fromLTRB(-w * .1, h * .62, w * 1.1, h * 1.55);
      canvas.drawRect(
        field,
        Paint()
          ..shader = RadialGradient(
            colors: [
              _flame.withValues(alpha: .30 * t),
              _ember.withValues(alpha: .12 * t),
              _ember.withValues(alpha: 0),
            ],
            stops: const [0, .45, 1],
          ).createShader(field),
      );
      final ceiling = Rect.fromLTRB(0, 0, w, h * .44);
      canvas.drawRect(
        ceiling,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _smoke.withValues(alpha: .24 * t),
              _smoke.withValues(alpha: 0),
            ],
          ).createShader(ceiling),
      );
      if (reducedMotion) return;
      for (var i = 0; i < 4; i++) {
        final cloud = Rect.fromCenter(
          center: Offset(
            ((_hash(i, 41) - sim.elapsed * .012) % 1.3 - .15) * w,
            h * (_hash(i, 43) * .10 - .04),
          ),
          width: w * (.46 + _hash(i, 45) * .30),
          height: h * (.26 + _hash(i, 47) * .14),
        );
        canvas.drawOval(
          cloud,
          Paint()
            ..shader = RadialGradient(
              colors: [
                _smoke.withValues(alpha: .13 * t),
                _smoke.withValues(alpha: 0),
              ],
            ).createShader(cloud),
        );
      }
      // Embers streaming up out of the vents far behind the playfield.
      final spark = Paint()
        ..strokeCap = StrokeCap.round
        ..strokeWidth = h * .006;
      for (var i = 0; i < 12; i++) {
        final climb =
            (sim.elapsed * (.16 + _hash(i, 3) * .18) + _hash(i, 5)) % 1;
        final x = (_hash(i, 7) + math.sin(climb * 4 + i) * .04) * w;
        final y = (1.04 - climb * 1.08) * h;
        spark.color = (i % 3 == 0 ? _core : _flame).withValues(
          alpha: .6 * t * (1 - climb) * (1 - climb),
        );
        canvas.drawLine(
          Offset(x, y),
          Offset(x, y + h * (.014 + _hash(i, 9) * .024)),
          spark,
        );
      }
      return;
    }
    if (path.kind == RushPathKind.swarm) {
      canvas.drawRect(
        bounds,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.centerRight,
            end: Alignment.centerLeft,
            colors: [
              _dusk.withValues(alpha: .46 * t),
              _dusk.withValues(alpha: .16 * t),
              _dusk.withValues(alpha: 0),
            ],
            stops: const [0, .45, 1],
          ).createShader(bounds),
      );
      // Dusk gathers overhead as well, which leaves the route band the
      // clearest part of the sky for the flocks to cross.
      final high = Rect.fromLTWH(0, 0, w, h * .44);
      canvas.drawRect(
        high,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _dusk.withValues(alpha: .20 * t),
              _dusk.withValues(alpha: 0),
            ],
          ).createShader(high),
      );
      // Far flocks stream in from the right in loose skeins, the deeper
      // ones smaller and slower. They gather ahead of the dusk, so the
      // warning already has a swarm on the horizon. Frozen, the sky keeps
      // them.
      final wing = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      for (var f = 0; f < 6; f++) {
        final depth = _hash(f, 11);
        final pass =
            (_hash(f, 13) +
                (reducedMotion ? 0 : sim.elapsed * (.16 - depth * .07))) %
            1;
        final lead = Offset(
          (1.12 - pass * 1.3) * w,
          (.06 + _hash(f, 17) * .66) * h,
        );
        final span = h * (.017 - depth * .008);
        wing
          ..color = _dusk.withValues(
            alpha:
                .55 *
                math.sqrt(t) *
                (1 - depth * .5) *
                math.sin(pass * math.pi),
          )
          ..strokeWidth = h * (.0055 - depth * .0022);
        for (var k = 0; k < 4; k++) {
          final x = lead.dx + k * span * 3.1;
          final y = lead.dy + (k.isOdd ? span : -span) * (.6 + k * .45);
          final flap = reducedMotion
              ? span * (.3 + _hash(f, k) * .6)
              : math.sin(sim.elapsed * (12 + f * 1.7) - k * .6) * span * .8;
          canvas.drawPath(
            Path()
              ..moveTo(x - span, y - flap)
              ..quadraticBezierTo(x - span * .45, y - flap * .2, x, y)
              ..quadraticBezierTo(
                x + span * .45,
                y - flap * .2,
                x + span,
                y - flap,
              ),
            wing,
          );
        }
      }
      return;
    }
    if (path.kind == RushPathKind.wildfire) {
      // Everything behind the bird is already burning, so the sky scorches
      // from the left and bruises darker the closer the wall gets. This is
      // what carries the threat while the wall itself is off screen.
      final (:near, :looms) = _fireHeat(sim, path);
      final drift = reducedMotion ? 0.0 : sim.elapsed;
      canvas.drawRect(
        bounds,
        Paint()
          ..shader = LinearGradient(
            colors: [
              _smoke.withValues(alpha: (.10 + .52 * looms) * t),
              _fireCoal.withValues(alpha: (.30 + .30 * looms + .20 * near) * t),
              _deep.withValues(alpha: (.26 + .22 * near) * t),
              _ember.withValues(alpha: (.12 + .16 * near) * t),
              _flame.withValues(alpha: .05 * t),
            ],
            stops: [0, .06 + .06 * near, .22 + .14 * near, .52 + .24 * near, 1],
          ).createShader(bounds),
      );
      // Firelight throbs on the sky at the edge the wall came in from. It is
      // pinned to the edge rather than to the wall, because for much of a run
      // the wall is off screen and this is the only thing carrying it.
      for (var i = 0; i < 4; i++) {
        final lift = (drift * (.06 + _hash(i, 31) * .07) + _hash(i, 33)) % 1;
        final centre = Offset(
          h * (.05 + _hash(i, 35) * .20),
          (1.2 - lift * 1.4) * h,
        );
        final radius = h * (.26 + _hash(i, 37) * .24);
        canvas.drawCircle(
          centre,
          radius,
          Paint()
            ..shader = RadialGradient(
              colors: [
                _ember.withValues(
                  alpha: (.05 + .30 * looms) * t * math.sin(lift * math.pi),
                ),
                _ember.withValues(alpha: 0),
              ],
            ).createShader(Rect.fromCircle(center: centre, radius: radius)),
        );
      }
      // Smoke pours off the top of the wall in billows: overlapping lobes
      // unioned into one path, so they stay chunky and never show a seam
      // where two of them cross.
      for (var band = 0; band < 2; band++) {
        final roll = Path();
        for (var k = 0; k < 7; k++) {
          // Lobes are born big over the wall and thin out as they blow
          // downwind, so the plume reads as coming from the fire.
          final along =
              (k / 7 + band * .07 + drift * (.013 + band * .006)) % 1.2 - .1;
          final swell = 1.28 - along * .82;
          roll.addOval(
            Rect.fromCenter(
              center: Offset(along * w, -h * (.12 + _hash(k, 11 + band) * .06)),
              width: w * (.26 + _hash(k, 13 + band) * .20) * swell,
              height: h * (band == 0 ? .60 : .42) * swell,
            ),
          );
        }
        // The fall-off lands on the lobes' own bottoms, so they thin out
        // into the sky instead of being cut off part way down.
        final reach = h * (band == 0 ? .30 : .18);
        canvas.drawPath(
          roll,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                _smoke.withValues(alpha: (band == 0 ? .34 : .52) * t),
                _smoke.withValues(alpha: (band == 0 ? .26 : .44) * t),
                _fireCoal.withValues(alpha: (band == 0 ? .16 : .26) * t),
                _fireCoal.withValues(alpha: 0),
              ],
              stops: const [0, .42, .82, 1],
            ).createShader(Rect.fromLTWH(0, -h * .18, w, reach + h * .18)),
        );
      }
      if (reducedMotion) return;
      // Ash and sparks blow downwind of the wall, far behind the playfield.
      for (var i = 0; i < 14; i++) {
        final run =
            (sim.elapsed * (.13 + _hash(i, 21) * .18) + _hash(i, 23)) % 1;
        final x = (run * 1.3 - .16) * w;
        final y =
            (_hash(i, 25) * 1.05 - .04 - run * .24) * h +
            math.sin(run * 7 + i) * h * .02;
        canvas.drawCircle(
          Offset(x, y),
          h * (.003 + _hash(i, 27) * .006),
          Paint()
            ..color = (i.isEven ? _ember : _smoke).withValues(
              alpha: .45 * t * math.sin(run * math.pi),
            ),
        );
      }
      return;
    }
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xff4b2a5e).withValues(alpha: .45 * t),
            _deep.withValues(alpha: .14 * t),
            _deep.withValues(alpha: 0),
          ],
          stops: const [0, .5, 1],
        ).createShader(bounds),
    );
    // The sky itself burns where the rocks are coming through.
    final crown = Rect.fromLTWH(0, 0, w, h * .36);
    canvas.drawRect(
      crown,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _ember.withValues(alpha: .20 * t),
            _ember.withValues(alpha: 0),
          ],
        ).createShader(crown),
    );
    if (reducedMotion) return;
    // Debris falling far behind the playfield, down the same line as the
    // meteors: a bright head with a tail that cools and thins behind it.
    final streak = Paint()..strokeCap = StrokeCap.round;
    final lean = math.atan2(1.2 * h, -.45 * w);
    for (var i = 0; i < 12; i++) {
      final depth = _hash(i, 11);
      final fall = (sim.elapsed * (.22 + depth * .45) + _hash(i, 7)) % 1;
      final head = Offset(
        (_hash(i, 3) * 1.4 - fall * .45) * w,
        (fall * 1.2 - .1) * h,
      );
      final step = Offset.fromDirection(
        lean + (_hash(i, 13) - .5) * .3,
        -h * (.012 + depth * .026),
      );
      final fade = .5 * t * (1 - fall) * (.35 + .65 * depth);
      streak.strokeWidth = h * (.0022 + depth * .0035);
      for (final (from, to, alpha) in [
        (0.0, 1.0, .55),
        (1.0, 2.0, .3),
        (2.0, 3.0, .12),
      ]) {
        canvas.drawLine(
          head + step * from,
          head + step * to,
          streak
            ..color = (from < .5 ? _ember : _deep).withValues(
              alpha: fade * alpha,
            ),
        );
      }
      canvas.drawCircle(
        head,
        h * (.0025 + depth * .004),
        streak
          ..color = (depth > .55 ? _core : _flame).withValues(
            alpha: fade * 1.5,
          ),
      );
    }
  }

  static const _fireChar = Color(0xff2e181f), _fireTip = Color(0xfffff4cf);
  static const _fireCoal = Color(0xff8d2a20);

  /// How hard the wall presses. `near` spikes as it closes on the bird and is
  /// the feedback that tells a slowing player to move; `looms` fades far more
  /// slowly, so a fire knocked back off screen still stains the sky while it
  /// climbs back.
  static ({double near, double looms}) _fireHeat(
    FlightSimulation sim,
    RushPath path,
  ) {
    final gap = sim.distance + FlightSimulation.birdX - path.fireDistance;
    return (
      near: (1 - (gap - .15) / .6).clamp(0.0, 1.0),
      looms: (1 - (gap - .55) / .95).clamp(0.0, 1.0),
    );
  }

  /// Fills [out] with a 0..1 reach for each row of the wall. A handful of big
  /// lobes climb the height, swelling on the way and dying at the top, with a
  /// few small quick ones riding them. Kept this coarse on purpose: at speed
  /// on a phone a finer edge turns to mush.
  static void _fireLicks(List<double> out, double t, int seed, double floor) {
    final last = out.length - 1;
    for (var i = 0; i <= last; i++) {
      out[i] = floor * (.55 + .45 * math.sin(i * .38 + seed + t * 1.5));
    }
    for (var k = 0; k < 11; k++) {
      final fine = k >= 5;
      // Lobes are dealt evenly around the climb rather than at random, so
      // the wall never happens to run out of flame over a stretch of it.
      final climb =
          (t * ((fine ? .30 : .12) + _hash(k, seed) * .07) +
              (fine ? (k - 5) / 6 : k / 5) +
              _hash(k, seed + 1) * .09) %
          1;
      final amp =
          (fine
              ? .26 + _hash(k, seed + 2) * .30
              : .58 + _hash(k, seed + 2) * .42) *
          math.sin(climb * math.pi);
      final span = fine
          ? .028 + _hash(k, seed + 3) * .034
          : .105 + _hash(k, seed + 3) * .135;
      final centre = 1.18 - climb * 1.36;
      final from = math.max(0, ((centre - span / 2.6) * last).floor());
      final to = math.min(last, ((centre + span) * last).ceil());
      for (var i = from; i <= to; i++) {
        final dy = i / last - centre;
        // A long rounded belly below, a steep face above: the lobe leans up.
        final d = (dy < 0 ? -dy * 2.6 : dy) / span;
        if (d >= 1) continue;
        final lick = amp * (dy < 0 ? 1 - d * d : 1 - d * d * d);
        if (lick > out[i]) out[i] = lick;
      }
    }
  }

  /// One tongue of flame: pinched at the foot, bulging just above it, then
  /// tapering to a point that leans into its own draught.
  static Path _fireTongue(
    double x,
    double y,
    double wide,
    double tall,
    double lean,
  ) => Path()
    ..moveTo(x - wide * .70, y)
    ..cubicTo(
      x - wide * 1.04,
      y - tall * .30,
      x - wide * .66 + lean * .3,
      y - tall * .66,
      x + lean,
      y - tall,
    )
    ..cubicTo(
      x + lean + wide * .32,
      y - tall * .62,
      x + wide * 1.04,
      y - tall * .28,
      x + wide * .70,
      y,
    )
    ..quadraticBezierTo(x, y + wide * .44, x - wide * .70, y)
    ..close();

  /// Walks a column of edge positions into [p], rounding through the
  /// midpoints so the lobes stay chunky rather than faceted.
  static void _fireRun(Path p, List<double> xs, double h, bool down) {
    final last = xs.length - 1;
    double y(int i) => i / last * (h + 16) - 8;
    if (down) {
      for (var i = 1; i < last; i++) {
        p.quadraticBezierTo(
          xs[i],
          y(i),
          (xs[i] + xs[i + 1]) / 2,
          (y(i) + y(i + 1)) / 2,
        );
      }
      p.lineTo(xs[last], y(last));
      return;
    }
    for (var i = last - 1; i > 0; i--) {
      p.quadraticBezierTo(
        xs[i],
        y(i),
        (xs[i] + xs[i - 1]) / 2,
        (y(i) + y(i - 1)) / 2,
      );
    }
    p.lineTo(xs[0], y(0));
  }

  /// A wall of flame fills the screen behind its leading edge. Big lobes
  /// climb the edge, hot patches break through them, and the colour drops
  /// back through ember and deep red into soot, so a wall that has fallen
  /// behind still reads as fire rather than as a bar.
  static void fire(
    Canvas canvas,
    Size size,
    FlightSimulation sim, {
    required bool reducedMotion,
  }) {
    final path = sim.rushPath;
    if (path == null ||
        path.kind != RushPathKind.wildfire ||
        path.phase == RushPhase.approach) {
      return;
    }
    final fade = intensity(sim);
    if (fade <= 0) return;
    final h = size.height;
    final front = (path.fireDistance - sim.distance) * h;
    final (:near, :looms) = _fireHeat(sim, path);
    final t = reducedMotion ? 0.0 : sim.elapsed;

    final spill = h * (.16 + .50 * near) * (.4 + .6 * looms);
    final air = Rect.fromLTRB(front - h, 0, front + spill, h);
    canvas.drawRect(
      air,
      Paint()
        ..shader = LinearGradient(
          colors: [
            _fireCoal.withValues(alpha: (.20 + .26 * near) * fade),
            _ember.withValues(alpha: (.24 + .28 * near) * fade),
            _flame.withValues(alpha: (.08 + .11 * near) * fade),
            _flame.withValues(alpha: 0),
          ],
          stops: [0, h / (h + spill), h / (h + spill) + .12, 1],
        ).createShader(air),
    );
    // Heat lifts off the wall in slow blooms, so the sky beside the fire
    // shimmers instead of banding into a bar.
    for (var i = 0; i < 4; i++) {
      final lift = (t * (.07 + _hash(i, 51) * .08) + _hash(i, 53)) % 1;
      final centre = Offset(
        front + spill * (.06 + _hash(i, 57) * .34),
        (1.2 - lift * 1.4) * h,
      );
      final radius = h * (.18 + _hash(i, 55) * .18) * (.45 + .55 * near);
      canvas.drawCircle(
        centre,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [
              _ember.withValues(
                alpha: (.10 + .14 * near) * fade * math.sin(lift * math.pi),
              ),
              _ember.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromCircle(center: centre, radius: radius)),
      );
    }
    // A tight halo where the flame meets the sky. It stays close to the wall
    // so the bird and the obstacles it still has to thread stay readable.
    final halo = Rect.fromLTRB(front - h * .06, 0, front + h * .16, h);
    canvas.drawRect(
      halo,
      Paint()
        ..shader = LinearGradient(
          colors: [
            _flame.withValues(alpha: (.18 + .20 * near) * fade),
            _flame.withValues(alpha: 0),
          ],
        ).createShader(halo),
    );
    if (front < -h * .10) return;

    const rows = 40;
    final mass = List<double>.filled(rows + 1, 0);
    final heat = List<double>.filled(rows + 1, 0);
    final back = List<double>.filled(rows + 1, 0);
    _fireLicks(mass, t, 41, .10);
    _fireLicks(heat, t * 1.9 + 3, 73, 0);
    // One field drives both the silhouette and the heat, because that is how
    // a fire reads: the parts that stand furthest forward are the hot ones.
    for (var i = 0; i <= rows; i++) {
      heat[i] = .55 * (mass[i] + heat[i]);
      mass[i] = front - h * .048 + h * .125 * mass[i];
    }

    // Soot at the back, ember at the lip: the drop in value backwards is
    // what keeps a wall that has fallen behind still reading as fire.
    final face = Path()..moveTo(mass[0], -8);
    _fireRun(face, mass, h, true);
    final body = Path.from(face)
      ..lineTo(-h, h + 8)
      ..lineTo(-h, -8)
      ..close();
    canvas.drawPath(
      body,
      Paint()
        ..shader = LinearGradient(
          colors: [
            _fireChar.withValues(alpha: fade),
            _smoke.withValues(alpha: fade),
            _fireCoal.withValues(alpha: fade),
            _deep.withValues(alpha: fade),
            _ember.withValues(alpha: fade),
            _flame.withValues(alpha: fade),
          ],
          stops: const [0, .18, .42, .70, .90, 1],
        ).createShader(Rect.fromLTRB(front - h * .62, 0, front + h * .075, h)),
    );

    // A hot band hugs the edge, swelling where a lobe stands proud of the
    // wall and thinning between them, so the rim glows in patches instead of
    // outlining the shape.
    for (var i = 0; i <= rows; i++) {
      back[i] = mass[i] - h * (.006 + .055 * heat[i]);
    }
    final band = Path.from(face)..lineTo(back[rows], h + 8);
    _fireRun(band, back, h, false);
    canvas.drawPath(
      band..close(),
      Paint()..color = _flame.withValues(alpha: fade),
    );

    // The wall burns in tongues, not in bands. Each is seated so its widest
    // point still falls short of the leading edge: the fire never paints
    // ahead of the line that catches the bird, and nothing has to be clipped
    // flat against the silhouette.
    for (var k = 0; k < 13; k++) {
      // Each tongue keeps its own slot up the wall and rises, swells and
      // dies inside it. Free-running licks drift into clumps over a long
      // run and leave stretches of the wall bare; these never do.
      final lane = (k + .5) / 13 + (_hash(k, 73) - .5) * .06;
      final climb = (t * (.26 + _hash(k, 61) * .22) + _hash(k, 63)) % 1;
      final grew = math.sin(climb * math.pi);
      if (grew <= .05) continue;
      final tall = h * (.10 + _hash(k, 67) * .28) * grew;
      final wide = h * (.032 + _hash(k, 69) * .054) * grew;
      // Squared, so most tongues crowd the hot lip and only a few sit back
      // in the wall: the flame field stays continuous out to the edge.
      final sunk = _hash(k, 65) * _hash(k, 65);
      final x = front - h * (.012 + sunk * .17) - wide;
      final y = (1.08 - lane * 1.16) * h - (climb - .5) * h * .18;
      canvas.drawPath(
        _fireTongue(x, y, wide, tall, h * (.006 + _hash(k, 71) * .030) * grew),
        Paint()..color = _flame.withValues(alpha: fade),
      );
      if (tall < h * .09) continue;
      canvas.drawPath(
        _fireTongue(x, y, wide * .42, tall * .62, h * .014 * grew),
        Paint()..color = _fireTip.withValues(alpha: .92 * fade),
      );
    }

    // Sparks tear off the lobes and blow forward; a closing fire throws more
    // of them, further.
    final sparks = 12 + (14 * near).round();
    final blow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < sparks; i++) {
      final life = (t * (.55 + _hash(i, 2) * .75) + _hash(i, 4)) % 1;
      final run = h * (.05 + _hash(i, 6) * .26) * (.45 + .55 * near);
      final x = front + h * .01 + life * run + math.sin(life * 7 + i) * h * .01;
      final y =
          _hash(i, 8) * (h + 20) - 10 - life * h * (.08 + _hash(i, 10) * .20);
      final tail = h * (.008 + _hash(i, 12) * .020) * (1 - life * .5);
      canvas.drawLine(
        Offset(x, y),
        Offset(x - tail, y + tail * (.2 + _hash(i, 16) * .7)),
        blow
          ..color = (i % 3 == 0 ? _fireTip : _flame).withValues(
            alpha: fade * (.5 + .5 * near) * math.sin(life * math.pi),
          )
          ..strokeWidth = h * (.004 + _hash(i, 14) * .005),
      );
    }
  }

  /// A rush barrier: two stacks of hewn stone leaving the ring route open
  /// between them. Mortar is the only thing holding the blocks apart, so
  /// warming it is what makes the whole wall look ready to come down.
  static void rubble(
    Canvas canvas,
    Size size,
    Obstacle o,
    FlightSimulation sim, {
    required bool reducedMotion,
  }) {
    final h = size.height;
    if (o.smashed) {
      debris(
        canvas,
        h,
        o,
        sim.elapsed - o.smashedAt!,
        reducedMotion: reducedMotion,
      );
      return;
    }
    if ((o.x + o.width) * h < -8 || o.x * h > size.width + 8) return;
    var stone = _materials[_kindOf(o).index];
    var glow = sim.ramming
        ? .82 + (reducedMotion ? 0 : .18 * math.sin(sim.elapsed * 15))
        : .26;
    if (o.hit) {
      stone = stone.spent;
      glow = .08;
    }
    _column(canvas, h, o, stone, glow, from: o.top, to: 0, seed: 1, hit: o.hit);
    _column(
      canvas,
      h,
      o,
      stone,
      glow,
      from: o.bottom,
      to: 1,
      seed: 2,
      hit: o.hit,
    );
  }

  /// One stack, from the gap edge [from] out to the frame at [to].
  static void _column(
    Canvas canvas,
    double h,
    Obstacle o,
    _Stone stone,
    double glow, {
    required double from,
    required double to,
    required int seed,
    required bool hit,
  }) {
    final span = (to - from).abs();
    if (span < .006) return;
    final left = o.x * h, width = o.width * h;
    final down = to > from;
    final direction = down ? 1.0 : -1.0;
    final body = Rect.fromLTRB(
      left,
      (down ? from : to) * h,
      left + width,
      (down ? to : from) * h,
    );
    final joint = math.max(1.0, h * .0045);
    final round = Radius.circular(h * .008);
    final mortar = Color.lerp(stone.dark, stone.soot, .7)!;
    final ember = Color.lerp(
      mortar,
      Color.lerp(stone.crack, stone.dark, .28)!,
      glow * glow * .6,
    )!;
    canvas.drawRect(
      body,
      Paint()
        ..shader = LinearGradient(
          begin: down ? Alignment.topCenter : Alignment.bottomCenter,
          end: down ? Alignment.bottomCenter : Alignment.topCenter,
          colors: [ember, ember, mortar],
          stops: const [0, .22, .95],
        ).createShader(body),
    );

    var y = from, cut = .5;
    for (var row = 0; row < 16 && (to - y) * direction > .01; row++) {
      final r = _hash(o.appearance * 31 + seed * 7, row);
      final remaining = (to - y).abs();
      var course = .044 + r * .044;
      if (remaining - course < .034) course = remaining;
      final y0 = (down ? y : y - course) * h, y1 = y0 + course * h;
      y += course * direction;
      // A running bond: every course cuts in a different place from the one
      // below it, and now and then a full stretcher ties the stack together.
      final s = _hash(seed * 13 + row, o.appearance + 5);
      if (r > .34) {
        cut = (s * .44 + .28 + ((s - cut).abs() < .12 ? .17 : 0)).clamp(
          .24,
          .76,
        );
      } else {
        cut = 1;
      }
      final edges = cut < 1 ? [0.0, cut, 1.0] : [0.0, 1.0];
      // Stone nearest the opening catches the light; the rest sinks back.
      final depth = ((y0 / h - from).abs() / span).clamp(0.0, 1.0);
      for (var b = 0; b + 1 < edges.length; b++) {
        final block = Rect.fromLTRB(
          left + width * edges[b] + joint * .6,
          y0 + joint * .6,
          left + width * edges[b + 1] - joint * .6,
          y1 - joint * .6,
        );
        if (block.width < 2 || block.height < 2) continue;
        final tone = _hash(row * 7 + b * 3 + seed, o.appearance + 2);
        final face = Color.lerp(
          Color.lerp(stone.mid, stone.light, .1 + tone * .55)!,
          stone.dark,
          depth * .22,
        )!;
        final shape = RRect.fromRectAndRadius(block, round);
        canvas.drawRRect(shape, Paint()..color = face);
        // Two flat bands, not a gradient: a hewn top and a shadowed foot.
        final band = block.height * (.2 + tone * .08);
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            Rect.fromLTWH(block.left, block.top, block.width, band),
            topLeft: round,
            topRight: round,
          ),
          Paint()..color = Color.lerp(face, stone.light, .42)!,
        );
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            Rect.fromLTWH(
              block.left,
              block.bottom - band * .62,
              block.width,
              band * .62,
            ),
            bottomLeft: round,
            bottomRight: round,
          ),
          Paint()..color = Color.lerp(face, stone.dark, .42)!,
        );
        if (tone > .62) {
          // A knocked-off corner, so no two blocks share a silhouette.
          final chip = math.min(block.width, block.height) * .3;
          final onLeft = tone > .82, onTop = row.isEven;
          final cx = onLeft ? block.left : block.right;
          final cy = onTop ? block.top : block.bottom;
          canvas.drawPath(
            Path()
              ..moveTo(cx + (onLeft ? chip : -chip), cy)
              ..lineTo(cx, cy)
              ..lineTo(cx, cy + (onTop ? chip * .8 : -chip * .8))
              ..close(),
            Paint()..color = mortar,
          );
        }
      }
    }

    // One fissure per column, opening at the exposed end and running in
    // across the courses. It is a joint the stone has lost, not a drawn-on
    // line, so it widens and lights up with the rest of the mortar.
    final reach = span * h * (span > .15 ? .46 : .78);
    final lip = h * (.0026 + .0055 * glow);
    final spine = <Offset>[];
    final mouth = from * h + direction * math.max(3.0, h * .021);
    var fx = left + width * (.26 + _hash(o.appearance * 17 + seed, 41) * .48);
    for (var i = 0; i <= 5; i++) {
      fx = (fx + (_hash(o.appearance + seed * 23, 60 + i) - .5) * width * .22)
          .clamp(left + width * .18, left + width * .82);
      spine.add(Offset(fx, mouth + direction * reach * (i / 5)));
    }
    final fissure = Path()..moveTo(spine.first.dx - lip, spine.first.dy);
    for (var i = 1; i < spine.length; i++) {
      fissure.lineTo(spine[i].dx - lip * (1 - i / 5), spine[i].dy);
    }
    for (var i = spine.length - 1; i >= 0; i--) {
      fissure.lineTo(spine[i].dx + lip * (1 - i / 5), spine[i].dy);
    }
    fissure.close();
    final branch = _hash(o.appearance, seed * 5 + 3);
    final fork = spine[2];
    fissure
      ..moveTo(fork.dx - lip * .6, fork.dy - lip * .6)
      ..lineTo(fork.dx + lip * .6, fork.dy + lip * .6)
      ..lineTo(
        (fork.dx + (branch - .5) * width * .62).clamp(
          left + width * .12,
          left + width * .88,
        ),
        fork.dy + direction * reach * .32,
      )
      ..close();
    canvas.drawPath(
      fissure,
      Paint()..color = Color.lerp(stone.dark, SkyColors.ink, .45)!,
    );
    final spinePath = Path()..addPolygon(spine, false);
    canvas.drawPath(
      spinePath,
      Paint()
        ..color = stone.crack.withValues(alpha: glow * .22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = lip * 2.6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(
      spinePath,
      Paint()
        ..color = Color.lerp(
          stone.crack,
          SkyColors.white,
          .5,
        )!.withValues(alpha: glow * .85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1, h * .0022)
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // The capstone squares off the opening: the edge the player threads.
    final capH = math.max(3.0, h * .021);
    final cap = Rect.fromLTWH(
      left,
      down ? from * h : from * h - capH,
      width,
      capH,
    );
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        cap,
        topLeft: down ? round : Radius.zero,
        topRight: down ? round : Radius.zero,
        bottomLeft: down ? Radius.zero : round,
        bottomRight: down ? Radius.zero : round,
      ),
      Paint()..color = stone.dark,
    );
    final lipY = down ? cap.top + capH * .32 : cap.bottom - capH * .32;
    canvas.drawLine(
      Offset(cap.left + capH * .5, lipY),
      Offset(cap.right - capH * .5, lipY),
      Paint()
        ..color = Color.lerp(
          stone.light,
          stone.crack,
          glow * .8,
        )!.withValues(alpha: .7 + glow * .3)
        ..strokeWidth = capH * .36
        ..strokeCap = StrokeCap.round,
    );

    // The silhouette carries the outline; the blocks inside only have
    // mortar between them, which keeps the stack reading as one mass.
    final edge = h * .006;
    canvas.drawRect(
      body.deflate(edge / 2),
      Paint()
        ..color = SkyColors.ink.withValues(alpha: .78)
        ..style = PaintingStyle.stroke
        ..strokeWidth = edge,
    );
    if (hit) {
      canvas.drawRect(
        body.deflate(edge * 1.8),
        Paint()
          ..color = SkyColors.cream.withValues(alpha: .55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = edge * .8,
      );
    }
  }

  /// Smashed barriers and walls blow apart in a third of a second, then the
  /// pieces tumble away as the course keeps racing past. Stone right on the
  /// line the bird punched flies hardest; the rest of the stack just drops.
  static void debris(
    Canvas canvas,
    double h,
    Obstacle o,
    double age, {
    required bool reducedMotion,
  }) {
    if (!(age >= 0 && age < debrisSeconds)) return;
    final stone = o.rubble ? _materials[_kindOf(o).index] : _wall;
    final t = age / debrisSeconds;
    final impact = Offset((o.x + o.width / 2) * h, o.smashY * h);
    final thrown = 1 - math.pow(1 - (age / .32).clamp(0.0, 1.0), 3).toDouble();
    final puffed = 1 - math.pow(1 - (age / .5).clamp(0.0, 1.0), 2).toDouble();
    final fade = 1 - _smooth((t - .3) / .5);

    // Dust billows out of the hole in torn lobed blobs. None of them is a
    // shape on its own: they overlap into one ragged mass that thins out
    // towards the ceiling and the floor instead of stopping.
    final haze = Color.lerp(stone.light, SkyColors.cream, .25)!;
    final soot = Color.lerp(stone.soot, stone.mid, .55)!;
    final settling =
        (1 - _smooth((t - .12) / .8)) * (age / .04).clamp(0.0, 1.0);
    if (settling > 0) {
      final tall = (o.top + 1 - o.bottom + .1) * h;
      for (var i = 0; i < (reducedMotion ? 11 : 20); i++) {
        final a = _hash(i, 21), b = _hash(i + 3, 23), c = _hash(i, 29);
        final drift = puffed * (.25 + a);
        final along = math.pow((b - .5) * 2, 3).toDouble() * .5;
        // The first three are the body of the cloud, spread down the line
        // the barrier stood on; the rest pile torn edges onto it.
        final body = i < 3;
        final at =
            impact +
            Offset(
              (a - .4) * h * (body ? .02 : .018 + drift * .06),
              body ? (i - 1) * tall * .3 : along * tall * (.62 + drift * 1.1),
            );
        canvas.drawPath(
          _dustBlob(
            at,
            body
                ? h * (.038 + drift * .05)
                : h * (.021 + drift * .048) * (.6 + c * .8),
            i,
            a * 6,
          ),
          Paint()
            ..color = (c > .7 ? soot : haze).withValues(
              alpha: (body ? .12 : (c > .7 ? .13 : .17)) * settling,
            ),
        );
      }
    }

    if (reducedMotion) {
      // A still burst mark where the barrier stood, in place of the flash:
      // it never grows, and it cannot be mistaken for a sprint ring.
      final mark = Paint()
        ..color = Color.lerp(
          stone.crack,
          SkyColors.cream,
          .35,
        )!.withValues(alpha: .6 * fade)
        ..strokeWidth = h * .009
        ..strokeCap = StrokeCap.round;
      for (var i = 0; i < 8; i++) {
        final angle = i * math.pi / 4 + .2;
        final dir = Offset(math.cos(angle) * 1.5, math.sin(angle));
        canvas.drawLine(impact + dir * h * .028, impact + dir * h * .062, mark);
      }
      canvas.drawCircle(impact, h * .026, mark);
    } else {
      final flash = _smooth(1 - (age / .14).clamp(0.0, 1.0));
      if (flash > 0) {
        for (var i = 0; i < 6; i++) {
          final angle = i * math.pi / 3 + .35;
          final dir = Offset(math.cos(angle) * 1.7, math.sin(angle));
          final out = h * (.05 + (1 - flash) * .13) * (i.isEven ? 1 : .6);
          final wide = h * .016 * flash;
          canvas.drawPath(
            Path()
              ..moveTo(impact.dx - dir.dy * wide, impact.dy + dir.dx * wide)
              ..lineTo(impact.dx + dir.dx * out, impact.dy + dir.dy * out)
              ..lineTo(impact.dx + dir.dy * wide, impact.dy - dir.dx * wide)
              ..close(),
            Paint()..color = SkyColors.white.withValues(alpha: flash * .85),
          );
        }
        canvas.drawCircle(
          impact,
          h * (.025 + (1 - flash) * .08),
          Paint()
            ..color = SkyColors.yellow.withValues(alpha: flash)
            ..style = PaintingStyle.stroke
            ..strokeWidth = h * .018 * flash + 1,
        );
        canvas.drawCircle(
          impact,
          h * .045 * flash,
          Paint()..color = SkyColors.white.withValues(alpha: flash),
        );
      }
    }

    final outline = Paint()
      ..color = SkyColors.ink.withValues(alpha: .7 * fade)
      ..style = PaintingStyle.stroke
      ..strokeWidth = h * .0045
      ..strokeJoin = StrokeJoin.round;
    for (var i = 0; i < (reducedMotion ? 8 : 18); i++) {
      final upper = i.isEven;
      final r1 = _hash(o.appearance + i, 11), r2 = _hash(i, 13);
      final r3 = _hash(i, 17 + o.appearance), r4 = _hash(i * 3, 19);
      final originY = upper
          ? o.top * (1 - r1 * r1)
          : o.bottom + (1 - o.bottom) * r1 * r1;
      final originX = o.x + o.width * (.12 + .76 * r2);
      final away = originY - o.smashY;
      final push = 1 / (1 + away.abs() * 6);
      final vx = (.35 + 2.3 * push) * (.55 + .8 * r3);
      final vy = away.sign * (.3 + 1.2 * push) * (.35 + r4) - .15;
      final s = h * (.014 + .038 * r3) * (.62 + .38 * fade);
      canvas.save();
      canvas.translate(
        (originX + vx * (.19 * thrown + .07 * age)) * h,
        (originY + vy * .2 * thrown + 1.05 * age * age) * h,
      );
      canvas.rotate(
        reducedMotion
            ? (r1 - .5) * 3
            : (r4 - .5) * 11 * (thrown * .4 + age) + r1 * 6.3,
      );
      // One solid lump split by a chord into a lit plane and a shaded one:
      // the facet edge touches the silhouette, so the piece reads as a
      // faceted stone rather than a lighter shape framed by a darker one.
      final corners = _chunk(i % 4, s, r2);
      final lit = Color.lerp(stone.mid, stone.light, .18 + r1 * .34)!;
      canvas.drawPath(
        Path()..addPolygon(corners, true),
        Paint()..color = lit.withValues(alpha: fade),
      );
      final cut = corners.length ~/ 2 + 1;
      canvas.drawPath(
        Path()..addPolygon([...corners.sublist(cut - 1), corners.first], true),
        Paint()
          ..color = Color.lerp(
            stone.dark,
            stone.mid,
            .1 + r4 * .3,
          )!.withValues(alpha: fade),
      );
      canvas.drawPath(Path()..addPolygon(corners, true), outline);
      if (i % 4 == 1) {
        canvas.drawLine(
          Offset(-s * .5, s * .2),
          Offset(s * .35, -s * .35),
          Paint()
            ..color = stone.crack.withValues(alpha: fade * .9)
            ..strokeWidth = s * .16
            ..strokeCap = StrokeCap.round,
        );
      }
      canvas.restore();
    }
  }

  /// Four broken-stone silhouettes, so a burst never reads as one shape
  /// repeated: a blocky fragment, a wedge, a seam splinter, a chipped lump.
  /// Each is convex, so a chord across it splits it into two clean planes.
  static List<Offset> _chunk(int kind, double s, double j) => switch (kind) {
    0 => [
      Offset(-s * 1.05, -s * (.5 + j * .2)),
      Offset(s * (.35 + j * .5), -s * .78),
      Offset(s * 1.0, -s * .12),
      Offset(s * .74, s * .66),
      Offset(-s * .88, s * .5),
    ],
    1 => [
      Offset(-s * 1.0, s * .62),
      Offset(s * (.05 + j * .6), -s * 1.05),
      Offset(s * 1.05, s * .3),
    ],
    2 => [
      Offset(-s * 1.45, -s * .1),
      Offset(s * .2, -s * (.26 + j * .2)),
      Offset(s * 1.4, s * .04),
      Offset(s * .1, s * .3),
    ],
    _ => [
      Offset(-s * .82, -s * .86),
      Offset(s * .5, -s * 1.0),
      Offset(s * (.85 + j * .2), -s * .05),
      Offset(s * .2, s * .92),
      Offset(-s * .95, s * .45),
    ],
  };

  /// A torn lobed puff. Dust never has a clean edge, so the blob wobbles
  /// around its radius and squashes flat, and only overlap gives it body.
  static Path _dustBlob(Offset at, double radius, int seed, double turn) {
    const lobes = 7;
    final rim = <Offset>[];
    for (var i = 0; i < lobes; i++) {
      final angle = i * math.pi * 2 / lobes + turn;
      final reach = radius * (.45 + _hash(seed * 7 + i, 31) * 1.0);
      rim.add(
        at + Offset(math.cos(angle) * reach, math.sin(angle) * reach * .78),
      );
    }
    var seam = (rim.last + rim.first) / 2;
    final path = Path()..moveTo(seam.dx, seam.dy);
    for (var i = 0; i < lobes; i++) {
      seam = (rim[i] + rim[(i + 1) % lobes]) / 2;
      path.quadraticBezierTo(rim[i].dx, rim[i].dy, seam.dx, seam.dy);
    }
    return path..close();
  }

  static const _ringDeep = Color(0xffb0660f), _ringGold = Color(0xffefab35);
  static const _ringLit = Color(0xffffdc6b), _ringCore = Color(0xfffff6dc);
  static const _ringPopSeconds = .38;

  /// Race gates on the racing line. A thick gold hoop with a real hole
  /// through it, lit from the upper left and with its far rim thinner than
  /// its near one, so it reads as something to fly through rather than a
  /// coin standing on edge. The next gate in the chain wears the arrows.
  static void rings(
    Canvas canvas,
    Size size,
    FlightSimulation sim, {
    required bool reducedMotion,
  }) {
    final h = size.height, w = size.width;
    var next = -1;
    for (var i = 0; i < sim.sprintRings.length; i++) {
      final ring = sim.sprintRings[i];
      if (ring.collected || ring.x < FlightSimulation.birdX) continue;
      next = i;
      break;
    }
    for (var i = 0; i < sim.sprintRings.length; i++) {
      final ring = sim.sprintRings[i];
      final center = Offset(ring.x * h, ring.y * h);
      if (center.dx < -h * .4 || center.dx > w + h * .35) continue;
      if (ring.collected) {
        _ringPop(
          canvas,
          h,
          center,
          sim.elapsed - ring.collectedAt!,
          reducedMotion,
        );
      } else {
        _ringHoop(
          canvas,
          h,
          center,
          ring,
          sim,
          lead: i == next,
          reducedMotion: reducedMotion,
        );
      }
    }
  }

  static void _ringHoop(
    Canvas canvas,
    double h,
    Offset center,
    SprintRing ring,
    FlightSimulation sim, {
    required bool lead,
    required bool reducedMotion,
  }) {
    final beat = reducedMotion
        ? .5
        : .5 + .5 * math.sin(sim.elapsed * 5.2 + ring.x * 3.7);
    final lit = lead ? 1.0 : .7;

    // A warm pool of light with a dark lip, so the gold holds up over hot
    // orange as readily as over dusk violet.
    final glowR = h * (.172 + .014 * beat) * (lead ? 1 : .84);
    canvas.drawCircle(
      center,
      glowR,
      Paint()
        ..shader = RadialGradient(
          colors: [
            _ringLit.withValues(alpha: (.46 + .14 * beat) * lit),
            _ringGold.withValues(alpha: .26 * lit),
            SkyColors.ink.withValues(alpha: .085 * lit),
            SkyColors.ink.withValues(alpha: 0),
          ],
          stops: const [0, .50, .80, 1],
        ).createShader(Rect.fromCircle(center: center, radius: glowR)),
    );

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(.10);
    final outer = Rect.fromCenter(
      center: Offset.zero,
      width: h * .128,
      height: h * .160,
    );
    // Sliding the opening toward the far rim leaves a fat near side and a
    // thin far one, which is the whole depth cue at this size.
    final hole = Rect.fromCenter(
      center: Offset(h * .004, 0),
      width: h * .092,
      height: h * .120,
    );

    final ping = reducedMotion ? .72 : (sim.elapsed * .85 + ring.x * .6) % 1;
    canvas.drawOval(
      outer.inflate(h * (.002 + ping * .026)),
      Paint()
        ..color = _ringLit.withValues(
          alpha: math.sin(ping * math.pi) * (lead ? .6 : .3),
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * .006 * (1 - ping) + 1,
    );

    // The bore lies in the near rim's shade, which keeps the opening
    // separate from the rim whatever happens to be drifting behind it.
    canvas.drawOval(
      hole,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-.55, -.45),
          radius: 1.15,
          colors: [
            SkyColors.ink.withValues(alpha: .22),
            SkyColors.ink.withValues(alpha: .07),
            SkyColors.ink.withValues(alpha: 0),
          ],
          stops: const [0, .62, 1],
        ).createShader(hole),
    );
    canvas.drawPath(
      Path()
        ..addOval(outer)
        ..addOval(hole)
        ..fillType = PathFillType.evenOdd,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment(-.95, -.7),
          end: Alignment(1, .55),
          colors: [_ringCore, _ringLit, _ringGold, _ringDeep],
          stops: [0, .22, .58, 1],
        ).createShader(outer),
    );
    // Two clamps on the rim: the gate is built, not minted.
    final clamp = Paint()..color = _ringDeep;
    final pin = Paint()..color = _ringLit;
    final clampInk = Paint()
      ..color = SkyColors.ink.withValues(alpha: .74)
      ..style = PaintingStyle.stroke
      ..strokeWidth = h * .0042;
    for (final side in const [-1.0, 1.0]) {
      final at = Offset(h * .002, side * h * .0715);
      final node = RRect.fromRectAndRadius(
        Rect.fromCenter(center: at, width: h * .030, height: h * .018),
        Radius.circular(h * .007),
      );
      canvas.drawRRect(node, clamp);
      canvas.drawRRect(node, clampInk);
      canvas.drawCircle(at, h * .0045, pin);
    }
    final ink = Paint()
      ..color = SkyColors.ink.withValues(alpha: .84)
      ..style = PaintingStyle.stroke
      ..strokeWidth = h * .0076;
    canvas.drawOval(outer, ink);
    canvas.drawOval(hole, ink..strokeWidth = h * .0052);

    // Inside the bore: the near rim shades the top of the opening, the far
    // rim catches the light along the bottom.
    canvas.drawArc(
      hole.deflate(h * .004),
      3.35,
      2.3,
      false,
      Paint()
        ..color = _ringDeep.withValues(alpha: .52)
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * .009
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawArc(
      hole.deflate(h * .004),
      .45,
      1.5,
      false,
      Paint()
        ..color = SkyColors.white.withValues(alpha: .5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * .005
        ..strokeCap = StrokeCap.round,
    );
    // The lit edge of the near rim.
    final rim = Rect.fromCenter(
      center: Offset(h * .002, 0),
      width: h * .110,
      height: h * .140,
    );
    canvas.drawArc(
      rim,
      3.55,
      1.0,
      false,
      Paint()
        ..color = SkyColors.white.withValues(alpha: .9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * .0065
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawArc(
      rim,
      .85,
      .5,
      false,
      Paint()
        ..color = SkyColors.white.withValues(alpha: .34)
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * .004
        ..strokeCap = StrokeCap.round,
    );

    final orbit = reducedMotion ? -1.15 : sim.elapsed * 2.4 + ring.x * 2;
    for (var k = 0; k < 2; k++) {
      final a = orbit + k * math.pi;
      final twinkle = reducedMotion
          ? .45 + .35 * _hash(k, 3)
          : .5 + .5 * math.sin(sim.elapsed * 7 + k * 2.1 + ring.x);
      canvas.drawPath(
        SkyScenery.star(
          Offset(math.cos(a) * h * .056, math.sin(a) * h * .071),
          h * (.005 + .005 * twinkle),
        ),
        Paint()..color = SkyColors.white.withValues(alpha: .45 + .55 * twinkle),
      );
    }
    canvas.restore();

    if (!lead) return;
    final slide = reducedMotion ? .55 : (sim.elapsed * 1.7 + ring.x) % 1;
    for (var i = 0; i < 2; i++) {
      final phase = (slide + i * .5) % 1;
      final x = center.dx - h * (.104 - phase * .032);
      final alpha = math.sin(phase * math.pi);
      final arm = h * .026;
      final dart = Path()
        ..moveTo(x - arm * .45, center.dy - arm)
        ..lineTo(x + arm * .45, center.dy)
        ..lineTo(x - arm * .45, center.dy + arm);
      canvas.drawPath(
        dart,
        Paint()
          ..color = SkyColors.ink.withValues(alpha: alpha * .5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = h * .017
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
      canvas.drawPath(
        dart,
        Paint()
          ..color = _ringCore.withValues(alpha: alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = h * .0085
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }
  }

  /// The gate blowing apart where it stood: a white flash, then the rim
  /// itself breaking into chunks that fly out and thin away. The bird's own
  /// bow wave goes off around it, so the two read as one hit.
  static void _ringPop(
    Canvas canvas,
    double h,
    Offset center,
    double age,
    bool reducedMotion,
  ) {
    if (age < 0 || age >= _ringPopSeconds) return;
    final s = age / _ringPopSeconds;
    final grow = reducedMotion ? .38 : 1 - (1 - s) * (1 - s) * (1 - s);
    final fade = (1 - s) * (1 - s * .5) * 1.4;

    final flash = (1 - s / .34).clamp(0.0, 1.0);
    if (flash > 0) {
      final r = h * (.055 + .13 * (1 - flash));
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..shader = RadialGradient(
            colors: [
              SkyColors.white.withValues(alpha: flash),
              _ringLit.withValues(alpha: flash * .85),
              _ringGold.withValues(alpha: flash * .25),
              _ringGold.withValues(alpha: 0),
            ],
            stops: const [0, .34, .68, 1],
          ).createShader(Rect.fromCircle(center: center, radius: r)),
      );
      // The line the bird took through the gate.
      final streak = Rect.fromCenter(
        center: center,
        width: h * (.14 + .34 * (1 - flash)),
        height: h * (.058 * flash + .012),
      );
      canvas.drawOval(
        streak,
        Paint()
          ..shader = RadialGradient(
            colors: [
              SkyColors.white.withValues(alpha: flash * .9),
              _ringLit.withValues(alpha: flash * .5),
              _ringLit.withValues(alpha: 0),
            ],
            stops: const [0, .5, 1],
          ).createShader(streak),
      );
    }

    // Six pieces of rim on the hoop's own ellipse, opening out as they go.
    final burst = Rect.fromCenter(
      center: center,
      width: h * .128 * (1 + grow * .85),
      height: h * .160 * (1 + grow * .70),
    );
    final sweep = .80 - grow * .42;
    final spin = .28 + grow * .5;
    final ink = Paint()
      ..color = SkyColors.ink.withValues(alpha: (fade * .45).clamp(0.0, 1.0))
      ..style = PaintingStyle.stroke
      ..strokeWidth = h * (.028 - grow * .010)
      ..strokeCap = StrokeCap.round;
    final chunk = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = h * (.021 - grow * .008)
      ..strokeCap = StrokeCap.round;
    for (var k = 0; k < 6; k++) {
      canvas.drawArc(burst, k * math.pi / 3 + spin, sweep, false, ink);
    }
    for (var k = 0; k < 6; k++) {
      canvas.drawArc(
        burst,
        k * math.pi / 3 + spin,
        sweep,
        false,
        chunk
          ..color = (k.isEven ? _ringLit : _ringGold).withValues(
            alpha: fade.clamp(0.0, 1.0),
          ),
      );
    }

    final sparkFade = (1 - s * 1.45).clamp(0.0, 1.0);
    if (sparkFade > 0) {
      for (var k = 0; k < 5; k++) {
        final a = k * math.pi * 2 / 5 - .42;
        final reach = h * (.05 + .17 * grow);
        canvas.drawPath(
          SkyScenery.star(
            center +
                Offset(math.cos(a) * reach * .9, math.sin(a) * reach * 1.15),
            h * .012 * sparkFade,
          ),
          Paint()..color = SkyColors.white.withValues(alpha: sparkFade),
        );
      }
    }
  }

  /// Burning rocks read at a glance: a dark, hot-edged body sitting on the
  /// circle it really hits, and a flame that fades out along the line the
  /// rock is travelling. Above the screen a marker stands on the point
  /// where the next one will come through.
  static void meteors(
    Canvas canvas,
    Size size,
    FlightSimulation sim, {
    required bool reducedMotion,
  }) {
    final h = size.height, w = size.width;
    final scroll = sim.speed * sim.courseBoost;
    final radius = Meteor.radius * h;
    for (final m in sim.meteors) {
      // Launch velocities differ per meteor, so each keeps its own shape.
      final seed = (m.vy * 997).round();
      // The apparent path swings with the course: a sprinting bird meets
      // the same rock almost head on.
      final vx = m.vx - scroll, vy = m.vy;
      final speed = math.sqrt(vx * vx + vy * vy);
      final ahead = speed == 0
          ? const Offset(-.6, .8)
          : Offset(vx / speed, vy / speed);
      if (m.y < -Meteor.radius) {
        final enter = -m.y / vy;
        _meteorMarker(
          canvas,
          size,
          (m.x + vx * enter) * h,
          ahead,
          enter,
          radius,
          reducedMotion: reducedMotion,
        );
        continue;
      }
      final center = Offset(m.x * h, m.y * h);
      if (center.dx < -h * .5 || center.dx > w + h * .6) continue;
      final back = -ahead, side = Offset(-ahead.dy, ahead.dx);
      final tail = radius * (4.3 + math.min(2.9, speed * 1.7));
      final lick = reducedMotion ? seed * .6 : m.age * 5.5 + seed;
      // Heat hanging around the rock, so it separates from a dark barrier
      // as surely as it does from the sky.
      final halo = Rect.fromCircle(
        center: center + back * (radius * .35),
        radius: radius * 1.9,
      );
      canvas.drawRect(
        halo,
        Paint()
          ..shader = RadialGradient(
            colors: [
              _ember.withValues(alpha: .26),
              _deep.withValues(alpha: .13),
              _deep.withValues(alpha: 0),
            ],
            stops: const [0, .5, 1],
          ).createShader(halo),
      );
      // Nose, body and core of the flame, each shorter and hotter than the
      // one beneath it and every one transparent well before its own tip.
      for (final (near, far, width, reach, waver) in [
        (
          _ember.withValues(alpha: .30),
          _deep.withValues(alpha: .20),
          1.22,
          1.0,
          .55,
        ),
        (
          _flame.withValues(alpha: .70),
          _ember.withValues(alpha: .34),
          .86,
          .72,
          .38,
        ),
        (
          _core.withValues(alpha: .92),
          _flame.withValues(alpha: .50),
          .60,
          .42,
          .22,
        ),
      ]) {
        final tip = center + back * (tail * reach);
        final box = Rect.fromPoints(center, tip).inflate(radius * 2);
        canvas.drawPath(
          _meteorFlame(
            center,
            back,
            side,
            radius * width,
            tail * reach,
            waver * radius,
            lick,
          ),
          Paint()
            ..shader = LinearGradient(
              begin: _meteorAt(box, center),
              end: _meteorAt(box, tip),
              colors: [near, far, far.withValues(alpha: 0)],
              stops: const [0, .55, 1],
            ).createShader(box),
        );
      }
      // Embers shed off the flame and cool as they fall behind.
      final spark = Paint()..strokeCap = StrokeCap.round;
      for (var i = 0; i < 4; i++) {
        final age = reducedMotion
            ? .2 + _hash(seed, i + 20) * .7
            : (m.age * 1.8 + _hash(seed, i + 20)) % 1;
        final drift = (_hash(seed, i + 40) - .5) * .9 + math.sin(age * 6) * .2;
        final at =
            center + back * (tail * (.3 + age * .8)) + side * (radius * drift);
        canvas.drawLine(
          at,
          at + back * (radius * (.5 - age * .3)),
          spark
            ..strokeWidth = radius * (.12 - age * .07)
            ..color = (i.isEven ? _core : _flame).withValues(
              alpha: .85 * (1 - age),
            ),
        );
      }
      const faces = 8;
      final spin = reducedMotion ? seed * .5 : m.age * 4 + seed;
      final corner = <Offset>[
        for (var i = 0; i < faces; i++)
          center +
              Offset.fromDirection(
                spin +
                    i * math.pi * 2 / faces +
                    (_hash(seed, i + 7) - .5) * .56,
                radius * (.74 + _hash(seed, i) * .36),
              ),
      ];
      final rock = Path()..moveTo(corner[0].dx, corner[0].dy);
      for (var i = 1; i < faces; i++) {
        rock.lineTo(corner[i].dx, corner[i].dy);
      }
      rock.close();
      // The body is lit from the face it is falling into and charred behind,
      // so which way it is going reads even where the flame is thin.
      final shade = Rect.fromCircle(center: center, radius: radius);
      final front = Alignment(ahead.dx, ahead.dy);
      final behind = Alignment(back.dx, back.dy);
      canvas.drawPath(
        rock,
        Paint()
          ..shader = LinearGradient(
            begin: front,
            end: behind,
            colors: const [
              _meteorGlow,
              _meteorRim,
              _rock,
              _meteorBody,
              _meteorChar,
            ],
            stops: const [0, .08, .26, .60, 1],
          ).createShader(shade),
      );
      // One cut plane in the shadow, quiet enough to stay texture: the
      // body gradient is what lights the rock.
      final j = seed % faces;
      final a = corner[j], b = corner[(j + 1) % faces];
      final inner = center + (a + b - center * 2) * .3;
      canvas.drawPath(
        Path()
          ..moveTo(a.dx, a.dy)
          ..lineTo(b.dx, b.dy)
          ..lineTo(inner.dx, inner.dy)
          ..close(),
        Paint()..color = _rockLight.withValues(alpha: .26),
      );
      // One crack wandering across the body: two marks this size would
      // pair up and read as a face.
      const bends = [(.4, .66), (1.6, .28), (2.8, .38), (4.0, .60)];
      final vein = Path();
      for (var i = 0; i < bends.length; i++) {
        final (turn, reach) = bends[i];
        final p = center + Offset.fromDirection(spin + turn, radius * reach);
        i == 0 ? vein.moveTo(p.dx, p.dy) : vein.lineTo(p.dx, p.dy);
      }
      final seam = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(
        vein,
        seam
          ..color = _magma
          ..strokeWidth = radius * .095,
      );
      canvas.drawPath(
        vein,
        seam
          ..color = _flame.withValues(alpha: .85)
          ..strokeWidth = radius * .036,
      );
      canvas.drawPath(
        rock,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = radius * .14
          ..strokeJoin = StrokeJoin.round
          ..shader = LinearGradient(
            begin: front,
            end: behind,
            colors: [
              _meteorRim,
              _ember,
              SkyColors.ink.withValues(alpha: .80),
              SkyColors.ink.withValues(alpha: .85),
            ],
            stops: const [0, .14, .34, 1],
          ).createShader(shade),
      );
    }
  }

  static const _meteorGlow = Color(0xffff9a52), _meteorRim = Color(0xffffc27a);
  static const _meteorBody = Color(0xff4e3c59);
  static const _meteorChar = Color(0xff231b31);

  /// Where a point falls inside a box, as a gradient alignment, so a shader
  /// can run along any line rather than along the box's own axes.
  static Alignment _meteorAt(Rect box, Offset p) => Alignment(
    (p.dx - box.center.dx) / (box.width / 2),
    (p.dy - box.center.dy) / (box.height / 2),
  );

  /// The flame envelope: a round nose wrapping the rock, then a taper that
  /// licks to one side, so the trail reads as fire rather than as a cone.
  static Path _meteorFlame(
    Offset center,
    Offset back,
    Offset side,
    double width,
    double length,
    double waver,
    double phase,
  ) {
    const steps = 12;
    final path = Path()
      ..moveTo(center.dx + side.dx * width, center.dy + side.dy * width)
      ..arcTo(
        Rect.fromCircle(center: center, radius: width),
        side.direction,
        -math.pi,
        false,
      );
    for (var pass = 0; pass < 2; pass++) {
      for (var k = 1; k <= steps; k++) {
        final i = pass == 0 ? k : steps - k;
        final t = i / steps;
        final girth =
            math.pow(1 - t, 1.3) *
            (1 + .3 * t * math.sin(t * 13 + phase)) *
            (pass == 0 ? -1 : 1);
        final sway = math.sin(t * 4.6 + phase) * waver * t;
        final p = center + back * (length * t) + side * (sway + girth * width);
        path.lineTo(p.dx, p.dy);
      }
    }
    return path..close();
  }

  /// Telegraphs a rock still above the screen. The arrow stands on the spot
  /// where it will come through and points the way it is going, over a hot
  /// smear on the sky it is falling out of. The flash is timed off the
  /// seconds left rather than off the clock, so it quickens all the way in
  /// and says how much of the warning is spent.
  static void _meteorMarker(
    Canvas canvas,
    Size size,
    double x,
    Offset ahead,
    double enter,
    double radius, {
    required bool reducedMotion,
  }) {
    final h = size.height, w = size.width;
    final soon = (1 - enter / .6).clamp(0.0, 1.0);
    final blink = reducedMotion
        ? 1.0
        : .60 + .40 * math.sin(enter * (15 * enter - 40));
    final side = Offset(-ahead.dy, ahead.dx);
    final head = Offset(
      x + ahead.dx / math.max(ahead.dy, .2) * h * .055,
      h * .055,
    );
    if (math.max(x, head.dx) < 0 || math.min(x, head.dx) > w) return;
    final flare = h * (.055 + .085 * soon);
    final sky = Rect.fromCircle(center: Offset(x, 0), radius: flare);
    canvas.drawCircle(
      sky.center,
      flare,
      Paint()
        ..shader = RadialGradient(
          colors: [
            _ember.withValues(alpha: (.16 + .38 * soon) * blink),
            _ember.withValues(alpha: 0),
          ],
        ).createShader(sky),
    );
    final from = head - ahead * (h * (.09 + .07 * soon));
    final wide = radius * .8;
    final box = Rect.fromPoints(from, head).inflate(radius * 2);
    canvas.drawPath(
      Path()
        ..moveTo(from.dx, from.dy)
        ..lineTo(head.dx + side.dx * wide, head.dy + side.dy * wide)
        ..lineTo(head.dx - side.dx * wide, head.dy - side.dy * wide)
        ..close(),
      Paint()
        ..shader = LinearGradient(
          begin: _meteorAt(box, from),
          end: _meteorAt(box, head),
          colors: [
            _flame.withValues(alpha: 0),
            _ember.withValues(alpha: (.34 + .48 * soon) * blink),
          ],
        ).createShader(box),
    );
    final arm = h * (.026 + .026 * soon);
    final tip = head + ahead * arm;
    final base = head - ahead * (arm * .48);
    final barb = side * (arm * .62);
    final notch = head - ahead * (arm * .28);
    final arrow = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(base.dx + barb.dx, base.dy + barb.dy)
      ..lineTo(notch.dx, notch.dy)
      ..lineTo(base.dx - barb.dx, base.dy - barb.dy)
      ..close();
    // Hot at the point, like the rock it stands for.
    final glow = Rect.fromPoints(tip, base).inflate(arm);
    final lit = (.60 + .40 * soon) * (.64 + .36 * blink);
    canvas.drawPath(
      arrow,
      Paint()
        ..shader = LinearGradient(
          begin: _meteorAt(glow, tip),
          end: _meteorAt(glow, base),
          colors: [
            _core.withValues(alpha: lit),
            _flame.withValues(alpha: lit),
            _ember.withValues(alpha: lit),
          ],
          stops: const [0, .35, 1],
        ).createShader(glow),
    );
    canvas.drawPath(
      arrow,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * .0055
        ..strokeJoin = StrokeJoin.round
        ..color = SkyColors.ink.withValues(alpha: .5 + .4 * soon),
    );
  }

  static const _ventRock = Color(0xff5e4759), _ventRockLit = Color(0xffa5879e);
  static const _ventCrust = Color(0xff7a2214);

  /// The lava column read across its width: a cooling crust at either rim,
  /// molten red inside that and a white-hot throat down the middle. One
  /// gradient instead of stacked bands, so nothing reads as a stripe.
  static const _ventHeat = [
    _ventCrust,
    _magma,
    _deep,
    _ember,
    _flame,
    _core,
    _flame,
    _ember,
    _deep,
    _magma,
    _ventCrust,
  ];
  static const _ventHeatStops = [
    0.0,
    .07,
    .18,
    .32,
    .43,
    .5,
    .57,
    .68,
    .82,
    .93,
    1.0,
  ];

  /// A basalt cone on the lower edge. While a vent rumbles, two rails and a
  /// bracket mark out the exact column its lava will fill and how high it
  /// will reach, and heat climbs the shaft as the fuse burns down; then the
  /// lava fills that column, crown and all.
  static void vents(
    Canvas canvas,
    Size size,
    FlightSimulation sim, {
    required bool reducedMotion,
  }) {
    final h = size.height, w = size.width;
    final t = reducedMotion ? 0.0 : sim.elapsed;
    final ink = Paint()
      ..color = SkyColors.ink.withValues(alpha: .75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = h * .005
      ..strokeJoin = StrokeJoin.round;
    for (final vent in sim.lavaVents) {
      final cx = vent.x * h, half = h * LavaVent.width / 2;
      if (cx < -h * .5 || cx > w + h * .5) continue;
      final seed = (vent.top * 1373).round();
      final cone = h * .09, base = half * 2.8, lip = half * 1.25;
      final mouthY = h - cone * .8;
      final fuse = vent.fuseEndsAt;
      final warn = fuse == null || !vent.rumbling
          ? 0.0
          : (1 - (fuse - sim.elapsed) / Rush.ventFuse).clamp(0.0, 1.0);
      final rise = vent.plume(sim.elapsed);
      // The crater stays lit through the blast and cools off afterwards.
      final cooling = vent.eruptedAt == null
          ? 0.0
          : ((sim.elapsed - vent.eruptedAt! - Rush.plumeSeconds) / .9).clamp(
              0.0,
              1.0,
            );
      final heat = math.max(rise, vent.eruptedAt == null ? warn : 1 - cooling);

      if (vent.rumbling) {
        final topY = vent.top * h;
        final span = mouthY - topY;
        final mark = _smooth(warn / .08);
        final beat = reducedMotion
            ? 1.0
            : .74 + .26 * math.sin(sim.elapsed * (9 + 13 * warn));
        // Heat climbing the shaft; it reaches the bracket as the fuse ends.
        final fill = Rect.fromLTRB(
          cx - half,
          mouthY - span * _smooth(warn),
          cx + half,
          mouthY,
        );
        if (fill.height > 1) {
          canvas.drawRect(
            fill,
            Paint()
              ..shader = LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  _core.withValues(alpha: .55 * beat),
                  _ember.withValues(alpha: .58 * beat),
                  _deep.withValues(alpha: .52 * beat),
                ],
                stops: const [0, .35, 1],
              ).createShader(fill),
          );
          canvas.drawLine(
            Offset(cx - half, fill.top),
            Offset(cx + half, fill.top),
            Paint()
              ..color = _core.withValues(alpha: .95 * beat)
              ..strokeWidth = h * .007
              ..strokeCap = StrokeCap.round,
          );
        }
        final rails = Path();
        final rungs = math.max(3, (span / (h * .05)).round());
        for (var i = 0; i < rungs; i++) {
          final a = topY + span * i / rungs;
          final b = a + span / rungs * .5;
          rails
            ..moveTo(cx - half, a)
            ..lineTo(cx - half, b)
            ..moveTo(cx + half, a)
            ..lineTo(cx + half, b);
        }
        canvas.drawPath(
          rails,
          Paint()
            ..color = _deep.withValues(alpha: (.46 + .40 * warn) * mark)
            ..style = PaintingStyle.stroke
            ..strokeWidth = h * .007
            ..strokeCap = StrokeCap.round,
        );
        final chevron = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = h * .008
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;
        for (var i = 0; i < 3; i++) {
          final climb = (t * 1.4 + i / 3) % 1;
          final y = mouthY - span * climb;
          chevron.color = _ember.withValues(
            alpha: mark * (.35 + .65 * math.sin(climb * math.pi)),
          );
          canvas.drawPath(
            Path()
              ..moveTo(cx - half * .6, y + half * .44)
              ..lineTo(cx, y - half * .16)
              ..lineTo(cx + half * .6, y + half * .44),
            chevron,
          );
        }
        final tick = Paint()
          ..color = _deep.withValues(alpha: .8 * mark)
          ..strokeWidth = h * .007
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(
          Offset(cx - half, topY),
          Offset(cx - half, topY + h * .03),
          tick,
        );
        canvas.drawLine(
          Offset(cx + half, topY),
          Offset(cx + half, topY + h * .03),
          tick,
        );
        final bar = RRect.fromRectAndRadius(
          Rect.fromLTRB(cx - half, topY - h * .008, cx + half, topY + h * .008),
          Radius.circular(h * .008),
        );
        canvas.drawRRect(
          bar,
          Paint()..color = _deep.withValues(alpha: .92 * mark * beat),
        );
        canvas.drawRRect(
          bar,
          Paint()
            ..color = SkyColors.ink.withValues(alpha: .7 * mark)
            ..style = PaintingStyle.stroke
            ..strokeWidth = h * .004,
        );
      }

      if (rise > 0) {
        final topY = vent.plumeTop(sim.elapsed) * h;
        final foot = h + h * .03;
        final crown = math.min(half * 1.1, (foot - topY) * .20);
        // A jet, not a tube: lumps of molten rock ride up either side and
        // the whole column sways, but it always fills its hit box and
        // never reaches past it.
        double ripple(int lane, double s) {
          final cell = s.floorToDouble();
          final a = _hash(lane, cell.toInt()),
              b = _hash(lane, cell.toInt() + 1);
          return a + (b - a) * _smooth(s - cell) - .5;
        }

        double lean(double u) =>
            math.sin(u * 1.9 + t * 2.6 + seed) * half * .04 * u;

        double edge(double u, int lane) {
          final spread = .84 + .06 * _smooth(u * 3);
          final lump =
              ripple(lane, u * 2.6 - t * 2.0) * .50 +
              ripple(lane + 3, u * 7.4 - t * 3.6) * .18;
          return (spread + lump * math.min(1, u * 4)).clamp(.72, .96);
        }

        Path body() {
          final shoulder = topY + crown;
          final reach = foot - shoulder;
          const rows = 16;
          final path = Path()..moveTo(cx - half * edge(0, 0), foot);
          for (var i = 1; i <= rows; i++) {
            final u = i / rows;
            path.lineTo(cx + lean(u) - half * edge(u, 0), foot - reach * u);
          }
          final left = cx + lean(1) - half * edge(1, 0);
          final right = cx + lean(1) + half * edge(1, 7);
          // Three tongues of lava split by narrow tears. One licks up to
          // the hit box top; the rest fall short of it.
          const tips = 7;
          final tall = 2 * (1 + seed % 3) - 1;
          var px = left, py = shoulder;
          for (var j = 1; j < tips; j++) {
            final x =
                left +
                (right - left) * (j + _hash(seed, j + 21) * .5 - .25) / 6.6;
            final high = j.isOdd;
            final k = j == tall
                ? 1.0
                : high
                ? .34 + _hash(seed, j + 11) * .34
                : -.14 * _hash(seed, j + 31);
            final y = shoulder - crown * k;
            path.quadraticBezierTo(high ? px : x, high ? y : py, x, y);
            px = x;
            py = y;
          }
          path.quadraticBezierTo(right, py, right, shoulder);
          for (var i = rows; i >= 0; i--) {
            final u = i / rows;
            path.lineTo(cx + lean(u) + half * edge(u, 7), foot - reach * u);
          }
          return path..close();
        }

        // Light spilling onto the sky, and a brighter bloom at the crown.
        final bloom = Rect.fromLTRB(
          cx - half * 2.9,
          topY - half * 2.4,
          cx + half * 2.9,
          h + half * 2,
        );
        canvas.drawRect(
          bloom,
          Paint()
            ..shader = RadialGradient(
              colors: [
                _flame.withValues(alpha: .58 * rise),
                _ember.withValues(alpha: .26 * rise),
                _ember.withValues(alpha: 0),
              ],
              stops: const [0, .40, 1],
            ).createShader(bloom),
        );
        final halo = Rect.fromCircle(
          center: Offset(cx, topY + half * .6),
          radius: half * 2.8,
        );
        canvas.drawRect(
          halo,
          Paint()
            ..shader = RadialGradient(
              colors: [
                _core.withValues(alpha: .55 * rise),
                _flame.withValues(alpha: .24 * rise),
                _flame.withValues(alpha: 0),
              ],
              stops: const [0, .42, 1],
            ).createShader(halo),
        );
        // Grey smoke rolling off the crown: the air above the lava reads
        // as the way through, not as more of the hazard.
        for (var i = 0; i < 3; i++) {
          final puff = (_hash(seed, i + 70) + t * .55) % 1;
          final wisp = Rect.fromCircle(
            center: Offset(
              cx + (_hash(seed, i + 72) - .5) * half * 1.6 * (.35 + puff),
              topY - puff * half * 1.9,
            ),
            radius: half * (.4 + puff * .9),
          );
          canvas.drawOval(
            wisp,
            Paint()
              ..shader = RadialGradient(
                colors: [
                  _smoke.withValues(alpha: .22 * rise * (1 - puff)),
                  _smoke.withValues(alpha: 0),
                ],
                stops: const [.25, 1],
              ).createShader(wisp),
          );
        }
        final shell = body();
        final across = Rect.fromLTRB(cx - half * .88, topY, cx + half * .88, h);
        canvas.drawPath(
          shell,
          Paint()
            ..shader = LinearGradient(
              colors: _ventHeat,
              stops: _ventHeatStops,
            ).createShader(across),
        );
        canvas.drawPath(
          shell,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                _core.withValues(alpha: .20),
                _flame.withValues(alpha: 0),
                _flame.withValues(alpha: .20),
              ],
              stops: const [0, .38, 1],
            ).createShader(across),
        );
        canvas.drawPath(
          shell,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                _magma.withValues(alpha: 0),
                _magma.withValues(alpha: .45),
              ],
              stops: const [0, .45],
            ).createShader(across)
            ..style = PaintingStyle.stroke
            ..strokeWidth = h * .0045
            ..strokeJoin = StrokeJoin.round,
        );
        // Gouts of fresh lava and slabs of cooling crust riding up the
        // flow, so a tall column never reads as a smooth pipe.
        canvas.save();
        canvas.clipPath(shell);
        for (var i = 0; i < 7; i++) {
          final crust = i % 3 == 2;
          final up =
              (_hash(seed, i * 3 + 1) + t * (.5 + _hash(seed, i) * .6)) % 1;
          final r = half * (crust ? .26 : .18) * (1 + _hash(seed, i + 9));
          final tint = crust
              ? _ventCrust
              : i.isEven
              ? _core
              : _flame;
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset(
                cx +
                    lean(up) +
                    (_hash(seed, i + 5) - .5) * half * (crust ? 1.5 : .7),
                h - (h - topY) * up,
              ),
              width: r * 2,
              height: r * (crust ? 3.4 : 4.4),
            ),
            Paint()
              ..color = tint.withValues(
                alpha: (crust ? .34 : .52) * (1 - up * .7),
              ),
          );
        }
        // Two seams of white-hot rock winding up the flow.
        final seam = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = half * .22
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;
        for (var i = 0; i < 2; i++) {
          final lane = 11 + i * 4;
          final wind = Path();
          for (var j = 0; j <= 8; j++) {
            final u = j / 8;
            final x =
                cx + lean(u) + ripple(lane, u * 3.1 - t * 2.2 + i) * half * 1.1;
            final y = h - (h - topY) * u;
            j == 0 ? wind.moveTo(x, y) : wind.lineTo(x, y);
          }
          seam.color = (i == 0 ? _core : _flame).withValues(alpha: .5);
          canvas.drawPath(wind, seam);
        }
        canvas.restore();
        if (!reducedMotion) {
          final age = sim.elapsed - vent.eruptedAt!;
          final spray = Paint();
          for (var i = 0; i < 5; i++) {
            final off = _hash(seed, i + 30);
            final fly = (t * (1.4 + off) + off * 3) % 1;
            final u = .25 + _hash(seed, i + 32) * .6;
            final side = i.isEven ? -1.0 : 1.0;
            spray.color = (i % 3 == 0 ? _flame : _ember).withValues(
              alpha: .85 * rise * (1 - fly),
            );
            canvas.drawCircle(
              Offset(
                cx + lean(u) + side * half * (.85 + fly * .95),
                topY + (h - topY) * (1 - u) + fly * fly * half * 2.2,
              ),
              half * (.09 + off * .09) * (1 - fly * .6),
              spray,
            );
          }
          for (var i = 0; i < 8; i++) {
            final vx = (_hash(seed, i + 40) - .5) * .95;
            final vy = -.26 - _hash(seed, i + 50) * .40;
            final drop = Offset(
              cx + vx * age * h,
              topY + crown * .45 + (vy * age + 1.9 * age * age) * h,
            );
            final r =
                h *
                (.005 + _hash(seed, i + 60) * .006) *
                (1 - age / Rush.plumeSeconds);
            if (drop.dy > h || r <= 0) continue;
            canvas.drawCircle(
              drop,
              r,
              Paint()..color = i.isEven ? _flame : _ember,
            );
          }
        }
      }

      final shake = reducedMotion || !vent.rumbling
          ? 0.0
          : math.sin(sim.elapsed * 46) * half * .06 * warn;
      // A chunky faceted cone: a lit flank, a shadowed one, and a crater
      // that stays warm between blasts.
      final rim = h - cone;
      final cone0 = Offset(cx - base + shake, h + 2);
      final cone1 = Offset(cx - base * .72 + shake, h - cone * .36);
      final cone2 = Offset(cx - lip * 1.3 + shake, h - cone * .84);
      final cone3 = Offset(cx - lip + shake, rim);
      final cone4 = Offset(cx + lip + shake, rim);
      final cone5 = Offset(cx + lip * 1.35 + shake, h - cone * .82);
      final cone6 = Offset(cx + base * .68 + shake, h - cone * .32);
      final cone7 = Offset(cx + base + shake, h + 2);
      final crater = Path()
        ..moveTo(cone0.dx, cone0.dy)
        ..lineTo(cone1.dx, cone1.dy)
        ..lineTo(cone2.dx, cone2.dy)
        ..lineTo(cone3.dx, cone3.dy)
        ..quadraticBezierTo(cx + shake, h - cone * .72, cone4.dx, cone4.dy)
        ..lineTo(cone5.dx, cone5.dy)
        ..lineTo(cone6.dx, cone6.dy)
        ..lineTo(cone7.dx, cone7.dy)
        ..close();
      canvas.drawPath(crater, Paint()..color = _ventRock);
      canvas.drawPath(
        Path()
          ..moveTo(cone0.dx, cone0.dy)
          ..lineTo(cone1.dx, cone1.dy)
          ..lineTo(cone2.dx, cone2.dy)
          ..lineTo(cone3.dx, cone3.dy)
          ..lineTo(cx - lip * .45 + shake, h - cone * .80)
          ..lineTo(cx - base * .36 + shake, h - cone * .30)
          ..lineTo(cx - base * .58 + shake, h + 2)
          ..close(),
        Paint()..color = _ventRockLit.withValues(alpha: .7),
      );
      canvas.drawPath(
        Path()
          ..moveTo(cone4.dx, cone4.dy)
          ..lineTo(cone5.dx, cone5.dy)
          ..lineTo(cone6.dx, cone6.dy)
          ..lineTo(cone7.dx, cone7.dy)
          ..lineTo(cx + base * .52 + shake, h + 2)
          ..lineTo(cx + base * .30 + shake, h - cone * .34)
          ..lineTo(cx + lip * .5 + shake, h - cone * .82)
          ..close(),
        Paint()..color = _basalt.withValues(alpha: .45),
      );
      // Seams left over from the last blast, banked up while a vent arms.
      canvas.drawPath(
        Path()
          ..moveTo(cx - lip * .8 + shake, h - cone * .78)
          ..lineTo(cx - lip * 1.05 + shake, h - cone * .46)
          ..lineTo(cx - base * .52 + shake, h - cone * .24)
          ..moveTo(cx + lip * .82 + shake, h - cone * .76)
          ..lineTo(cx + lip * 1.15 + shake, h - cone * .40),
        Paint()
          ..color = _ember.withValues(alpha: .30 + .55 * heat)
          ..style = PaintingStyle.stroke
          ..strokeWidth = h * .0045
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
      canvas.drawPath(crater, ink);
      final mouth = Rect.fromCenter(
        center: Offset(cx + shake, h - cone * .78),
        width: lip * 2.1,
        height: cone * .46,
      );
      canvas.drawOval(
        mouth,
        Paint()
          ..shader = RadialGradient(
            colors: [
              _core.withValues(alpha: (.5 + .5 * heat) * (1 - .8 * rise)),
              _ember.withValues(alpha: (.4 + .5 * heat) * (1 - .8 * rise)),
              _magma.withValues(alpha: (.35 + .4 * heat) * (1 - .6 * rise)),
            ],
            stops: const [0, .5, 1],
          ).createShader(mouth),
      );
      // The lip catches the light coming up out of the crater.
      canvas.drawLine(
        cone3,
        cone4,
        Paint()
          ..color = _flame.withValues(
            alpha: (.35 + .5 * heat) * (1 - .7 * rise),
          )
          ..strokeWidth = h * .004
          ..strokeCap = StrokeCap.round,
      );
      if (reducedMotion || !vent.rumbling) continue;
      for (var i = 0; i < 8; i++) {
        final life =
            (sim.elapsed * (1.9 + _hash(seed, i + 70) * 1.7) +
                _hash(seed, i + 80)) %
            1;
        final spread = (_hash(seed, i + 90) - .5) * half * 1.9;
        final r = half * .18 * (1 - life) * (.5 + warn);
        if (r <= 0) continue;
        canvas.drawCircle(
          Offset(
            cx + shake + spread * (.3 + life),
            mouthY - life * cone * (1.2 + 1.8 * warn),
          ),
          r,
          Paint()
            ..color = (i.isEven ? _flame : _core).withValues(
              alpha: (1 - life) * (.35 + .65 * warn),
            ),
        );
      }
    }
  }

  /// A charging bat of the same family as the shot enemies, but raked back
  /// into a dart: ears pinned flat, both wings swept behind the shoulders,
  /// one lit eye leading. Drawn on a canvas already scaled to its hit radius.
  /// [haze] sinks it into the dusk, for the bats further back in a flock.
  static void _swarmBat(
    Canvas c, {
    required bool route,
    required double sweep,
    required double aim,
    required double haze,
    required int seed,
  }) {
    Color sink(int value) =>
        Color.lerp(Color(value), const Color(0xffa295c8), haze)!;
    // The ink line barely fades: the silhouette has to hold even for the
    // bats sunk furthest into the dusk.
    final ink = Color.lerp(
      Color(route ? 0xff241a3e : 0xff2f2028),
      const Color(0xff5c5480),
      haze * .55,
    )!;
    final fur = sink(route ? 0xff4a3a7e : 0xff74463f);
    final furLight = sink(route ? 0xff9a80d6 : 0xffbb8367);
    final furDark = sink(route ? 0xff2c2154 : 0xff42262b);
    final skin = sink(route ? 0xffa68fdd : 0xffc9906f);
    final skinDark = sink(route ? 0xff644da3 : 0xff8b5548);
    final ear = sink(route ? 0xffcbaef0 : 0xffe0a890);
    final glint = sink(route ? 0xffffd878 : 0xffffc06a);
    final wake = route ? const Color(0xffe6ddff) : const Color(0xfff8d8bd);

    final outline = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = .105
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Speed streaks peel off the body itself, long enough to reach the bat
    // behind: three of them knit into one band of motion down the lane.
    final len = route ? 3.8 : 3.3;
    final stream = Paint()
      ..shader = LinearGradient(
        colors: [
          wake.withValues(alpha: .78 * (1 - haze)),
          wake.withValues(alpha: .48 * (1 - haze)),
          wake.withValues(alpha: 0),
        ],
        stops: const [0, .35, 1],
      ).createShader(Rect.fromLTRB(.7, -1, len, 1));
    for (var i = 0; i < 3; i++) {
      final y = -.42 + i * .44;
      final far = len * (i == 1 ? 1 : .5 + .3 * _hash(i, seed));
      final thick = i == 1 ? .21 : .13;
      c.drawPath(
        Path()
          ..moveTo(-.4, y - thick)
          ..quadraticBezierTo(far * .55, y - thick * .75, far, y)
          ..quadraticBezierTo(far * .55, y + thick * .75, -.4, y + thick)
          ..close(),
        stream,
      );
    }

    final bone = Paint()
      ..color = furLight.withValues(alpha: .6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = .05
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // The far wing runs the best part of a stroke behind the near one, so
    // the pair reads as two wings instead of one slab.
    c.save();
    c.translate(.06, -.22);
    c.scale(.84, .86);
    _swarmWing(
      c,
      _smooth(.5 + .5 * math.sin(sweep + 2.2)),
      skin: Paint()..color = skinDark,
      outline: outline,
      bone: bone,
      far: true,
    );
    c.restore();

    final body = Path()
      ..moveTo(-1.24, .06)
      ..quadraticBezierTo(-1.14, -.28, -.84, -.38)
      ..quadraticBezierTo(-.52, -.56, -.24, -.48)
      ..quadraticBezierTo(.3, -.5, .6, -.2)
      ..quadraticBezierTo(.8, .04, .58, .32)
      ..quadraticBezierTo(.24, .56, -.18, .5)
      ..quadraticBezierTo(-.66, .46, -.98, .3)
      ..quadraticBezierTo(-1.2, .22, -1.24, .06)
      ..close();
    // Ears raked flat along the back: a bat with its head down and running.
    for (final near in const [false, true]) {
      final lift = near ? 0.0 : -.14;
      final pinned = Path()
        ..moveTo(-.88 + (near ? 0 : .2), -.3 + lift)
        ..quadraticBezierTo(-.6, -.94 + lift, .12 + (near ? 0 : .2), -.86)
        ..quadraticBezierTo(-.42, -.5 + lift, -.54 + (near ? 0 : .2), -.24)
        ..close();
      c.drawPath(pinned, Paint()..color = near ? ear : furDark);
      c.drawPath(pinned, outline);
      if (!near) c.drawPath(body, Paint()..color = furDark);
    }
    c.drawPath(
      body,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [furLight, fur, furDark],
        ).createShader(const Rect.fromLTRB(-1.3, -.55, .9, .6)),
    );
    c.drawPath(body, outline);
    c.drawPath(
      Path()
        ..moveTo(-1.0, .2)
        ..quadraticBezierTo(-.46, .42, .14, .28)
        ..quadraticBezierTo(-.3, .56, -.96, .3)
        ..close(),
      Paint()..color = furLight.withValues(alpha: .5),
    );

    // Open muzzle with one fang, then the eye: the brightest mark on the
    // bat, so a player picks the gaps between faces at speed.
    c.drawPath(
      Path()
        ..moveTo(-1.22, .08)
        ..lineTo(-.78, .14)
        ..quadraticBezierTo(-.92, .4, -1.14, .28)
        ..close(),
      Paint()..color = ink,
    );
    c.drawPath(
      Path()
        ..moveTo(-1.1, .16)
        ..lineTo(-.96, .17)
        ..lineTo(-1.05, .31)
        ..close(),
      Paint()..color = SkyColors.cream,
    );
    final eye = Path()
      ..moveTo(-1.0, -.16)
      ..quadraticBezierTo(-.74, -.5, -.42, -.14)
      ..quadraticBezierTo(-.7, .08, -.94, -.02)
      ..close();
    c.drawPath(eye, Paint()..color = glint);
    c.save();
    c.clipPath(eye);
    c.drawOval(
      Rect.fromCenter(
        center: Offset(-.82, -.16 + aim * .09),
        width: .2,
        height: .32,
      ),
      Paint()..color = ink,
    );
    c.drawCircle(
      Offset(-.88, -.26 + aim * .06),
      .07,
      Paint()..color = SkyColors.cream,
    );
    c.restore();
    c.drawPath(eye, outline);

    _swarmWing(
      c,
      _smooth(.5 + .5 * math.sin(sweep)),
      skin: Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [skin, skinDark],
        ).createShader(const Rect.fromLTRB(-.3, -1.4, 1.7, 1.3)),
      outline: outline,
      bone: bone,
      far: false,
    );
  }

  /// One swept wing, pivoting at the shoulder so its shape holds through
  /// the stroke: a long arm to the wrist, then three fingers scalloping the
  /// membrane back toward the body. [beat] runs 0 at the top of the stroke
  /// to 1 at the bottom, and the wrist stays behind the shoulder
  /// throughout, which is what makes a swarm bat read as charging rather
  /// than hovering.
  static void _swarmWing(
    Canvas c,
    double beat, {
    required Paint skin,
    required Paint outline,
    required Paint bone,
    required bool far,
  }) {
    c.save();
    c.translate(-.16, -.32);
    c.rotate(-.66 + beat * 1.28);
    c.translate(.16, .32);
    final membrane = Path()
      ..moveTo(-.16, -.32)
      ..quadraticBezierTo(.24, -.64, .62, -.62)
      ..quadraticBezierTo(.98, -.74, 1.26, -.66)
      ..quadraticBezierTo(1.68, -.6, 1.94, -.32)
      // The membrane scallops between taut finger points.
      ..quadraticBezierTo(1.74, -.02, 1.52, .24)
      ..quadraticBezierTo(1.26, .1, 1.0, .5)
      ..quadraticBezierTo(.74, .28, .46, .52)
      ..quadraticBezierTo(.2, .32, -.02, .36)
      ..quadraticBezierTo(-.16, .04, -.16, -.32)
      ..close();
    c.drawPath(membrane, skin);
    c.drawPath(membrane, outline);
    if (!far) {
      c.drawPath(
        Path()
          ..moveTo(-.1, -.3)
          ..quadraticBezierTo(.26, -.6, .62, -.6)
          ..quadraticBezierTo(.98, -.7, 1.26, -.64)
          ..lineTo(1.94, -.32)
          ..moveTo(1.26, -.64)
          ..lineTo(1.52, .24)
          ..moveTo(1.26, -.64)
          ..lineTo(1.0, .5)
          ..moveTo(1.2, -.6)
          ..lineTo(.46, .52),
        bone,
      );
    }
    c.restore();
  }

  /// Bats racing down the route in flocks, trailing speed lines that knit
  /// into one band of motion. Flocks on the route are purple; flocks beside
  /// it are warm cave bats, so a glance says which lane is blocked.
  static void swarm(
    Canvas canvas,
    Size size,
    FlightSimulation sim, {
    required bool reducedMotion,
  }) {
    final h = size.height, w = size.width;
    final radius = h * SwarmBat.radius;
    SwarmBat? ahead;
    var rank = 0;
    for (final bat in sim.swarm) {
      // Flocks come a second apart and their members a tenth of a screen, so
      // a bat close behind the last one is flying in the same formation.
      rank =
          ahead == null ||
              ahead.lane != bat.lane ||
              (bat.x - ahead.x).abs() > Rush.flockSpacing * 1.8
          ? 0
          : math.min(rank + 1, Rush.flockSize - 1);
      ahead = bat;
      final center = Offset(bat.x * h, bat.y * h);
      if (center.dx < -h * .5 || center.dx > w + h * .5) continue;
      // A wingbeat runs back through the formation instead of every bat
      // flapping on its own; frozen, that stagger still poses them apart.
      final sweep = bat.phase - rank * .95 + (reducedMotion ? 0 : bat.age * 13);
      canvas.save();
      canvas.translate(center.dx, center.dy);
      final aim = ((sim.birdY - bat.y) * 3).clamp(-1.0, 1.0);
      // Hunting tilt: the flock angles onto the bird's height.
      canvas.rotate(-aim * .18);
      canvas.scale(radius * (1 - rank * .055));
      _swarmBat(
        canvas,
        route: bat.lane == 0,
        sweep: sweep,
        aim: aim,
        haze: rank * .17,
        seed: bat.phase.floor(),
      );
      canvas.restore();
    }
  }

  /// Sonic booms for ring pickups, a flare when fire or lava catches the
  /// bird, shattering rocks for smashed or shot meteors, and a burst for
  /// each swarm bat.
  static void effects(
    Canvas canvas,
    double h,
    FlightSimulation sim, {
    required bool reducedMotion,
  }) {
    final bird = Offset(FlightSimulation.birdX * h, sim.birdY * h);
    for (final event in sim.events) {
      final age = sim.elapsed - event.at;
      if (age < 0) continue;
      final seed = (event.at * 60).floor();
      switch (event.kind) {
        case FlightEventKind.sprintRing when age < _impactBoomSeconds:
          _impactSonic(canvas, h, bird, age, event.value, reducedMotion);
        case FlightEventKind.scorched when age < _impactBurnSeconds:
          _impactScorch(canvas, h, bird, age, seed, reducedMotion);
        case FlightEventKind.meteorSmashed when age < _impactShatterSeconds:
          _impactRubble(
            canvas,
            h,
            Offset((event.gateWorldX! - sim.distance) * h, event.y * h),
            age,
            seed,
            reducedMotion,
          );
        case FlightEventKind.swarmSmashed when age < EnemyDefeatArt.seconds:
          final at = Offset(
            (event.gateWorldX! - sim.distance) * h,
            event.y * h,
          );
          // Swarm bats go down like any bat: the same poof and fur, without
          // the small enemy's own figure. A chain value means a sprint ram.
          EnemyDefeatArt.paint(
            canvas,
            at,
            h * SwarmBat.radius,
            age: age,
            reducedMotion: reducedMotion,
            rammed: event.value > 0,
            kind: EnemyKind.simpleBat,
            ghost: false,
            seed: (event.at * 1000).round() + (event.y * 997).round(),
          );
          _impactPlow(canvas, h, at, age, seed, reducedMotion);
        default:
          break;
      }
    }
  }

  static const _impactBoomSeconds = .42, _impactBurnSeconds = .62;
  static const _impactShatterSeconds = .62, _impactPlowSeconds = .34;
  static const _impactSoot = Color(0xff3c2422);

  /// A slice of torn air: pointed at both ends, fattest just behind its
  /// leading tip, so it reads as a smear rather than a dash.
  static Path _impactSliver(double x, double y, double length, double weight) =>
      Path()
        ..moveTo(x, y)
        ..quadraticBezierTo(x + length * .3, y - weight, x + length, y)
        ..quadraticBezierTo(x + length * .3, y + weight, x, y)
        ..close();

  /// Air torn open at a pickup: a white pop, flat shocks that fall away
  /// behind the bird and a spray of slivers thrown back down the course.
  /// The chain count buys size, colour and more of everything, so a long
  /// chain is unmistakably bigger than a first ring.
  static void _impactSonic(
    Canvas canvas,
    double h,
    Offset bird,
    double age,
    int chain,
    bool reducedMotion,
  ) {
    final s = age / _impactBoomSeconds;
    final grade = ((chain - 1) / 5).clamp(0.0, 1.0);
    final scale = 1 + .8 * grade;
    final tone = Color.lerp(SkyColors.yellow, SkyColors.coralDeep, grade)!;
    for (var i = 0; i < 1 + math.min(chain - 1, 2); i++) {
      final grow = reducedMotion ? .4 + i * .16 : s - i * .15;
      if (grow <= .05 || grow >= 1) continue;
      final fade = 1 - grow;
      final width = h * (.16 + grow * .95 * scale);
      final height = width * (.4 - .12 * grow);
      canvas.drawOval(
        Rect.fromCenter(
          center: bird - Offset(width * .15, 0),
          width: width,
          height: height,
        ),
        Paint()
          ..color = (i == 0 ? SkyColors.white : tone).withValues(
            alpha: fade * (i == 0 ? .95 : .8),
          )
          ..style = PaintingStyle.stroke
          ..strokeWidth = height * (i == 0 ? .19 : .11) * fade + 1,
      );
    }
    if (reducedMotion) return;
    final flash = 1 - (age / .12).clamp(0.0, 1.0);
    if (flash > 0) {
      final open = (1 - flash) * (1 - flash);
      canvas.drawOval(
        Rect.fromCenter(
          center: bird - Offset(h * (.035 + .09 * open), 0),
          width: h * (.16 + .44 * open) * scale,
          height: h * (.13 + .09 * open),
        ),
        Paint()..color = SkyColors.white.withValues(alpha: flash * .34),
      );
    }
    final ease = 1 - (1 - s) * (1 - s);
    for (var i = 0; i < 5 + chain.clamp(1, 6) * 2; i++) {
      final u = _hash(i, chain), v = _hash(i + 17, chain);
      canvas.drawPath(
        _impactSliver(
          bird.dx - h * (.06 + .22 * ease * (.4 + .6 * u)),
          bird.dy + (v - .5) * h * (.16 + .5 * ease) * (.6 + .8 * grade),
          h * (.08 + .16 * u) * (1 - s),
          h * (.005 + .009 * v),
        ),
        Paint()
          ..color = Color.lerp(
            SkyColors.white,
            tone,
            u,
          )!.withValues(alpha: (1 - s) * (1 - s) * .95),
      );
    }
  }

  /// Getting burned. A ragged scorch mark with a dark rim reads over even a
  /// fire-lit sky, soot stays on the bird, and smoke hangs about after the
  /// flames are gone, so a catch is impossible to miss.
  static void _impactScorch(
    Canvas canvas,
    double h,
    Offset bird,
    double age,
    int seed,
    bool reducedMotion,
  ) {
    final s = age / _impactBurnSeconds;
    final fade = (1 - s) * (1 - s);
    final spread = reducedMotion ? .5 : 1 - math.pow(1 - s, 2.6).toDouble();
    final radius = h * (.055 + .09 * spread);
    // A ragged blot, stretched along the course and rimmed in soot so it
    // never reads as a tidy star on a fire-lit sky.
    final blot = Path();
    for (var i = 0; i < 14; i++) {
      final reach = radius * (.45 + .55 * _hash(i, seed));
      final angle = (i + .35 * _hash(i + 40, seed)) * math.pi / 7;
      final x = bird.dx + math.cos(angle) * reach * 1.45;
      final y = bird.dy + math.sin(angle) * reach * .95;
      if (i == 0) {
        blot.moveTo(x, y);
      } else {
        blot.lineTo(x, y);
      }
    }
    blot.close();
    canvas
      ..drawPath(blot, Paint()..color = _flame.withValues(alpha: fade * .5))
      ..drawPath(
        blot,
        Paint()
          ..color = _smoke.withValues(alpha: fade * .8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = h * .01 * fade + .9
          ..strokeJoin = StrokeJoin.round,
      )
      ..drawOval(
        Rect.fromCenter(center: bird, width: radius * 1.1, height: radius * .8),
        Paint()..color = _deep.withValues(alpha: fade * .45),
      );
    final soot = reducedMotion ? .2 : (1 - age / .4).clamp(0.0, 1.0) * .3;
    if (soot > 0) {
      canvas.drawOval(
        Rect.fromCenter(center: bird, width: h * .115, height: h * .1),
        Paint()..color = _impactSoot.withValues(alpha: soot),
      );
    }
    if (reducedMotion) {
      canvas.drawCircle(
        bird - Offset(h * .095, h * .06),
        h * .04,
        Paint()..color = _smoke.withValues(alpha: fade * .35),
      );
      return;
    }
    for (var i = 0; i < 6; i++) {
      final u = _hash(i, seed + 3), v = _hash(i + 9, seed + 3);
      canvas.drawPath(
        _impactSliver(
          bird.dx - h * (.04 + .32 * s * (.5 + .7 * u)),
          bird.dy + h * ((i - 2.5) * .022 - .26 * s * (.3 + v)),
          h * (.05 + .05 * u) * (1 - s),
          h * (.02 + .012 * v) * (1 - s),
        ),
        Paint()
          ..color = (i.isEven ? _flame : _core).withValues(alpha: (1 - s) * .9),
      );
    }
    for (var i = 0; i < 3; i++) {
      final u = _hash(i + 21, seed);
      canvas.drawCircle(
        Offset(
          bird.dx - h * (.06 + .34 * s * (.6 + u)),
          bird.dy - h * (.03 + .22 * s * (.4 + u)),
        ),
        h * (.022 + .05 * s),
        Paint()..color = _smoke.withValues(alpha: (1 - s) * .32),
      );
    }
  }

  /// A smashed meteor breaks into chunks that keep the ink outline of the
  /// rock they came from, under a flash and a puff of dust.
  static void _impactRubble(
    Canvas canvas,
    double h,
    Offset at,
    double age,
    int seed,
    bool reducedMotion,
  ) {
    final s = age / _impactShatterSeconds;
    final flash = reducedMotion ? 0.0 : 1 - (age / .1).clamp(0.0, 1.0);
    if (flash > 0) {
      final open = 1 - flash;
      canvas.drawOval(
        Rect.fromCenter(
          center: at,
          width: h * (.1 + .16 * open),
          height: h * (.09 + .07 * open),
        ),
        Paint()..color = _core.withValues(alpha: flash * .8),
      );
    }
    if (!reducedMotion) {
      for (var i = 0; i < 3; i++) {
        final u = _hash(i + 5, seed);
        canvas.drawCircle(
          Offset(
            at.dx - h * (.02 + .2 * s * (.5 + u)),
            at.dy - h * (.01 + .12 * s * u),
          ),
          h * (.025 + .055 * s),
          Paint()..color = _smoke.withValues(alpha: (1 - s) * .28),
        );
      }
    }
    final travel = reducedMotion ? .4 : 1 - (1 - s) * (1 - s) * (1 - s);
    final alpha = math.min(1.0, (1 - s) * 2.4);
    for (var i = 0; i < 6; i++) {
      final u = _hash(i, seed), v = _hash(i + 11, seed);
      final angle = i * math.pi / 3 + u * .8;
      final reach = h * (.02 + .16 * travel);
      final size = h * (.022 + .016 * v) * (reducedMotion ? .85 : 1 - s * .5);
      final shard = Path()
        ..moveTo(-size, -size * (.3 + .4 * u))
        ..lineTo(-size * .2, -size)
        ..lineTo(size * (.6 + .4 * v), -size * .3)
        ..lineTo(size * .75, size * .55)
        ..lineTo(-size * (.3 + .4 * v), size)
        ..close();
      canvas
        ..save()
        ..translate(
          at.dx + math.cos(angle) * (1.25 + .4 * v) * reach,
          at.dy + (math.sin(angle) + 1.7 * travel) * reach,
        )
        ..rotate(u * 6.2 + (reducedMotion ? 0 : travel * 4 * (v - .5)))
        ..drawPath(
          shard,
          Paint()
            ..color = (i.isEven ? _rockLight : _rock).withValues(alpha: alpha),
        )
        ..drawPath(
          shard,
          Paint()
            ..color = SkyColors.ink.withValues(alpha: alpha * .75)
            ..style = PaintingStyle.stroke
            ..strokeWidth = size * .2
            ..strokeJoin = StrokeJoin.round,
        )
        ..restore();
    }
    if (reducedMotion) return;
    for (var i = 0; i < 3; i++) {
      final u = _hash(i + 31, seed);
      final angle = -.9 + i * .9 + u * .5;
      final reach = h * (.04 + .22 * travel * (.6 + u));
      canvas.drawPath(
        _impactSliver(
          at.dx - math.cos(angle) * reach,
          at.dy + math.sin(angle) * reach * .6,
          h * (.04 + .05 * u) * (1 - s),
          h * .008,
        ),
        Paint()..color = _ember.withValues(alpha: (1 - s) * (1 - s) * .9),
      );
    }
  }

  /// The bow wave meets a bat head on, so its wreckage sweeps backwards
  /// instead of scattering evenly.
  static void _impactPlow(
    Canvas canvas,
    double h,
    Offset at,
    double age,
    int seed,
    bool reducedMotion,
  ) {
    final s = (age / _impactPlowSeconds).clamp(0.0, 1.0);
    if (s >= 1) return;
    final fade = (1 - s) * (1 - s);
    final spread = h * (.03 + .1 * s);
    canvas.drawPath(
      Path()
        ..moveTo(at.dx + spread * .9, at.dy)
        ..quadraticBezierTo(
          at.dx - spread * .2,
          at.dy - spread * .55,
          at.dx - spread * 1.3,
          at.dy - spread * 1.1,
        )
        ..moveTo(at.dx + spread * .9, at.dy)
        ..quadraticBezierTo(
          at.dx - spread * .2,
          at.dy + spread * .55,
          at.dx - spread * 1.3,
          at.dy + spread * 1.1,
        ),
      Paint()
        ..color = SkyColors.white.withValues(alpha: fade)
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * .014 * fade + .8
        ..strokeCap = StrokeCap.round,
    );
    if (reducedMotion) return;
    for (var i = 0; i < 4; i++) {
      final u = _hash(i, seed), v = _hash(i + 7, seed);
      final size = h * (.013 + .009 * v) * (1 - s);
      final shard = Path()
        ..moveTo(-size * 1.5, -size * .2)
        ..quadraticBezierTo(0, -size * 1.3, size * 1.4, -size * .3)
        ..lineTo(size * .3, size)
        ..close();
      canvas
        ..save()
        ..translate(
          at.dx - h * (.03 + .3 * s * (.5 + u)),
          at.dy + (v - .5) * h * (.05 + .22 * s),
        )
        ..rotate(u * 5 + s * 3 * (v - .5))
        ..drawPath(
          shard,
          Paint()..color = SkyColors.purple.withValues(alpha: (1 - s) * .9),
        )
        ..drawPath(
          shard,
          Paint()
            ..color = SkyColors.ink.withValues(alpha: (1 - s) * .7)
            ..style = PaintingStyle.stroke
            ..strokeWidth = size * .28
            ..strokeJoin = StrokeJoin.round,
        )
        ..restore();
    }
  }

  /// The wake: a smear tapering down the flown line with hard ghosts
  /// stepped along it. This is the clearest sign that the bird itself is
  /// moving fast, so it survives Reduced Motion — the smear is pinned to
  /// the path the bird really flew, not animated on a clock of its own.
  static void afterimages(
    Canvas canvas,
    double h,
    FlightSimulation sim, {
    required bool reducedMotion,
    required void Function(Offset center, double alpha, Color tint) paint,
  }) {
    final strength = ((sim.courseBoost - 1) / (Sprint.peakBoost - 1)).clamp(
      0.0,
      1.0,
    );
    if (strength <= .05) return;
    final over =
        ((sim.courseBoost - Sprint.peakBoost) /
                (RingSprint.peakBoost - Sprint.peakBoost))
            .clamp(0.0, 1.0);
    final points = sim.flightPath.recent.toList(growable: false);
    if (points.length < 3) return;
    final span = .3 * (.4 + .35 * strength + .25 * over);
    final line = <Offset>[], taper = <double>[];
    for (var i = 0; i < points.length; i += 3) {
      final point = points[i];
      final left = 1 - (sim.distance - point.distance) / span;
      line.add(
        Offset(
          (FlightSimulation.birdX + point.distance - sim.distance) * h,
          point.y * h,
        ),
      );
      taper.add(left.clamp(0.0, 1.0));
      if (left <= 0) break;
    }
    if (line.length < 3) return;

    Path smear(double width, int falloff) {
      final path = Path();
      for (var pass = 0; pass < 2; pass++) {
        for (var i = 0; i < line.length; i++) {
          final index = pass == 0 ? i : line.length - 1 - i;
          final u = taper[index];
          final half =
              width *
              (falloff == 1
                  ? u
                  : falloff == 2
                  ? u * u
                  : u * u * u) *
              (pass == 0 ? -1 : 1);
          final point = line[index];
          if (pass == 0 && i == 0) {
            path.moveTo(point.dx, point.dy + half);
          } else {
            path.lineTo(point.dx, point.dy + half);
          }
        }
      }
      return path..close();
    }

    // A smear of the bird's own colour: warm and solid at the core, pale at
    // the edge, so it carries over a hot sky and a cold one alike.
    final dim = reducedMotion ? .75 : 1.0;
    canvas
      ..drawPath(
        smear(h * .05, 1),
        Paint()
          ..color = SkyColors.cream.withValues(alpha: strength * .26 * dim),
      )
      ..drawPath(
        smear(h * .034, 1),
        Paint()
          ..color = Color.lerp(
            SkyColors.yellow,
            SkyColors.coral,
            over * .6,
          )!.withValues(alpha: strength * .45 * dim),
      )
      ..drawPath(
        smear(h * .018, 2),
        Paint()
          ..color = Color.lerp(
            SkyColors.gold,
            SkyColors.coral,
            over,
          )!.withValues(alpha: strength * .7 * dim),
      );

    // Newest ghost last, so the freshest copy sits over the older ones.
    final tint = Color.lerp(SkyColors.gold, SkyColors.coralDeep, over)!;
    const ghosts = [(.26, .45), (.5, .28), (.76, .15)];
    for (var i = (reducedMotion ? 2 : 3) - 1; i >= 0; i--) {
      final (place, alpha) = ghosts[i];
      final target = sim.distance - span * place;
      final point = points.firstWhere(
        (p) => p.distance <= target,
        orElse: () => points.last,
      );
      paint(
        Offset(
          (FlightSimulation.birdX + point.distance - sim.distance) * h,
          point.y * h,
        ),
        strength * alpha * dim,
        tint,
      );
    }
  }

  /// A knock rather than a wobble: every hit starts at full throw, mostly
  /// along the course, and rings down inside its own short life.
  static Offset cameraOffset(FlightSimulation sim, bool reducedMotion) {
    if (reducedMotion) return Offset.zero;
    var x = 0.0, y = 0.0;
    void knock(double age, double throwBack, double span, double seed) {
      if (!(age >= 0 && age < span)) return;
      final decay = (1 - age / span) * (1 - age / span);
      x -= throwBack * decay * math.cos(age * 74);
      y += throwBack * decay * math.sin(age * 58 + seed) * .42;
    }

    for (final event in sim.events) {
      final age = sim.elapsed - event.at;
      switch (event.kind) {
        case FlightEventKind.smashed ||
            FlightEventKind.meteorSmashed ||
            FlightEventKind.swarmSmashed ||
            FlightEventKind.enemyRammed:
          knock(age, .0085, .2, event.at);
        case FlightEventKind.scorched:
          knock(age, .017, .34, event.at);
        case FlightEventKind.sprintRing:
          knock(age, .0045 + .0012 * event.value.clamp(0, 5), .16, event.at);
        default:
          break;
      }
    }
    for (final vent in sim.lavaVents) {
      knock(
        sim.elapsed - (vent.eruptedAt ?? double.infinity),
        .006,
        .28,
        vent.x,
      );
    }
    return Offset(x.clamp(-.014, .014), y.clamp(-.0085, .0085));
  }

  // Deeper than the ink the world is outlined with: every accent, warm or
  // cool, has to shout off this plate over a pale sky.
  static const _bannerInk = Color(0xff14252e);
  static const _bannerLife = 1.9;
  static const _galeBlue = Color(0xff5bc0eb);

  /// Stands in for the gale card's orange "!" inside its translated line
  /// (`encounterGaleDetail`), so the mark is found wherever a language puts
  /// it.
  static const _galeMark = '\u{E000}';

  /// Announces a run and celebrates the escape and a run's every ring, above
  /// everything else.
  static void banner(
    Canvas canvas,
    Size size,
    FlightSimulation sim, {
    required bool reducedMotion,
  }) {
    var top = size.height * .115;
    final l = L10n.strings;
    for (final event in sim.events) {
      final age = sim.elapsed - event.at;
      if (age < 0 || age >= _bannerLife) continue;
      final String title, detail;
      final Color accent;
      final RushPathKind? motif;
      var wind = false;
      switch (event.kind) {
        case FlightEventKind.rushWarning:
          final kind = RushPathKind
              .values[event.value.clamp(0, RushPathKind.values.length - 1)];
          motif = kind;
          title = l.rushWarningTitle(kind);
          detail = l.rushWarningDetail(kind);
          accent = switch (kind) {
            RushPathKind.wildfire => SkyColors.coral,
            RushPathKind.skyfall => SkyColors.purple,
            RushPathKind.eruption => _ember,
            RushPathKind.swarm => SkyColors.teal,
          };
        case FlightEventKind.rushEscaped:
          final flawless = event.value > Rush.escapeBonus;
          motif = null;
          title = flawless
              ? l.encounterFlawless(event.value)
              : l.encounterRushEscaped(event.value);
          detail = l.rushEscapedDetail(
            sim.lastRushKind ?? RushPathKind.wildfire,
          );
          accent = SkyColors.gold;
        case FlightEventKind.galeWarning:
          motif = null;
          wind = true;
          title = l.encounterGale;
          detail = l.encounterGaleDetail(_galeMark);
          accent = _galeBlue;
        case FlightEventKind.galeWeathered:
          final flawless = event.value > Gale.weatherBonus;
          motif = null;
          title = flawless
              ? l.encounterFlawless(event.value)
              : l.encounterGaleWeathered(event.value);
          detail = l.encounterGaleWeatheredDetail;
          accent = SkyColors.gold;
        case FlightEventKind.allRings:
          // The value is in tenths of a second.
          final tenths = event.value;
          final seconds = tenths % 10 == 0
              ? '${tenths ~/ 10}'
              : (tenths / 10).toStringAsFixed(1);
          motif = null;
          title = l.encounterAllRings;
          detail = l.encounterAllRingsDetail(seconds);
          accent = SkyColors.yellow;
        default:
          continue;
      }
      // Stacking keeps a warning and an escape apart if they ever overlap.
      top +=
          _bannerCard(
            canvas,
            size,
            top: top,
            title: title,
            detail: detail,
            accent: accent,
            motif: motif,
            wind: wind,
            age: age,
            reducedMotion: reducedMotion,
          ) +
          size.height * .022;
    }
  }

  /// Draws one title card and returns the height it claimed.
  static double _bannerCard(
    Canvas canvas,
    Size size, {
    required double top,
    required String title,
    required String detail,
    required Color accent,
    required RushPathKind? motif,
    required double age,
    required bool reducedMotion,
    bool wind = false,
  }) {
    final h = size.height;
    final celebrating = motif == null && !wind;
    final fade = math.min(
      (age / .09).clamp(0.0, 1.0),
      _smooth((_bannerLife - age) / .28),
    );
    final land = _smooth(age / .2);
    final leave = _smooth((age - (_bannerLife - .28)) / .28);
    final reveal = reducedMotion ? 1.0 : _smooth((age - .03) / .2);
    final unfurl = reducedMotion ? 1.0 : _smooth(age / .18);
    // The plate holds its weight while the words dissolve, so the card never
    // spends its exit as a translucent smear over the sky.
    final solid = math.sqrt(fade);

    TextPainter type(
      String value,
      double points,
      FontWeight weight,
      Paint paint,
    ) => TextPainter(
      text: TextSpan(
        text: value,
        style: TextStyle(
          fontFamily: L10n.fonts.heading,
          fontFamilyFallback: L10n.fonts.headingFallback,
          fontWeight: weight,
          fontSize: points,
          letterSpacing: h * .002,
          foreground: paint,
        ),
      ),
      // Words run their language's way; the card stays where it is.
      textDirection: L10n.textDirection,
    )..layout();

    final titleSize = h * .09, detailSize = h * .038;
    // The title's shadow pass also measures it: the card is cut to its words.
    final shade = type(
      title,
      titleSize,
      FontWeight.w700,
      Paint()
        ..color = Color.lerp(accent, _bannerInk, .62)!.withValues(alpha: fade),
    );
    final detailPaint = Paint()
      ..color = SkyColors.cream.withValues(alpha: .94 * fade * reveal);
    final mark = wind ? detail.indexOf(_galeMark) : -1;
    final TextPainter line;
    if (mark < 0) {
      line = type(detail, detailSize, FontWeight.w600, detailPaint);
    } else {
      // The gale's "!" wears the warning's own orange, so the card teaches
      // the mark the player is about to watch for.
      TextStyle style(Paint paint, FontWeight weight) => TextStyle(
        fontFamily: L10n.fonts.heading,
        fontFamilyFallback: L10n.fonts.headingFallback,
        fontWeight: weight,
        fontSize: detailSize,
        letterSpacing: h * .002,
        foreground: paint,
      );
      line = TextPainter(
        text: TextSpan(
          style: style(detailPaint, FontWeight.w600),
          children: [
            TextSpan(text: detail.substring(0, mark)),
            TextSpan(
              text: '!',
              style: style(
                Paint()
                  ..color = GaleArt.warning.withValues(alpha: fade * reveal),
                FontWeight.w700,
              ),
            ),
            TextSpan(text: detail.substring(mark + _galeMark.length)),
          ],
        ),
        textDirection: L10n.textDirection,
      )..layout();
    }
    final glyph = h * .04, gap = h * .028;
    final cardW =
        math.max(shade.width + (glyph * 2 + gap) * 2, line.width) + h * .1;
    final cardH = shade.height + line.height + h * .062;
    final tail = h * .055;
    final fit = math.min(1.0, (size.width - h * .09) / (cardW + tail * 2));
    final wobble = reducedMotion || age < .2
        ? 0.0
        : math.sin((age - .2) * 25) * .022 * math.max(0, 1 - (age - .2) / .45);
    final pop = reducedMotion
        ? 1.0
        : (1.12 - .12 * land) * (1 + wobble) * (1 - .08 * leave);

    canvas.save();
    canvas.translate(
      size.width / 2,
      top + cardH * fit / 2 - (reducedMotion ? 0 : h * .055 * leave),
    );
    canvas.scale(fit * pop);
    final halfW = cardW / 2, halfH = cardH / 2;
    final plate = RRect.fromRectAndRadius(
      Rect.fromLTRB(-halfW, -halfH, halfW, halfH),
      Radius.circular(h * .03),
    );

    if (celebrating) {
      // A slow wheel of light behind the card: the escape is the payoff.
      canvas.save();
      canvas.scale(halfW * 2.3, halfH * 2.9);
      canvas.rotate(reducedMotion ? .12 : .12 + age * .38);
      final ray = Paint()..color = accent.withValues(alpha: .2 * fade);
      for (var i = 0; i < 12; i++) {
        final a = i * math.pi / 6;
        final reach = (i.isEven ? 1.0 : .68) * (reducedMotion ? 1 : land);
        canvas.drawPath(
          Path()
            ..moveTo(math.cos(a - .16) * .3, math.sin(a - .16) * .3)
            ..lineTo(math.cos(a) * reach, math.sin(a) * reach)
            ..lineTo(math.cos(a + .16) * .3, math.sin(a + .16) * .3)
            ..close(),
          ray,
        );
      }
      canvas.restore();
    }

    if (wind) {
      // Gusts stream past behind the card and out either side of it, the
      // way the gale is about to blow across the screen.
      final drift = reducedMotion ? 0.0 : age * h * .1 + (1 - land) * h * .08;
      final gust = Color.lerp(
        accent,
        _bannerInk,
        .2,
      )!.withValues(alpha: .85 * fade);
      for (final (i, (y, curl, lead)) in const [
        (-.62, -1, .05),
        (.06, 0, .11),
        (.66, 1, .02),
      ].indexed) {
        GaleArt.gust(
          canvas,
          Offset(-halfW - tail - h * lead - drift, halfH * y),
          halfW * 2 + tail * 2 + h * (.16 + lead),
          h * (i == 1 ? .0042 : .0052),
          gust,
          curl: curl == 0 ? 0 : h * .026,
          turn: curl,
          sway: i * 2.0,
        );
      }
    }

    final ribbon = halfH * .62 * unfurl;
    if (ribbon > 0) {
      for (final side in [-1.0, 1.0]) {
        final x = side * (halfW - h * .02);
        final reach = side * tail * unfurl;
        canvas.drawPath(
          Path()
            ..moveTo(x, -ribbon)
            ..lineTo(x + reach, -ribbon - h * .008)
            ..lineTo(x + reach - side * h * .022, 0)
            ..lineTo(x + reach, ribbon + h * .008)
            ..lineTo(x, ribbon)
            ..close(),
          Paint()..color = _bannerDeep(accent, .6).withValues(alpha: solid),
        );
        canvas.drawPath(
          Path()
            ..moveTo(x, -ribbon)
            ..lineTo(x + reach, -ribbon - h * .008)
            ..lineTo(x + reach, -ribbon + h * .006)
            ..lineTo(x, -ribbon + h * .014)
            ..close(),
          Paint()..color = _bannerDeep(accent, .88).withValues(alpha: solid),
        );
      }
    }

    canvas.drawRRect(
      plate.shift(Offset(0, h * .019)),
      Paint()..color = SkyColors.ink.withValues(alpha: .2 * solid),
    );
    // A coloured edge under the plate gives the card some thickness.
    canvas.drawRRect(
      plate.shift(Offset(0, h * .009)),
      Paint()..color = _bannerDeep(accent, .48).withValues(alpha: solid),
    );
    canvas.drawRRect(
      plate,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(_bannerInk, accent, .1)!.withValues(alpha: .97 * solid),
            _bannerInk.withValues(alpha: .97 * solid),
          ],
        ).createShader(plate.outerRect),
    );
    if (!reducedMotion) {
      // One sweep of light crosses the plate as it settles.
      final s = (age - .26) / .5;
      if (s > 0 && s < 1) {
        canvas.save();
        canvas.clipRRect(plate);
        final x = -halfW * 1.6 + s * cardW * 2.1;
        final glare = SkyColors.cream.withValues(
          alpha: .18 * fade * math.sin(s * math.pi),
        );
        canvas.drawPath(
          Path()
            ..moveTo(x, halfH)
            ..lineTo(x + h * .06, halfH)
            ..lineTo(x + h * .06 + halfH, -halfH)
            ..lineTo(x + halfH, -halfH)
            ..close(),
          Paint()
            ..shader = LinearGradient(
              colors: [
                glare.withValues(alpha: 0),
                glare,
                glare.withValues(alpha: 0),
              ],
            ).createShader(Rect.fromLTWH(x, -halfH, h * .06 + halfH, cardH)),
        );
        canvas.restore();
      }
    }
    final alert = reducedMotion
        ? 0.0
        : math.max(0.0, math.sin(age * 8)) * (1 - _smooth(age / 1.1));
    canvas.drawRRect(
      plate.deflate(h * .005),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * .008
        ..color = Color.lerp(
          accent,
          SkyColors.cream,
          .3 * alert,
        )!.withValues(alpha: solid),
    );
    canvas.drawRRect(
      plate.deflate(h * .017),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * .0025
        ..color = SkyColors.cream.withValues(alpha: .18 * solid),
    );

    final titleTop = -halfH + h * .028;
    final punch = reducedMotion ? 1.0 : 1 + .16 * (1 - _smooth(age / .22));
    canvas.save();
    canvas.translate(0, titleTop + shade.height / 2);
    canvas.scale(punch);
    canvas.translate(0, -titleTop - shade.height / 2);
    shade.paint(canvas, Offset(-shade.width / 2, titleTop + h * .008));
    type(
      title,
      titleSize,
      FontWeight.w700,
      Paint()
        ..shader =
            LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                _bannerDeep(accent, 1.34).withValues(alpha: fade),
                accent.withValues(alpha: fade),
              ],
              stops: const [0, .82],
            ).createShader(
              Rect.fromLTWH(
                -shade.width / 2,
                titleTop,
                shade.width,
                shade.height,
              ),
            ),
    ).paint(canvas, Offset(-shade.width / 2, titleTop));
    canvas.restore();
    line.paint(
      canvas,
      Offset(
        -line.width / 2,
        titleTop + shade.height + h * .006 + (1 - reveal) * h * .022,
      ),
    );

    final grow = reducedMotion ? 1.0 : _smooth((age - .02) / .2);
    final bob = reducedMotion ? 0.0 : math.sin(age * 5.5) * glyph * .1;
    for (final side in [-1.0, 1.0]) {
      canvas.save();
      canvas.translate(
        side * (shade.width / 2 + gap + glyph),
        titleTop + shade.height * .5 + bob,
      );
      // Wind badges both face the way the gale blows, not the title.
      canvas.scale((wind ? -1 : side) * glyph * grow, glyph * grow);
      if (wind) {
        _windMotif(canvas, accent, fade);
      } else {
        _bannerMotif(canvas, motif, accent, fade);
      }
      canvas.restore();
    }

    if (celebrating && !reducedMotion) {
      final burst = (age / .8).clamp(0.0, 1.0);
      if (burst < 1) {
        final spark = Paint()
          ..color = SkyColors.yellow.withValues(alpha: (1 - burst) * fade);
        for (var i = 0; i < 10; i++) {
          final a = _hash(i, 21) * math.pi * 2;
          final reach = (.8 + _hash(i, 23) * .8) * halfW * _smooth(burst);
          canvas.drawPath(
            SkyScenery.star(
              Offset(math.cos(a) * reach, math.sin(a) * reach * .62),
              halfH * .12 * (1 - burst) * (.6 + _hash(i, 25) * .7),
            ),
            spark,
          );
        }
      }
    }
    canvas.restore();
    return cardH * fit;
  }

  /// A darker, still saturated accent for the card's ribbon and edge.
  static Color _bannerDeep(Color accent, double amount) {
    final hsl = HSLColor.fromColor(accent);
    return hsl
        .withLightness((hsl.lightness * amount).clamp(0.0, 1.0))
        .toColor();
  }

  /// Two gusts rolling over into curls, the way wind is drawn on a weather
  /// map, in a unit box around the origin. The curls are big and left open
  /// so at badge size they read as air rather than as bars.
  static void _windMotif(Canvas canvas, Color accent, double alpha) {
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .28
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(
      Path()
        ..moveTo(-1.05, -.1)
        ..lineTo(.3, -.1)
        ..arcTo(
          Rect.fromCircle(center: const Offset(.3, -.48), radius: .38),
          math.pi / 2,
          -4.4,
          false,
        ),
      stroke
        ..color = Color.lerp(
          accent,
          SkyColors.cream,
          .55,
        )!.withValues(alpha: alpha),
    );
    canvas.drawPath(
      Path()
        ..moveTo(-.75, .38)
        ..lineTo(0, .38)
        ..arcTo(
          Rect.fromCircle(center: const Offset(0, .7), radius: .32),
          -math.pi / 2,
          4.4,
          false,
        ),
      stroke..color = accent.withValues(alpha: alpha),
    );
  }

  /// The badge that flanks a title, drawn in a unit box around the origin.
  static void _bannerMotif(
    Canvas canvas,
    RushPathKind? kind,
    Color accent,
    double alpha,
  ) {
    final body = Paint()..color = accent.withValues(alpha: alpha);
    final lit = Paint()
      ..color = Color.lerp(
        accent,
        SkyColors.cream,
        .55,
      )!.withValues(alpha: alpha);
    switch (kind) {
      case null:
        canvas.drawPath(SkyScenery.star(Offset.zero, 1), body);
        canvas.drawPath(SkyScenery.star(Offset.zero, .44), lit);
      case RushPathKind.wildfire:
        canvas.drawPath(
          Path()
            ..moveTo(.06, -1)
            ..cubicTo(.35, -.45, .92, -.15, .84, .35)
            ..cubicTo(.76, .92, .2, 1.06, -.06, 1.06)
            ..cubicTo(-.5, 1.06, -.92, .72, -.86, .2)
            ..cubicTo(-.83, -.1, -.56, -.26, -.42, -.52)
            ..cubicTo(-.3, -.2, -.12, -.2, -.06, -.46)
            ..cubicTo(-.01, -.64, .02, -.82, .06, -1)
            ..close(),
          body,
        );
        canvas.drawPath(
          Path()
            ..moveTo(.06, -.3)
            ..cubicTo(.3, .05, .52, .26, .46, .56)
            ..cubicTo(.4, .88, .1, 1, -.08, 1)
            ..cubicTo(-.36, 1, -.54, .76, -.5, .5)
            ..cubicTo(-.45, .24, -.1, .1, .06, -.3)
            ..close(),
          lit,
        );
      case RushPathKind.skyfall:
        canvas.drawPath(
          Path()
            ..moveTo(-.16, .78)
            ..quadraticBezierTo(-.74, -.02, -1.08, -1.08)
            ..quadraticBezierTo(-.02, -.74, .78, -.16)
            ..close(),
          body,
        );
        canvas.drawCircle(const Offset(.3, .3), .62, lit);
        canvas.drawCircle(const Offset(.14, .14), .2, body);
      case RushPathKind.eruption:
        canvas.drawPath(
          Path()
            ..moveTo(-1, 1)
            ..lineTo(-.4, -.04)
            ..lineTo(.4, -.04)
            ..lineTo(1, 1)
            ..close(),
          body,
        );
        canvas.drawPath(
          Path()
            ..moveTo(-.16, -.04)
            ..lineTo(.16, -.04)
            ..lineTo(.36, 1)
            ..lineTo(0, 1)
            ..close(),
          lit,
        );
        for (final blob in const [
          [0.0, -.62, .42],
          [-.5, -.3, .27],
          [.52, -.34, .29],
          [-.26, -1.02, .14],
          [.34, -1.04, .12],
        ]) {
          canvas.drawCircle(Offset(blob[0], blob[1]), blob[2], lit);
        }
      case RushPathKind.swarm:
        void bat(double x, double y, double scale, Paint paint) {
          canvas.save();
          canvas.translate(x, y);
          canvas.scale(scale);
          canvas.drawPath(
            Path()
              ..moveTo(-1, -.34)
              ..quadraticBezierTo(-.6, -.36, -.36, -.64)
              ..quadraticBezierTo(-.18, -.2, 0, -.26)
              ..quadraticBezierTo(.18, -.2, .36, -.64)
              ..quadraticBezierTo(.6, -.36, 1, -.34)
              ..quadraticBezierTo(.66, .22, .4, .3)
              ..quadraticBezierTo(.18, .44, 0, .62)
              ..quadraticBezierTo(-.18, .44, -.4, .3)
              ..quadraticBezierTo(-.66, .22, -1, -.34)
              ..close(),
            paint,
          );
          canvas.drawCircle(const Offset(0, -.16), .26, paint);
          canvas.restore();
        }

        bat(-.62, .62, .34, body);
        bat(.64, .54, .3, body);
        bat(-.02, -.2, .96, lit);
    }
  }
}
