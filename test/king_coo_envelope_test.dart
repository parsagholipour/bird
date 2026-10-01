import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/sky_boss.dart';
import 'package:push_up_bird/game/king_coo_boss_rig.dart';
import 'package:push_up_bird/game/king_coo_layout.dart';
import 'package:push_up_bird/game/king_coo_pose.dart';

import 'king_coo_test_kit.dart';
import 'proof/king_coo_proof_rig.dart';

/// King Coo must fit the screen.
///
/// At 640x360 and 800x360 the chest sits .55 h (4.78 rig units) from the right
/// edge and the rules bob it .06 h (.52 unit), so the visible window is
/// x <= 4.78, -3.83 <= y <= 3.83 in the worst case (`KingCooLayout.visibleWorst`).
/// Every COMBAT pose of every part, at every point of the waddle, the wingbeat,
/// the throw, the puff, the whistle, the pop, the hit, the fury and the stomp,
/// must stay inside `KingCooLayout.envelope`; the arrival (with its swell) and
/// the defeat must stay inside `layerBounds`.
///
/// Two checks share the sweeps:
///  1. the layout numbers + the real pose channels, drawn as the proof rig in
///     test/proof (must always pass: it guards the numbers and the pose maths);
///  2. the real art through `KingCooBossRig.paintPose`. Until every part has
///     landed it only REPORTS; flip [enforceRealArt] (test/king_coo_test_kit.dart,
///     one line) to make it fail. A failure names the part, the pose, the side
///     and the coordinate of the offending pixel:
///       hold #12 fury: nearWing T+0.31 at (2.10,-4.03)
/// The sweep runs the clock densely (every 1/12 s of [envelopeCycles] whole 14 s
/// cycles of each scenario), so every phase of the beat meets every state.

// Sweeps scan at 20 px per unit (a pixel is .05 unit): a little coarser than
// the tuning runs, with a matching slack.
const _ppu = 20.0, _slack = .05;

/// The parts the real rig paints, in z-order, for naming an offender.
final _parts = KingCooLayout.zOrder;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Sweeps every pose of [poses] and reports/enforces its bounds.
  Future<void> sweep(
    WidgetTester tester, {
    required String label,
    required Iterable<(String, KingCooPose)> Function() poses,
    required Rect box,
    required void Function(Canvas, KingCooPose) draw,
    void Function(Canvas, KingCooPose, Set<String>)? drawPart,
    required bool enforce,
    int solid = scanSolid,
  }) async {
    const named = 24;
    await tester.runAsync(() async {
      final failures = <String>[];
      var worst = Rect.zero;
      var attributed = 0, count = 0;
      final reach = <String, (double, String)>{
        'L': (99, ''),
        'T': (99, ''),
        'R': (-99, ''),
        'B': (-99, ''),
      };
      for (final (name, pose) in poses()) {
        count++;
        final r = await scan((c) => draw(c, pose), solid: solid, ppu: _ppu);
        worst = worst.expandToInclude(r.rect);
        if (r.rect.left < reach['L']!.$1) reach['L'] = (r.rect.left, name);
        if (r.rect.top < reach['T']!.$1) reach['T'] = (r.rect.top, name);
        if (r.rect.right > reach['R']!.$1) reach['R'] = (r.rect.right, name);
        if (r.rect.bottom > reach['B']!.$1) reach['B'] = (r.rect.bottom, name);
        final o = over(r, box, slack: _slack);
        if (o.isEmpty) continue;
        if (drawPart == null || attributed >= named) {
          failures.add('$name: $o');
          continue;
        }
        attributed++;
        final culprits = <String>[];
        for (final part in _parts) {
          final pr = await scan(
            (c) => drawPart(c, pose, {part}),
            solid: solid,
            ppu: _ppu,
          );
          final po = over(pr, box, slack: _slack);
          if (po.isNotEmpty) culprits.add('$part $po');
        }
        failures.add('$name: ${culprits.isEmpty ? o : culprits.join('; ')}');
      }
      // ignore: avoid_print
      print(
        '$label ($count poses) union: L ${worst.left.toStringAsFixed(2)} '
        'T ${worst.top.toStringAsFixed(2)} R ${worst.right.toStringAsFixed(2)} '
        'B ${worst.bottom.toStringAsFixed(2)}   box $box\n'
        '  furthest: ${reach.entries.map((e) => '${e.key} ${e.value.$1.toStringAsFixed(2)} (${e.value.$2})').join(', ')}',
      );
      if (failures.isNotEmpty) {
        // ignore: avoid_print
        print(
          '$label: ${failures.length} over (first ${math.min(failures.length, 30)}):\n'
          '${failures.take(30).join('\n')}',
        );
      }
      if (enforce) expect(failures, isEmpty, reason: '$label leaves its box');
    });
  }

  Iterable<(String, KingCooPose)> combat(bool reduced) => combatPoses(
    cycles: envelopeCycles,
    dt: 1 / 12,
    reduced: reduced,
  );

  /// The proof rig is the calibration fixture of this sweep (it shows the box
  /// is reachable), not the art: it passes the first cycle by design and tops
  /// the box by .05 at the cap's hop in some later cycles (K2, K3 and K8 all
  /// saw it at `KING_COO_CYCLES=6`). So it is always swept for ONE cycle; the
  /// real art gets all [envelopeCycles].
  Iterable<(String, KingCooPose)> proofCombat(bool reduced) =>
      combatPoses(cycles: 1, dt: 1 / 12, reduced: reduced);

  testWidgets('layout + pose channels: the proof rig fits the combat envelope', (
    tester,
  ) async {
    await sweep(
      tester,
      label: 'proof combat',
      poses: () => proofCombat(false),
      box: KingCooLayout.envelope,
      draw: (c, p) => paintProofCoo(c, p),
      enforce: true,
      solid: 40,
    );
  });

  testWidgets('layout + pose channels: the proof rig fits under Reduced Motion', (
    tester,
  ) async {
    await sweep(
      tester,
      label: 'proof combat RM',
      poses: () => proofCombat(true),
      box: KingCooLayout.envelope,
      draw: (c, p) => paintProofCoo(c, p),
      enforce: true,
      solid: 40,
    );
  });

  testWidgets('the proof rig fits the arrival and the defeat in the layer', (
    tester,
  ) async {
    await sweep(
      tester,
      label: 'proof staged',
      poses: () => stagedPoses(),
      box: KingCooLayout.layerBounds,
      draw: (c, p) => paintProofCoo(c, p),
      enforce: true,
      solid: 40,
    );
  });

  testWidgets('the real art fits the combat envelope (reports until enforced)', (
    tester,
  ) async {
    await sweep(
      tester,
      label: 'art combat',
      poses: () => combat(false),
      box: KingCooLayout.envelope,
      draw: (c, p) => KingCooBossRig.paintPose(c, p),
      drawPart: (c, p, only) => KingCooBossRig.paintPose(c, p, only: only),
      enforce: enforceRealArt,
    );
  });

  testWidgets('the real art fits the envelope under Reduced Motion', (
    tester,
  ) async {
    await sweep(
      tester,
      label: 'art combat RM',
      poses: () => combat(true),
      box: KingCooLayout.envelope,
      draw: (c, p) => KingCooBossRig.paintPose(c, p),
      drawPart: (c, p, only) => KingCooBossRig.paintPose(c, p, only: only),
      enforce: enforceRealArt,
    );
  });

  testWidgets('the real art fits the arrival (with its swell) and the defeat', (
    tester,
  ) async {
    await sweep(
      tester,
      label: 'art staged',
      poses: () => stagedPoses(),
      box: KingCooLayout.layerBounds,
      draw: (c, p) => KingCooBossRig.paintPose(c, p),
      drawPart: (c, p, only) => KingCooBossRig.paintPose(c, p, only: only),
      enforce: enforceRealArt,
    );
  });

  testWidgets('the calm Reduced Motion pose keeps the rest envelope', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final pose = KingCooPose.still;
      final proof = await scan((c) => paintProofCoo(c, pose), solid: 40, ppu: 24);
      expect(over(proof, KingCooLayout.restEnvelope), isEmpty, reason: '$proof');
      final art = await scan((c) => KingCooBossRig.paintPose(c, pose), ppu: 24);
      final o = over(art, KingCooLayout.restEnvelope);
      // ignore: avoid_print
      print('art rest: $art   over: ${o.isEmpty ? 'nothing' : o}');
      if (enforceRealArt) expect(o, isEmpty);
    });
  });

  group('the screen', () {
    // Where the rules put him (game_rules `_advanceBoss`) on a [w]x360 screen.
    const h = 360.0, unit = h * .115;

    test('the envelope fits 640x360 and 800x360 in the worst hover', () {
      for (final w in [640.0, 800.0]) {
        final x = math.max(birdX + .70, w / h - .55) * h;
        final e = KingCooLayout.envelope;
        for (final hover in [-.06, .06]) {
          final y = (.5 + hover) * h;
          expect(x + e.right * unit, lessThan(w), reason: 'right at $w');
          expect(y + e.top * unit, greaterThan(0), reason: 'top at $w hover $hover');
          expect(y + e.bottom * unit, lessThan(h), reason: 'bottom at $w');
        }
        // The spare room the layout documents.
        expect((w - x) / unit, closeTo(KingCooLayout.screenRight, .02));
        expect(
          KingCooLayout.screenRight - e.right,
          greaterThan(.55),
          reason: 'right margin',
        );
        // The health bar: cap and siren stay above it by the documented margin.
        expect(e.top - KingCooLayout.healthBarClearance, greaterThan(.2));
      }
    });

    test('the layer bounds hold the envelope at the arrival swell', () {
      final e = KingCooLayout.envelope, l = KingCooLayout.layerBounds;
      const s = KingCooLayout.arrivalSwell;
      expect(l.left, lessThanOrEqualTo(e.left * s));
      expect(l.top, lessThanOrEqualTo(e.top * s));
      expect(l.right, greaterThanOrEqualTo(e.right * s));
      expect(l.bottom, greaterThanOrEqualTo(e.bottom * s));
    });

    testWidgets('the arrival stays on screen at the rules\' own positions', (
      tester,
    ) async {
      await tester.runAsync(() async {
        final offenders = <String>[];
        for (final w in [640.0, 800.0]) {
          final target = math.max(birdX + .70, w / h - .55);
          for (var age = 0.0; age <= 4.6; age += 1 / 12) {
            final entrance = ((age - .95) / 1.7).clamp(0.0, 1.0);
            final ease = 1 - math.pow(1 - entrance, 3);
            final bx = ((w / h + .3) * (1 - ease) + target * ease) * h;
            final by = (.5 - .14 * math.sin(entrance * math.pi)) * h;
            final pose = poseOf(arrivingBoss(age));
            // The proof rig is the contract's guarantee; the art reports.
            final r = await scan(
              (c) => paintProofCoo(c, pose),
              solid: 40,
              ppu: _ppu,
            );
            final top = by + r.top * unit, bottom = by + r.bottom * unit;
            final right = bx + r.right * unit;
            if (top < -1) offenders.add('$w age $age: top $top');
            if (bottom > h + 1) offenders.add('$w age $age: bottom $bottom');
            // Once he has arrived (entrance 1 at 2.65 s) nothing may crop.
            if (age >= 2.65 && right > w) {
              offenders.add('$w age $age: right $right');
            }
          }
        }
        expect(offenders.take(6), isEmpty);
      });
    });
  });

  test('sanity: the layout numbers are what the report tabulates', () {
    expect(KingCooLayout.hitRadius, SkyBoss.radius / SkyBoss.radius);
    expect(KingCooLayout.pxPerUnit, closeTo(360 * SkyBoss.radius, .01));
    expect(KingCooLayout.screenRight, closeTo(.55 / SkyBoss.radius, .01));
    expect(KingCooLayout.hoverReach, closeTo(.06 / SkyBoss.radius, .01));
    expect(KingCooLayout.visibleWorst.top, closeTo(-(.5 - .06) / SkyBoss.radius, .01));
  });
}
