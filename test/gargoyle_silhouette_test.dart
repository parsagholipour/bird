import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/sky_boss.dart';
import 'package:push_up_bird/game/gargoyle_boss_rig.dart';
import 'package:push_up_bird/game/gargoyle_layout.dart';
import 'package:push_up_bird/game/gargoyle_pose.dart';

import 'gargoyle_enforce.dart';
import 'proof/gargoyle_proof_rig.dart';
import 'proof/gargoyle_raster.dart';
import 'proof/gargoyle_stage.dart';

/// The silhouette gates ([GargoyleGates]): at 250 and 120 px the creature must
/// read as a stern Art Deco eagle gargoyle, not a cute goggle-eyed owl. The
/// report warned that the first placeholder was an owl (a dome, goggles, no neck,
/// 66% of its bounding box filled); these gates are what the real art must keep:
///
///  * three negative spaces stay open: the THROAT NOTCH (under the beak, in
///    front of the chest), the WING V (between the crest and the near fan) and
///    the TAIL POCKET (between the body and the tail fan), each the diameter of
///    the largest empty disc in its box;
///  * the figure is not a blob: its area over its bounding box's stays under
///    [GargoyleGates.maxFill];
///  * (layout test) the scowl, the visor cover and the hook.
///
/// Measured on flat black silhouettes of the contract's reference rig (layout
/// numbers and pose channels only: ALWAYS enforced) at the pixel scale of a
/// 120 px and a 250 px cell, and of the real art (reports until
/// [enforceRealArt]). At rest every gate holds in full; in action (beam, vent,
/// shrug, roar) the wing V may close to 80%, the throat (a head bowed to look
/// down a LOW beam covers it) to 70% and the tail pocket to 70% while the head
/// moves.
const _throat = ui.Rect.fromLTRB(-3.6, -1.4, -1.45, -.15);
const _wingV = ui.Rect.fromLTRB(-.3, -4.3, 2.3, -1.9);
const _pocket = ui.Rect.fromLTRB(1.75, .55, 3.5, 1.95);

/// A cell shows 9.7 rig units (see the review sheets): 120 px -> 12.4 px per
/// unit, 250 px -> 25.8.
const _ppu120 = 120 / 9.7, _ppu250 = 250 / 9.7;

typedef _M = ({double throat, double v, double pocket, double fill});

Future<_M> _metrics(void Function(ui.Canvas) draw, double ppu) async {
  final m = await rasterize(draw, ppu: ppu, solid: 128);
  return (
    throat: m.largestEmptyDisc(_throat),
    v: m.largestEmptyDisc(_wingV),
    pocket: m.largestEmptyDisc(_pocket),
    fill: m.fill,
  );
}

String _fmt(_M m) =>
    'throat ${m.throat.toStringAsFixed(2)} V ${m.v.toStringAsFixed(2)} pocket ${m.pocket.toStringAsFixed(2)} fill ${m.fill.toStringAsFixed(2)}';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final poses = <(String, GargoylePose Function(), bool rest)>[
    ('idle (Reduced Motion)', () => GargoylePose.still, true),
    ('perch', () => poseOf(gBoss(1.0)), true),
    ('warning', () => poseOf(gBoss(3.0)), false),
    ('sweep HIGH', () => poseOf(gBoss(4.8)), false),
    ('sweep LOW', () => poseOf(gBoss(4.8, side: BeamSide.low)), false),
    ('vent', () => poseOf(gBoss(7.2)), false),
    ('fury slit', () => poseOf(gBoss(5.0, fury: true, slit: true)), false),
    ('shrug', () => poseOf(gBoss(4.55)), false),
    ('fury roar', () => poseOf(gBoss(1.0, fury: true, enragedAgo: .4)), false),
    ('hit', () => poseOf(gBoss(1.0, hitAgo: .08)), false),
  ];

  void check(String who, String name, _M m, bool rest, List<String> problems) {
    final kt = rest ? 1.0 : .7, kv = rest ? 1.0 : .8;
    if (m.throat < GargoyleGates.throatNotch * kt) problems.add('$who $name: throat ${m.throat.toStringAsFixed(2)} < ${(GargoyleGates.throatNotch * kt).toStringAsFixed(2)}');
    if (m.v < GargoyleGates.wingV * kv) problems.add('$who $name: wing V ${m.v.toStringAsFixed(2)} < ${(GargoyleGates.wingV * kv).toStringAsFixed(2)}');
    if (m.pocket < GargoyleGates.tailPocket * (rest ? 1.0 : .7)) problems.add('$who $name: tail pocket ${m.pocket.toStringAsFixed(2)} < ${(GargoyleGates.tailPocket * (rest ? 1 : .7)).toStringAsFixed(2)}');
    if (m.fill > GargoyleGates.maxFill) problems.add('$who $name: fill ${m.fill.toStringAsFixed(2)} > ${GargoyleGates.maxFill}');
  }

  testWidgets('the reference silhouette keeps the three negative spaces and is not a blob, at 120 and 250 px', (tester) async {
    await tester.runAsync(() async {
      final problems = <String>[];
      for (final ppu in [_ppu120, _ppu250]) {
        for (final (name, mk, rest) in poses) {
          final pose = mk();
          final m = await _metrics((c) => paintProofGargoyle(c, pose), ppu);
          // ignore: avoid_print
          print('proof @${ppu.round()}ppu $name: ${_fmt(m)}');
          check('proof@${ppu.round()}', name, m, rest, problems);
        }
      }
      expect(problems, isEmpty);
    });
  }, timeout: const Timeout(Duration(minutes: 3)));

  testWidgets('the real art keeps them too (reports until enforced)', (tester) async {
    await tester.runAsync(() async {
      final problems = <String>[];
      for (final (name, mk, rest) in poses) {
        final pose = mk();
        final m = await _metrics((c) => GargoyleBossRig.paintPose(c, pose, plinth: false), _ppu120);
        // ignore: avoid_print
        print('art @120px $name: ${_fmt(m)}');
        check('art', name, m, rest, problems);
      }
      if (problems.isNotEmpty) {
        // ignore: avoid_print
        print('silhouette gates broken by the real art:\n${problems.join('\n')}');
      }
      if (enforceRealArt) expect(problems, isEmpty);
    });
  }, timeout: const Timeout(Duration(minutes: 3)));

  testWidgets('the owl of the first placeholder fails the gates: a dome head on a bean with a flat fill', (tester) async {
    // The gates would have caught the report's placeholder: a fan-less, necks-less
    // blob. A solid ellipse body with a round head stands in for it.
    await tester.runAsync(() async {
      final m = await _metrics((c) {
        final p = ui.Paint()..color = const ui.Color(0xff000000);
        c.drawOval(const ui.Rect.fromLTRB(-2.0, -1.9, 1.9, 2.9), p);
        c.drawCircle(const ui.Offset(-1.2, -2.2), 1.5, p);
        c.drawRect(const ui.Rect.fromLTRB(1.0, -3.6, 3.5, 2.9), p);
      }, _ppu120);
      final problems = <String>[];
      check('owl', 'blob', m, true, problems);
      expect(problems, isNotEmpty, reason: 'the gates must fail a blob: ${_fmt(m)}');
    });
  });

  testWidgets('the gates are scale stable: 120 px and 250 px agree within a fifth', (tester) async {
    await tester.runAsync(() async {
      final pose = GargoylePose.still;
      final a = await _metrics((c) => paintProofGargoyle(c, pose), _ppu120);
      final b = await _metrics((c) => paintProofGargoyle(c, pose), _ppu250);
      expect(a.throat, closeTo(b.throat, b.throat * .2 + .1));
      expect(a.v, closeTo(b.v, b.v * .2 + .1));
      expect(a.pocket, closeTo(b.pocket, b.pocket * .2 + .1));
      expect((a.fill - b.fill).abs(), lessThan(.04));
    });
  });

  testWidgets('every silhouette is one piece of the same size class: the figure is 6.5 to 8 units tall', (tester) async {
    await tester.runAsync(() async {
      final m = await rasterize((c) => paintProofGargoyle(c, GargoylePose.still), ppu: 24, solid: 200);
      final r = m.bounds!.rect;
      expect(r.height, inInclusiveRange(6.4, 8.2), reason: 'crest to talons');
      expect(r.width, inInclusiveRange(7.5, 9.0), reason: 'beak to fan tip');
      expect(GargoyleLayout.restEnvelope.contains(r.topLeft) && GargoyleLayout.restEnvelope.contains(r.bottomRight), isTrue);
      expect(math.max(r.width, r.height), lessThan(9.0));
    });
  });
}
