// M1 integration: the Steam Geysers' art (A2) over the REAL vents of the
// steam rules (R1). The art was built and measured against vents laid by hand
// ("the simulation lays none until the rules land"); here every vent of real
// routes, with the plume tops the rules really compute, goes through the same
// budget and envelope checks, and real flights are painted by the real
// renderer at 640 and 800.
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/game/steam_geyser_art.dart';
import 'package:push_up_bird/game/steam_geyser_emitter_art.dart';

import 'ny_arena.dart' as arena;
import 'steam_geyser_counting_canvas.dart';
import 'steam_geyser_scenes.dart' show mountGame, narrow, shoot, wide;

const _h = 360.0, _w = 800.0;

LevelPlan alley({
  SteamPlan steam = SteamPlan.steady,
  int seed = 3103,
  double length = 80,
}) => arena.rulesPlan(
  id: '3-3',
  length: length,
  start: 100,
  seed: seed,
  lineup: const [],
  steam: steam,
  marks: const StarMarks(55, 90),
);

/// Every vent a real flight of [plan] lays, as the simulation built it.
List<SteamVent> realVents(LevelPlan plan) {
  final sim = arena.arenaOf(plan);
  final seen = <int, SteamVent>{};
  arena.runUntil(
    sim,
    (s) => s.phase == RunPhase.ended,
    steer: arena.vacuumY,
    immortal: true,
    seconds: 200,
    watch: (s) {
      for (final v in s.steamVents) {
        seen.putIfAbsent(
          v.geyser.slot,
          () => SteamVent(geyser: v.geyser, x: v.geyser.x, top: v.top),
        );
      }
    },
  );
  return seen.values.toList();
}

final _plans = [
  alley(),
  alley(seed: 3203),
  alley(seed: 7001),
  alley(steam: SteamPlan.sparse, length: 30, seed: 3104),
];

/// Every 0.1 s of the vent's cycle, hiss to sleep.
final _taus = [for (var i = -15; i < 28; i++) i * .1];

void _paint(
  ui.Canvas canvas,
  SteamVent vent,
  double tau, {
  bool reduced = false,
}) {
  final route = vent.geyser.burstAt + tau;
  SteamGeyserArt.paintVent(canvas, _h, 400, vent, route, 3.3, reduced);
}

Future<Uint8List> _pixels(void Function(ui.Canvas) paint) async {
  final recorder = ui.PictureRecorder();
  paint(ui.Canvas(recorder));
  final picture = recorder.endRecording();
  final image = await picture.toImage(_w.toInt(), _h.toInt());
  final bytes = (await image.toByteData())!.buffer.asUint8List();
  image.dispose();
  picture.dispose();
  return Uint8List.fromList(bytes);
}

void main() {
  late List<SteamVent> vents;
  setUpAll(() => vents = [for (final plan in _plans) ...realVents(plan)]);

  test(
    'the real routes lay hop and ride vents with the tops the art knows',
    () {
      expect(vents.length, greaterThan(24));
      expect(vents.any((v) => v.kind == SteamKind.hop), isTrue);
      expect(vents.any((v) => v.kind == SteamKind.ride), isTrue);
      for (final v in vents) {
        expect(v.top, inInclusiveRange(.38, .66), reason: '${v.geyser.slot}');
        expect(v.top, lessThan(v.mouth));
      }
    },
  );

  group('budget, on every real vent', () {
    test('at most 80 draw calls in any state, no layers, blur or shaders', () {
      var worst = 0;
      for (final vent in vents) {
        for (final reduced in [false, true]) {
          for (final tau in _taus) {
            final count = CountingCanvas(ui.Canvas(ui.PictureRecorder()));
            _paint(count, vent, tau, reduced: reduced);
            final why =
                'slot ${vent.geyser.slot} ${vent.kind.name} top '
                '${vent.top.toStringAsFixed(3)} at $tau';
            expect(
              count.draws,
              lessThanOrEqualTo(SteamGeyserArt.maxOpsPerVent),
              reason: why,
            );
            expect(count.layers, 0, reason: why);
            expect(count.blurs, 0, reason: why);
            expect(count.shaders, 0, reason: why);
            expect(count.clips, 0, reason: why);
            worst = math.max(worst, count.draws);
          }
        }
      }
      expect(worst, greaterThan(40), reason: 'the probe really paints');
    });
  });

  group('the plume against the hit and lift boxes, real tops', () {
    /// The solid run either side of the vent's centre line at row [y].
    (int, int) runAt(Uint8List px, int cx, int y) {
      int a(int x) => px[(y * _w.toInt() + x) * 4 + 3];
      var left = 0, right = 0;
      while (a(cx - left - 1) > 200 && left < 120) {
        left++;
      }
      while (a(cx + right) > 200 && right < 120) {
        right++;
      }
      return (left, right);
    }

    testWidgets('a hop burst is never narrower than the hit box and stands on '
        'the rules\' plume top', (tester) async {
      await tester.runAsync(() async {
        for (final vent in vents.where((v) => v.kind == SteamKind.hop)) {
          for (final tau in const [.14, .3, .4]) {
            final route = vent.geyser.burstAt + tau;
            final top = vent.plumeTop(route) * _h;
            final mouth = SteamEmitterArt.lipY(vent, _h);
            final px = await _pixels(
              (c) => _paint(c, vent, tau, reduced: true),
            );
            int? first;
            for (var y = top.round() - 12; y < mouth - 10; y++) {
              final (l, r) = runAt(px, 400, y);
              if (l + r == 0) continue;
              first ??= y;
              if (y < top + 9) continue;
              final least = (SteamCycle.hitHalfWidth * _h).floor();
              final why =
                  'slot ${vent.geyser.slot} top ${vent.top} tau $tau row '
                  '${y - top.round()}';
              expect(l, greaterThanOrEqualTo(least), reason: '$why left');
              expect(r, greaterThanOrEqualTo(least), reason: '$why right');
            }
            expect(
              (first! - top).abs(),
              lessThanOrEqualTo(4),
              reason: 'slot ${vent.geyser.slot} tau $tau: crown top',
            );
          }
        }
      });
    });

    testWidgets('a billow is never narrower than the lift box and stands on '
        'the vent\'s top, hop or ride', (tester) async {
      await tester.runAsync(() async {
        for (final vent in vents) {
          for (final tau in const [.7, .95, 1.3]) {
            final top = vent.top * _h, mouth = SteamEmitterArt.lipY(vent, _h);
            final px = await _pixels(
              (c) => _paint(c, vent, tau, reduced: true),
            );
            int? first;
            for (var y = top.round() - 12; y < mouth - 10; y++) {
              final (l, r) = runAt(px, 400, y);
              if (l + r == 0) continue;
              first ??= y;
              if (y < top + 12) continue;
              final least = (SteamCycle.liftHalfWidth * _h).floor();
              final why =
                  'slot ${vent.geyser.slot} ${vent.kind.name} top ${vent.top} '
                  'tau $tau row ${y - top.round()}';
              expect(l, greaterThanOrEqualTo(least), reason: '$why left');
              expect(r, greaterThanOrEqualTo(least), reason: '$why right');
            }
            expect(
              (first! - top).abs(),
              lessThanOrEqualTo(4),
              reason: 'slot ${vent.geyser.slot} ${vent.kind.name} tau $tau',
            );
          }
        }
      });
    });
  });

  group('the real renderer over a real flight', () {
    testWidgets('steam is painted over New York, the bird '
        'untouched, at 640 and 800, in every phase', (tester) async {
      for (final size in [wide, narrow]) {
        // Each phase seen where the bird meets it: the hiss while the vent
        // is still ahead, the burst and the billow as it is reached.
        for (final (phase, near, far) in [
          (SteamPhase.hiss, .4, 1.2),
          (SteamPhase.burst, -.05, .6),
          (SteamPhase.billow, -.5, .3),
        ]) {
          final sim = arena.arenaOf(alley());
          arena.runUntil(
            sim,
            (s) => s.steamVents.any(
              (v) =>
                  v.phaseAt(s.routeSeconds) == phase &&
                  v.x > FlightSimulation.birdX + near &&
                  v.x < FlightSimulation.birdX + far,
            ),
            steer: arena.vacuumY,
            immortal: true,
            seconds: 200,
          );
          final game = await mountGame(tester, sim, size);
          late Uint8List withSteam, without;
          await tester.runAsync(() async {
            withSteam = (await (await shoot(
              game,
              size,
            )).toByteData())!.buffer.asUint8List();
            final held = List.of(sim.steamVents);
            sim.steamVents.clear();
            without = (await (await shoot(
              game,
              size,
            )).toByteData())!.buffer.asUint8List();
            sim.steamVents.addAll(held);
          });
          var differing = 0;
          for (var i = 0; i < withSteam.length; i++) {
            if (withSteam[i] != without[i]) differing++;
          }
          expect(differing, greaterThan(400), reason: '${size.width} $phase');
          // The bird's patch is identical with and without the steam (the
          // vents are painted behind it).
          final bx = (FlightSimulation.birdX * size.height).round();
          final by = (sim.birdY * size.height).round();
          for (var dy = -6; dy <= 6; dy++) {
            for (var dx = -6; dx <= 6; dx++) {
              final i = ((by + dy) * size.width.round() + bx + dx) * 4;
              for (var k = 0; k < 4; k++) {
                expect(
                  withSteam[i + k],
                  without[i + k],
                  reason: '${size.width} $phase: the bird at $dx,$dy',
                );
              }
            }
          }
        }
      }
    });
  });
}
