import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../domain/game_rules.dart' show FlightSimulation;
import '../domain/sky_boss.dart';
import '../domain/sky_enemy.dart' show SkyEnemy;
import '../ui/theme.dart' show heading;
import 'boss_motion.dart';
import 'enemy_designs/alley_pigeon.dart';
import 'king_coo_boss_rig.dart';
import 'king_coo_kit.dart';
import 'king_coo_pose.dart';

/// A band of sky from [top] to [bottom], in screen heights (0 = top).
final class LaneBand {
  const LaneBand(this.top, this.bottom);
  final double top, bottom;
  double get height => bottom - top;
  double get centre => (top + bottom) / 2;

  /// Whether a bird centred at [y] is inside the band (edges inclusive).
  bool holds(double y) => y >= top && y <= bottom;

  @override
  String toString() =>
      'LaneBand(${top.toStringAsFixed(3)}..${bottom.toStringAsFixed(3)})';
}

/// What a squadron plan says about the sky, as the rules play it: the heights
/// where a bird is hurt ([red]: within a pigeon's reach of a lane, or closer
/// to a course edge than its own radius) and the heights where it is safe
/// ([green]). Pure: derived from the plan's slots and the rules' constants
/// only, so what is lit is exactly what hurts.
final class SquadLanes {
  SquadLanes(this.red, this.green, [this.footprint = const []]);
  final List<LaneBand> red, green;

  /// Where the pigeons' bodies fly: each lane `+-` [KingCooSquadArt.footprintHalf],
  /// merged. (The red is wider: a pigeon HURTS a little further than it is.)
  final List<LaneBand> footprint;

  /// The part of the red the art hatches: the red inside the pigeons'
  /// footprint. The rest of the red (the sliver between the last pigeon of a
  /// picket and the course edge, the margins of a V) is only washed.
  late final List<LaneBand> hatch = [
    for (final r in red)
      for (final f in footprint)
        if (math.min(r.bottom, f.bottom) - math.max(r.top, f.top) > .02)
          LaneBand(math.max(r.top, f.top), math.min(r.bottom, f.bottom)),
  ];

  /// Every red/green boundary a pigeon makes: its height and whether the red
  /// is above it. (The course-edge slivers are red too, but no pigeon draws
  /// them, so they get no line, no bank and no cones.)
  late final List<(double, bool)> boundaries = () {
    bool real(double at, {required bool above}) => red.any(
      (r) =>
          r.height > .06 &&
          ((above ? r.bottom : r.top) - at).abs() < 1e-6,
    );
    return [
      for (final g in green) ...[
        if (g.top > .01 && real(g.top, above: true)) (g.top, true),
        if (g.bottom < .99 && real(g.bottom, above: false)) (g.bottom, false),
      ],
    ];
  }();

  /// Whether a bird holding height [y] is hurt as the squadron crosses.
  bool blocked(double y) => red.any((b) => b.holds(y));

  /// Whether a bird holding height [y] crosses safely.
  bool safe(double y) => green.any((b) => b.holds(y));
}

/// One planned squadron as the art sees it: its lanes and the boss-age
/// times of its beats. The tip crosses the bird's column at [firstCrossAt],
/// the last pigeon at [lastCrossAt], and it has cleared the bird (its last
/// edge is past) at [clearAt].
final class SquadFormation {
  const SquadFormation({
    required this.index,
    required this.plan,
    required this.lanes,
    required this.puffAt,
    required this.releaseAt,
    required this.firstCrossAt,
    required this.lastCrossAt,
    required this.clearAt,
  });

  /// Its place in `boss.squad` (fury calls a V, then a picket).
  final int index;
  final SquadPlan plan;
  final SquadLanes lanes;
  final double puffAt, releaseAt, firstCrossAt, lastCrossAt, clearAt;
}

/// How many squad pigeons the art may draw at once while they wait, and the
/// budgets of the pieces (`KingCooBudget.lanes` is the lane layer's).
abstract final class KingCooSquadBudget {
  /// The lane layer (washes, hatch, edges, cones, chevrons, tag), per frame.
  static const lanes = 60;

  /// A ghost formation: one bounded layer, one picture per pigeon.
  static const ghostOps = 14, ghostLayers = 1;

  /// The queue behind him: at most this many idle gliders (30 ops each).
  static const queueGliders = 6, queueExtraOps = 12;

  /// The siren's light on the scene, the inhale and the whistle's blast.
  static const sirenOps = 8, cueOps = 16;

  /// The cancel's puffs and chip.
  static const cancelOps = 40;
}

/// King Coo's whistle squadron on screen: the call, the lanes that go red
/// (blocked) and green (go), the ghost of the formation before it comes, the
/// queue of pigeons waiting behind him, the siren's light on the scene and
/// the call's cancellation.
///
/// THE LANES ARE THE RULES' LANES. [lanesOf] derives red and green from
/// `SquadPlan.slots` and the rules' reach (`KingCoo.pigeonReach`, the edges'
/// `KingCoo.birdRadius`): a bird holding a green height is never touched by
/// the squadron, a bird holding a red one is (the test flies the real
/// simulation to prove it at 640 and 800, calm and fury).
///
/// FAIRNESS READS FOUR WAYS. Colour: hazard rose over a dark plum wash vs
/// mint. Pattern: red is a diagonal hatch with a dashed edge and traffic cones,
/// green is open sky with left-flowing chevrons and a bright bank along the
/// edge. Brightness: red darkens the sky, green lifts it. Words: a tag that
/// spells it out (`GREEN LANE = GO`, `USE THE GAP`) with three pips that fill
/// until the first pigeon reaches the bird's column. Up and down chevrons
/// inside the red point to the nearest green.
///
/// THE STORY OF A CALL (boss clock, cycle seconds). 7.6 the puff: the siren
/// blinks, air streams into his beak, the lanes fade in (.3 s), a ghost of the
/// formation hangs near the bird and pigeons fly in from the right edge to
/// queue behind him. 9.2 the whistle: sound arcs from the whistle, the lanes
/// flash, the ghost gives way to the real pigeons that burst from his chest
/// (the queue slides behind him a beat before and goes). Then the lanes hold
/// until the LAST pigeon has passed the bird's column (crossing times from
/// `SkyBoss.squadCrossesAt`, so any screen width), fade out in .35 s. Fury
/// calls a V and then a picket: the V's lanes first, a chip says what comes
/// next, and the picket's lanes take over as the V clears. A pop BEFORE the
/// whistle cancels the call: the lanes fade, the ghost and the queue dissolve
/// into puffs of feathers, a chip says `SQUAD CANCELLED`.
///
/// Everything is a pure function of the boss clock (`boss.age`), the plan the
/// rules latched (`boss.squad`, `boss.cancelledSquad`) and the screen size:
/// pauses, seeks and replays repeat exactly. No random, no wall clock, no
/// blur. Reduced Motion holds every mark still (lanes fade in place, the
/// siren is steady) and keeps every state readable.
///
/// PAINT it with [paint] in `BossEncounterArt.backdrop` (under the stars, the
/// obstacles, the boss, the pigeons and the bird: nothing here can hide
/// them). [prewarm] builds what a frame needs.
abstract final class KingCooSquadArt {
  // --------------------------------------------------------------- palette --

  static const _ink = KingCooPalette.ink;
  static const _stop = KingCooPalette.stop, _go = KingCooPalette.go;
  static const _cone = KingCooPalette.cone;
  static const _plum = Color(0xff3a0b2b);
  static const _goLit = Color(0xffdcffec);
  static const _stopLit = Color(0xffffc9cf);
  static const _plate = KingCooPalette.navyDeep;
  static const _cream = Color(0xfffff4f6);

  // -------------------------------------------------------------- timeline --

  /// The lanes fade in over [fadeIn] from the puff and out over [fadeOut]
  /// once the last pigeon has passed the bird's column.
  static const fadeIn = .2, fadeOut = .35;

  /// The whistle's blast: sound arcs for this long.
  static const blastSeconds = .45;

  /// The cancel plays for this long after the pop.
  static const cancelSeconds = 1.6;

  /// The ghost hangs this far (screen heights) in front of the bird's
  /// column, tip first.
  static const ghostAhead = .18;

  static const _queueEntry = .85, _queueStagger = .10, _queueSlide = .4;

  // ----------------------------------------------------------------- model --

  /// The narrowest safe band the art lights as a lane: a bird (a `.076`
  /// diameter that flaps up and down a little as it holds a height) cannot
  /// live in less, so a thinner sliver (between a V and a course edge) is not
  /// a lane and is drawn as the danger it is in practice. Every height the art
  /// calls green is safe by the rules; every safe band at least this tall is
  /// green.
  static const minLane = .10;

  /// A pigeon's body spans its lane `+-` this (its radius is .045; the rose
  /// hatch is drawn a little over it): the hatch is confined to it.
  static const footprintHalf = .075;

  /// The lane marks start this far (screen heights) left of the bird's
  /// column and run to just in front of his chest: the pigeons' flight
  /// footprint. Left of the bird they have passed.
  static const leftReach = .15;

  /// The lanes of [plan] as the rules play them.
  static SquadLanes lanesOf(SquadPlan plan) {
    const reach = KingCoo.pigeonReach, edge = KingCoo.birdRadius;
    // Hazard spans: a pigeon's reach on each side of its lane, and the
    // sliver along each course edge a bird cannot fly in.
    final spans = <(double, double)>[(-1.0, edge), (1 - edge, 2.0)];
    for (final slot in plan.slots) {
      if (slot.y.isFinite) spans.add((slot.y - reach, slot.y + reach));
    }
    spans.sort((a, b) => a.$1.compareTo(b.$1));
    // The safe bands: the gaps between hazard spans, wide enough to live in.
    final green = <LaneBand>[];
    var hi = spans.first.$2;
    for (final span in spans.skip(1)) {
      if (span.$1 > hi + 1e-9 && span.$1 - hi >= minLane) {
        green.add(LaneBand(hi, span.$1));
      }
      hi = math.max(hi, span.$2);
    }
    // The red is everything else.
    final red = <LaneBand>[];
    var from = 0.0;
    for (final g in green) {
      if (g.top > from + 1e-9) red.add(LaneBand(from, g.top));
      from = g.bottom;
    }
    if (from < 1 - 1e-9) red.add(LaneBand(from, 1.0));
    // The footprint: each pigeon's lane +- its body, merged where they touch.
    final lanes = [
      for (final s in plan.slots)
        if (s.y.isFinite) s.y,
    ]..sort();
    final footprint = <LaneBand>[];
    for (final y in lanes) {
      final top = math.max(0.0, y - footprintHalf);
      final bottom = math.min(1.0, y + footprintHalf);
      if (bottom <= top) continue;
      if (footprint.isNotEmpty && top <= footprint.last.bottom + .02) {
        final last = footprint.removeLast();
        footprint.add(LaneBand(last.top, math.max(last.bottom, bottom)));
      } else {
        footprint.add(LaneBand(top, bottom));
      }
    }
    return SquadLanes(red, green, footprint);
  }

  /// Whether [boss] is a King Coo in the fight on a finite clock.
  static bool _fighting(SkyBoss boss) =>
      boss.isKingCoo &&
      boss.phase == BossPhase.attacking &&
      boss.age.isFinite &&
      boss.arrivalDuration.isFinite &&
      boss.x.isFinite &&
      boss.y.isFinite;

  /// The squadrons the rules planned for the current puff, with the times of
  /// their beats against the bird's column [column]. Empty outside the fight,
  /// before the puff, after a cancel (see `SkyBoss.cancelledSquad`) and once
  /// every pigeon has passed.
  static List<SquadFormation> formationsOf(
    SkyBoss boss, {
    double column = FlightSimulation.birdX,
  }) {
    if (!_fighting(boss) || boss.squad.isEmpty || !column.isFinite) {
      return const [];
    }
    return _formations(boss, boss.squad, column);
  }

  static List<SquadFormation> _formations(
    SkyBoss boss,
    List<SquadPlan> plans,
    double column,
  ) {
    final out = <SquadFormation>[];
    for (final (i, plan) in plans.indexed) {
      if (plan.slots.isEmpty) continue;
      final release = boss.squadReleaseAt(plan);
      if (!release.isFinite) continue;
      var first = double.infinity, last = double.negativeInfinity;
      for (final slot in plan.slots) {
        final at = boss.squadCrossesAt(plan, slot, column);
        if (!at.isFinite) continue;
        first = math.min(first, at);
        last = math.max(last, at);
      }
      if (!first.isFinite) continue;
      out.add(
        SquadFormation(
          index: i,
          plan: plan,
          lanes: lanesOf(plan),
          puffAt: release - plan.delay - (KingCoo.whistleAt - KingCoo.puffAt),
          releaseAt: release,
          firstCrossAt: first,
          lastCrossAt: last,
          clearAt: last + KingCoo.pigeonReach / KingCoo.squadSpeed,
        ),
      );
    }
    return out;
  }

  /// How strongly formation [k] of [all] shows its lanes at boss age [age]:
  /// in from its puff (a later formation, from the moment the one before has
  /// cleared the bird), out as its last pigeon passes. 0 to 1.
  static double lanesAlpha(List<SquadFormation> all, int k, double age) {
    final f = all[k];
    final from = k == 0 ? f.puffAt : all[k - 1].clearAt - .15;
    final inn = BossMotion.ease(BossMotion.ramp(age, from, from + fadeIn));
    final out =
        1 - BossMotion.ease(BossMotion.ramp(age, f.clearAt, f.clearAt + fadeOut));
    return inn * out;
  }

  /// The squadrons a pop before the whistle called off, with how many
  /// seconds ago, or null when no call was just cancelled.
  static (List<SquadFormation>, double)? cancelOf(SkyBoss boss) {
    if (!_fighting(boss) || boss.cancelledSquad.isEmpty) return null;
    final at = boss.poppedAt;
    if (at == null || !at.isFinite || !boss.popped || boss.squadCalled) {
      return null;
    }
    final since = boss.age - at;
    if (since < 0 || since >= cancelSeconds) return null;
    final fs = _formations(boss, boss.cancelledSquad, FlightSimulation.birdX);
    return fs.isEmpty ? null : (fs, since);
  }

  // -------------------------------------------------------------- the call --

  /// Everything the art shows of the call, as numbers (tests read it; the
  /// painter reads the same): which formations are lit and how strongly.
  static ({
    List<SquadFormation> formations,
    List<double> alpha,
    double blast,
    double inhale,
    double onset,
  })
  stateOf(SkyBoss boss, {double column = FlightSimulation.birdX}) {
    final fs = formationsOf(boss, column: column);
    final alpha = [for (var k = 0; k < fs.length; k++) lanesAlpha(fs, k, boss.age)];
    final c = boss.cooCycle;
    final inhale = _fighting(boss) && fs.isNotEmpty
        ? BossMotion.ramp(c, KingCoo.puffAt, KingCoo.puffAt + 1.0) *
              (1 - BossMotion.ramp(c, KingCoo.whistleAt - .2, KingCoo.whistleAt))
        : 0.0;
    final since = c - KingCoo.whistleAt;
    final blast = _fighting(boss) && boss.squadCalled && since >= 0 && since < blastSeconds
        ? math.sin(math.pi * since / blastSeconds)
        : 0.0;
    // The lanes light up with a brief pulse as the puff plans them: the first
    // beat of the tell.
    final onset = _fighting(boss) && fs.isNotEmpty && c >= KingCoo.puffAt
        ? math.sin(math.pi * BossMotion.ramp(c, KingCoo.puffAt, KingCoo.puffAt + .55)) * .7
        : 0.0;
    return (
      formations: fs,
      alpha: alpha,
      blast: blast,
      inhale: inhale,
      onset: onset,
    );
  }

  // ----------------------------------------------------------------- paint --

  /// The pieces [paint] draws, in z-order (`only` takes any of them).
  static const parts = [
    'siren',
    'lanes',
    'ghost',
    'queue',
    'cues',
    'tags',
    'cancel',
  ];

  /// Paints the call's marks for [boss] at [size] (a screen `w x h` px with
  /// `h` the playfield height): the siren's light, the lanes, the ghost, the
  /// queue, the cues and the tags. Paint it BEFORE the stars, the boss, the
  /// pigeons and the bird (`BossEncounterArt.backdrop`). [pose] is the boss's
  /// pose when the caller has built it (else it is built here, ~55 us).
  /// [only] limits the drawing to the named [parts] (tests and previews: the
  /// budget test measures each piece; a game frame passes nothing).
  static void paint(
    Canvas c,
    Size size,
    SkyBoss boss,
    BossMotion m, {
    KingCooPose? pose,
    Set<String>? only,
  }) {
    if (!boss.isKingCoo || !_sane(size, boss)) return;
    if (boss.phase == BossPhase.defeated) return;
    bool on(String part) => only == null || only.contains(part);
    final x = _Ctx(c, size, boss, m.reducedMotion);
    final p = pose ?? KingCooPose(boss, m);
    if (on('siren')) _siren(x, p);
    if (boss.phase != BossPhase.attacking) return;

    final cancelled = cancelOf(boss);
    if (cancelled != null) {
      if (on('cancel') || on('lanes')) {
        _cancel(
          x,
          cancelled.$1,
          cancelled.$2,
          boss.poppedAt!,
          withLanes: on('lanes'),
          withPuffs: on('cancel'),
        );
      }
      return;
    }
    final fs = formationsOf(boss);
    if (fs.isEmpty) return;
    final state = stateOf(boss);
    var lit = false, dominant = 0;
    for (var k = 1; k < fs.length; k++) {
      if (state.alpha[k] > state.alpha[dominant]) dominant = k;
    }
    for (var k = 0; k < fs.length; k++) {
      if (state.alpha[k] <= .004) continue;
      lit = true;
      if (on('lanes')) {
        _lanes(
          x,
          fs[k],
          state.alpha[k],
          x.reduced ? 0 : math.max(state.blast, state.onset),
          detail: k == dominant,
        );
      }
    }
    // The ghost and the queue belong to the squadrons not yet released.
    if (on('ghost')) _ghost(x, fs.first);
    if (on('queue')) _queue(x, fs);
    if (on('cues')) {
      _inhale(x, p, state.inhale);
      _blast(x, p, state.blast);
    }
    if (lit && on('tags')) _tags(x, fs, state.alpha);
  }

  /// Builds every gradient, glow, picture, outline and label a frame of the
  /// call asks for into a picture nobody sees, so no frame of the fight does.
  static void prewarm() {
    final rec = ui.PictureRecorder();
    final c = Canvas(rec);
    const size = Size(800, 360);
    for (final reduced in [false, true]) {
      for (final (shape, age, popped) in [
        (SquadShape.v, 4.6 + 8.4, false),
        (SquadShape.picket, 4.6 + 9.6, false),
        (SquadShape.v, 4.6 + 8.4, true),
      ]) {
        final boss = SkyBoss(
          number: 6,
          x: 1.672,
          kind: BossKind.kingCoo,
          cinematic: true,
        )..age = age;
        boss.y = .5;
        final plans = KingCoo.squad(
          cycle: shape == SquadShape.v ? 0 : 1,
          birdY: .5,
          fury: false,
        );
        if (popped) {
          boss.cancelledSquad = plans;
          boss.poppedAt = age - .3;
        } else {
          boss.squad = plans;
          boss.squadCalled = age >= 4.6 + KingCoo.whistleAt;
        }
        boss.puffsLatched = 1;
        paint(c, size, boss, BossMotion(boss, reducedMotion: reduced));
      }
    }
    for (var coat = 0; coat < AlleyPigeonArtCoats.count; coat++) {
      _gliderPicture(coat);
    }
    rec.endRecording().dispose();
  }

  /// Empties the caches this art keeps (labels, the glider picture). For
  /// tests (determinism) and memory pressure; a game never needs it.
  static void clearCaches() {
    _labels.clear();
    for (var i = 0; i < _gliders.length; i++) {
      _gliders[i]?.dispose();
      _gliders[i] = null;
    }
  }

  // ------------------------------------------------------------- the frame --

  static bool _sane(Size size, SkyBoss boss) =>
      size.width.isFinite &&
      size.height.isFinite &&
      size.width > 0 &&
      size.height > 0 &&
      size.width < 1e5 &&
      size.height < 1e5 &&
      boss.age.isFinite &&
      boss.x.isFinite &&
      boss.y.isFinite &&
      boss.arrivalDuration.isFinite;

  // The siren's light on the scene: a faint cast over everything, a bloom
  // round the dome and a pool on the roofs. Red or blue as the pose has it
  // (steady under Reduced Motion). Cheap: no blur, no layer.
  static void _siren(_Ctx x, KingCooPose pose) {
    final glow = pose.sirenGlow;
    if (!glow.isFinite || glow <= .02 || pose.siren == 0) return;
    final color = pose.siren == 2
        ? KingCooPalette.sirenBlue
        : KingCooPalette.sirenRed;
    final dome = KingCooBossRig.sirenAt(pose);
    final at = Offset(
      x.bossX + dome.dx * x.unit,
      x.bossY + dome.dy * x.unit,
    );
    if (!_near(x, at, x.h * 2)) return;
    final c = x.c, h = x.h;
    c.drawRect(Offset.zero & x.size, KingCooKit.fill(color, .035 * glow));
    KingCooKit.glow(c, at, h * .62, color, .26 * glow);
    KingCooKit.glow(c, at, h * .22, color, .42 * glow);
    // The rooftops catch it: a wide pool on the street below him.
    c.drawOval(
      Rect.fromCenter(
        center: Offset(at.dx - h * .55, h * .955),
        width: h * 1.5,
        height: h * .12,
      ),
      KingCooKit.fill(color, .08 * glow),
    );
  }

  // ----------------------------------------------------------------- lanes --

  /// A paint of [color] that fades in over the first tenth of a screen
  /// height of the lanes' run (left of the bird) and out over the last 22%
  /// (toward his chest); [alpha] scales it. The gradient is built once per
  /// run, in px.
  static Paint _fade(Color color, _Ctx x, double alpha) {
    final base = KingCooKit.cached(
      ('sqFade', color.toARGB32(), x.left.round(), x.x1.round()),
      () {
        final span = math.max(1.0, x.x1 - x.left);
        final lead = (x.h * .16 / span).clamp(0.0, .3);
        return KingCooKit.linear(
          Offset(x.left, 0),
          Offset(x.x1, 0),
          [color.withValues(alpha: 0), color, color, color.withValues(alpha: 0)],
          [0, lead, .78, 1],
        );
      },
    );
    return Paint()
      ..shader = base.shader
      ..color = Color.fromRGBO(0, 0, 0, alpha.clamp(0.0, 1.0));
  }

  static Paint _fadeLine(Color color, _Ctx x, double alpha, double width) =>
      _fade(color, x, alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round;

  static Path _hatch(_Ctx x) =>
      KingCooKit.cachedPath(('sqHatch', x.h.round(), x.left.round(), x.x1.round()), () {
        final path = Path();
        final pitch = x.h * .126;
        for (var xx = x.left - x.h; xx < x.x1 + pitch; xx += pitch) {
          path
            ..moveTo(xx, x.h)
            ..lineTo(xx + x.h, 0);
        }
        return path;
      });

  static void _lanes(
    _Ctx x,
    SquadFormation fm,
    double a,
    double flash, {
    bool detail = true,
  }) {
    final c = x.c, h = x.h;
    if (x.x1 - x.left <= h * .3) return;
    final minBand = h * .012;

    // RED: a faint plum wash over the whole blocked span, the rose HATCH only
    // where the pigeons' bodies fly (thin, ink under rose so it reads on the
    // pink haze), and the dashed edge that faces the safe sky.
    for (final band in fm.lanes.red) {
      final top = band.top * h, bottom = band.bottom * h;
      if (bottom - top < minBand) continue;
      c.drawRect(Rect.fromLTRB(x.left, top, x.x1, bottom), _fade(_plum, x, .12 * a));
    }
    final hatch = _hatch(x);
    for (final band in fm.lanes.hatch) {
      final top = band.top * h, bottom = band.bottom * h;
      if (bottom - top < minBand) continue;
      c.save();
      c.clipRect(Rect.fromLTRB(x.left, top, x.x1, bottom), doAntiAlias: false);
      c.drawPath(hatch, _fadeLine(_ink, x, .22 * a, h * .0130));
      c.drawPath(hatch, _fadeLine(_stop, x, (.44 + .30 * flash) * a, h * .0066));
      c.restore();
    }

    // GREEN: open sky lifted a little, a bright bank along each edge it
    // shares with the red.
    for (final band in fm.lanes.green) {
      final top = band.top * h, bottom = band.bottom * h;
      if (bottom - top < minBand) continue;
      final rect = Rect.fromLTRB(x.left, top, x.x1, bottom);
      c.drawRect(
        rect,
        _fade(_go, x, (.30 + .10 * flash) * a)..blendMode = BlendMode.screen,
      );
      final depth = math.min(h * .05, (bottom - top) * .3);
      final real = fm.lanes.boundaries;
      if (real.any((e) => e.$2 && (e.$1 - band.top).abs() < 1e-6)) {
        _bank(x, top, depth, true, (.34 + .2 * flash) * a);
      }
      if (real.any((e) => !e.$2 && (e.$1 - band.bottom).abs() < 1e-6)) {
        _bank(x, bottom, depth, false, (.34 + .2 * flash) * a);
      }
    }

    _edges(x, fm, a, flash);
    _cones(x, fm, a);
    // The chevrons are the fine print: a lane on its way in or out goes
    // without, and in a cross-fade only the stronger of the two has them.
    if (detail && a > .35) {
      _flow(x, fm, a);
      _arrows(x, fm, a);
    }
  }

  /// A bank of light (mint) along the edge at [y] that fades into the green:
  /// [depth] px deep, [downward] when the green is below the edge.
  static void _bank(_Ctx x, double y, double depth, bool downward, double alpha) {
    final base = KingCooKit.cached(
      'sqBank',
      () => KingCooKit.linear(
        Offset.zero,
        const Offset(0, 1),
        [_goLit, _goLit.withValues(alpha: 0)],
      ),
    );
    final c = x.c;
    c.save();
    c.translate(0, y);
    c.scale(1, downward ? depth : -depth);
    c.drawRect(
      Rect.fromLTRB(x.left, 0, x.x1, 1),
      Paint()
        ..shader = base.shader
        ..color = Color.fromRGBO(0, 0, 0, alpha.clamp(0.0, 1.0)),
    );
    c.restore();
  }

  /// The edges between red and green: a dashed rose line on the red side
  /// (marching toward the bird, as the pigeons will) and a solid mint one
  /// just inside the green, each over a dark ink line.
  static void _edges(_Ctx x, SquadFormation fm, double a, double flash) {
    final h = x.h, c = x.c;
    final dash = h * .045, gap = h * .028, period = dash + gap;
    final march = x.reduced ? 0.0 : (x.age * h * .30) % period;
    for (final (y, redAbove) in fm.lanes.boundaries) {
      final py = y * h;
      final line = Path();
      for (var xx = x.left - march; xx < x.x1; xx += period) {
        final x0 = math.max(x.left, xx), x1 = math.min(x.x1, xx + dash);
        if (x1 > x0) {
          line
            ..moveTo(x0, py)
            ..lineTo(x1, py);
        }
      }
      c.drawPath(line, _fadeLine(_ink, x, .70 * a, h * .0185));
      c.drawPath(line, _fadeLine(_stop, x, a, h * .0105));
      final inner = py + (redAbove ? h * .013 : -h * .013);
      final solid = Path()
        ..moveTo(x.left, inner)
        ..lineTo(x.x1, inner);
      c.drawPath(solid, _fadeLine(_ink, x, .55 * a, h * .0165));
      c.drawPath(solid, _fadeLine(_go, x, (.85 + .15 * flash) * a, h * .008));
    }
  }

  /// A cone standing on the point ([x], [y]) with its tip [dir] (-1 up, 1
  /// down) and base width .66 of its [size] height ([body]: the cone and its
  /// base; else the stripe).
  static void _addCone(
    Path p,
    double x,
    double y,
    double size,
    double dir, {
    required bool body,
  }) {
    double px(double v) => x + v * size;
    double py(double v) => y + v * size * dir;
    if (body) {
      p
        ..moveTo(px(-.50), py(0))
        ..lineTo(px(-.15), py(-1.0))
        ..lineTo(px(.15), py(-1.0))
        ..lineTo(px(.50), py(0))
        ..close()
        ..moveTo(px(-.66), py(.04))
        ..lineTo(px(-.66), py(-.12))
        ..lineTo(px(.66), py(-.12))
        ..lineTo(px(.66), py(.04))
        ..close();
    } else {
      p
        ..moveTo(px(-.33), py(-.40))
        ..lineTo(px(.33), py(-.40))
        ..lineTo(px(.24), py(-.64))
        ..lineTo(px(-.24), py(-.64))
        ..close();
    }
  }

  /// Traffic cones standing on every edge, tips toward the red, with one at
  /// the boss's end of each edge as a stop. Built once per screen and lanes.
  static void _cones(_Ctx x, SquadFormation fm, double a) {
    final h = x.h;
    final key = Object.hashAll([
      'sqCones',
      h.round(),
      x.left.round(),
      x.x1.round(),
      for (final (y, up) in fm.lanes.boundaries) ...[(y * 1000).round(), up],
    ]);
    final size = h * .052;
    List<double> spots() => [x.left + h * .07, (x.left + x.x1) / 2, x.x1 - h * .04];
    Path build(bool body) {
      final all = Path();
      for (final (y, redAbove) in fm.lanes.boundaries) {
        final xs = spots();
        for (final xx in xs) {
          _addCone(all, xx, y * h, size, redAbove ? 1.0 : -1.0, body: body);
        }
      }
      return all;
    }

    final body = KingCooKit.cachedPath((key, 'b'), () => build(true));
    final stripes = KingCooKit.cachedPath((key, 's'), () => build(false));
    final c = x.c;
    c.drawPath(body, KingCooKit.line(_ink, h * .0095, a));
    c.drawPath(body, KingCooKit.fill(_cone, a));
    c.drawPath(stripes, KingCooKit.fill(_cream, a));
  }

  /// Chevrons flowing left along the green: the way the traffic goes, and
  /// open sky.
  static void _flow(_Ctx x, SquadFormation fm, double a) {
    final h = x.h, c = x.c;
    final s = h * .03, spacing = h * .23;
    final span = x.x1 - x.left - h * .08;
    if (span <= spacing) return;
    final march = x.reduced ? 0.0 : (x.age * h * .26) % spacing;
    for (final band in fm.lanes.green) {
      final height = band.height * h;
      if (height < h * .09) continue;
      final rows = height > h * .22 ? 2 : 1;
      for (var r = 0; r < rows; r++) {
        final y = (band.top + band.height * (r + .5) / rows) * h;
        final path = Path();
        // A row's chevrons march left and fade in and out at its ends (the
        // lane's own fade).
        for (var xx = x.left + h * .06 - march + spacing; xx < x.left + span; xx += spacing) {
          if (xx < x.left + h * .02) continue;
          _chevron(path, xx, y, s, const Offset(-1, 0));
        }
        c.drawPath(path, _fadeLine(_ink, x, .5 * a, h * .0185));
        c.drawPath(path, _fadeLine(_goLit, x, .92 * a, h * .0095));
      }
    }
  }

  /// A chevron of size [s] centred at ([cx], [cy]) pointing along [dir].
  static void _chevron(Path p, double cx, double cy, double s, Offset dir) {
    final px = -dir.dy, py = dir.dx;
    final ax = cx + dir.dx * s * .5, ay = cy + dir.dy * s * .5;
    final bx = cx - dir.dx * s * .5, by = cy - dir.dy * s * .5;
    p
      ..moveTo(bx + px * s, by + py * s)
      ..lineTo(ax, ay)
      ..lineTo(bx - px * s, by - py * s);
  }

  /// Up and down chevrons inside the red, marching toward the nearest green:
  /// the way out for a bird that is in the wrong place.
  static void _arrows(_Ctx x, SquadFormation fm, double a) {
    final h = x.h, c = x.c;
    final s = h * .034;
    // ONE column, just left of the bird: the way out, where the eye is.
    final cols = <double>[
      (FlightSimulation.birdX - .11) * h,
    ].where((v) => v > x.left + h * .03 && v < x.x1 - h * .06).toList();
    if (cols.isEmpty) return;
    for (final band in fm.lanes.red) {
      final top = band.top * h, bottom = band.bottom * h;
      if (bottom - top < h * .05) continue;
      final greenAbove = band.top > .01, greenBelow = band.bottom < .99;
      final mid = (top + bottom) / 2;
      final halves = <(double, double, bool)>[
        if (greenAbove && greenBelow) ...[(top, mid, true), (mid, bottom, false)],
        if (greenAbove && !greenBelow) (top, bottom, true),
        if (!greenAbove && greenBelow) (top, bottom, false),
      ];
      for (final (t, b, up) in halves) {
        final dir = Offset(0, up ? -1 : 1);
        for (var row = 0; row < 2; row++) {
          final phase = x.reduced ? (row + .5) / 2 : (x.age * 1.1 + row / 2) % 1;
          final alpha = math.sin(phase * math.pi) * a;
          if (alpha <= .03) continue;
          final from = up ? b - (b - t) * .12 : t + (b - t) * .12;
          final to = up ? t + (b - t) * .12 : b - (b - t) * .12;
          final y = from + (to - from) * phase;
          final path = Path();
          for (final cx in cols) {
            _chevron(path, cx, y, s, dir);
            _chevron(path, cx, y + (up ? s * .85 : -s * .85), s, dir);
          }
          c.drawPath(path, KingCooKit.line(_ink, h * .021, alpha * .55));
          c.drawPath(path, KingCooKit.line(_goLit, h * .0115, alpha));
        }
      }
    }
  }

  // ------------------------------------------------------------------ tags --

  /// What the tag says for a [shape] (the HUD's `cooHint` says the same).
  /// No colour is named: the lane is open sky and the tag works for a player
  /// who cannot tell green from red.
  static String labelOf(SquadShape shape) =>
      shape == SquadShape.v ? 'OPEN LANE = GO' : 'USE THE GAP';

  /// What comes next, on the pips' line (fury calls two squadrons).
  static String nextOf(SquadShape shape) =>
      shape == SquadShape.v ? 'THEN: V' : 'THEN: GAP';

  static const cancelLabel = 'SQUAD CANCELLED';

  static final _labels = <String, TextPainter>{};

  static TextPainter _text(String value, double size, Color color) {
    final key = '$value|${size.toStringAsFixed(1)}|${color.toARGB32()}';
    final hit = _labels.remove(key);
    if (hit != null) return _labels[key] = hit;
    if (_labels.length >= 48) _labels.remove(_labels.keys.first);
    return _labels[key] = TextPainter(
      text: TextSpan(
        text: value,
        style: heading(size, color: color).copyWith(letterSpacing: size * .05),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  /// The room the tags have: left of the bird, clear of its column.
  static double _room(_Ctx x) =>
      (FlightSimulation.birdX - .085) * x.h - x.h * .03 - x.h * .03;

  /// A pill with an icon and a label, [left] / centred on [cy]; the label is
  /// set smaller (never past [minSize]) so the pill fits [_room]. Returns the
  /// pill's rect.
  static Rect _pill(
    _Ctx x,
    String label,
    double cy,
    double a, {
    required Color accent,
    required Color ink,
    required void Function(Canvas c, Offset at, double size) icon,
    bool pips = false,
    double pipFill = 0,
    double pipBlink = 0,
    double scale = 1,
    String? sub,
  }) {
    final h = x.h, c = x.c;
    final pad = h * .016 * scale, iconW = h * .036 * scale;
    final room = _room(x);
    final base = h * .040 * scale;
    var text = _text(label, base, ink);
    final spare = room - (pad * 2 + iconW + pad * .7);
    if (text.width > spare) {
      final fit = math.max(h * .028 * scale, (base * spare / text.width * 10).floorToDouble() / 10);
      text = _text(label, fit, ink);
    }
    final tall = h * (pips ? .092 : .060) * scale;
    final w = pad * 2 + iconW + pad * .7 + text.width;
    final rect = Rect.fromLTWH(
      h * .03,
      (cy - tall / 2).clamp(h * .17, h - tall - h * .04),
      w,
      tall,
    );
    final plate = RRect.fromRectAndRadius(rect, Radius.circular(tall * (pips ? .26 : .40)));
    c.drawRRect(plate.shift(Offset(0, h * .006)), KingCooKit.fill(_ink, .45 * a));
    c.drawRRect(plate, KingCooKit.fill(_plate, .93 * a));
    c.drawRRect(plate, KingCooKit.line(accent, h * .0055, a));
    final rowCy = pips ? rect.top + tall * .36 : rect.center.dy;
    icon(c, Offset(rect.left + pad + iconW / 2, rowCy), iconW);
    if (a > .4) {
      text.paint(
        c,
        Offset(rect.left + pad + iconW + pad * .7, rowCy - text.height / 2 - h * .003),
      );
    }
    if (pips) {
      final pipH = h * .013, gap = h * .008;
      // The sub-line: the pips, and (fury) what comes next beside them.
      final span = (rect.width - pad * 2) * (sub == null ? 1 : .46);
      final pipW = (span - gap * 2) / 3;
      final y = rect.bottom - pad * 1.05 - pipH;
      final back = Path(), fill = Path();
      for (var i = 0; i < 3; i++) {
        final x0 = rect.left + pad + i * (pipW + gap);
        back.addRRect(
          RRect.fromLTRBR(x0, y, x0 + pipW, y + pipH, Radius.circular(pipH / 2)),
        );
        final f = ((pipFill * 3) - i).clamp(0.0, 1.0);
        if (f > 0) {
          fill.addRRect(
            RRect.fromLTRBR(
              x0,
              y,
              x0 + pipW * f,
              y + pipH,
              Radius.circular(pipH / 2),
            ),
          );
        }
      }
      c.drawPath(back, KingCooKit.fill(_ink, .6 * a));
      c.drawPath(
        fill,
        KingCooKit.fill(
          Color.lerp(KingCooPalette.gold, _goLit, pipBlink)!,
          a,
        ),
      );
      if (sub != null && a > .4) {
        final then = _text(sub, h * .026 * scale, _stopLit);
        then.paint(
          c,
          Offset(
            rect.right - pad - then.width,
            y + pipH / 2 - then.height / 2 - h * .002,
          ),
        );
      }
    }
    return rect;
  }

  static void _flowIcon(Canvas c, Offset at, double size) {
    final path = Path();
    _chevron(path, at.dx - size * .17, at.dy, size * .34, const Offset(-1, 0));
    _chevron(path, at.dx + size * .17, at.dy, size * .34, const Offset(-1, 0));
    c.drawPath(path, KingCooKit.line(_ink, size * .30, .6));
    c.drawPath(path, KingCooKit.line(_go, size * .17));
  }

  static void _gapIcon(Canvas c, Offset at, double size) {
    final r = size * .5;
    final bars = Path()
      ..moveTo(at.dx - r, at.dy - r * .78)
      ..lineTo(at.dx + r, at.dy - r * .78)
      ..moveTo(at.dx - r, at.dy + r * .78)
      ..lineTo(at.dx + r, at.dy + r * .78);
    c.drawPath(bars, KingCooKit.line(_ink, size * .30, .6));
    c.drawPath(bars, KingCooKit.line(_stop, size * .17));
    final arrow = Path();
    _chevron(arrow, at.dx, at.dy, size * .36, const Offset(-1, 0));
    c.drawPath(arrow, KingCooKit.line(_ink, size * .30, .6));
    c.drawPath(arrow, KingCooKit.line(_go, size * .17));
  }

  static void _cancelIcon(Canvas c, Offset at, double size) {
    final r = size * .36;
    c.drawCircle(at, r, KingCooKit.line(_ink, size * .30, .6));
    c.drawCircle(at, r, KingCooKit.line(KingCooPalette.gold, size * .17));
    final slash = Path()
      ..moveTo(at.dx - r * .7, at.dy + r * .7)
      ..lineTo(at.dx + r * .7, at.dy - r * .7);
    c.drawPath(slash, KingCooKit.line(_ink, size * .30, .6));
    c.drawPath(slash, KingCooKit.line(KingCooPalette.gold, size * .17));
  }

  static void _tags(_Ctx x, List<SquadFormation> fs, List<double> alpha) {
    // The current formation: the first not yet cleared.
    var k = 0;
    while (k < fs.length - 1 && x.age >= fs[k].clearAt) {
      k++;
    }
    final fm = fs[k];
    final a = alpha[k];
    if (a <= .02) return;
    final h = x.h;
    // The tag sits in the tallest green lane (the lower one on a tie).
    final cy = _tagHeight(fm) * h;
    final fill = BossMotion.ramp(
      x.age,
      k == 0 ? fm.puffAt : fs[k - 1].clearAt,
      fm.firstCrossAt,
    );
    final blink = x.reduced || fill < 1
        ? 0.0
        : .5 + .5 * math.sin((x.age - fm.firstCrossAt) * 18);
    // ONE tag: the label, the pips, and (fury's V) what comes next on the
    // pips' line.
    _pill(
      x,
      labelOf(fm.plan.shape),
      cy,
      a,
      accent: _go,
      ink: _goLit,
      icon: fm.plan.shape == SquadShape.v ? _flowIcon : _gapIcon,
      pips: true,
      pipFill: fill,
      pipBlink: blink,
      sub: k + 1 < fs.length ? nextOf(fs[k + 1].plan.shape) : null,
    );
  }

  // ------------------------------------------------------------------ ghost --

  static final List<ui.Picture?> _gliders = List.filled(
    AlleyPigeonArtCoats.count,
    null,
  );

  /// A squadron glider (the Alley Pigeon's variant, resting wings) of plumage
  /// [coat], recorded once at unit radius. The squadron are individuals: the
  /// ghost's pigeons wear the three coats in turn, as the real ones do.
  static ui.Picture _gliderPicture(int coat) {
    final i = coat % AlleyPigeonArtCoats.count;
    return _gliders[i] ??= () {
      final rec = ui.PictureRecorder();
      AlleyPigeonArt.paint(
        Canvas(rec),
        1,
        seconds: 0,
        reducedMotion: true,
        pose: PigeonPose(coat: i),
        glider: true,
      );
      return rec.endRecording();
    }();
  }

  /// Where a ghost pigeon of [slot] hangs: tip at the ghost column, wings
  /// behind it as the real V will fly.
  static Offset _ghostAt(_Ctx x, SquadSlot slot) => Offset(
    (FlightSimulation.birdX + ghostAhead + slot.behind) * x.h,
    slot.y * x.h,
  );

  static void _ghost(_Ctx x, SquadFormation fm) {
    final h = x.h, c = x.c;
    final inn = BossMotion.ease(
      BossMotion.ramp(x.age, fm.puffAt, fm.puffAt + fadeIn + .1),
    );
    final out =
        1 - BossMotion.ease(BossMotion.ramp(x.age, fm.releaseAt, fm.releaseAt + .35));
    final a = inn * out;
    if (a <= .01) return;
    final shimmer = x.reduced ? 0.0 : math.sin(x.age * 9) * .08;
    final r = h * SkyEnemy.radius;
    Rect? box;
    final spots = [for (final s in _drawable(fm.plan)) _ghostAt(x, s)];
    for (final p in spots) {
      final one = Rect.fromCircle(center: p, radius: r * 2.4);
      box = box == null ? one : box.expandToInclude(one);
    }
    if (box == null || !box.isFinite) return;
    final clipped = box.intersect(Offset.zero & x.size);
    if (clipped.isEmpty) return;
    c.saveLayer(
      clipped,
      Paint()
        ..color = Color.fromRGBO(255, 255, 255, (.78 + shimmer) * a)
        ..colorFilter = ColorFilter.mode(
          _stop.withValues(alpha: .40),
          BlendMode.srcATop,
        ),
    );
    for (var i = 0; i < spots.length; i++) {
      final p = spots[i];
      c.save();
      c.translate(p.dx, p.dy);
      c.scale(r);
      c.rotate(PigeonPose.squadTilt(i + fm.index * 3));
      c.drawPicture(_gliderPicture(i + fm.index));
      c.restore();
    }
    c.restore();
  }

  // ------------------------------------------------------------------ queue --

  /// Where a waiting pigeon of [slot] stands: behind his chest, the V's
  /// shape kept, at its lane's height.
  static Offset _home(_Ctx x, SquadSlot slot) => Offset(
    x.bossX + 2.0 * x.unit + slot.behind * x.h,
    slot.y * x.h,
  );

  /// Where it leaves from: his chest, where the real pigeon is born.
  static Offset _spawn(_Ctx x, SquadSlot slot) =>
      Offset(x.bossX + slot.behind * x.h, x.bossY);

  /// The pigeons of the next squadron to leave, at most
  /// [KingCooSquadBudget.queueGliders]: they fly in from the right edge along
  /// their lanes (a faint streak behind each), stand behind him fidgeting,
  /// and slide behind his chest as the whistle nears, where the real ones are
  /// born.
  static void _queue(_Ctx x, List<SquadFormation> fs) {
    SquadFormation? fm;
    for (final f in fs) {
      if (x.age < f.releaseAt) {
        fm = f;
        break;
      }
    }
    if (fm == null) return;
    final h = x.h, c = x.c;
    final slots = _drawable(fm.plan);
    final n = math.min(slots.length, KingCooSquadBudget.queueGliders);
    // A later squadron starts coming in once the one before has left.
    final start = fm.index == 0 ? fm.puffAt : math.max(fm.puffAt, fs[fm.index - 1].releaseAt);
    final r = h * SkyEnemy.radius;
    final trails = Path();
    final order = [for (var i = 0; i < n; i++) i];
    // Far lanes first, so the near ones overlap them.
    order.sort((a, b) => slots[a].y.compareTo(slots[b].y));
    for (final i in order) {
      final slot = slots[i];
      final home = _home(x, slot);
      final spawn = _spawn(x, slot);
      final enter = Offset(x.size.width + h * .12, home.dy);
      final t0 = start + i * _queueStagger;
      if (x.age < t0) continue;
      // Reduced Motion: they are simply there (no flight in, no slide out).
      final u = x.reduced ? 1.0 : BossMotion.ramp(x.age, t0, t0 + _queueEntry);
      final slide = x.reduced
          ? 0.0
          : BossMotion.ramp(x.age, fm.releaseAt - _queueSlide, fm.releaseAt);
      final eased = 1 - math.pow(1 - u, 3).toDouble();
      var at = Offset.lerp(enter, home, eased)!;
      at = Offset.lerp(at, spawn, slide * slide)!;
      final idle = u >= 1 && !x.reduced
          ? math.sin(x.age * 5.2 + i * 1.7) * h * .006
          : 0.0;
      at += Offset(0, idle);
      if (!_near(x, at, r * 4)) continue;
      if (u < 1 && !x.reduced) {
        final trail = h * .10 * (1 - u);
        for (final k in [-1, 1]) {
          trails
            ..moveTo(at.dx + r * 1.6, at.dy + k * r * .5)
            ..lineTo(at.dx + r * 1.6 + trail, at.dy + k * r * .5);
        }
      }
      c.save();
      c.translate(at.dx, at.dy);
      AlleyPigeonArt.paint(
        c,
        r,
        seconds: x.reduced ? 0 : x.age + i * .31,
        reducedMotion: x.reduced,
        pose: PigeonPose(
          coat: i + fm.index,
          tilt: PigeonPose.squadTilt(i + fm.index * 3),
        ),
        glider: true,
      );
      c.restore();
    }
    c.drawPath(trails, KingCooKit.line(_ink, h * .011, .30));
    c.drawPath(trails, KingCooKit.line(_cream, h * .0055, .65));
  }

  // ------------------------------------------------------------------- cues --

  // The inhale: air curls into the beak (the chest swells, the siren
  // blinks). Tapering wisps spiralling in toward the whistle from the bird's
  // side, drawn in as the whistle nears.
  static void _inhale(_Ctx x, KingCooPose pose, double k) {
    if (k <= .02) return;
    final h = x.h, c = x.c;
    final mouth = KingCooBossRig.whistleAt(pose);
    final at = Offset(x.bossX + mouth.dx * x.unit, x.bossY + mouth.dy * x.unit);
    if (!_near(x, at, x.h * 2)) return;
    final path = Path();
    const n = 7;
    for (var i = 0; i < n; i++) {
      final angle = math.pi + (i / (n - 1) - .5) * 2.1;
      final life = x.reduced ? .35 : (x.age * 1.15 + i * .37) % 1;
      final r0 = h * (.34 - .27 * life), len = h * .13 * (1 - life * .6);
      final swirl = .38 * (1 - life);
      final a0 = angle + swirl, a1 = angle + swirl * .4;
      final p0 = at + Offset(math.cos(a0), math.sin(a0)) * r0;
      final p1 = at + Offset(math.cos(a1), math.sin(a1)) * (r0 - len);
      final mid = Offset.lerp(p0, p1, .5)! +
          Offset(math.cos(angle + math.pi / 2), math.sin(angle + math.pi / 2)) * h * .018;
      path
        ..moveTo(p0.dx, p0.dy)
        ..quadraticBezierTo(mid.dx, mid.dy, p1.dx, p1.dy);
    }
    c.drawPath(path, KingCooKit.line(_ink, h * .0165, .40 * k));
    c.drawPath(path, KingCooKit.line(_cream, h * .0085, .85 * k));
  }

  // The whistle's blast: sound arcs spreading from the whistle toward the
  // bird, over .45 s.
  static void _blast(_Ctx x, KingCooPose pose, double k) {
    if (k <= .02) return;
    final h = x.h, c = x.c;
    final w = KingCooBossRig.whistleAt(pose);
    final at = Offset(x.bossX + w.dx * x.unit, x.bossY + w.dy * x.unit);
    if (!_near(x, at, x.h * 2)) return;
    final since = (x.boss.cooCycle - KingCoo.whistleAt) / blastSeconds;
    final u = x.reduced ? .5 : since.clamp(0.0, 1.0);
    final arcs = Path();
    for (var i = 0; i < 3; i++) {
      final radius = h * (.07 + .075 * i + .26 * u);
      arcs.addArc(
        Rect.fromCircle(center: at, radius: radius),
        math.pi - .62,
        1.24,
      );
    }
    final fade = x.reduced ? .9 : (1 - u * u);
    c.drawPath(arcs, KingCooKit.line(_ink, h * .024, .5 * fade));
    c.drawPath(arcs, KingCooKit.line(_cream, h * .013, .95 * fade));
  }

  // ----------------------------------------------------------------- cancel --

  /// The call called off: the lanes fade, the ghost and the queue dissolve
  /// into puffs of feathers, a chip says so. [since] is seconds since the pop,
  /// [popAt] the boss age of it.
  static void _cancel(
    _Ctx x,
    List<SquadFormation> fs,
    double since,
    double popAt, {
    required bool withLanes,
    required bool withPuffs,
  }) {
    final h = x.h, c = x.c;
    final fm = fs.first;
    // The lanes' last light (as bright as they had grown), then nothing.
    final grown = BossMotion.ease(
      BossMotion.ramp(popAt, fm.puffAt, fm.puffAt + fadeIn),
    );
    final lanesA = x.reduced
        ? 0.0
        : grown * (1 - BossMotion.ease(BossMotion.ramp(since, 0, .3)));
    if (withLanes && lanesA > .01) {
      for (final f in fs) {
        _lanes(x, f, lanesA, 0);
      }
    }
    if (!withPuffs) return;
    final u = x.reduced ? .45 : BossMotion.ramp(since, 0, .6);
    // Puffs where the ghost hung and where the queue stood (as much of each
    // as had come by the pop).
    final seen = BossMotion.ease(
      BossMotion.ramp(popAt, fm.puffAt, fm.puffAt + .4),
    );
    final slots = _drawable(fm.plan);
    final spots = <Offset>[
      for (final s in slots) _ghostAt(x, s),
      for (final s in slots.take(KingCooSquadBudget.queueGliders)) _home(x, s),
    ];
    final r = x.h * SkyEnemy.radius;
    final feathers = Path();
    final fade = seen * (1 - BossMotion.ease(BossMotion.ramp(u, .55, 1.0)));
    final puff = KingCooKit.scallop(5, .20, turn: .3);
    final grow = r * (.8 + 1.2 * BossMotion.ease(u));
    for (final (i, p) in spots.indexed) {
      if (!_near(x, p, r * 8)) continue;
      if (fade > .01) {
        c.save();
        c.translate(p.dx, p.dy);
        c.scale(grow);
        c.drawPath(puff, KingCooKit.fill(_cream, .85 * fade));
        c.drawPath(puff, KingCooKit.line(_ink, h * .0085 / grow, .5 * fade));
        c.restore();
      }
      for (var f = 0; f < 2; f++) {
        final angle = (i * 2 + f) * 2.399963;
        final out = r * (1.2 + 4.0 * u) * (.7 + .3 * ((i + f) % 3) / 2);
        final fp =
            p +
            Offset(
              math.cos(angle) * out,
              math.sin(angle) * out - r * u * 1.5,
            );
        final turn = angle + u * 3;
        final d = Offset(math.cos(turn), math.sin(turn)) * r * .55;
        feathers
          ..moveTo(fp.dx - d.dx, fp.dy - d.dy)
          ..quadraticBezierTo(
            fp.dx - d.dy * .5,
            fp.dy + d.dx * .5,
            fp.dx + d.dx,
            fp.dy + d.dy,
          )
          ..quadraticBezierTo(
            fp.dx + d.dy * .5,
            fp.dy - d.dx * .5,
            fp.dx - d.dx,
            fp.dy - d.dy,
          );
      }
    }
    if (fade > .01) {
      c.drawPath(feathers, KingCooKit.fill(const Color(0xffc9cfee), fade));
      c.drawPath(feathers, KingCooKit.line(_ink, h * .006, .7 * fade));
    }
    // The chip.
    final chip =
        BossMotion.ease(BossMotion.ramp(since, .1, .3)) *
        (1 -
            BossMotion.ease(
              BossMotion.ramp(since, cancelSeconds - .35, cancelSeconds),
            ));
    if (chip > .02) {
      _pill(
        x,
        cancelLabel,
        _tagHeight(fm) * h,
        chip,
        accent: KingCooPalette.gold,
        ink: KingCooPalette.gold,
        icon: _cancelIcon,
      );
    }
  }

  /// Whether [p] is within [pad] px of the screen: marks further away are
  /// not drawn (a hostile boss position cannot send a canvas to infinity).
  static bool _near(_Ctx x, Offset p, double pad) =>
      p.dx.isFinite &&
      p.dy.isFinite &&
      p.dx > -pad &&
      p.dx < x.size.width + pad &&
      p.dy > -pad &&
      p.dy < x.size.height + pad;

  /// The slots of [plan] that have a place to draw: a hostile plan (a NaN
  /// lane, an infinite offset) is drawn without them.
  static List<SquadSlot> _drawable(SquadPlan plan) => [
    for (final s in plan.slots)
      if (s.y.isFinite && s.behind.isFinite && s.y.abs() < 10 && s.behind.abs() < 10) s,
  ];

  /// The height (screen heights) a tag sits at: the middle of the tallest
  /// green lane of [fm] (the lower one on a tie).
  static double _tagHeight(SquadFormation fm) {
    LaneBand? lane;
    for (final g in fm.lanes.green) {
      if (lane == null || g.height >= lane.height - 1e-9) lane = g;
    }
    return lane?.centre ?? .5;
  }
}

/// The frame's numbers, computed once per paint.
final class _Ctx {
  _Ctx(this.c, this.size, this.boss, this.reduced)
    : h = size.height,
      age = boss.age,
      unit = size.height * SkyBoss.radius,
      bossX = boss.x * size.height,
      bossY = boss.y * size.height {
    // The lanes run from the left edge to just in front of his chest.
    x1 = (bossX - 1.2 * unit).clamp(0.0, size.width);
    // ...and start a little left of the bird's column.
    left = (FlightSimulation.birdX * h - KingCooSquadArt.leftReach * h).clamp(
      0.0,
      x1,
    );
  }

  final Canvas c;
  final Size size;
  final SkyBoss boss;
  final bool reduced;
  final double h, age, unit, bossX, bossY;
  late final double x1, left;
}
