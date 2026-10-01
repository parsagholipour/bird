import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/sky_boss.dart';
import 'package:push_up_bird/game/king_coo_boss_rig.dart';
import 'package:push_up_bird/game/king_coo_kit.dart';
import 'package:push_up_bird/game/king_coo_layout.dart';
import 'package:push_up_bird/game/king_coo_pose.dart';

import 'king_coo_test_kit.dart';

/// Pixels depend only on the inputs.
///
/// The parts keep paths and gradients between frames (`KingCooKit.cached`,
/// `cachedPath`, the glow shaders). A cache must never change a pixel: the
/// same state must render identically whatever was drawn before it and
/// whatever is (or is not) cached. The tone is laid over static gradients as
/// a wash, so there is nothing to snap; this test is the referee.
///
/// It renders many states in one order, then EMPTIES every cache, then
/// renders them all again in the opposite order: a state's pixels must be
/// identical either way. A pixel that differs is named by state.
const _w = 360, _h = 360, _ppu = 24.0;

typedef _State = (String, KingCooPose Function());

const _lights = <KingCooSkyLight>[
  KingCooSkyLight.neutral,
  KingCooSkyLight(dark: .41, sky: ui.Color(0xff8a70a8)),
  KingCooSkyLight(dark: .80, sky: ui.Color(0xff5a48a0)),
];

List<_State> _states() {
  final rnd = math.Random(7);
  final out = <_State>[];
  // Random moments of the fight with a hit, the fury, a throw and a pop mixed
  // in.
  for (var i = 0; i < 40; i++) {
    final combat = rnd.nextDouble() * 28;
    final light = _lights[i % 3];
    out.add((
      'fight $i (combat ${combat.toStringAsFixed(2)})',
      () {
        final b = cooBoss(
          combat: combat,
          fury: i % 3 == 0,
          setup: (b) {
            if (i % 5 == 0) b.lastHitAt = b.age - .1;
            if (i % 4 == 1) b.lobs.add(lobAt(b.age - .3 - .05 * (i % 9)));
            if (i % 7 == 2) b.poppedAt = b.age - .3;
          },
        );
        return poseOf(b, reduced: i % 6 == 5, light: light);
      },
    ));
  }
  // The pose sheet's moments, in every look the tone has: calm, hit-flashed,
  // furious, on a dusk sky and a night one.
  for (final (name, t) in const [
    ('idle', 1.2),
    ('inhale', 8.3),
    ('puffed', 9.0),
    ('whistle', 9.3),
    ('release', 1.4),
  ]) {
    for (final (look, fury, hit, light) in const [
      ('calm', false, false, 0),
      ('hit', false, true, 0),
      ('fury', true, false, 0),
      ('fury hit', true, true, 1),
      ('dusk', false, false, 1),
      ('night', false, true, 2),
    ]) {
      out.add((
        '$name $look',
        () => poseOf(
          cooBoss(
            combat: t,
            fury: fury,
            setup: (b) {
              if (hit) b.lastHitAt = b.age - .1;
              if (name == 'release') b.lobs.add(lobAt(b.age - .8));
            },
          ),
          light: _lights[light],
        ),
      ));
    }
  }
  for (final age in [.5, 1.9, 2.4, 3.0, 4.0]) {
    out.add(('arrival $age', () => poseOf(arrivingBoss(age), light: _lights[2])));
  }
  for (final d in [.1, .5, .9, 1.2]) {
    out.add(('defeat $d', () => poseOf(dyingBoss(d), light: _lights[1])));
  }
  return out;
}

Future<Uint8List> _px(_State s, {Set<String>? only}) => rawPixels(_w, _h, (c) {
  c.translate(_w / 2, _h / 2);
  c.scale(_ppu);
  KingCooBossRig.paintPose(c, s.$2(), only: only);
});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a state renders the same pixels whatever was drawn before it', (
    tester,
  ) async {
    await tester.runAsync(() async {
      KingCooKit.clearCaches();
      final states = _states();
      expect(states.length, greaterThanOrEqualTo(70));
      final order = [for (var i = 0; i < states.length; i++) i];
      final fwd = <int, Uint8List>{};
      for (final i in order) {
        fwd[i] = await _px(states[i]);
      }
      // Empty every cache the parts keep, then come back the other way round.
      KingCooKit.clearCaches();
      final back = <int, Uint8List>{};
      for (final i in order.reversed) {
        back[i] = await _px(states[i]);
      }
      final bad = <String>[];
      for (final i in order) {
        final a = fwd[i]!, b = back[i]!;
        var n = 0, maxd = 0;
        for (var p = 0; p < a.length; p++) {
          final d = (a[p] - b[p]).abs();
          if (d > 0) {
            if (p % 4 == 0) n++;
            maxd = math.max(maxd, d);
          }
        }
        if (n > 0) bad.add('${states[i].$1}: $n px differ, max $maxd/255');
      }
      // ignore: avoid_print
      print('mismatching states: ${bad.length} of ${states.length}${bad.isEmpty ? '' : '\n${bad.join('\n')}'}');
      expect(bad, isEmpty, reason: 'pixels depended on the visiting order');
    });
  }, timeout: const Timeout(Duration(minutes: 10)));

  testWidgets('the same state twice in a row is the same picture', (tester) async {
    await tester.runAsync(() async {
      for (final s in _states().take(30)) {
        expect(await _px(s), await _px(s), reason: s.$1);
      }
    });
  });

  testWidgets('every part is deterministic on its own', (tester) async {
    await tester.runAsync(() async {
      final states = [for (var i = 0; i < 40; i += 8) _states()[i]];
      for (final part in KingCooBossRig_parts) {
        KingCooKit.clearCaches();
        final fwd = [for (final s in states) await _px(s, only: {part})];
        KingCooKit.clearCaches();
        for (var i = states.length - 1; i >= 0; i--) {
          expect(await _px(states[i], only: {part}), fwd[i], reason: '$part ${states[i].$1}');
        }
      }
    });
  });

  test('the pose does not read the wall clock, a random or history', () {
    // Two separately built identical bosses give the same channels, and a
    // boss that was evaluated at other ages first gives the same channels.
    final a = cooBoss(combat: 9.3, setup: (b) => b.lastHitAt = b.age - .1);
    final b = cooBoss(combat: 9.3, setup: (b) => b.lastHitAt = b.age - .1);
    poseOf(a, at: 4.6 + 2.0);
    poseOf(a, at: 4.6 + 12.0);
    expect(poseOf(a).values, poseOf(b).values);
    expect(SkyBoss, isNotNull);
  });
}

// ignore: non_constant_identifier_names, prefer_const_declarations
final KingCooBossRig_parts = KingCooLayout.zOrder;
