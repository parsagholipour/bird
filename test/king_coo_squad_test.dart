import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/game/bird_puppet.dart';
import 'package:push_up_bird/game/boss_encounter_art.dart';
import 'package:push_up_bird/game/boss_motion.dart';
import 'package:push_up_bird/game/combat_art.dart';
import 'package:push_up_bird/game/king_coo_kit.dart';
import 'package:push_up_bird/game/king_coo_layout.dart';
import 'package:push_up_bird/game/king_coo_pose.dart';
import 'package:push_up_bird/game/king_coo_squad_art.dart';
import 'package:push_up_bird/game/sky_scenery.dart';

import 'king_coo_helpers.dart';
import 'king_coo_test_kit.dart' hide birdX;

/// K6: King Coo's whistle squadron on screen (`KingCooSquadArt`): the lanes
/// that go red (blocked) and green (go), the ghost of the formation, the
/// queue behind him, the siren's light, the cues and the cancel.
///
/// What is pinned, in order:
///  * THE LANES ARE THE RULES' LANES: derived from the plans the rules make,
///    checked against the squad tracks' geometry and against the real
///    simulation (a bird held at a green height is never hurt by the
///    squadron, one held at a red height is) at 640 and 800, calm and fury;
///    and the pixels the art draws put the red and the green exactly where
///    the model says.
///  * Timing: lanes live from the puff to the last pigeon's passing (crossing
///    times match the simulation's), a fury's second call takes over as the
///    first clears, the ghost and the queue end at the whistle.
///  * The cancel (a pop before the whistle) and the rules hook it needs.
///  * Budget, determinism, non-finite safety, Reduced Motion, never hiding
///    the bird, the cues and the tags' room.
///  * Evidence renders (`build/king-coo-squad-review/`).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('the lanes are the rules\' lanes', _lanesGroup);
  group('timeline', _timelineGroup);
  group('cancel', _cancelGroup);
  group('pixels', _pixelsGroup);
  group('budget and robustness', _budgetGroup);
  group('Reduced Motion', _reducedGroup);
  group('evidence', _evidenceGroup);
}

// ======================================================================
// helpers
// ======================================================================

const _h = 360.0;
const _widths = [640.0, 800.0];
double _heights(double px) => px / _h;

/// The bird's column on a screen, in px.
double _birdPx() => FlightSimulation.birdX * _h;

/// A King Coo [c] seconds into cycle [cycle] with the squadron the rules
/// plan for a bird at [birdY] (the plan exists from the puff).
SkyBoss _boss({
  double c = 8.4,
  int cycle = 0,
  bool fury = false,
  double birdY = .5,
  double widthPx = 640,
  bool called = false,
  double? popAt,
}) {
  final boss = SkyBoss(
    number: 6,
    x: bossColumn(_heights(widthPx)),
    kind: BossKind.kingCoo,
    cinematic: true,
  );
  if (fury) {
    boss.hp = KingCoo.furyHp;
    boss.enragedAt = boss.arrivalDuration - 30;
  }
  boss.age = boss.arrivalDuration + cycle * KingCoo.period + c;
  boss.puffsLatched = cycle + 1;
  boss.squadCalled = called || c >= KingCoo.whistleAt;
  final plans = KingCoo.squad(cycle: cycle, birdY: birdY, fury: fury);
  if (popAt != null) {
    boss.poppedAt = boss.arrivalDuration + cycle * KingCoo.period + popAt;
    if (popAt < KingCoo.whistleAt) {
      boss.cancelledSquad = plans;
      boss.squadCalled = false;
    } else {
      boss.squad = plans;
    }
  } else if (c >= KingCoo.puffAt) {
    boss.squad = plans;
  }
  return boss;
}

BossMotion _motion(SkyBoss b, {bool reduced = false}) =>
    BossMotion(b, reducedMotion: reduced);

/// The squad art alone on a transparent [w] x 360 canvas.
void _art(
  Canvas c,
  double w,
  SkyBoss boss, {
  bool reduced = false,
  Set<String>? only,
}) {
  KingCooSquadArt.paint(
    c,
    Size(w, _h),
    boss,
    _motion(boss, reduced: reduced),
    only: only,
  );
}

Future<Uint8List> _pixels(
  double w,
  SkyBoss boss, {
  bool reduced = false,
  Set<String>? only,
}) => rawPixels(w.round(), _h.round(), (c) => _art(c, w, boss, reduced: reduced, only: only));

int _hash(Uint8List data) {
  var hash = 0x811c9dc5;
  for (var i = 0; i < data.length; i += 1) {
    hash = ((hash ^ data[i]) * 0x01000193) & 0xffffffff;
  }
  return hash;
}

/// A fight (a flight of the test-only 3-2) brought to [c] seconds into cycle
/// [cycle], the bird held at [hold] (before and after the puff alike).
FlightSimulation _fightAt(
  double widthPx,
  int cycle,
  double c, {
  double hold = .5,
  bool fury = false,
}) {
  final sim = cooFight(width: _heights(widthPx));
  if (fury) sim.boss!.hp = KingCoo.furyHp;
  runTo(
    sim,
    cycle * KingCoo.period + c,
    width: _heights(widthPx),
    hold: hold,
    protect: true,
  );
  return sim;
}

/// The scene as the encounter composes it: the sky, the encounter's
/// backdrop (which calls the squad art), the rig, the real pigeons and the
/// bird. Used by the evidence and the "never hides" tests.
void _scene(
  Canvas c,
  FlightSimulation sim,
  double w, {
  bool reduced = false,
  bool bird = true,
  WorldRegion? region,
}) {
  final size = Size(w, _h);
  c.save();
  c.clipRect(Offset.zero & size);
  SkyScenery.paint(
    c,
    size,
    seconds: sim.elapsed,
    distance: sim.distance,
    reducedMotion: reduced,
    held: region ?? sim.region,
  );
  final boss = sim.boss!;
  final m = BossMotion(boss, reducedMotion: reduced);
  BossEncounterArt.backdrop(c, size, boss, m);
  final sky = SkyPalette.at(sim.elapsed, held: region ?? sim.region);
  final light = KingCooSkyLight.fromSky(
    top: sky.top,
    horizon: sky.horizon,
    haze: sky.haze,
  );
  final pose = KingCooPose(
    boss,
    m,
    lookY: (sim.birdY - boss.y) * 3,
    light: light,
  );
  paintFigure(c, pose, Offset(boss.x * _h, boss.y * _h), _h);
  CombatArt.paint(c, _h, sim, reducedMotion: reduced);
  if (bird) _bird(c, sim.birdY);
  c.restore();
}

void _bird(Canvas c, double y) {
  const bw = _h * .145;
  c.save();
  c.translate(_birdPx(), y * _h);
  BirdPuppet.paint(
    c,
    Rect.fromLTWH(-bw * .48, -bw * .43, bw, bw * 224 / 256),
    bird: 0,
    wing: .3,
  );
  c.restore();
}

// ======================================================================
// the lanes are the rules' lanes
// ======================================================================

/// A bird holding height [y] at the bird's column is within a pigeon's reach
/// of a lane of [plan] at some moment, by the squad tracks' own geometry.
bool _hitByTracks(SkyBoss boss, SquadPlan plan, double y) {
  final release = boss.squadReleaseAt(plan);
  for (final slot in plan.slots) {
    final track = SquadTrack(
      x0: boss.x + slot.behind,
      fromY: boss.y,
      lane: slot.y,
      bornAt: release,
    );
    final cross = track.crossesAt(FlightSimulation.birdX);
    for (var t = cross - .4; t <= cross + .4; t += 1 / 240) {
      final dx = track.x(t) - FlightSimulation.birdX;
      final dy = track.y(t) - y;
      if (dx * dx + dy * dy <= KingCoo.pigeonReach * KingCoo.pigeonReach) {
        return true;
      }
    }
  }
  return false;
}

void _lanesGroup() {
  test('red and green tile the sky: no gap, no overlap, in order', () {
    final plans = <SquadPlan>[
      for (final tip in [.25, .3, .35, .4, .5, .6, .65, .7, .75])
        KingCoo.squad(cycle: 0, birdY: tip, fury: false).single,
      for (final bird in [.5, .8, .2])
        for (final cycle in [1, 3])
          KingCoo.squad(cycle: cycle, birdY: bird, fury: false).single,
      ...KingCoo.squad(cycle: 0, birdY: .4, fury: true),
    ];
    for (final plan in plans) {
      final lanes = KingCooSquadArt.lanesOf(plan);
      final all = [...lanes.red, ...lanes.green]
        ..sort((a, b) => a.top.compareTo(b.top));
      expect(all.first.top, closeTo(0, 1e-9));
      expect(all.last.bottom, closeTo(1, 1e-9));
      for (var i = 1; i < all.length; i++) {
        expect(all[i].top, closeTo(all[i - 1].bottom, 1e-9), reason: '$plan');
        expect(all[i].height, greaterThan(0));
      }
      for (final g in lanes.green) {
        expect(g.height, greaterThanOrEqualTo(KingCooSquadArt.minLane - 1e-9));
      }
    }
  });

  test('a green height is outside every pigeon\'s reach; a red one is not '
      '(or is a sliver no bird can hold)', () {
    const reach = KingCoo.pigeonReach, edge = KingCoo.birdRadius;
    final plans = <SquadPlan>[
      for (final tip in [.25, .3, .35, .4, .5, .6, .75])
        KingCoo.squad(cycle: 0, birdY: tip, fury: false).single,
      for (final bird in [.5, .8, .2])
        for (final cycle in [1, 3])
          KingCoo.squad(cycle: cycle, birdY: bird, fury: false).single,
    ];
    for (final plan in plans) {
      final lanes = KingCooSquadArt.lanesOf(plan);
      for (var y = 0.0; y <= 1.0; y += .002) {
        final hurt =
            plan.slots.any((s) => (y - s.y).abs() <= reach) ||
            y <= edge ||
            y >= 1 - edge;
        if (lanes.safe(y)) {
          expect(hurt, isFalse, reason: 'green but hurt at $y ($plan)');
        }
        if (lanes.blocked(y) && !hurt) {
          // Red where nothing hurts: only the unusable slivers.
          final near = lanes.green.every(
            (g) => y < g.top || y > g.bottom,
          );
          expect(near, isTrue);
          final room = _sliverAt(plan, y);
          expect(room, lessThan(KingCooSquadArt.minLane), reason: 'y=$y');
        }
      }
    }
  });

  test('a picket lights exactly its gap; a V lights the sky outside its wings',
      () {
    for (final (cycle, bird, gap) in [
      (1, .5, .30),
      (3, .5, .70),
      (1, .8, .50),
      (1, .2, .50),
    ]) {
      final plan = KingCoo.squad(cycle: cycle, birdY: bird, fury: false).single;
      expect(plan.gap, closeTo(gap, 1e-9));
      final lanes = KingCooSquadArt.lanesOf(plan);
      expect(lanes.green, hasLength(1));
      expect(lanes.green.single.top, closeTo(gap - .15, 1e-9));
      expect(lanes.green.single.bottom, closeTo(gap + .15, 1e-9));
      expect(lanes.red, hasLength(2));
    }
    for (final tip in [.3, .4, .5, .6, .7]) {
      final plan = KingCoo.squad(cycle: 0, birdY: tip, fury: false).single;
      final lanes = KingCooSquadArt.lanesOf(plan);
      for (final g in lanes.green) {
        expect(
          g.bottom <= tip - .233 + 1e-9 || g.top >= tip + .233 - 1e-9,
          isTrue,
          reason: 'tip $tip: $g',
        );
      }
      final red = lanes.red.firstWhere((b) => b.holds(tip));
      expect(red.top, lessThanOrEqualTo(tip - .233 + 1e-9));
      expect(red.bottom, greaterThanOrEqualTo(tip + .233 - 1e-9));
    }
  });

  test('the hatch is confined to the pigeons\' footprint inside the red', () {
    const half = KingCooSquadArt.footprintHalf;
    final plans = <SquadPlan>[
      for (final tip in [.25, .3, .4, .5, .6, .75])
        KingCoo.squad(cycle: 0, birdY: tip, fury: false).single,
      for (final bird in [.5, .8, .2])
        for (final cycle in [1, 3])
          KingCoo.squad(cycle: cycle, birdY: bird, fury: false).single,
      ...KingCoo.squad(cycle: 0, birdY: .4, fury: true),
    ];
    for (final plan in plans) {
      final lanes = KingCooSquadArt.lanesOf(plan);
      // Everything hatched is red and under a pigeon's body.
      for (final band in lanes.hatch) {
        for (var y = band.top; y <= band.bottom; y += .004) {
          expect(lanes.blocked(y), isTrue, reason: 'hatch outside the red at $y');
          expect(
            plan.slots.any((s) => (y - s.y).abs() <= half + .02 + 1e-9),
            isTrue,
            reason: 'hatch with no pigeon near at $y ($plan)',
          );
        }
      }
      // Every body inside the red is hatched.
      for (final slot in plan.slots) {
        for (final y in [slot.y - half * .9, slot.y, slot.y + half * .9]) {
          if (y <= .03 || y >= .97 || !lanes.blocked(y)) continue;
          expect(
            lanes.hatch.any((b) => b.holds(y)),
            isTrue,
            reason: 'a pigeon at ${slot.y} is not hatched at $y',
          );
        }
      }
      // And less of the sky than the whole blocked span.
      final blocked = lanes.red.fold(0.0, (a, b) => a + b.height);
      final hatched = lanes.hatch.fold(0.0, (a, b) => a + b.height);
      expect(hatched, lessThanOrEqualTo(blocked + 1e-9));
    }
  });

  test('by the squad tracks\' geometry, green is never hit and red is, at '
      '640 and 800, calm and fury', () {
    for (final w in _widths) {
      final scenarios = <String, SkyBoss>{
        'V tip .5': _boss(c: 9.3, widthPx: w, called: true),
        'V tip .3': _boss(c: 9.3, widthPx: w, birdY: .3),
        'V tip .7': _boss(c: 9.3, widthPx: w, birdY: .7),
        'picket .30': _boss(c: 9.3, cycle: 1, widthPx: w),
        'picket .70': _boss(c: 9.3, cycle: 3, widthPx: w),
        'picket .50': _boss(c: 9.3, cycle: 1, widthPx: w, birdY: .8),
        'fury V + picket': _boss(c: 9.3, widthPx: w, fury: true, birdY: .3),
      };
      for (final e in scenarios.entries) {
        final boss = e.value;
        for (final plan in boss.squad) {
          final lanes = KingCooSquadArt.lanesOf(plan);
          for (var y = .045; y <= .955; y += .004) {
            final hit = _hitByTracks(boss, plan, y);
            if (lanes.safe(y)) {
              expect(hit, isFalse, reason: '${e.key} @$w green y=$y was hit');
            } else if (lanes.blocked(y) &&
                !_inSliver(lanes, plan, y) &&
                y > .05 &&
                y < .95) {
              expect(hit, isTrue, reason: '${e.key} @$w red y=$y not hit');
            }
          }
        }
      }
    }
  });

  test('in the real simulation a bird held at a green height is never hurt '
      'by the squadron and one at a red height is, at 640 and 800, calm and '
      'fury', () {
    // (cycle, fury, the bird's height at the puff, where it is held after)
    final cases = <(String, int, bool, double)>[
      ('V', 0, false, .5),
      ('V low tip', 0, false, .7),
      ('picket .30', 1, false, .5),
      ('picket .50', 1, false, .8),
      ('fury V + picket', 0, true, .3),
    ];
    for (final w in _widths) {
      final width = _heights(w);
      for (final (name, cycle, fury, atPuff) in cases) {
        // The lanes, from a run to the puff.
        final probe = _fightAt(w, cycle, 7.8, hold: atPuff, fury: fury);
        final plans = probe.boss!.squad;
        expect(plans, isNotEmpty, reason: name);
        final lanes = [for (final p in plans) KingCooSquadArt.lanesOf(p)];
        // Heights to try: inside each band, away from its edges.
        final tries = <double>{};
        for (final l in lanes) {
          for (final b in [...l.red, ...l.green]) {
            if (b.height < .06) continue;
            for (final y in [b.top + .025, b.centre, b.bottom - .025]) {
              if (y > .06 && y < .94) tries.add((y * 1000).round() / 1000);
            }
          }
        }
        for (final y in tries) {
          // Blocked by some squadron (fury calls two in turn), or by none.
          final blocked = lanes.any((l) => l.blocked(y));
          final safe = lanes.every((l) => l.safe(y));
          if (!blocked && !safe) continue;
          final sim = _fightAt(w, cycle, 7.8, hold: atPuff, fury: fury);
          // A bird at full health whose protection is off from here on.
          sim
            ..hearts = 3
            ..shield = true
            ..invulnerableUntil = 0;
          final before = (sim.hearts, sim.shield);
          runTo(
            sim,
            cycle * KingCoo.period + 13.4,
            width: width,
            hold: y,
            protect: false,
          );
          final hurt = (sim.hearts, sim.shield) != before;
          expect(
            hurt,
            blocked,
            reason: '$name @$w: held at y=$y (${blocked ? 'red' : 'green'})',
          );
        }
      }
    }
  }, timeout: const Timeout(Duration(minutes: 8)));

  test('the crossing times the art waits for are the simulation\'s', () {
    for (final w in _widths) {
      for (final (cycle, fury) in [(0, false), (1, false), (0, true)]) {
        final sim = _fightAt(w, cycle, 7.8, fury: fury);
        final boss = sim.boss!;
        final formations = KingCooSquadArt.formationsOf(boss);
        expect(formations, isNotEmpty);
        // The bird holds the middle of the tallest green lane of the squadron
        // that is crossing, so no pigeon is lost to it on the way.
        final crossed = <double>[];
        final seen = <SkyEnemy>{};
        void watch(FlightSimulation s) {
          for (final e in squadOf(s)) {
            if (e.x <= FlightSimulation.birdX && seen.add(e)) {
              crossed.add(s.boss!.age);
            }
          }
        }

        for (final f in formations) {
          final lane = KingCooSquadArt.lanesOf(f.plan).green.reduce(
            (a, b) => a.height >= b.height ? a : b,
          );
          runTo(
            sim,
            f.clearAt - boss.arrivalDuration + .05,
            width: _heights(w),
            hold: lane.centre,
            protect: true,
            each: watch,
          );
        }
        final planned = <double>[
          for (final f in formations)
            for (final slot in f.plan.slots)
              boss.squadCrossesAt(f.plan, slot, FlightSimulation.birdX),
        ]..sort();
        final got = [...crossed]..sort();
        expect(got.length, planned.length, reason: '$w c$cycle fury $fury');
        for (var i = 0; i < got.length; i++) {
          expect(got[i], closeTo(planned[i], 1 / 60), reason: 'pigeon $i');
        }
        // And the art's last beat is after the last crossing.
        for (final f in formations) {
          expect(f.clearAt, greaterThan(f.lastCrossAt));
          expect(f.firstCrossAt, lessThanOrEqualTo(f.lastCrossAt));
        }
      }
    }
  }, timeout: const Timeout(Duration(minutes: 4)));
}

/// The height of the safe band (not drawn as a lane) that contains [y], or 0.
double _sliverAt(SquadPlan plan, double y) {
  const reach = KingCoo.pigeonReach, edge = KingCoo.birdRadius;
  var lo = edge, hi = 1 - edge;
  for (final s in plan.slots) {
    if (s.y + reach <= y && s.y + reach > lo) lo = s.y + reach;
    if (s.y - reach >= y && s.y - reach < hi) hi = s.y - reach;
  }
  return hi - lo;
}

bool _inSliver(SquadLanes lanes, SquadPlan plan, double y) =>
    _sliverAt(plan, y) < KingCooSquadArt.minLane;

// ======================================================================
// timeline
// ======================================================================

void _timelineGroup() {
  test('the lanes come in from the puff, hold to the last pigeon, and go '
      '(a V at 640 and 800)', () {
    for (final w in _widths) {
      SkyBoss at(double c) => _boss(c: c, widthPx: w);
      expect(KingCooSquadArt.stateOf(at(7.0)).formations, isEmpty);
      final first = KingCooSquadArt.formationsOf(at(8.0)).single;
      expect(first.puffAt, closeTo(at(0).arrivalDuration + 7.6, 1e-9));
      expect(first.releaseAt, closeTo(at(0).arrivalDuration + 9.2, 1e-9));
      double alphaAt(double c) {
        final s = KingCooSquadArt.stateOf(at(c));
        return s.formations.isEmpty ? 0 : s.alpha.single;
      }

      expect(alphaAt(7.61), lessThan(.1));
      expect(alphaAt(7.95), closeTo(1, 1e-9));
      expect(alphaAt(9.2), closeTo(1, 1e-9));
      // The tip crosses at (x_boss - birdX) / .62 after the whistle: 1.22 s
      // at 640, 1.94 s at 800; the lanes hold until the last wing has passed.
      final cross = 9.2 + (bossColumn(_heights(w)) - FlightSimulation.birdX) / .62;
      expect(first.firstCrossAt - at(0).arrivalDuration, closeTo(cross, 1e-6));
      expect(alphaAt(cross + .3), closeTo(1, 1e-9));
      expect(alphaAt(cross + .39 + .134 + .35), closeTo(0, 1e-9));
      expect(KingCooSquadArt.stateOf(at(13.9)).alpha.every((a) => a == 0), isTrue);
    }
  });

  test('fury: the V\'s lanes first, the picket\'s take over as the V clears',
      () {
    final calls = KingCooSquadArt.formationsOf(
      _boss(c: 9.3, fury: true, birdY: .3, widthPx: 800),
    );
    expect(calls.map((f) => f.plan.shape), [SquadShape.v, SquadShape.picket]);
    expect(calls[1].releaseAt - calls[0].releaseAt, closeTo(1.4, 1e-9));
    expect(calls[1].firstCrossAt, greaterThan(calls[0].lastCrossAt));
    SkyBoss at(double c) => _boss(c: c, fury: true, birdY: .3, widthPx: 800);
    List<double> a(double c) => KingCooSquadArt.stateOf(at(c)).alpha;
    expect(a(9.0)[0], closeTo(1, 1e-9));
    expect(a(9.0)[1], closeTo(0, 1e-9), reason: 'the picket waits its turn');
    // While the V is current the picket's lanes are not lit yet.
    expect(a(10.0)[1], closeTo(0, 1e-9));
    // As the V clears the picket's come in (cross-fade).
    final clear = calls[0].clearAt - at(0).arrivalDuration;
    expect(a(clear - .2)[1], closeTo(0, 1e-9));
    expect(a(clear + .35)[1], closeTo(1, 1e-9));
    expect(a(clear + .5)[0], closeTo(0, 1e-9));
    // And the picket's go once it has passed.
    final end = calls[1].clearAt - at(0).arrivalDuration;
    expect(a(end + .4)[1], closeTo(0, 1e-9));
  });

  test('nothing is lit before the puff, with no plan, outside the fight, or '
      'for another boss', () {
    expect(KingCooSquadArt.formationsOf(_boss(c: 3)), isEmpty);
    final arriving = _boss()..age = 2.0;
    expect(KingCooSquadArt.formationsOf(arriving), isEmpty);
    final dead = _boss()..defeatedAt = _boss().age - 1;
    expect(KingCooSquadArt.formationsOf(dead), isEmpty);
    final other = SkyBoss(number: 1, x: 1.6, kind: BossKind.baronBat)
      ..age = 20;
    expect(KingCooSquadArt.formationsOf(other), isEmpty);
    // The previous cycle's plan (before the new puff) is long past.
    final stale = _boss(c: 3.0, cycle: 1);
    stale.squad = KingCoo.squad(cycle: 0, birdY: .5, fury: false);
    stale.puffsLatched = 1;
    expect(
      KingCooSquadArt.stateOf(stale).alpha.every((a) => a == 0),
      isTrue,
    );
  });

  test('a late pop keeps the squadron and its lanes', () {
    final boss = _boss(c: 9.8, popAt: 9.6, widthPx: 800);
    expect(KingCooSquadArt.cancelOf(boss), isNull);
    expect(KingCooSquadArt.stateOf(boss).alpha.single, closeTo(1, 1e-9));
  });

  test('the whistle\'s blast and the inhale have their windows', () {
    final calm = KingCooSquadArt.stateOf(_boss(c: 8.4));
    expect(calm.inhale, greaterThan(.5));
    expect(calm.blast, 0);
    final blown = KingCooSquadArt.stateOf(_boss(c: 9.2 + .225));
    expect(blown.blast, closeTo(1, 1e-6));
    expect(blown.inhale, 0);
    expect(
      KingCooSquadArt.stateOf(_boss(c: 9.2 + KingCooSquadArt.blastSeconds + .01))
          .blast,
      0,
    );
    expect(KingCooSquadArt.stateOf(_boss(c: 7.0)).inhale, 0);
  });

  test('the labels name no colour', () {
    // No colour is named (a player who cannot tell them apart reads it too).
    expect(KingCooSquadArt.labelOf(SquadShape.v), 'OPEN LANE = GO');
    expect(KingCooSquadArt.labelOf(SquadShape.picket), 'USE THE GAP');
    expect(KingCooSquadArt.nextOf(SquadShape.picket), 'THEN: GAP');
    for (final shape in SquadShape.values) {
      for (final text in [
        KingCooSquadArt.labelOf(shape),
        KingCooSquadArt.nextOf(shape),
      ]) {
        expect(text.toLowerCase(), isNot(contains('green')));
        expect(text.toLowerCase(), isNot(contains('red')));
      }
    }
    final boss = _boss(c: 9.5, called: true)..squadCalled = true;
    expect(boss.cooHint.toLowerCase(), contains('open lane'));
  });
}

// ======================================================================
// cancel
// ======================================================================

void _cancelGroup() {
  test('a pop before the whistle keeps the cancelled plan for the art and '
      'the next puff clears it (the rules hook)', () {
    final sim = _fightAt(640, 0, 7.9);
    final boss = sim.boss!;
    expect(boss.squad, isNotEmpty);
    expect(boss.cancelledSquad, isEmpty);
    final planned = boss.squad;
    for (var i = 0; i < 3; i++) {
      boss.strike(10);
    }
    tick(sim, width: _heights(640));
    expect(boss.popped, isTrue);
    expect(boss.squad, isEmpty, reason: 'the rules cancel it as before');
    expect(boss.cancelledSquad, planned);
    runTo(sim, 10, width: _heights(640), hold: .5, protect: true);
    expect(boss.cancelledSquad, planned, reason: 'kept through the window');
    runTo(sim, 14 + 7.9, width: _heights(640), hold: .5, protect: true);
    expect(boss.cancelledSquad, isEmpty, reason: 'the next puff clears it');
    expect(boss.squad, isNotEmpty);
  });

  test('a pop after the whistle is no cancel', () {
    final sim = _fightAt(640, 0, 9.3);
    final boss = sim.boss!;
    for (var i = 0; i < 3; i++) {
      boss.strike(10);
    }
    tick(sim, width: _heights(640));
    expect(boss.popped, isTrue);
    expect(boss.cancelledSquad, isEmpty);
    expect(boss.squad, isNotEmpty);
    expect(KingCooSquadArt.cancelOf(boss), isNull);
  });

  test('the cancel plays for 1.6 s after the pop, then nothing', () {
    // He pops at 8.0 s (before the whistle); [since] seconds later.
    SkyBoss at(double since) => _boss(c: 8.0 + since, popAt: 8.0);

    expect(KingCooSquadArt.cancelOf(at(0))!.$2, closeTo(0, 1e-9));
    expect(KingCooSquadArt.cancelOf(at(1.0))!.$2, closeTo(1.0, 1e-9));
    expect(KingCooSquadArt.cancelOf(at(1.61)), isNull);
    expect(KingCooSquadArt.formationsOf(at(.5)), isEmpty);
    // Fury cancels both calls.
    final fury = _boss(c: 8.5, fury: true, popAt: 8.4);
    expect(KingCooSquadArt.cancelOf(fury)!.$1, hasLength(2));
  });

  testWidgets('a cancel frame: the lanes fade by .3 s, puffs and a chip show, '
      'then it is gone', (tester) async {
    await tester.runAsync(() async {
      await loadFonts();
      Future<Uint8List> at(double since) =>
          _pixels(640, _boss(c: 8.0 + since, popAt: 8.0));
      int opaque(Uint8List d) {
        var n = 0;
        for (var i = 3; i < d.length; i += 4) {
          if (d[i] > 8) n++;
        }
        return n;
      }

      final live = await _pixels(640, _boss(c: 8.0));
      final just = await at(.02);
      final later = await at(.5);
      final chip = await at(1.0);
      final gone = await at(1.7);
      expect(opaque(just), greaterThan(opaque(later)));
      expect(opaque(later), greaterThan(0), reason: 'puffs and the chip');
      // After .3 s the lanes are gone: the only marks are puffs and the chip,
      // far fewer than the live lanes'.
      expect(opaque(later), lessThan(opaque(live) ~/ 4));
      expect(opaque(chip), greaterThan(0), reason: 'the chip holds');
      expect(opaque(gone), 0, reason: 'then nothing');
      expect(_hash(live), isNot(_hash(just)));
    });
  });
}

// ======================================================================
// pixels
// ======================================================================

/// The row means of (R - G) over [x0, x1) of a premultiplied RGBA picture:
/// positive rows are red, negative rows green.
List<double> _rowRedness(Uint8List data, int w, int x0, int x1) {
  final rows = data.length ~/ 4 ~/ w;
  return [
    for (var y = 0; y < rows; y++)
      () {
        var sum = 0.0;
        for (var x = x0; x < x1; x++) {
          final i = (y * w + x) * 4;
          sum += data[i] - data[i + 1];
        }
        return sum / (x1 - x0);
      }(),
  ];
}

void _pixelsGroup() {
  testWidgets('the drawn lanes are red where the model says red and green '
      'where it says green, at 640 and 800, calm and fury', (tester) async {
    await tester.runAsync(() async {
    for (final w in _widths) {
      final scenarios = <(String, SkyBoss, SquadLanes)>[
        for (final (name, boss) in [
          ('V', _boss(c: 9.6, widthPx: w, called: true)),
          ('V low', _boss(c: 9.6, widthPx: w, birdY: .7, called: true)),
          ('picket', _boss(c: 9.6, cycle: 1, widthPx: w, called: true)),
          (
            'picket gap .7',
            _boss(c: 9.6, cycle: 3, widthPx: w, birdY: .5, called: true),
          ),
          (
            'fury V',
            _boss(c: 9.6, widthPx: w, fury: true, birdY: .4, called: true),
          ),
        ])
          (name, boss, KingCooSquadArt.lanesOf(boss.squad.first)),
      ];
      for (final (name, boss, lanes) in scenarios) {
        final data = await _pixels(w, boss, only: {'lanes'});
        final x1 = (boss.x * _h - 1.2 * _h * SkyBoss.radius).round();
        final rows = _rowRedness(data, w.round(), (_birdPx() - KingCooSquadArt.leftReach * _h + .12 * _h).round(), x1 - (.12 * _h).round());
        final edges = [
          for (final b in [...lanes.red, ...lanes.green]) ...[b.top * _h, b.bottom * _h],
        ];
        for (var y = 6; y < _h - 6; y++) {
          // Rows within 7 px of a boundary carry the dashed line, the bank
          // and the cones: skip them.
          if (edges.any((e) => (e - y).abs() < 7 && e > 3 && e < _h - 3)) continue;
          final yy = (y + .5) / _h;
          if (lanes.blocked(yy)) {
            expect(rows[y], greaterThan(2), reason: '$name @$w row $y should be red');
          } else if (lanes.safe(yy)) {
            expect(rows[y], lessThan(-3), reason: '$name @$w row $y should be green');
          }
        }
      }
    }
    });
  });

  testWidgets('the red/green boundary is where the lanes say, within 2 px',
      (tester) async {
    await tester.runAsync(() async {
    for (final w in _widths) {
      for (final boss in [
        _boss(c: 9.6, widthPx: w, called: true),
        _boss(c: 9.6, cycle: 1, widthPx: w, birdY: .8, called: true),
      ]) {
        final lanes = KingCooSquadArt.lanesOf(boss.squad.single);
        final data = await _pixels(w, boss, only: {'lanes'});
        final x1 = (boss.x * _h - 1.2 * _h * SkyBoss.radius).round();
        final rows = _rowRedness(data, w.round(), (_birdPx() - KingCooSquadArt.leftReach * _h + .12 * _h).round(), x1 - (.12 * _h).round());
        for (final g in lanes.green) {
          for (final edge in [g.top, g.bottom]) {
            if (edge < .05 || edge > .95) continue;
            final py = edge * _h;
            // Just inside the green is green, just outside it red.
            final inside = g.top == edge ? py + 9 : py - 9;
            final outside = g.top == edge ? py - 9 : py + 9;
            expect(rows[inside.round()], lessThan(0), reason: 'inside $edge @$w');
            expect(rows[outside.round()], greaterThan(0), reason: 'outside $edge @$w');
            // The edge itself: the dashed rose line is the reddest row
            // near it and the solid mint line (just inside the green) the
            // greenest, each within 2 px of where the lanes put them.
            int argmax(int from, int to, int sign) {
              var best = from;
              for (var y = from; y <= to; y++) {
                if (rows[y] * sign > rows[best] * sign) best = y;
              }
              return best;
            }

            final p0 = py.round();
            expect(argmax(p0 - 6, p0 + 6, 1), closeTo(py, 2.0), reason: 'dashed edge @$w');
            final mint = g.top == edge ? py + .013 * _h : py - .013 * _h;
            expect(argmax(p0 - 8, p0 + 8, -1), closeTo(mint, 2.5), reason: 'mint line @$w');
          }
        }
      }
    }
    });
  });

  testWidgets('the tag stays left of the bird\'s column and under the room it '
      'has', (tester) async {
    await tester.runAsync(() async {
      await loadFonts();
      for (final w in _widths) {
        for (final boss in [
          _boss(c: 9.6, widthPx: w, called: true),
          _boss(c: 9.6, cycle: 1, widthPx: w, called: true),
          _boss(c: 10.0, widthPx: w, fury: true, birdY: .3, called: true),
        ]) {
          final data = await _pixels(w, boss, only: {'tags'});
          var minX = 1 << 30, maxX = -1, minY = 1 << 30, maxY = -1;
          for (var y = 0; y < _h; y++) {
            for (var x = 0; x < w; x++) {
              if (data[(y * w.round() + x) * 4 + 3] > 20) {
                minX = math.min(minX, x);
                maxX = math.max(maxX, x);
                minY = math.min(minY, y);
                maxY = math.max(maxY, y);
              }
            }
          }
          expect(maxX, greaterThan(0), reason: 'a tag is drawn');
          expect(minX, greaterThanOrEqualTo(0));
          expect(maxX, lessThan(_birdPx() - 20), reason: 'clear of the bird');
          expect(maxX - minX, lessThanOrEqualTo(130), reason: '<= 130 px');
          expect(minY, greaterThanOrEqualTo((.17 * _h).floor() - 2),
              reason: 'below the health bar');
        }
      }
    });
  });

  testWidgets('the lane marks run only from just left of the bird to just in '
      'front of his chest, and the hatch covers a third of the sky at most',
      (tester) async {
    await tester.runAsync(() async {
      for (final w in _widths) {
        for (final (name, boss) in [
          ('V', _boss(c: 9.6, widthPx: w, called: true)),
          ('picket', _boss(c: 9.6, cycle: 1, widthPx: w, birdY: .8, called: true)),
          ('fury V', _boss(c: 9.6, widthPx: w, fury: true, birdY: .3, called: true)),
        ]) {
          final data = await _pixels(w, boss, only: {'lanes'});
          final x1 = boss.x * _h - 1.2 * _h * SkyBoss.radius;
          final left = _birdPx() - KingCooSquadArt.leftReach * _h;
          var outside = 0;
          for (var y = 0; y < _h; y++) {
            for (var x = 0; x < w; x++) {
              if (data[(y * w.round() + x) * 4 + 3] > 3 && (x < left - 3 || x > x1 + 3)) {
                outside++;
              }
            }
          }
          expect(outside, 0, reason: '$name @$w: marks outside [left, chest]');
          // The hatched area, from the model and the run, as a share of the
          // playfield (the old overlay hatched the whole blocked span from
          // the screen edge: about 45% of it for a picket).
          final lanes = KingCooSquadArt.lanesOf(boss.squad.first);
          final hatched = lanes.hatch.fold(0.0, (a, b) => a + b.height) * _h;
          final share = hatched * (x1 - left) / (w * _h);
          expect(share, lessThan(.34), reason: '$name @$w hatches $share of the sky');
        }
      }
    });
  });

  testWidgets('one chevron column points the way out, one tag names the lane',
      (tester) async {
    await tester.runAsync(() async {
      await loadFonts();
      for (final w in _widths) {
        // A picket: wide red bands above and below the gap.
        final boss = _boss(c: 9.6, cycle: 1, widthPx: w, birdY: .8, called: true);
        final lanes = KingCooSquadArt.lanesOf(boss.squad.single);
        final data = await _pixels(w, boss, only: {'lanes'});
        final stride = w.round();
        // Bright (chevron) pixels inside the red bands, away from the
        // dashed edge and the cones: one narrow column.
        var minX = 1 << 30, maxX = -1;
        for (final band in lanes.red) {
          final y0 = (band.top * _h + 12).round(), y1 = (band.bottom * _h - 12).round();
          for (var y = math.max(y0, 6); y < math.min(y1, _h - 6); y++) {
            for (var x = 0; x < stride; x++) {
              final i = (y * stride + x) * 4;
              if (data[i + 3] > 200 && data[i] > 200 && data[i + 1] > 235) {
                minX = math.min(minX, x);
                maxX = math.max(maxX, x);
              }
            }
          }
        }
        expect(maxX, greaterThan(0), reason: 'the arrows are drawn');
        final column = _birdPx() - .11 * _h;
        expect(minX, greaterThan(column - .06 * _h), reason: '@$w');
        expect(maxX, lessThan(column + .06 * _h), reason: '@$w');

        // One tag, even in fury (the next call rides on its pip line).
        for (final b in [
          _boss(c: 9.6, widthPx: w, called: true),
          _boss(c: 9.6, widthPx: w, fury: true, birdY: .3, called: true),
        ]) {
          final tag = await _pixels(w, b, only: {'tags'});
          var top = 1 << 30, bottom = -1;
          for (var y = 0; y < _h; y++) {
            for (var x = 0; x < stride; x++) {
              if (tag[(y * stride + x) * 4 + 3] > 20) {
                top = math.min(top, y);
                bottom = math.max(bottom, y);
              }
            }
          }
          expect(bottom, greaterThan(0));
          expect(bottom - top, lessThanOrEqualTo(.105 * _h), reason: 'one pill @$w');
        }
      }
    });
  });

  testWidgets('the lanes never cover the bird: its pixels are the same with '
      'and without the squad art', (tester) async {
    await tester.runAsync(() async {
      await loadFonts();
      for (final w in _widths) {
        for (final y in [.5, .3, .8]) {
          final sim = _fightAt(w, 0, 9.6, hold: y);
          final withArt = await rawPixels(w.round(), _h.round(), (c) {
            _scene(c, sim, w);
          });
          // Same frame, with the boss moved out of the call window (so the
          // art draws nothing), the bird on top as ever.
          final boss = sim.boss!;
          final saved = boss.squad;
          boss.squad = const [];
          final without = await rawPixels(w.round(), _h.round(), (c) {
            _scene(c, sim, w);
          });
          boss.squad = saved;
          // Where the bird is opaque, the two frames agree exactly.
          final mask = await rawPixels(w.round(), _h.round(), (c) {
            c.save();
            _bird(c, sim.birdY);
            c.restore();
          });
          var checked = 0;
          for (var i = 3; i < mask.length; i += 4) {
            if (mask[i] == 255) {
              checked++;
              for (var k = -3; k <= 0; k++) {
                expect(withArt[i + k], without[i + k], reason: 'bird pixel $i');
              }
            }
          }
          expect(checked, greaterThan(500));
          expect(_hash(withArt), isNot(_hash(without)), reason: 'it did draw');
        }
      }
    });
  });

  testWidgets('the encounter\'s backdrop calls the art for King Coo and no '
      'one else', (tester) async {
    await tester.runAsync(() async {
      final boss = _boss(c: 9.0, widthPx: 640, called: true);
      final plain = _boss(c: 7.0, widthPx: 640);
      Future<Uint8List> backdrop(SkyBoss b) => rawPixels(640, 360, (c) {
        BossEncounterArt.backdrop(c, const Size(640, 360), b, _motion(b));
      });
      expect(_hash(await backdrop(boss)), isNot(_hash(await backdrop(plain))));
      final baron = SkyBoss(number: 1, x: 1.4, kind: BossKind.baronBat)
        ..age = 14;
      final before = _hash(await backdrop(baron));
      baron.squad = KingCoo.squad(cycle: 0, birdY: .5, fury: false);
      expect(_hash(await backdrop(baron)), before);
    });
  });
}

// ======================================================================
// budget and robustness
// ======================================================================

/// Counts what a frame asks of the canvas (see `king_coo_budget_test`).
class _Counting implements Canvas {
  _Counting(this.inner);
  final Canvas inner;
  final counts = <String, int>{};
  void _n(String k) => counts[k] = (counts[k] ?? 0) + 1;
  int get draws => counts.entries
      .where((e) => e.key.startsWith('draw') && !e.key.contains('.'))
      .fold(0, (a, e) => a + e.value);
  int get clips =>
      (counts['clipPath'] ?? 0) +
      (counts['clipPath.noAA'] ?? 0) +
      (counts['clipRect'] ?? 0);
  int get layers => counts['saveLayer'] ?? 0;
  int get blurs => counts['maskFilter'] ?? 0;
  int get unforwarded => counts.entries
      .where((e) => e.key.startsWith('UNFORWARDED'))
      .fold(0, (a, e) => a + e.value);

  @override
  void save() => inner.save();
  @override
  void restore() => inner.restore();
  @override
  void saveLayer(Rect? bounds, Paint paint) {
    _n('saveLayer');
    if (paint.maskFilter != null) _n('maskFilter');
    inner.saveLayer(bounds, paint);
  }

  @override
  void translate(double dx, double dy) => inner.translate(dx, dy);
  @override
  void scale(double sx, [double? sy]) => inner.scale(sx, sy);
  @override
  void rotate(double r) => inner.rotate(r);
  @override
  void clipPath(Path p, {bool doAntiAlias = true}) {
    _n(doAntiAlias ? 'clipPath' : 'clipPath.noAA');
    inner.clipPath(p, doAntiAlias: doAntiAlias);
  }

  @override
  void clipRect(Rect rect, {ui.ClipOp clipOp = ui.ClipOp.intersect, bool doAntiAlias = true}) {
    _n('clipRect');
    inner.clipRect(rect, clipOp: clipOp, doAntiAlias: doAntiAlias);
  }

  void _paint(String k, Paint p) {
    _n(k);
    if (p.shader != null) _n('$k.shader');
    if (p.maskFilter != null) _n('maskFilter');
  }

  @override
  void drawPath(Path p, Paint paint) {
    _paint('drawPath', paint);
    inner.drawPath(p, paint);
  }

  @override
  void drawCircle(Offset c, double r, Paint paint) {
    _paint('drawCircle', paint);
    inner.drawCircle(c, r, paint);
  }

  @override
  void drawRect(Rect r, Paint paint) {
    _paint('drawRect', paint);
    inner.drawRect(r, paint);
  }

  @override
  void drawRRect(RRect r, Paint paint) {
    _paint('drawRRect', paint);
    inner.drawRRect(r, paint);
  }

  @override
  void drawOval(Rect r, Paint paint) {
    _paint('drawOval', paint);
    inner.drawOval(r, paint);
  }

  @override
  void drawArc(Rect r, double a, double b, bool c, Paint paint) {
    _paint('drawArc', paint);
    inner.drawArc(r, a, b, c, paint);
  }

  @override
  void drawLine(Offset a, Offset b, Paint paint) {
    _paint('drawLine', paint);
    inner.drawLine(a, b, paint);
  }

  @override
  void drawPoints(ui.PointMode mode, List<Offset> points, Paint paint) {
    _paint('drawPoints', paint);
    inner.drawPoints(mode, points, paint);
  }

  @override
  void drawPicture(ui.Picture picture) {
    _n('drawPicture');
    inner.drawPicture(picture);
  }

  @override
  void drawParagraph(ui.Paragraph paragraph, Offset offset) {
    _n('drawParagraph');
    inner.drawParagraph(paragraph, offset);
  }

  @override
  dynamic noSuchMethod(Invocation i) {
    _n('UNFORWARDED.${i.memberName}');
    return null;
  }
}

_Counting _count(
  double w,
  SkyBoss boss, {
  bool reduced = false,
  Set<String>? only,
}) {
  final canvas = _Counting(Canvas(ui.PictureRecorder()));
  _art(canvas, w, boss, reduced: reduced, only: only);
  return canvas;
}

/// Frames across a whole call, every 1/12 s of the fight's cycle, calm and
/// fury, a V, a picket and a pop before the whistle.
Iterable<(String, SkyBoss)> _callFrames(double w) sync* {
  for (final (name, cycle, fury, bird, pop) in [
    ('V', 0, false, .5, null),
    ('picket', 1, false, .8, null),
    ('picket gap .30', 1, false, .5, null),
    ('fury', 0, true, .3, null),
    ('pop before the whistle', 0, false, .5, 8.5),
    ('pop after the whistle', 0, false, .5, 9.6),
  ]) {
    for (var c = 7.4; c <= 14.0; c += 1 / 12) {
      yield (
        '$name c=${c.toStringAsFixed(2)}',
        _boss(
          c: c,
          cycle: cycle,
          fury: fury,
          birdY: bird,
          widthPx: w,
          popAt: pop != null && c >= pop ? pop : null,
        ),
      );
    }
  }
}

void _budgetGroup() {
  test('budget: the lanes and tags <= 60 ops, the ghost one layer, the '
      'queue six gliders, no blur, every frame of a call, 640 and 800', () {
    // Warm every cache first: a game builds them in the arrival.
    for (final w in _widths) {
      KingCooSquadArt.prewarm();
      for (final (_, boss) in _callFrames(w).take(120)) {
        _art(Canvas(ui.PictureRecorder()), w, boss);
      }
    }
    var worstLanes = 0, worstGhost = 0, worstQueue = 0, worstAll = 0;
    var worstSiren = 0, worstCues = 0, worstCancel = 0, maxClips = 0;
    var worstName = '';
    for (final w in _widths) {
      for (final (name, boss) in _callFrames(w)) {
        final before = KingCooKit.shadersBuilt;
        final lanes = _count(w, boss, only: {'lanes', 'tags'});
        final ghost = _count(w, boss, only: {'ghost'});
        final queue = _count(w, boss, only: {'queue'});
        final siren = _count(w, boss, only: {'siren'});
        final cues = _count(w, boss, only: {'cues'});
        final cancel = _count(w, boss, only: {'cancel'});
        final all = _count(w, boss);
        expect(KingCooKit.shadersBuilt - before, 0, reason: '$name @$w builds shaders');
        for (final c in [lanes, ghost, queue, siren, cues, cancel, all]) {
          expect(c.blurs, 0, reason: '$name: no blur');
          expect(c.unforwarded, 0, reason: '$name: ${c.counts}');
        }
        expect(lanes.layers + queue.layers + siren.layers + cues.layers, 0);
        expect(ghost.layers, lessThanOrEqualTo(KingCooSquadBudget.ghostLayers));
        expect(all.layers, lessThanOrEqualTo(KingCooSquadBudget.ghostLayers),
            reason: '$name: at most the ghost\'s one layer');
        if (lanes.draws > worstLanes) worstName = name;
        worstLanes = math.max(worstLanes, lanes.draws);
        worstGhost = math.max(worstGhost, ghost.draws);
        worstQueue = math.max(worstQueue, queue.draws);
        worstSiren = math.max(worstSiren, siren.draws);
        worstCues = math.max(worstCues, cues.draws);
        worstCancel = math.max(worstCancel, cancel.draws);
        worstAll = math.max(worstAll, all.draws);
        maxClips = math.max(maxClips, all.clips);
      }
    }
    // ignore: avoid_print
    print(
      'K6 budget: lanes+tags $worstLanes ($worstName), ghost $worstGhost, '
      'queue $worstQueue, siren $worstSiren, cues $worstCues, '
      'cancel $worstCancel, whole frame $worstAll, clips $maxClips',
    );
    expect(worstLanes, lessThanOrEqualTo(KingCooBudget.lanes));
    expect(worstGhost, lessThanOrEqualTo(KingCooSquadBudget.ghostOps));
    expect(
      worstQueue,
      lessThanOrEqualTo(
        KingCooBudget.squadPigeon * KingCooSquadBudget.queueGliders +
            KingCooSquadBudget.queueExtraOps,
      ),
    );
    expect(worstSiren, lessThanOrEqualTo(KingCooSquadBudget.sirenOps));
    expect(worstCues, lessThanOrEqualTo(KingCooSquadBudget.cueOps));
    expect(worstCancel, lessThanOrEqualTo(KingCooSquadBudget.cancelOps));
    // A clipRect (no antialiasing) per red band, two bands per squadron, two
    // squadrons in a fury's cross-fade.
    expect(maxClips, lessThanOrEqualTo(4));
  });

  test('a call frame is cheap to build (the pose and the paints)', () {
    final boss = _boss(c: 8.8, widthPx: 800);
    KingCooSquadArt.prewarm();
    final canvas = Canvas(ui.PictureRecorder());
    for (var i = 0; i < 50; i++) {
      _art(canvas, 800, boss);
    }
    final watch = Stopwatch()..start();
    for (var i = 0; i < 400; i++) {
      boss.age += 1 / 400;
      _art(canvas, 800, boss);
    }
    final micros = watch.elapsedMicroseconds / 400;
    // ignore: avoid_print
    print('K6 paint: ${micros.toStringAsFixed(0)} us per call frame');
    // A 60 fps frame is 16,000 us; the call is a small share of it.
    expect(micros, lessThan(2500));
  });

  testWidgets('deterministic: the same frames in any order, caches emptied '
      'between, are the same pixels', (tester) async {
    await tester.runAsync(() async {
      await loadFonts();
      final frames = <(String, double, SkyBoss)>[
        ('V call', 640, _boss(c: 8.4)),
        ('V blast', 800, _boss(c: 9.35, widthPx: 800)),
        ('V cross', 640, _boss(c: 10.2)),
        ('picket', 800, _boss(c: 8.8, cycle: 1, widthPx: 800, birdY: .8)),
        ('fury', 800, _boss(c: 11.9, fury: true, birdY: .3, widthPx: 800)),
        ('cancel', 640, _boss(c: 8.6, popAt: 8.3)),
      ];
      Future<Map<String, int>> run(List<int> order) async {
        final out = <String, int>{};
        for (final i in order) {
          KingCooKit.clearCaches();
          KingCooSquadArt.clearCaches();
          final (name, w, boss) = frames[i];
          out[name] = _hash(await _pixels(w, boss));
        }
        return out;
      }

      final forward = await run([0, 1, 2, 3, 4, 5]);
      final backward = await run([5, 4, 3, 2, 1, 0]);
      final shuffled = await run([3, 0, 5, 2, 4, 1]);
      expect(backward, forward);
      expect(shuffled, forward);
      // And a frame is not a function of the one before it.
      final again = _hash(await _pixels(640, _boss(c: 8.4)));
      expect(again, forward['V call']);
      expect(forward.values.toSet(), hasLength(frames.length));
    });
  });

  testWidgets('hostile inputs draw nothing or something sane, never throw',
      (tester) async {
    await tester.runAsync(() async {
      Future<void> ok(SkyBoss boss, {Size size = const Size(640, 360), bool reduced = false}) async {
        final rec = ui.PictureRecorder();
        KingCooSquadArt.paint(
          Canvas(rec),
          size,
          boss,
          _motion(boss, reduced: reduced),
        );
        final pic = rec.endRecording();
        // It must render.
        final img = await pic.toImage(64, 64);
        img.dispose();
        pic.dispose();
      }

      for (final reduced in [false, true]) {
        final nan = _boss(c: 8.4)..age = double.nan;
        await ok(nan, reduced: reduced);
        final inf = _boss(c: 8.4)..age = double.infinity;
        await ok(inf, reduced: reduced);
        final x = _boss(c: 8.4)..x = double.nan;
        await ok(x, reduced: reduced);
        final y = _boss(c: 8.4)..y = double.infinity;
        await ok(y, reduced: reduced);
        final far = _boss(c: 8.4)..x = 1e12;
        await ok(far, reduced: reduced);
        final slots = _boss(c: 9.0)
          ..squad = [
            SquadPlan(
              shape: SquadShape.v,
              slots: const [
                SquadSlot(behind: double.nan, y: .5),
                SquadSlot(behind: 0, y: double.nan),
                SquadSlot(behind: 0, y: double.infinity),
                SquadSlot(behind: double.infinity, y: .4),
              ],
              delay: double.nan,
            ),
            const SquadPlan(shape: SquadShape.picket, slots: []),
          ];
        await ok(slots, reduced: reduced);
        final pop = _boss(c: 8.4, popAt: 8.3)..poppedAt = double.nan;
        await ok(pop, reduced: reduced);
        final popInf = _boss(c: 8.4, popAt: 8.3)..poppedAt = double.negativeInfinity;
        await ok(popInf, reduced: reduced);
        for (final size in const [
          Size(0, 360),
          Size(640, 0),
          Size(-5, 360),
          Size(double.nan, 360),
          Size(640, double.infinity),
          Size(1, 1),
        ]) {
          await ok(_boss(c: 8.4), size: size, reduced: reduced);
        }
        final late = _boss(c: 9.5)..age = 1e9;
        await ok(late, reduced: reduced);
        final negative = _boss(c: 8.4)..age = -5;
        await ok(negative, reduced: reduced);
      }
      // A bad frame draws nothing at all.
      final bad = _boss(c: 8.4)..age = double.nan;
      final data = await rawPixels(
        64,
        64,
        (c) => KingCooSquadArt.paint(c, const Size(64, 64), bad, _motion(bad)),
      );
      expect(data.every((b) => b == 0), isTrue);
    });
  });

  test('lanesOf and the formations survive hostile plans', () {
    final plan = SquadPlan(
      shape: SquadShape.picket,
      slots: const [
        SquadSlot(behind: 0, y: double.nan),
        SquadSlot(behind: 0, y: -3),
        SquadSlot(behind: 0, y: 4),
      ],
    );
    final lanes = KingCooSquadArt.lanesOf(plan);
    for (final b in [...lanes.red, ...lanes.green]) {
      expect(b.top.isFinite && b.bottom.isFinite, isTrue);
      expect(b.bottom, greaterThan(b.top));
    }
    expect(KingCooSquadArt.lanesOf(const SquadPlan(shape: SquadShape.v, slots: [])).green,
        hasLength(1));
  });
}

// ======================================================================
// Reduced Motion
// ======================================================================

void _reducedGroup() {
  testWidgets('under Reduced Motion nothing marches or pulses: a held call is '
      'the same picture at any later moment', (tester) async {
    await tester.runAsync(() async {
      await loadFonts();
      for (final w in _widths) {
        // After the first pigeon has crossed (pips full, ghost and queue
        // gone, the siren out) only the lanes remain, and they hold still.
        final cross = (bossColumn(_heights(w)) - FlightSimulation.birdX) / .62;
        final c0 = 9.2 + cross + .08;
        final a = await _pixels(w, _boss(c: c0, widthPx: w), reduced: true);
        final b = await _pixels(w, _boss(c: c0 + .07, widthPx: w), reduced: true);
        expect(_hash(a), _hash(b), reason: 'RM lanes at $w are still');
        final moving = await _pixels(w, _boss(c: c0 + .07, widthPx: w));
        expect(_hash(a), isNot(_hash(moving)), reason: 'full motion marches');
      }
    });
  });

  testWidgets('every state has its own Reduced Motion frame: call, blast, '
      'crossing, picket, fury next, cancel', (tester) async {
    await tester.runAsync(() async {
      await loadFonts();
      final states = <String, SkyBoss>{
        'call': _boss(c: 8.4),
        'blast': _boss(c: 9.2 + .22),
        'crossing': _boss(c: 10.5),
        'picket call': _boss(c: 8.4, cycle: 1, birdY: .8),
        'picket crossing': _boss(c: 10.5, cycle: 1, birdY: .8),
        'fury next': _boss(c: 10.0, fury: true, birdY: .3),
        'fury picket': _boss(c: 11.6, fury: true, birdY: .3),
        'cancelled': _boss(c: 8.6, popAt: 8.3),
      };
      final seen = <int, String>{};
      for (final e in states.entries) {
        final h = _hash(await _pixels(640, e.value, reduced: true));
        expect(seen[h], isNull, reason: '${e.key} = ${seen[h]}');
        seen[h] = e.key;
      }
    });
  });

  testWidgets('under Reduced Motion the siren is steady: blue while he '
      'inhales, red from the whistle', (tester) async {
    await tester.runAsync(() async {
      Future<(int, int)> tint(double c) async {
        final d = await _pixels(640, _boss(c: c), reduced: true, only: {'siren'});
        var red = 0, blue = 0;
        for (var i = 0; i < d.length; i += 4) {
          if (d[i + 3] == 0) continue;
          if (d[i] > d[i + 2]) red++;
          if (d[i + 2] > d[i]) blue++;
        }
        return (red, blue);
      }

      final inhale = await tint(8.3);
      final inhale2 = await tint(8.7);
      final blown = await tint(9.5);
      expect(inhale.$2, greaterThan(inhale.$1));
      expect(inhale, inhale2, reason: 'steady, not blinking');
      expect(blown.$1, greaterThan(blown.$2));
    });
  });
}

// ======================================================================
// evidence
// ======================================================================

const _out = String.fromEnvironment(
  'KING_COO_SQUAD_OUT',
  defaultValue: 'build/king-coo-squad-review',
);

Future<ui.Image> _frame(FlightSimulation sim, double w, {bool reduced = false, WorldRegion? region}) async {
  final rec = ui.PictureRecorder();
  _scene(Canvas(rec), sim, w, reduced: reduced, region: region);
  final pic = rec.endRecording();
  final img = await pic.toImage(w.round(), _h.round());
  pic.dispose();
  return img;
}

/// A fight flown once, with a frame painted at each of [times] (cycle
/// seconds of [cycle]); [popAt] strikes him three times then.
Future<List<ui.Image>> _sequence(
  double w,
  int cycle,
  List<double> times, {
  double hold = .5,
  bool fury = false,
  bool reduced = false,
  double? popAt,
  WorldRegion? region,
}) async {
  final sim = cooFight(width: _heights(w));
  if (fury) sim.boss!.hp = KingCoo.furyHp;
  final out = <ui.Image>[];
  var popped = false;
  for (final t in times) {
    runTo(
      sim,
      cycle * KingCoo.period + t,
      width: _heights(w),
      hold: hold,
      protect: true,
      each: (s) {
        if (popAt != null &&
            !popped &&
            s.boss!.cooCycleNumber == cycle &&
            s.boss!.cooCycle >= popAt) {
          popped = true;
          for (var i = 0; i < 3; i++) {
            s.boss!.strike(10);
          }
        }
      },
    );
    out.add(await _frame(sim, w, reduced: reduced, region: region));
  }
  return out;
}

Future<void> _sheet(
  String name,
  List<ui.Image> frames,
  List<String> labels, {
  int cols = 2,
}) async {
  final w = frames.first.width, h = frames.first.height;
  final rows = (frames.length / cols).ceil();
  final rec = ui.PictureRecorder();
  final c = Canvas(rec);
  c.drawRect(
    Rect.fromLTWH(0, 0, (w * cols).toDouble(), (h * rows).toDouble()),
    Paint()..color = const Color(0xff000000),
  );
  for (var i = 0; i < frames.length; i++) {
    final x = (i % cols) * w.toDouble(), y = (i ~/ cols) * h.toDouble();
    c.drawImage(frames[i], Offset(x, y), Paint());
    c.drawRect(
      Rect.fromLTWH(x, y, math.min(w * .75, labels[i].length * 7.5 + 12), 18),
      Paint()..color = const Color(0xcc0c0a24),
    );
    label(c, labels[i], Offset(x + 4, y + 1), color: const Color(0xffffffff), size: 12);
  }
  final pic = rec.endRecording();
  final img = await pic.toImage(w * cols, h * rows);
  final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
  File('$_out/$name.png')
    ..parent.createSync(recursive: true)
    ..writeAsBytesSync(bytes!.buffer.asUint8List());
  img.dispose();
}

/// A colour-vision-deficiency simulation of [src] (Machado et al. 2009,
/// severity 1, in linear light) as an image.
Future<ui.Image> _simulate(ui.Image src, List<double> m) async {
  final data = (await src.toByteData())!.buffer.asUint8List();
  final out = Uint8List(data.length);
  double lin(int v) {
    final c = v / 255;
    return c <= .04045 ? c / 12.92 : math.pow((c + .055) / 1.055, 2.4).toDouble();
  }

  int enc(double v) {
    final c = v.clamp(0.0, 1.0);
    return ((c <= .0031308 ? c * 12.92 : 1.055 * math.pow(c, 1 / 2.4) - .055) * 255).round();
  }

  for (var i = 0; i < data.length; i += 4) {
    final r = lin(data[i]), g = lin(data[i + 1]), b = lin(data[i + 2]);
    for (var k = 0; k < 3; k++) {
      out[i + k] = enc(m[k * 3] * r + m[k * 3 + 1] * g + m[k * 3 + 2] * b);
    }
    out[i + 3] = data[i + 3];
  }
  final done = Completer<ui.Image>();
  ui.decodeImageFromPixels(out, src.width, src.height, ui.PixelFormat.rgba8888, done.complete);
  return done.future;
}

Future<ui.Image> _grey(ui.Image src) => _simulate(src, const [
  .2126, .7152, .0722,
  .2126, .7152, .0722,
  .2126, .7152, .0722,
]);

void _evidenceGroup() {
  testWidgets('evidence 1: the call at 640 and 800 (a V, a picket) over '
      'New York at night', (tester) async {
    await tester.runAsync(() async {
      await loadFonts();
      final v640 = await _sequence(640, 0, [8.5]);
      final v800 = await _sequence(800, 0, [8.5]);
      final p640 = await _sequence(640, 1, [8.5], hold: .8);
      final p800 = await _sequence(800, 1, [8.5], hold: .5);
      await _sheet(
        '01-the-call',
        [v640.first, p640.first, v800.first, p800.first],
        ['V call 640 (bird .5)', 'picket call 640 (bird .8: gap .50)', 'V call 800', 'picket call 800 (bird .5: gap .30)'],
      );
    });
  });

  testWidgets('evidence 2: the whistle and the crossing, a V at 640 and 800',
      (tester) async {
    await tester.runAsync(() async {
      await loadFonts();
      const t640 = [7.7, 9.0, 9.4, 10.1];
      const t800 = [9.0, 9.4, 10.2, 10.9];
      final a = await _sequence(640, 0, t640);
      final b = await _sequence(800, 0, t800);
      await _sheet(
        '02-whistle-and-crossing',
        [...a, ...b],
        [
          for (final t in t640) 'V 640 c=$t',
          for (final t in t800) 'V 800 c=$t',
        ],
      );
    });
  });

  testWidgets('evidence 3: the picket\'s gap and fury\'s two calls',
      (tester) async {
    await tester.runAsync(() async {
      await loadFonts();
      const tp = [9.4, 10.5];
      final p = await _sequence(640, 1, tp, hold: .5);
      const tf = [8.6, 10.6, 11.9, 12.4];
      final f = await _sequence(800, 0, tf, hold: .3, fury: true);
      await _sheet(
        '03-gap-and-fury',
        [...p, ...f],
        [
          for (final t in tp) 'picket 640 c=$t',
          for (final t in tf) 'fury 800 c=$t',
        ],
      );
    });
  });

  testWidgets('evidence 4: popped before the whistle: the squad dissolves',
      (tester) async {
    await tester.runAsync(() async {
      await loadFonts();
      const t = [8.2, 8.32, 8.45, 8.7];
      final c = await _sequence(640, 0, t, popAt: 8.25);
      const l = [9.3, 9.7];
      final late = await _sequence(640, 0, l, popAt: 9.25);
      await _sheet(
        '04-cancel',
        [...c, ...late],
        [
          for (final x in t) 'pop at 8.25: c=$x',
          for (final x in l) 'pop at 9.25 (after the whistle): c=$x',
        ],
      );
    });
  });

  testWidgets('evidence 5: close-ups on dark and light skies', (tester) async {
    await tester.runAsync(() async {
      await loadFonts();
      final night = await _sequence(640, 0, [8.6]);
      final day = await _sequence(640, 0, [8.6], region: WorldRegion.egypt);
      final picket = await _sequence(800, 1, [9.6], hold: .8);
      final pDay = await _sequence(800, 1, [9.6], hold: .8, region: WorldRegion.egypt);
      Future<ui.Image> crop(ui.Image src, Rect r, double k) async {
        final rec = ui.PictureRecorder();
        final c = Canvas(rec);
        c.drawImageRect(src, r, Rect.fromLTWH(0, 0, r.width * k, r.height * k), Paint()..filterQuality = FilterQuality.medium);
        return rec.endRecording().toImage((r.width * k).round(), (r.height * k).round());
      }

      final a = await crop(night.first, const Rect.fromLTWH(0, 200, 300, 160), 2.4);
      final b = await crop(night.first, const Rect.fromLTWH(190, 70, 260, 200), 2.4);
      final c = await crop(day.first, const Rect.fromLTWH(0, 200, 300, 160), 2.4);
      final d = await crop(day.first, const Rect.fromLTWH(190, 70, 260, 200), 2.4);
      final e = await crop(picket.first, const Rect.fromLTWH(0, 80, 300, 200), 2.4);
      final f = await crop(pDay.first, const Rect.fromLTWH(0, 80, 300, 200), 2.4);
      // Each sheet cell is one size: pad the crops into equal frames.
      Future<ui.Image> pad(ui.Image i) async {
        final rec = ui.PictureRecorder();
        final cv = Canvas(rec);
        cv.drawRect(const Rect.fromLTWH(0, 0, 720, 480), Paint()..color = const Color(0xff000000));
        cv.drawImage(i, Offset.zero, Paint());
        return rec.endRecording().toImage(720, 480);
      }

      await _sheet(
        '05-closeups-dark-light',
        [await pad(a), await pad(b), await pad(c), await pad(d), await pad(e), await pad(f)],
        ['dark: tag, green lane, chevrons (x2.4)', 'dark: ghost V, inhale wisps, cap light (x2.4)', 'light: tag, green lane (x2.4)', 'light: ghost V (x2.4)', 'dark: the gap (x2.4)', 'light: the gap (x2.4)'],
      );
    });
  });

  testWidgets('evidence 6: Reduced Motion states and colour-blind views',
      (tester) async {
    await tester.runAsync(() async {
      await loadFonts();
      final call = await _sequence(640, 0, [8.4], reduced: true);
      final blast = await _sequence(640, 0, [9.42], reduced: true);
      final cross = await _sequence(800, 1, [10.8], hold: .8, reduced: true);
      final cancel = await _sequence(640, 0, [8.7], popAt: 8.25, reduced: true);
      await _sheet(
        '06a-reduced-motion',
        [call.first, blast.first, cross.first, cancel.first],
        ['RM call (siren steady blue)', 'RM whistle (siren steady red)', 'RM picket crossing 800', 'RM cancelled'],
      );
      final live = await _sequence(800, 0, [8.6]);
      final gap = await _sequence(800, 1, [8.6], hold: .8);
      const prot = [0.152286, 1.052583, -0.204868, 0.114503, 0.786281, 0.099216, -0.003882, -0.048116, 1.051998];
      const deut = [0.367322, 0.860646, -0.227968, 0.280085, 0.672501, 0.047413, -0.011820, 0.042940, 0.968881];
      await _sheet(
        '06b-colour-blind',
        [
          await _simulate(live.first, prot),
          await _simulate(live.first, deut),
          await _grey(live.first),
          await _simulate(gap.first, prot),
          await _simulate(gap.first, deut),
          await _grey(gap.first),
        ],
        ['V: protanopia', 'V: deuteranopia', 'V: greyscale', 'gap: protanopia', 'gap: deuteranopia', 'gap: greyscale'],
        cols: 3,
      );
    });
  });
}
