import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/sky_boss.dart';
import 'package:push_up_bird/game/boss_health_bar_art.dart';
import 'package:push_up_bird/game/gargoyle_boss_rig.dart';
import 'package:push_up_bird/game/gargoyle_layout.dart';
import 'package:push_up_bird/game/gargoyle_pose.dart';

import 'gargoyle_enforce.dart';
import 'proof/gargoyle_proof_rig.dart';
import 'proof/gargoyle_raster.dart';
import 'proof/gargoyle_stage.dart';

/// The Searchlight Gargoyle must fit the screen.
///
/// At 640x360 and 800x360 the chest lamp sits 180 px (4.35 rig units) from the
/// right edge, 180 px from the top and 180 px from the bottom, and he never
/// bobs, so the screen is x <= 4.35, -4.35 <= y <= 4.35 at both sizes
/// ([GargoyleLayout.screen]). Every COMBAT pose of every part, at every point of
/// every animation, must stay inside [GargoyleLayout.envelope]; the arrival and
/// the defeat inside [GargoyleLayout.layerBounds], and from the roar on inside
/// the screen too.
///
/// Two checks share one list of states:
///  1. the layout numbers + the real pose channels, drawn as the contract's
///     proof silhouette (test/proof): must always pass, it guards the numbers
///     and the pose maths;
///  2. the real art through `GargoyleBossRig.paintPose`: reports until
///     [enforceRealArt]. A failure names the part, the pose, the side and the
///     coordinate of the offending pixel:
///       sweep LOW #12: nearFan T+0.31 at (2.10,-4.03)
const _ppu = 24.0;
const _solid = 200;
const _tol = .03;

typedef _State = (String name, SkyBoss Function() boss, bool reduced);

/// Every combat state the sweep visits: the whole 9 s cycle (two cycles, so the
/// second cycle's first feather and the wrap are included) in every look, at
/// [phases] offsets of the idle sway, plus the events (hits, the fury onset,
/// glances, the feather flicks) on a fine grid.
List<_State> _states(int phases) {
  final out = <_State>[];
  for (final (look, fury, slit) in const [
    ('calm', false, false),
    ('fury', true, false),
    ('slit', true, true),
  ]) {
    for (final side in BeamSide.values) {
      if (slit && side == BeamSide.low) continue;
      for (var k = 0; k < 18 * 2; k++) {
        final t = k / 2;
        for (var p = 0; p < phases; p++) {
          final tt = t + p * .0411;
          out.add((
            '$look ${side.name} t${tt.toStringAsFixed(2)}',
            () => gBoss(tt, fury: fury, slit: slit, side: side),
            false,
          ));
        }
      }
    }
  }
  // Events on a fine grid: a hit in every phase of the cycle, the fury's onset,
  // a glance, and the feather flicks.
  for (var t = 0.0; t < 9; t += .5) {
    for (final hit in const [.02, .06, .12, .2]) {
      out.add(('hit t$t +$hit', () => gBoss(t + hit, hitAgo: hit), false));
      out.add(('fury hit t$t +$hit', () => gBoss(t + hit, hitAgo: hit, fury: true), false));
    }
    out.add(('glance t$t', () => gBoss(t, glanceAgo: .07), false));
  }
  for (var d = 0.0; d < 1.3; d += .05) {
    out.add(('rage +$d', () => gBoss(1.0 + d, fury: true, enragedAgo: d), false));
    out.add(('rage low +$d', () => gBoss(5.0 + d, fury: true, enragedAgo: d, side: BeamSide.low), false));
  }
  for (final e in const [.2, 4.6, 4.5, 5.2, 9.2]) {
    for (var d = -.5; d < .9; d += .03) {
      out.add(('flick $e ${d.toStringAsFixed(2)}', () => gBoss(e + d, fury: e == 4.5 || e == 5.2), false));
    }
  }
  // Reduced Motion: the states the pose keeps.
  for (var k = 0; k < 18 * 2; k++) {
    final t = k * .5;
    out.add(('RM calm t$t', () => gBoss(t), true));
    out.add(('RM fury low t$t', () => gBoss(t, fury: true, side: BeamSide.low), true));
    out.add(('RM slit t$t', () => gBoss(t, fury: true, slit: true), true));
  }
  return out;
}

/// Arrival and defeat: staged cinematics, exempt from the combat envelope.
final _staged = <(String, SkyBoss Function(), bool reduced)>[
  for (final r in const [false, true])
    for (var age = 0.0; age < 4.6; age += .1) ('arrival ${age.toStringAsFixed(1)}', () => gBoss(age - 4.6), r),
  for (final r in const [false, true])
    for (var d = 0.0; d < 3.9; d += .1) ('defeat ${d.toStringAsFixed(1)}', () => gBoss(1.0, deadFor: d), r),
  for (final r in const [false, true])
    for (var d = 0.0; d < 3.9; d += .2) ('defeat from sweep ${d.toStringAsFixed(1)}', () => gBoss(4.8, deadFor: d), r),
  for (final d in const [.1, .3, .6])
    ('defeat from vent $d', () => gBoss(7.2, deadFor: d, fury: true), false),
];

String _over(Mask m, ui.Rect box) {
  final b = m.bounds;
  if (b == null) return '';
  final r = b.rect;
  String at(ui.Offset o) => '(${o.dx.toStringAsFixed(2)},${o.dy.toStringAsFixed(2)})';
  return [
    if (r.left < box.left - _tol) 'L+${(box.left - r.left).toStringAsFixed(2)} at ${at(b.atLeft)}',
    if (r.top < box.top - _tol) 'T+${(box.top - r.top).toStringAsFixed(2)} at ${at(b.atTop)}',
    if (r.right > box.right + _tol) 'R+${(r.right - box.right).toStringAsFixed(2)} at ${at(b.atRight)}',
    if (r.bottom > box.bottom + _tol) 'B+${(r.bottom - box.bottom).toStringAsFixed(2)} at ${at(b.atBottom)}',
  ].join(', ');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // The plinth is staging; the loosened blade flies off the top by design.
  final parts = [for (final p in GargoyleLayout.zOrder) if (p != 'ledge' && p != 'shed') p];

  /// Sweeps the combat states and then the staged cinematics.
  Future<void> sweep(
    WidgetTester tester, {
    required String label,
    required void Function(ui.Canvas, GargoylePose) draw,
    void Function(ui.Canvas, GargoylePose, Set<String>)? drawPart,
    required bool enforce,
  }) async {
    await tester.runAsync(() async {
      final failures = <String>[];
      var worst = ui.Rect.zero;
      final reach = <String, (double, String)>{'L': (99, ''), 'T': (99, ''), 'R': (-99, ''), 'B': (-99, '')};
      var attributed = 0;
      Future<void> fail(String name, GargoylePose pose, Mask m, ui.Rect box) async {
        final o = _over(m, box);
        if (o.isEmpty) return;
        if (drawPart == null || attributed >= 30) {
          failures.add('$name: $o');
          return;
        }
        attributed++;
        final culprits = <String>[];
        for (final part in parts) {
          final pm = await rasterize((c) => drawPart(c, pose, {part}), ppu: _ppu, solid: _solid);
          final po = _over(pm, box);
          if (po.isNotEmpty) culprits.add('$part $po');
        }
        failures.add('$name: ${culprits.isEmpty ? o : culprits.join('; ')}');
      }

      var n = 0;
      for (final (name, mk, reduced) in _states(envelopePhases)) {
        final pose = poseOf(mk(), reduced: reduced);
        final m = await rasterize((c) => draw(c, pose), ppu: _ppu, solid: _solid);
        final b = m.bounds;
        if (b == null) continue;
        n++;
        worst = worst.expandToInclude(b.rect);
        if (b.rect.left < reach['L']!.$1) reach['L'] = (b.rect.left, name);
        if (b.rect.top < reach['T']!.$1) reach['T'] = (b.rect.top, name);
        if (b.rect.right > reach['R']!.$1) reach['R'] = (b.rect.right, name);
        if (b.rect.bottom > reach['B']!.$1) reach['B'] = (b.rect.bottom, name);
        await fail(name, pose, m, GargoyleLayout.envelope);
      }
      // ignore: avoid_print
      print(
        '$label combat union over $n states: L ${worst.left.toStringAsFixed(2)} '
        'T ${worst.top.toStringAsFixed(2)} R ${worst.right.toStringAsFixed(2)} '
        'B ${worst.bottom.toStringAsFixed(2)}   envelope ${GargoyleLayout.envelope}\n'
        '  furthest: ${reach.entries.map((e) => '${e.key} ${e.value.$1.toStringAsFixed(2)} (${e.value.$2})').join(', ')}',
      );
      for (final (name, mk, reduced) in _staged) {
        final pose = poseOf(mk(), reduced: reduced);
        final m = await rasterize((c) => draw(c, pose), ppu: _ppu, solid: _solid);
        await fail('$name${reduced ? ' (RM)' : ''} (layer)', pose, m, GargoyleLayout.layerBounds);
      }
      if (failures.isNotEmpty) {
        // ignore: avoid_print
        print('$label: ${failures.length} over (first ${math.min(failures.length, 40)}):\n${failures.take(40).join('\n')}');
      }
      if (enforce) expect(failures, isEmpty, reason: '$label leaves the envelope');
    });
  }

  testWidgets('layout + pose channels: the proof silhouette fits the envelope', (tester) async {
    await sweep(tester, label: 'proof', draw: (c, pose) => paintProofGargoyle(c, pose), enforce: true);
  }, timeout: const Timeout(Duration(minutes: 6)));

  testWidgets('the real art fits the envelope (reports until enforced)', (tester) async {
    await sweep(
      tester,
      label: 'art',
      draw: (c, pose) => GargoyleBossRig.paintPose(c, pose, only: parts.toSet(), plinth: false),
      drawPart: (c, pose, only) => GargoyleBossRig.paintPose(c, pose, only: only, plinth: false),
      enforce: enforceRealArt,
    );
  }, timeout: const Timeout(Duration(minutes: 6)));

  testWidgets('the calm idle pose (every Reduced Motion idle too) stays inside the rest envelope', (tester) async {
    await tester.runAsync(() async {
      for (final (name, mk) in <(String, GargoylePose Function())>[
        ('still', () => GargoylePose.still),
        for (var t = .5; t < 1.95; t += .15) ('perch t$t', () => poseOf(gBoss(t))),
        for (var t = .5; t < 1.95; t += .5) ('perch RM t$t', () => poseOf(gBoss(t), reduced: true)),
        ('perch cycle 2', () => poseOf(gBoss(9.8))),
      ]) {
        final pose = mk();
        for (final (label, draw) in <(String, void Function(ui.Canvas))>[
          ('proof', (c) => paintProofGargoyle(c, pose)),
          ('art', (c) => GargoyleBossRig.paintPose(c, pose, only: parts.toSet(), plinth: false)),
        ]) {
          final m = await rasterize(draw, ppu: _ppu, solid: _solid);
          expect(_over(m, GargoyleLayout.restEnvelope), isEmpty, reason: '$label $name');
        }
      }
    });
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('the envelope nests: rest inside combat inside the layer clip, combat inside the screen', () {
    bool inside(ui.Rect a, ui.Rect b) =>
        a.left >= b.left && a.top >= b.top && a.right <= b.right && a.bottom <= b.bottom;
    expect(inside(GargoyleLayout.restEnvelope, GargoyleLayout.envelope), isTrue);
    expect(inside(GargoyleLayout.envelope, GargoyleLayout.layerBounds), isTrue);
    expect(inside(GargoyleLayout.envelope, GargoyleLayout.screen), isTrue);
    expect(GargoyleBossRig.bounds, GargoyleLayout.layerBounds);
  });

  testWidgets('at 640x360 and 800x360 every combat pose is on screen; the arrival from the roar, the defeat throughout',
      (tester) async {
    await tester.runAsync(() async {
      for (final w in const [640.0, 800.0]) {
        final size = ui.Size(w, 360);
        final aspect = w / 360;
        final u = 360 * SkyBoss.radius;
        final anchor = SearchlightGargoyle.anchorX(GargoyleLayout.birdColumn, aspect) * 360;
        // Screen limits in rig units from the real anchor.
        final right = (w - anchor) / u;
        final top = -180 / u, bottom = 180 / u;
        final bad = <String>[];
        Future<void> check(String name, SkyBoss b, {bool reduced = false, bool layerOnly = false}) async {
          final pose = poseOf(b, reduced: reduced);
          final m = await rasterize((c) => paintProofGargoyle(c, pose), ppu: _ppu, solid: _solid);
          final r = m.bounds?.rect;
          if (r == null) return;
          if (layerOnly) return;
          if (r.right > right + _tol) bad.add('$name at $w: right ${r.right.toStringAsFixed(2)} > $right');
          if (r.top < top - _tol) bad.add('$name at $w: top ${r.top.toStringAsFixed(2)} < ${top.toStringAsFixed(2)}');
          if (r.bottom > bottom + _tol) bad.add('$name at $w: bottom ${r.bottom.toStringAsFixed(2)} > ${bottom.toStringAsFixed(2)}');
        }

        for (final t in const [.5, 1.0, 3.0, 4.4, 4.55, 5.5, 7.0, 8.5, 9.3, 13.6, 14.5]) {
          await check('combat t$t', gBoss(t, aspect: aspect));
          await check('fury t$t', gBoss(t, fury: true, slit: t > 10, aspect: aspect));
        }
        // Arrival: the rules slide him in from the right edge until 2.65 s; from
        // the roar (2.65 s) he stands at the anchor and must fit. Before that he
        // is off to the right by design and only the layer clip applies.
        for (var age = 2.65; age < 4.6; age += .1) {
          await check('arrival $age', gBoss(age - 4.6, aspect: aspect));
        }
        for (var d = 0.0; d < 3.8; d += .1) {
          await check('defeat $d', gBoss(1.0, deadFor: d, aspect: aspect));
        }
        // ignore: avoid_print
        print('screen fit at ${size.width.toInt()}x360: ${bad.isEmpty ? 'all inside' : bad.take(8).join('; ')}');
        expect(bad, isEmpty);
      }
    });
  }, timeout: const Timeout(Duration(minutes: 4)));

  test('the lenses and the beak never go under the health bar, and the beak keeps clear of the bird', () {
    // The bar covers the strip BossHealthBarArt.bounds gives at each size; crest
    // tips may pass under it, the lenses and the beak never. Checked on the
    // anchors through the real pose channels, so it holds whatever art is in
    // place; each anchor's own radius is kept clear too.
    var nearestBeak = 999.0;
    final offenders = <String>[];
    for (final w in const [640.0, 800.0]) {
      final size = ui.Size(w, 360);
      final aspect = w / 360;
      final u = 360 * SkyBoss.radius;
      for (final (name, mk, reduced) in _states(2)) {
        final boss = mk()..x = SearchlightGargoyle.anchorX(GargoyleLayout.birdColumn, aspect);
        final pose = poseOf(boss, reduced: reduced);
        final bar = BossHealthBarArt.bounds(size, boss);
        final centre = ui.Offset(boss.x * 360, 180);
        for (final (what, rig, r) in [
          ('near lens', GargoyleBossRig.eyeAt(pose), GargoyleLayout.eyeNearRadius * GargoyleLayout.headScale),
          ('far lens', GargoyleBossRig.eyeAt(pose, far: true), GargoyleLayout.eyeFarRadius * GargoyleLayout.headScale),
          ('beak tip', GargoyleBossRig.beakTipAt(pose), .1),
        ]) {
          final p = centre + rig * u;
          if (bar.inflate(r * u).contains(p)) offenders.add('$name at $w: $what under the bar at $p');
        }
        final beak = centre + GargoyleBossRig.beakTipAt(pose) * u;
        nearestBeak = math.min(nearestBeak, beak.dx - GargoyleLayout.birdColumn * 360 - GargoyleLayout.birdRadius * 360);
      }
    }
    // ignore: avoid_print
    print('nearest beak tip to the bird\'s circle: ${nearestBeak.toStringAsFixed(1)} px');
    expect(offenders.take(6), isEmpty);
    expect(nearestBeak, greaterThanOrEqualTo(GargoyleLayout.beakToBirdMinPx - 14.0 - 1));
  });

  test('the layout\'s bar numbers are the real bar\'s', () {
    // x < healthBarRight and y < healthBarBottom are covered at 640 / 800 wide.
    for (final (w, right) in const [(640.0, GargoyleLayout.healthBarRight640), (800.0, GargoyleLayout.healthBarRight800)]) {
      final aspect = w / 360;
      final boss = gBoss(1.0, aspect: aspect);
      final bar = BossHealthBarArt.bounds(ui.Size(w, 360), boss);
      final u = 360 * SkyBoss.radius;
      final cx = boss.x * 360;
      expect((bar.right - cx) / u, closeTo(right, .06), reason: 'bar right edge at $w');
      expect((bar.bottom - 180) / u, closeTo(GargoyleLayout.healthBarBottom, .06), reason: 'bar bottom at $w');
    }
  });
}
