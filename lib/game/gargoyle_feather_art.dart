import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../domain/sky_boss.dart';
import 'boss_health_bar_art.dart';
import 'gargoyle_kit.dart';
import 'gargoyle_layout.dart';

/// The Searchlight Gargoyle's stone feathers and what tells of them: the
/// feather in flight, the dust that announces it at the top edge, the clink
/// (or the thud) of a rock on his lamp and the chips of a feather that breaks.
///
/// **The feather** is the blade that left his wing (the near fan's top blade,
/// `GargoyleWingArt.shedBlade`), cut as a swallow-tailed dart so its heading
/// reads at once: a steel frame and a long steel tip around a limestone vane,
/// a dark ridge down it, the house ink ring and one hard white glint on the
/// tip's steel. Its tip and both tail points lie on the hit circle
/// (`BossAmmo.radius`, the rules' .028 of the screen height) and the ink ring's
/// outer edge IS the circle there; the wake's dust, which fills the circle
/// behind the blade, shows the rest of what hurts. It is cream and steel
/// (a pale, cool, angular thing on New York's navy night, nothing like the
/// Baron's red ember, the Spitter's green acid, the Empress's gold pollen,
/// the Captain's iron ball or the Dragon's orange fire, and the only shot that
/// is not round).
///
/// **How it moves.** It points along its velocity and rocks about that line
/// like a heavy blade that tumbles as it falls, and its glint flashes as the
/// tip swings toward the moon: all a pure function of the feather's AGE, which
/// is worked out from where it is (the rules give a shot that never splits no
/// clock), so pause, seek and replay are exact. Behind it streams a wake of
/// limestone dust drawn on the feather's TRUE path (its own velocity and
/// gravity run backwards, so the wake bends with the lob: the aim line is the
/// wake, it points back up and to the right) with a few chips of stone shed
/// along it. In fury it is hot: an amber frame and tip, bleached stone, an
/// ember wake. Reduced Motion: no rocking, no flashing, no streaming chips
/// (one still frame for each position).
///
/// **Budget.** A feather is 8 draw ops in every look (the wake's ribbon and
/// its core with the chips, then the body: a dark halo, the frame, the vane,
/// its shaded half, the ink with the ridge, the glint); three on screen are 24. No
/// shader, no `saveLayer`, no blur, no `Random`, no static `Path` built per
/// frame (the shapes are cached; the wake reuses scratch paths). The telegraph
/// ([dust]), the clink ([glance]), the thud ([impact]) and the shatter
/// ([shatter]) are each at most 8; none is charged to the feathers.
///
/// **Hooks.** `BossAmmoArt.shot` calls [paint] for every shot of a Gargoyle
/// (the one patch in `boss_ammo_art.dart`); the staging calls [dust] with
/// `GargoylePose.dust` at [entryX], [glance] with `GargoylePose.glance` and the
/// lamp's `lamp` at the lamp's centre, [impact] with `GargoylePose.hit`; the HUD
/// pass calls [overBar] right after the health bar. [shatter] is for a feather
/// that breaks (the rules never remove one but at the bird or off screen).
abstract final class GargoyleFeatherArt {
  /// Draw ops of one feather in any look.
  static const opsPerFeather = 8;

  // ------------------------------------------------------------- shapes --
  // Unit space: the hit circle is radius 1, the feather flies along +x, the
  // sky's light comes from -y (the caller flips it when the shot flies left).

  /// The silhouette: a kite point at (1, 0), flanks .6 off the axis, a swallow
  /// tail whose two points (-.8, +-.6) lie on the circle like the tip.
  static final Path _outer = GargoyleKit.poly(const [
    Offset(1, 0),
    Offset(.22, -.6),
    Offset(-.8, -.6),
    Offset(-.36, 0),
    Offset(-.8, .6),
    Offset(.22, .6),
  ]);

  /// The limestone vane inside the steel frame, cut square behind the long
  /// steel tip.
  static final Path _vane = GargoyleKit.poly(const [
    Offset(.44, -.254),
    Offset(.172, -.46),
    Offset(-.524, -.46),
    Offset(-.186, 0),
    Offset(-.524, .46),
    Offset(.172, .46),
    Offset(.44, .254),
  ]);

  /// The shaded half of the vane (below the ridge).
  static final Path _shade = GargoyleKit.poly(const [
    Offset(.44, 0),
    Offset(.44, .254),
    Offset(.172, .46),
    Offset(-.524, .46),
    Offset(-.186, 0),
  ]);

  /// The ink: the outline and the ridge from the steel to the notch, one stroke
  /// as heavy as the ring; with two nested Deco chevrons pointing at the tip when
  /// the feather is big enough to show them.
  static final Path _inkCoarse = Path()
    ..addPath(_outer, Offset.zero)
    ..moveTo(.44, 0)
    ..lineTo(-.18, 0);

  static final Path _inkFine = Path()
    ..addPath(_inkCoarse, Offset.zero)
    ..moveTo(.0, -.3)
    ..lineTo(.2, 0)
    ..lineTo(.0, .3)
    ..moveTo(-.34, -.36)
    ..lineTo(-.16, 0)
    ..lineTo(-.34, .36);

  /// The white glint on the steel of the tip: a four-point sparkle (it reads at
  /// any turn of the blade, and on the small steel kite there is no room for a
  /// bar), half size .27, with a thin waist.
  static final Path _glintPlaced = GargoyleKit.poly([
    for (var i = 0; i < 8; i++)
      Offset(.6, -.04) +
          Offset(math.cos(i * math.pi / 4), math.sin(i * math.pi / 4)) * (i.isEven ? .27 : .07),
  ]);

  // ------------------------------------------------------------- paints --

  static final Paint _fillPaint = Paint();
  static final Paint _linePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  static Paint _fill(Color color, [double alpha = 1]) => _fillPaint
    ..color = alpha >= 1 ? color : color.withValues(alpha: (color.a * alpha).clamp(0.0, 1.0));

  static Paint _line(Color color, double width, [double alpha = 1]) => _linePaint
    ..color = alpha >= 1 ? color : color.withValues(alpha: (color.a * alpha).clamp(0.0, 1.0))
    ..strokeWidth = width;

  // Calm and fury colours.
  static const _frame = GargoylePalette.steel, _frameHot = GargoylePalette.lampAmber;
  static const _vaneLit = GargoylePalette.limeSheen, _vaneHot = GargoylePalette.white;
  static const _vaneShade = GargoylePalette.lime, _shadeHot = GargoylePalette.arcBody;
  static const _wakeDust = GargoylePalette.dust, _wakeHot = GargoylePalette.lampWarm;

  // ---------------------------------------------------------- the clock --

  /// The seconds a feather has been in flight, worked out from where it is: it
  /// leaves the cornice at (the bird's column + [SearchlightGargoyle.featherOffsetX])
  /// and crosses at its constant horizontal speed. The rules keep no age for a
  /// shot that never splits; this is exact for a feather the rules launched
  /// and still a pure function of the shot for any other (a sprint's rush
  /// only makes it a little older than it is).
  static double age(BossAmmo a) {
    if (!a.x.isFinite || !a.vx.isFinite || a.vx > -1e-6) return 0;
    final spawn = GargoyleLayout.birdColumn + SearchlightGargoyle.featherOffsetX;
    return ((spawn - a.x) / -a.vx).clamp(0.0, 6.0);
  }

  /// Where a feather launched at a bird [birdY] high (screen heights) first
  /// shows below the top edge, as a screen height x: the lob rises above the
  /// screen for a high bird, so the entry is left of the cornice column. The
  /// telegraph's dust can drop here instead of at `GargoyleBossRig.featherSpawn`.
  static double entryX(double birdY, {bool fury = false}) {
    const spawn = GargoyleLayout.birdColumn + SearchlightGargoyle.featherOffsetX;
    if (!birdY.isFinite) return spawn;
    final shot = SearchlightGargoyle.featherShot(birdY.clamp(0.0, 1.0), enraged: fury);
    const g = SearchlightGargoyle.featherGravity;
    // y(t) = featherY + vy t + g/2 t^2 reaches -radius (the body's lower edge on the top edge).
    final drop = -(SearchlightGargoyle.featherY + SearchlightGargoyle.featherRadius);
    final t = (-shot.vy + math.sqrt(shot.vy * shot.vy + 2 * g * drop)) / g;
    return spawn + shot.vx * t;
  }

  // -------------------------------------------------------------- paint --

  /// Paints feather [a] at its place; [h] is the screen height in px. The
  /// feather tumbles with its age (Reduced Motion: it holds its heading, the
  /// tip along its velocity). [seconds] is the simulation clock: the feather's
  /// motion follows its own [age] and does not read it.
  static void paint(
    Canvas c,
    double h,
    BossAmmo a, {
    double seconds = 0,
    bool reducedMotion = false,
    bool fury = false,
  }) {
    final r = a.radius * h;
    if (!h.isFinite || !r.isFinite || r <= 0) return;
    if (!a.x.isFinite || !a.y.isFinite || !a.vx.isFinite || !a.vy.isFinite || !a.gravity.isFinite) return;
    final heading = math.atan2(a.vy, a.vx);
    final age = GargoyleFeatherArt.age(a);
    // A per-feather phase from the launch's own vertical speed.
    final phase = ((a.vy - a.gravity * age) * 9.1).abs() % (2 * math.pi);
    final facing = heading + (reducedMotion ? 0.0 : tumble(age, phase, fury: fury));
    final flip = math.cos(heading) < 0;
    c.save();
    c.translate(a.x * h, a.y * h);
    _wake(c, h, r, a, age, reducedMotion, fury);
    c.rotate(facing);
    if (flip) c.scale(1, -1);
    c.scale(r);
    // The steel flashes when the tip swings toward the moon (upper right).
    final flash = reducedMotion ? 1.0 : .7 + .3 * math.pow(math.max(0.0, math.cos(facing + math.pi / 4)), 1.5);
    unit(c, edge: _edge(r), fury: fury, glint: flash, fine: r >= 14);
    c.restore();
  }

  /// The tumble's angle (radians, added to the heading): a rock about the
  /// heading that eases as the blade settles into its fall. Pure in [age].
  static double tumble(double age, double phase, {bool fury = false}) =>
      rockAmplitude * (1 - .3 * math.min(age / 1.8, 1.0)) * math.sin(2 * math.pi * (fury ? 1.4 : 1.15) * age + phase);

  /// The rock's amplitude in radians.
  static const rockAmplitude = .55;

  /// The ink ring's width in unit space: about 1.8 px at the game's size.
  static double _edge(double r) => (1.8 / r).clamp(.13, .45);

  /// The feather's body in unit space (hit radius 1, flying along +x, light
  /// from -y), 6 draw ops: a dark halo, the steel frame, the vane, its shaded
  /// half, the ink with the ridge (and, when [fine], the chevrons) and the
  /// glint. [edge] is the ring's width in these units (its outer edge lies on
  /// the circle at the tip); [glint] is the glint's brightness.
  /// `BossAmmoArt.paint` draws this for the shared muzzle path.
  static void unit(
    Canvas c, {
    double edge = .18,
    bool fury = false,
    double glint = 1,
    bool fine = false,
  }) {
    final e = edge.isFinite ? edge.clamp(.1, .5) : .18;
    final s = 1 - e / 2;
    c.save();
    c.scale(s);
    // A dark halo just outside the ring, so the pale stone never melts into a
    // lit window or the amber beam.
    c.drawPath(_outer, _line(GargoylePalette.ink, (e + .5) / s, .34));
    c.drawPath(_outer, _fill(fury ? _frameHot : _frame));
    c.drawPath(_vane, _fill(fury ? _vaneHot : _vaneLit));
    c.drawPath(_shade, _fill(fury ? _shadeHot : _vaneShade));
    c.drawPath(fine ? _inkFine : _inkCoarse, _line(GargoylePalette.ink, e / s));
    c.drawPath(_glintPlaced, _fill(GargoylePalette.white, glint.isFinite ? glint.clamp(0.0, 1.0) : 1.0));
    c.restore();
  }

  // --------------------------------------------------------------- wake --

  static final Path _ribbon = Path(), _core = Path(), _chips = Path();
  static final List<Offset> _spine = List.filled(5, Offset.zero), _norm = List.filled(5, Offset.zero);
  static const _wakeSeconds = .42, _wakeSecondsFury = .36;
  static const _chipEvery = .075, _chipSlots = 5, _chipFrom = .1;

  /// Where [a] was [tau] seconds ago, relative to now, in screen heights: its own
  /// velocity and gravity run backwards (its exact ballistic path).
  static Offset trailAt(BossAmmo a, double tau) => Offset(
    -a.vx * tau,
    -a.vy * tau + a.gravity * tau * tau / 2,
  );

  /// A tapered ribbon along the spine's first [points] points, [half0] wide at
  /// the head, into [into].
  static void _strip(Path into, int points, double half0) {
    into.reset();
    into.moveTo(_spine[0].dx + _norm[0].dx * half0, _spine[0].dy + _norm[0].dy * half0);
    for (var k = 1; k < points; k++) {
      final w = half0 * math.pow(1 - k / (points - 1), .8) + .2;
      into.lineTo(_spine[k].dx + _norm[k].dx * w, _spine[k].dy + _norm[k].dy * w);
    }
    for (var k = points - 1; k >= 0; k--) {
      final w = half0 * math.pow(1 - k / (points - 1), .8) + .2;
      into.lineTo(_spine[k].dx - _norm[k].dx * w, _spine[k].dy - _norm[k].dy * w);
    }
    into.close();
  }

  /// The wake, in px about the feather's centre: a broad ribbon of dust along
  /// the path it has flown (1 op) and a brighter core with the chips it sheds
  /// (1 op: chips are subpaths of the core's fill, so they are as faint as it).
  static void _wake(Canvas c, double h, double r, BossAmmo a, double age, bool still, bool fury) {
    final span = fury ? _wakeSecondsFury : _wakeSeconds;
    for (var k = 0; k < 5; k++) {
      _spine[k] = trailAt(a, span * k / 4) * h;
    }
    for (var k = 0; k < 5; k++) {
      final back = _spine[math.min(k + 1, 4)] - _spine[math.max(k - 1, 0)];
      _norm[k] = back.distance < 1e-6 ? const Offset(0, -1) : Offset(-back.dy, back.dx) / back.distance;
    }
    _strip(_ribbon, 5, r * .95);
    c.drawPath(_ribbon, _fill(fury ? _wakeHot : _wakeDust, fury ? .28 : .26));
    _strip(_core, 4, r * .42);
    // Chips shed along the path: one is born every [_chipEvery] seconds and
    // streams back and down; which slot it is in is its age's phase. Wound
    // against the strip (which runs the other way round) so that where a chip
    // overlaps the core the fills add up and no hole is cut.
    final base = still ? 0 : (age / _chipEvery).floor();
    final frac = still ? .5 : age / _chipEvery - base;
    for (var m = 0; m < _chipSlots; m++) {
      final j = still ? m : base - m;
      if (j < 0) continue;
      // Chips are born clear of the body.
      final tau = _chipFrom + (still ? (m + .5) * _chipEvery : (m + frac) * _chipEvery);
      if (tau > span) continue;
      final side = GargoyleKit.hash(j, 3) > .5 ? 1.0 : -1.0;
      final spread = (.5 + .9 * GargoyleKit.hash(j, 5)) * (.6 + tau / span);
      final at = trailAt(a, tau) * h + Offset(0, -side * r * spread + r * 6.4 * tau * tau);
      final size = r * (.3 - .14 * tau / span) * (.8 + .4 * GargoyleKit.hash(j, 7));
      final turn = GargoyleKit.hash(j, 11) * math.pi * 2 + (still ? 0 : tau * 6);
      for (var v = 0; v < 3; v++) {
        final ang = turn - v * 2.1;
        final p = at + Offset(math.cos(ang), math.sin(ang)) * size * (v == 0 ? 1.5 : 1);
        v == 0 ? _core.moveTo(p.dx, p.dy) : _core.lineTo(p.dx, p.dy);
      }
      _core.close();
    }
    c.drawPath(_core, _fill(fury ? GargoylePalette.arcCore : GargoylePalette.limeSheen, fury ? .48 : .42));
  }

  /// Feathers over the health bar's plate. A feather enters at the top edge,
  /// exactly where the bar lies (its strip is y 7-29 px at 360 high, x 173-467
  /// at 640 and 216-584 at 800), so for .3 to .6 s of every fall the bar would
  /// hide it: the HUD hook calls this right AFTER the bar, once, with the
  /// shots in flight, and the ones that touch the strip are drawn again over it
  /// (the cream dart crossing the dark plate; nothing else changes). Does nothing
  /// while the bar is hidden (the cutscenes) or for a boss that is not the
  /// Gargoyle.
  static void overBar(
    Canvas c,
    Size size,
    Iterable<BossAmmo> ammo,
    SkyBoss boss, {
    bool reducedMotion = false,
  }) {
    if (!boss.isGargoyle || boss.inCutscene || !size.height.isFinite || size.height <= 0) return;
    final h = size.height;
    final strip = BossHealthBarArt.bounds(size, boss);
    for (final a in ammo) {
      if (!a.feather || !a.x.isFinite || !a.y.isFinite) continue;
      final reach = a.radius * h * 1.3;
      if (!strip.inflate(reach).contains(Offset(a.x * h, a.y * h))) continue;
      paint(c, h, a, reducedMotion: reducedMotion, fury: boss.enraged);
    }
  }

  /// The solid body's radius in px for [a], exactly the hit circle (the tests
  /// compare it to `ammo.radius`).
  static double bodyRadius(BossAmmo a, double h) => a.radius * h * GargoyleLayout.hitRadius;

  // --------------------------------------------------------------- dust --

  static final Path _star = Path(), _puff = Path();

  /// The dust that tells a feather is coming loose from the cornice at screen
  /// x = [at] (screen heights) along the top edge: [progress] 0..1 over the .45
  /// s before the launch. Motion: none under Reduced Motion.
  static void dust(Canvas c, Size size, double progress, double at, {bool reducedMotion = false}) {
    if (!progress.isFinite || progress <= 0 || reducedMotion || !size.height.isFinite || !at.isFinite) return;
    final h = size.height, u = progress.clamp(0.0, 1.0);
    final x = at * h;
    // Under the health bar's strip (the bar is drawn over the cornice's column
    // at both widths), where the feather first shows.
    final y0 = h * dustTop;
    final s = u * .45;
    // A cloud of grit shaken off the stone: three overlapping puffs (one fill,
    // so it reads as a puff and not as bubbles) that swell and sink.
    _puff.reset();
    final pr = h * (.022 + .012 * u);
    for (final (dx, dy, k) in const [(-.022, .012, 1.0), (.018, .004, .9), (-.002, .04, 1.15)]) {
      _puff.addOval(Rect.fromCircle(
        center: Offset(x + h * dx, y0 + h * (dy + (dy * .6 + .045) * u)),
        radius: pr * k,
      ));
    }
    c.drawPath(_puff, _fill(GargoylePalette.dust, .32 * (1 - .35 * u)));
    // Chips fall, each on its own clock, big enough to read at 640.
    _chips.reset();
    for (var i = 0; i < 6; i++) {
      final e = .02 + .06 * i;
      if (s < e) continue;
      final tau = s - e;
      final px = x + (GargoyleKit.hash(i, 17) - .5) * h * .07;
      final py = y0 + h * (.004 + 1.2 * tau * tau);
      final size0 = h * (.0085 + .004 * GargoyleKit.hash(i, 19));
      final turn = GargoyleKit.hash(i, 23) * 6.28 + tau * 7;
      for (var v = 0; v < 3; v++) {
        final ang = turn + v * 2.1;
        final p = Offset(px + math.cos(ang) * size0 * (v == 0 ? 1.5 : 1), py + math.sin(ang) * size0 * (v == 0 ? 1.5 : 1));
        v == 0 ? _chips.moveTo(p.dx, p.dy) : _chips.lineTo(p.dx, p.dy);
      }
      _chips.close();
    }
    c.drawPath(_chips, _fill(GargoylePalette.limeSheen, .95));
    // The glint of the steel edge as it comes loose: a four-point star in the last
    // quarter, right where the feather will show.
    final g = ((u - .68) / .24).clamp(0.0, 1.0);
    if (g > 0) {
      final rr = h * .062 * (.4 + .6 * g);
      final cy = y0 + h * .045;
      _star.reset();
      for (var i = 0; i < 8; i++) {
        final ang = -math.pi / 2 + i * math.pi / 4;
        final d = i.isEven ? rr : rr * .2;
        final p = Offset(x + math.cos(ang) * d, cy + math.sin(ang) * d);
        i == 0 ? _star.moveTo(p.dx, p.dy) : _star.lineTo(p.dx, p.dy);
      }
      _star.close();
      c.drawPath(_star, _fill(GargoylePalette.white, .97 * g));
      c.drawCircle(Offset(x, cy), rr * .26, _fill(GargoylePalette.steelLit, g));
    }
  }

  /// Where the telegraph's grit starts, in screen heights from the top: just
  /// under the health bar's strip (the bar is over the top edge at both widths).
  static const dustTop = .12;

  // ------------------------------------------------------------ glance --

  /// The brass clink where a rock glanced off the shut lamp [t] 0..1 through
  /// the .15 s glance, at [at] (px, the lamp's centre) with [unit] px per rig
  /// unit: a white-hot flash, a ring, a brass flare along the shutter and
  /// three sparks thrown back toward the bird. With the lamp OPEN ([open] from the
  /// pose's `lamp`, .5 or more) the same event is a dull thud instead
  /// ([impact]). Reduced Motion draws one still frame (the flash, held).
  static void glance(
    Canvas c,
    Offset at,
    double unit,
    double t, {
    double open = 0,
    bool fury = false,
    bool reducedMotion = false,
    Offset rim = const Offset(-.86, -.22),
  }) {
    if (!t.isFinite || t <= 0 || !unit.isFinite || !at.dx.isFinite || !at.dy.isFinite) return;
    if (open >= .5) {
      impact(c, at, unit, t, fury: fury, reducedMotion: reducedMotion, rim: rim);
      return;
    }
    final k = t.clamp(0.0, 1.0);
    final p = reducedMotion ? .5 : k;
    final hit = at + rim * unit;
    // The brass flares along the shutter's rim where it was struck.
    c.drawArc(
      Rect.fromCircle(center: at, radius: unit * 1.02),
      math.pi * .86,
      math.pi * .3,
      false,
      _line(GargoylePalette.brassLit, unit * .1, .75 * k),
    );
    // A ring shivers out of the strike.
    c.drawCircle(hit, unit * (.2 + .34 * p), _line(GargoylePalette.lampWarm, unit * .05, .85 * k));
    // The white-hot flash: a four-point star over a darker one, so it holds on
    // the pale limestone as well as on the glass.
    _star.reset();
    final rr = unit * (.3 + .26 * k);
    for (var i = 0; i < 8; i++) {
      final ang = i * math.pi / 4;
      final d = i.isEven ? rr : rr * .26;
      final q = hit + Offset(math.cos(ang), math.sin(ang)) * d;
      i == 0 ? _star.moveTo(q.dx, q.dy) : _star.lineTo(q.dx, q.dy);
    }
    _star.close();
    c.drawPath(_star, _line(GargoylePalette.ink, unit * .07, .8 * k));
    c.drawPath(_star, _fill(fury ? GargoylePalette.arcCore : GargoylePalette.lampCore, k));
    // Three sparks thrown back, away from the lamp, amber on a dark line (they
    // fly over cream stone), and their white-hot tips.
    _chips.reset();
    final tips = <Offset>[];
    const dirs = [-2.75, -3.55, -2.15];
    for (var i = 0; i < 3; i++) {
      final d = Offset(math.cos(dirs[i]), math.sin(dirs[i]));
      final from = hit + d * unit * (.18 + .3 * p), to = hit + d * unit * (.46 + .55 * p);
      _chips.moveTo(from.dx, from.dy);
      _chips.lineTo(to.dx, to.dy);
      tips.add(to);
    }
    c.drawPath(_chips, _line(GargoylePalette.ink, unit * .12, .7 * k));
    c.drawPath(_chips, _line(GargoylePalette.lampAmber, unit * .07, k));
    c.drawPoints(ui.PointMode.points, tips, _line(GargoylePalette.white, unit * .11, k));
  }

  /// The dull thud of a rock landing on the OPEN lamp, or of any hit on the
  /// shell: no bright sparks, a flat amber ring, a puff of limestone dust and
  /// three chips that drop. [t] 0..1 is a pulse as for [glance].
  static void impact(
    Canvas c,
    Offset at,
    double unit,
    double t, {
    bool fury = false,
    bool reducedMotion = false,
    Offset rim = const Offset(-.86, -.22),
  }) {
    if (!t.isFinite || t <= 0 || !unit.isFinite || !at.dx.isFinite || !at.dy.isFinite) return;
    final k = t.clamp(0.0, 1.0);
    final p = reducedMotion ? .5 : k;
    final hit = at + rim * unit;
    // A flat amber bruise of light on the glass.
    c.drawOval(
      Rect.fromCenter(center: hit, width: unit * (.9 + .5 * p), height: unit * (.6 + .3 * p)),
      _fill(fury ? GargoylePalette.arcEdge : GargoylePalette.lampDeep, .45 * k),
    );
    // The dull ring: dark, not bright.
    c.drawCircle(hit, unit * (.3 + .3 * p), _line(GargoylePalette.ink, unit * .07, .5 * k));
    // Limestone dust puffs out and up.
    c.drawPoints(
      ui.PointMode.points,
      [
        hit + Offset(-unit * .22 * p, -unit * (.1 + .3 * p)),
        hit + Offset(-unit * (.12 + .3 * p), unit * .02),
        hit + Offset(-unit * .02, -unit * (.3 + .3 * p)),
      ],
      _line(GargoylePalette.limeDeep, unit * (.28 + .12 * p), .42 * k),
    );
    // Three chips drop (little rhombi, each its own way).
    _chips.reset();
    for (var i = 0; i < 3; i++) {
      final s = unit * (.06 + .02 * i);
      final q = hit + Offset(-unit * (.2 + .16 * i) * p, unit * (.02 + .55 * p * p));
      final a = GargoyleKit.hash(i, 53) * math.pi;
      final ux = Offset(math.cos(a), math.sin(a)) * s * 1.4, uy = Offset(-math.sin(a), math.cos(a)) * s * .8;
      _chips.moveTo(q.dx + ux.dx, q.dy + ux.dy);
      _chips.lineTo(q.dx + uy.dx, q.dy + uy.dy);
      _chips.lineTo(q.dx - ux.dx, q.dy - ux.dy);
      _chips.lineTo(q.dx - uy.dx, q.dy - uy.dy);
      _chips.close();
    }
    c.drawPath(_chips, _fill(GargoylePalette.limeShade, k));
  }

  // ------------------------------------------------------------ shatter --

  /// A feather breaking: [tau] seconds after it ended (0 to about .4), at [at]
  /// (px) with [unit] px per hit radius (the feather's own radius in px):
  /// six chips of stone and steel fly out and fall, a ring of dust opens and a
  /// white flash blinks. Reduced Motion: the frame at .1 s, fading in place.
  static void shatter(
    Canvas c,
    Offset at,
    double unit,
    double tau, {
    bool fury = false,
    bool reducedMotion = false,
  }) {
    if (!tau.isFinite || tau < 0 || tau > .4 || !unit.isFinite || unit <= 0) return;
    if (!at.dx.isFinite || !at.dy.isFinite) return;
    final life = (tau / .4).clamp(0.0, 1.0);
    final s = reducedMotion ? .1 : tau;
    final fade = 1 - life;
    final flash = 1 - (tau / .06).clamp(0.0, 1.0);
    if (flash > 0 && !reducedMotion) {
      c.drawCircle(at, unit * (1.3 - .3 * flash), _fill(GargoylePalette.white, flash * .9));
    }
    c.drawCircle(at, unit * (.8 + 3.2 * math.sqrt(s / .4)), _line(_wakeDust, unit * .16 * fade + .6, .5 * fade));
    _chips.reset();
    for (var i = 0; i < 6; i++) {
      final dir = (i + GargoyleKit.hash(i, 29) * .7) * math.pi / 3;
      final speed = unit * (7 + 4 * GargoyleKit.hash(i, 31));
      final q = at + Offset(math.cos(dir) * speed * s, math.sin(dir) * speed * s + unit * 9 * s * s);
      final size = unit * (.3 + .15 * GargoyleKit.hash(i, 37)) * (1 - .4 * life);
      final turn = GargoyleKit.hash(i, 41) * 6.28 + s * 9;
      for (var v = 0; v < 3; v++) {
        final ang = turn + v * 2.1;
        final p = q + Offset(math.cos(ang), math.sin(ang)) * size * (v == 0 ? 1.5 : 1);
        v == 0 ? _chips.moveTo(p.dx, p.dy) : _chips.lineTo(p.dx, p.dy);
      }
      _chips.close();
    }
    c.drawPath(_chips, _fill(fury ? GargoylePalette.lampWarm : GargoylePalette.limeLit, fade.clamp(0.0, 1.0)));
    c.drawPath(_chips, _line(GargoylePalette.ink, unit * .05, fade.clamp(0.0, 1.0)));
  }
}
