import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/campaign.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/game/steam_geyser_art.dart';
import 'package:push_up_bird/game/steam_geyser_emitter_art.dart';

import 'campaign_flight.dart' show levelFlight;
import 'steam_geyser_counting_canvas.dart';
import 'steam_geyser_scenes.dart';

/// The Steam Geysers' art: a per-vent draw-call budget with no layers, blur
/// or shaders, pure-function animation (Reduced Motion still frames per
/// phase), the plume never narrower than the hit and lift boxes and its top
/// on the hit box's top, hot against cool, and the bird and the stars never
/// covered, through the real renderer.
const _h = 360.0, _w = 800.0;

/// One vent of each design: a hop manhole cover (short plume), a ride subway
/// grate (short), a hop Con Ed stack (tall) and, which the rules never lay
/// but the art must survive, a ride stack.
final _designs = <(String, VentSpec)>[
  ('hop cover', spec(1.2, .52, 0, slot: 12)),
  ('ride grate', spec(1.2, .56, 0, kind: SteamKind.ride)),
  ('hop stack', spec(1.2, .40, 0)),
  ('ride stack', spec(1.2, .42, 0, kind: SteamKind.ride)),
];

/// Every 0.05 s of the 4.2 s cycle, hiss to sleep.
final _taus = [for (var i = -30; i < 54; i++) i * .05];

FlightSimulation _bare() {
  final sim = levelFlight(Campaign.level('3-3')!, practice: true);
  sim.steamVents.clear();
  return sim;
}

/// Paints [v] caught [tau] route seconds into its cycle.
void _vent(
  ui.Canvas canvas,
  VentSpec v,
  double tau, {
  bool reduced = false,
  double clock = 3.3,
}) {
  const route = 50.0;
  final vent = makeVent((
    x: v.x,
    top: v.top,
    kind: v.kind,
    tau: tau,
    slot: v.slot,
  ), route);
  SteamGeyserArt.paintVent(canvas, _h, v.x * _h, vent, route, clock, reduced);
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

/// The fraction of pixels that differ between two frames.
double _diff(Uint8List a, Uint8List b) {
  var n = 0;
  for (var i = 0; i < a.length; i += 4) {
    if (a[i] != b[i] ||
        a[i + 1] != b[i + 1] ||
        a[i + 2] != b[i + 2] ||
        a[i + 3] != b[i + 3]) {
      n++;
    }
  }
  return n / (a.length / 4);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('budget', () {
    test(
      'a vent costs at most 80 draw calls in any state, no layers, blur or shaders',
      () {
        var worst = 0, least = 1 << 30;
        for (final (name, v) in _designs) {
          for (final reduced in [false, true]) {
            for (final tau in _taus) {
              final count = CountingCanvas(ui.Canvas(ui.PictureRecorder()));
              _vent(count, v, tau, reduced: reduced);
              final why = '$name at $tau${reduced ? ' (Reduced Motion)' : ''}';
              expect(
                count.draws,
                lessThanOrEqualTo(SteamGeyserArt.maxOpsPerVent),
                reason: why,
              );
              expect(count.layers, 0, reason: '$why: saveLayer');
              expect(count.blurs, 0, reason: '$why: blur');
              expect(count.shaders, 0, reason: '$why: shader');
              expect(count.clips, 0, reason: '$why: clip');
              expect(count.unforwarded, 0, reason: '$why: ${count.counts}');
              worst = math.max(worst, count.draws);
              least = math.min(least, count.draws);
            }
          }
        }
        // ignore: avoid_print
        print('steam vent draw calls: $least to $worst per vent');
        expect(worst, greaterThan(40), reason: 'the probe really paints');
      },
    );

    test('the heaviest frame the rules can lay stays under 160', () {
      // Slots are at least three passages apart, about 3.1 screen heights
      // (the culling range is 3.1 heights too), so an 800 px screen holds two
      // vents only at the very edges. Every phase of the first against every
      // phase of the second, and the bird's own feedback on top.
      final sim = _bare();
      var worst = 0;
      for (final (i, kinds) in [
        (0, [_designs[0].$2, _designs[1].$2]),
        (1, [_designs[1].$2, _designs[0].$2]),
        (2, [_designs[2].$2, _designs[1].$2]),
      ]) {
        for (var tau = -1.5; tau < 2.7; tau += .05) {
          for (var off = 0.0; off < 4.2; off += .35) {
            sim.steamVents
              ..clear()
              ..addAll([
                for (final (k, v) in kinds.indexed)
                  makeVent((
                    x: -.44 + k * 3.1,
                    top: v.top,
                    kind: v.kind,
                    tau: tau + k * off,
                    slot: v.slot,
                  ), sim.routeSeconds),
              ]);
            final count = CountingCanvas(ui.Canvas(ui.PictureRecorder()));
            SteamGeyserArt.vents(
              count,
              const Size(_w, _h),
              sim,
              reducedMotion: false,
            );
            SteamGeyserArt.feedback(
              count,
              const Size(_w, _h),
              sim,
              reducedMotion: false,
            );
            expect(
              count.draws,
              lessThanOrEqualTo(SteamGeyserArt.maxOpsPerFrame),
              reason: 'pair $i tau $tau offset $off',
            );
            expect(count.layers + count.blurs + count.shaders, 0);
            worst = math.max(worst, count.draws);
          }
        }
      }
      // ignore: avoid_print
      print('steam frame of two vents: worst $worst draw calls');
    });

    test(
      'three vents 3.1 heights apart on a wide screen, as the route times them',
      () {
        // On a 2000 px wide viewport three vents 3.1 heights apart can show;
        // a route has them 6.9 s apart, which is 2.7 s apart in the 4.2 s cycle.
        final sim = _bare();
        var worst = 0;
        for (var tau = -1.5; tau < 2.7; tau += .05) {
          sim.steamVents
            ..clear()
            ..addAll([
              for (final (k, (_, v)) in _designs.take(3).indexed)
                makeVent((
                  x: -.44 + k * 3.1,
                  top: v.top,
                  kind: v.kind,
                  tau: tau + k * 2.7,
                  slot: v.slot,
                ), sim.routeSeconds),
            ]);
          final count = CountingCanvas(ui.Canvas(ui.PictureRecorder()));
          SteamGeyserArt.vents(
            count,
            const Size(2000, _h),
            sim,
            reducedMotion: false,
          );
          // A 5.6:1 screen: nothing a player holds. Recorded so a regression
          // shows, not a promise (the frame budget is for 16:9 phones).
          expect(count.draws, lessThanOrEqualTo(190), reason: 'tau $tau');
          worst = math.max(worst, count.draws);
        }
        // ignore: avoid_print
        print(
          'steam frame of three vents, route-timed: worst $worst draw calls',
        );
      },
    );

    test('vents off screen cost nothing and an empty list costs nothing', () {
      final sim = _bare();
      final count = CountingCanvas(ui.Canvas(ui.PictureRecorder()));
      SteamGeyserArt.vents(
        count,
        const Size(_w, _h),
        sim,
        reducedMotion: false,
      );
      SteamGeyserArt.feedback(
        count,
        const Size(_w, _h),
        sim,
        reducedMotion: false,
      );
      expect(count.draws, 0);
      for (final x in [-1.2, 4.0]) {
        sim.steamVents.add(makeVent(spec(x, .5, .2), sim.routeSeconds));
      }
      SteamGeyserArt.vents(
        count,
        const Size(_w, _h),
        sim,
        reducedMotion: false,
      );
      expect(count.draws, 0);
    });
  });

  group('pure function of the clocks', () {
    testWidgets('the same inputs always paint the same pixels', (tester) async {
      await tester.runAsync(() async {
        for (final (name, v) in _designs) {
          for (final tau in const [-1.0, -.1, .05, .3, .8, 1.6, 2.4]) {
            for (final reduced in [false, true]) {
              final a = await _pixels(
                (c) => _vent(c, v, tau, reduced: reduced),
              );
              // Paint something else in between: no state may leak.
              await _pixels((c) => _vent(c, _designs[2].$2, .3));
              final b = await _pixels(
                (c) => _vent(c, v, tau, reduced: reduced),
              );
              expect(_diff(a, b), 0, reason: '$name at $tau reduced=$reduced');
            }
          }
        }
      });
    });

    testWidgets(
      'Reduced Motion ignores the simulation clock and keeps the state',
      (tester) async {
        await tester.runAsync(() async {
          for (final (name, v) in _designs) {
            final frames = <double, Uint8List>{};
            for (final tau in const [-1.1, -.4, .3, .9, 2.3]) {
              final a = await _pixels(
                (c) => _vent(c, v, tau, reduced: true, clock: 0),
              );
              final b = await _pixels(
                (c) => _vent(c, v, tau, reduced: true, clock: 97.3),
              );
              expect(
                _diff(a, b),
                0,
                reason: '$name at $tau: clock must not matter',
              );
              frames[tau] = a;
            }
            // ...while the phase itself still moves the picture.
            expect(
              _diff(frames[-1.1]!, frames[-.4]!),
              greaterThan(0),
              reason: '$name hiss builds',
            );
          }
        });
      },
    );

    testWidgets('with motion the decoration follows the clock', (tester) async {
      await tester.runAsync(() async {
        // Hiss, burst and billow all have something that moves; a sleeping
        // vent's wisps do too.
        for (final tau in const [-.6, .3, 1.0, 2.3]) {
          final a = await _pixels(
            (c) => _vent(c, _designs[0].$2, tau, clock: 1.0),
          );
          final b = await _pixels(
            (c) => _vent(c, _designs[0].$2, tau, clock: 1.37),
          );
          expect(_diff(a, b), greaterThan(0), reason: 'tau $tau');
        }
      });
    });
  });

  group('the four phases', () {
    testWidgets('read as four different pictures, with and without motion', (
      tester,
    ) async {
      await tester.runAsync(() async {
        for (final (name, v) in _designs) {
          for (final reduced in [false, true]) {
            final still = <String, Uint8List>{
              'sleep': await _pixels((c) => _vent(c, v, 2.3, reduced: reduced)),
              'hiss': await _pixels((c) => _vent(c, v, -.5, reduced: reduced)),
              'burst': await _pixels((c) => _vent(c, v, .3, reduced: reduced)),
              'billow': await _pixels(
                (c) => _vent(c, v, .95, reduced: reduced),
              ),
            };
            for (final a in still.keys) {
              for (final b in still.keys) {
                if (a.compareTo(b) >= 0) continue;
                expect(
                  _diff(still[a]!, still[b]!),
                  greaterThan(.004),
                  reason: '$name: $a vs $b (reduced=$reduced)',
                );
              }
            }
          }
        }
      });
    });

    testWidgets(
      'a hop vent and a ride vent are told apart before the burst and in the billow',
      (tester) async {
        await tester.runAsync(() async {
          final hop = spec(1.2, .56, 0, slot: 4),
              ride = spec(1.2, .56, 0, kind: SteamKind.ride, slot: 4);
          for (final tau in const [-.6, .95, 2.3]) {
            final a = await _pixels((c) => _vent(c, hop, tau, reduced: true));
            final b = await _pixels((c) => _vent(c, ride, tau, reduced: true));
            expect(_diff(a, b), greaterThan(.0005), reason: 'tau $tau');
          }
        });
      },
    );

    testWidgets(
      'the tall and the short emitter differ, and top picks the design',
      (tester) async {
        await tester.runAsync(() async {
          final stack = await _pixels(
            (c) => _vent(c, spec(1.2, .40, 0), 2.3, reduced: true),
          );
          final cover = await _pixels(
            (c) => _vent(c, spec(1.2, .52, 0), 2.3, reduced: true),
          );
          expect(_diff(stack, cover), greaterThan(.001));
        });
      },
    );

    testWidgets('hot steam is warm and soft steam is cool', (tester) async {
      await tester.runAsync(() async {
        for (final v in [_designs[0].$2, _designs[2].$2]) {
          final burst = await _pixels((c) => _vent(c, v, .3, reduced: true));
          final billow = await _pixels((c) => _vent(c, v, 1.0, reduced: true));
          // The plume's middle, inside the ink: average colour.
          (double, double) mean(Uint8List px, double top, double bottom) {
            var r = 0.0, b = 0.0, n = 0;
            for (var y = (top * _h).round(); y < (bottom * _h).round(); y++) {
              for (
                var x = (v.x * _h).round() - 30;
                x < (v.x * _h).round() + 30;
                x++
              ) {
                final i = (y * _w.toInt() + x) * 4;
                if (px[i + 3] < 250) continue;
                r += px[i];
                b += px[i + 2];
                n++;
              }
            }
            return (r / n, b / n);
          }

          final lo = v.top + .10, hi = v.top + .20;
          final (hr, hb) = mean(burst, lo, hi);
          final (cr, cb) = mean(billow, lo, hi);
          expect(
            hr - hb,
            greaterThan(25),
            reason: 'the burst is warm (${v.top})',
          );
          expect(
            cb - cr,
            greaterThan(5),
            reason: 'the billow is cool (${v.top})',
          );
        }
      });
    });
  });

  group('the plume against the hit and lift boxes', () {
    /// The solid (opaque) run either side of the vent's centre line at row y.
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

    testWidgets(
      'a burst is never narrower than the hit box and stands on its top',
      (tester) async {
        await tester.runAsync(() async {
          for (final (name, v) in _designs) {
            for (final tau in const [.14, .2, .3, .4]) {
              final vent = makeVent((
                x: v.x,
                top: v.top,
                kind: v.kind,
                tau: tau,
                slot: v.slot,
              ), 50);
              final top = vent.plumeTop(50) * _h;
              final mouth = SteamEmitterArt.lipY(vent, _h);
              final px = await _pixels((c) => _vent(c, v, tau, reduced: true));
              final cx = (v.x * _h).round();
              int? first;
              for (var y = top.round() - 12; y < mouth - 10; y++) {
                final (l, r) = runAt(px, cx, y);
                if (l + r == 0) continue;
                first ??= y;
                if (y < top + 9) continue;
                expect(
                  l,
                  greaterThanOrEqualTo((SteamCycle.hitHalfWidth * _h).floor()),
                  reason: '$name tau $tau row ${y - top.round()} left',
                );
                expect(
                  r,
                  greaterThanOrEqualTo((SteamCycle.hitHalfWidth * _h).floor()),
                  reason: '$name tau $tau row ${y - top.round()} right',
                );
              }
              expect(
                (first! - top).abs(),
                lessThanOrEqualTo(4),
                reason: '$name tau $tau: crown top vs hit top',
              );
            }
          }
        });
      },
    );

    testWidgets(
      'a billow is never narrower than the lift box and stands on its top',
      (tester) async {
        await tester.runAsync(() async {
          for (final (name, v) in _designs) {
            for (final tau in const [.7, .95, 1.3]) {
              final vent = makeVent((
                x: v.x,
                top: v.top,
                kind: v.kind,
                tau: tau,
                slot: v.slot,
              ), 50);
              final top = v.top * _h, mouth = SteamEmitterArt.lipY(vent, _h);
              final px = await _pixels((c) => _vent(c, v, tau, reduced: true));
              final cx = (v.x * _h).round();
              int? first;
              for (var y = top.round() - 12; y < mouth - 10; y++) {
                final (l, r) = runAt(px, cx, y);
                if (l + r == 0) continue;
                first ??= y;
                if (y < top + 12) continue;
                expect(
                  l,
                  greaterThanOrEqualTo((SteamCycle.liftHalfWidth * _h).floor()),
                  reason: '$name tau $tau row ${y - top.round()} left',
                );
                expect(
                  r,
                  greaterThanOrEqualTo((SteamCycle.liftHalfWidth * _h).floor()),
                  reason: '$name tau $tau row ${y - top.round()} right',
                );
              }
              expect(
                (first! - top).abs(),
                lessThanOrEqualTo(4),
                reason: '$name tau $tau: cloud top',
              );
            }
          }
        });
      },
    );

    testWidgets(
      'nothing stands above a sleeping or hissing vent but the ghost',
      (tester) async {
        await tester.runAsync(() async {
          // No solid steam (opaque cream) outside the emitter in the hiss.
          final v = _designs[0].$2;
          final px = await _pixels((c) => _vent(c, v, -.8, reduced: true));
          final vent = makeVent((
            x: v.x,
            top: v.top,
            kind: v.kind,
            tau: -.8,
            slot: v.slot,
          ), 50);
          final cx = (v.x * _h).round();
          final reach = v.top * _h;
          for (
            var y = 0;
            y < (SteamEmitterArt.lipY(vent, _h) - 30).round();
            y++
          ) {
            // (the reach tick is a bar across the top of the ghost)
            if (y > reach - 6 && y < reach + 8) continue;
            final (l, r) = runAt(px, cx, y);
            expect(
              l + r,
              lessThan(26),
              reason: 'row $y: only rails, the dome and puffs, never a plume',
            );
          }
        });
      },
    );
  });

  group('drawn over the world, never over the bird or a star', () {
    testWidgets('a vent leaves the bird and a star untouched', (tester) async {
      for (final (size, tag) in [(wide, '800'), (narrow, '640')]) {
        for (final (tau, kind, top) in [
          (.3, SteamKind.hop, .44),
          (1.0, SteamKind.ride, .52),
          (-.4, SteamKind.hop, .44),
        ]) {
          final sim = scene('3-3', [spec(.47, top, tau, kind: kind)], y: .56);
          // A star deep inside the column, where the steam is densest.
          sim.stars.add(SkyStar(x: .47, y: .72));
          final game = await mountGame(tester, sim, size);
          late Uint8List withSteam, without;
          await tester.runAsync(() async {
            withSteam = (await (await shoot(
              game,
              size,
            )).toByteData())!.buffer.asUint8List();
            retime(sim, const []);
            without = (await (await shoot(
              game,
              size,
            )).toByteData())!.buffer.asUint8List();
          });
          bool same(double x, double y) {
            for (var dy = -3; dy <= 3; dy++) {
              for (var dx = -3; dx <= 3; dx++) {
                final i =
                    (((y * _h).round() + dy) * size.width.round() +
                        ((x * _h).round() + dx)) *
                    4;
                for (var k = 0; k < 4; k++) {
                  if (withSteam[i + k] != without[i + k]) return false;
                }
              }
            }
            return true;
          }

          expect(
            same(FlightSimulation.birdX, .56),
            isTrue,
            reason: '$tag $kind $tau: the bird',
          );
          expect(same(.47, .72), isTrue, reason: '$tag $kind $tau: the star');
        }
      }
    });

    testWidgets(
      'the real renderer paints the steam over New York, 640 and 800',
      (tester) async {
        for (final size in [wide, narrow]) {
          final sim = scene('3-3', [
            spec(.9, .44, .3),
            spec(1.5, .52, 1.0, kind: SteamKind.ride),
          ]);
          final game = await mountGame(tester, sim, size);
          late Uint8List withSteam, without;
          await tester.runAsync(() async {
            withSteam = (await (await shoot(
              game,
              size,
            )).toByteData())!.buffer.asUint8List();
            retime(sim, const []);
            without = (await (await shoot(
              game,
              size,
            )).toByteData())!.buffer.asUint8List();
          });
          expect(
            _diff(withSteam, without),
            greaterThan(.02),
            reason: 'two vents are a good part of the frame',
          );
        }
      },
    );
  });

  group('the bird\'s side of the steam', () {
    FlightSimulation bird({
      required double tau,
      required double y,
      double? since,
      SteamKind kind = SteamKind.hop,
    }) {
      final sim = _bare()
        ..birdY = y
        ..velocity = 0;
      sim.steamVents.add(
        makeVent(
          spec(FlightSimulation.birdX, .44, tau, kind: kind),
          sim.routeSeconds,
        ),
      );
      if (since != null) sim.invulnerableUntil = sim.elapsed + 1.5 - since;
      return sim;
    }

    int ops(FlightSimulation sim, {bool reduced = false}) {
      final count = CountingCanvas(ui.Canvas(ui.PictureRecorder()));
      SteamGeyserArt.feedback(
        count,
        const Size(_w, _h),
        sim,
        reducedMotion: reduced,
      );
      return count.draws;
    }

    test('a scald rings the bird for 0.35 s, and never in Reduced Motion', () {
      expect(ops(bird(tau: .25, y: .6, since: .1)), 2);
      expect(ops(bird(tau: .25, y: .6, since: .1), reduced: true), 0);
      expect(ops(bird(tau: .25, y: .6, since: .5)), 0, reason: 'too late');
      expect(ops(bird(tau: .25, y: .6)), 0, reason: 'no hit: no ring');
      expect(
        ops(bird(tau: -.5, y: .6, since: .1)),
        0,
        reason: 'a hit in a hiss is not a scald',
      );
      expect(
        ops(bird(tau: .25, y: .2, since: .1)),
        0,
        reason: 'far above the plume',
      );
    });

    test('a bird in a billow gets lift streaks under it', () {
      expect(ops(bird(tau: 1.0, y: .6)), 1);
      expect(
        ops(bird(tau: 1.0, y: .6), reduced: true),
        1,
        reason: 'still, not hidden',
      );
      expect(ops(bird(tau: 1.0, y: .2)), 0, reason: 'above the cloud');
      expect(ops(bird(tau: 2.3, y: .6)), 0, reason: 'asleep');
    });
  });

  group('presence in a real flight (the fix round)', () {
    /// Opaque pixels (alpha > 200) in a window over the vent, rows from
    /// [top] to [bottom] and columns within [half] of its centre.
    int solid(Uint8List px, int cx, int top, int bottom, int half) {
      var n = 0;
      for (var y = top; y < bottom; y++) {
        for (var x = cx - half; x < cx + half; x++) {
          if (px[(y * _w.toInt() + x) * 4 + 3] > 200) n++;
        }
      }
      return n;
    }

    testWidgets(
      'a burst or a billow is broad but never wider than the bird can feel',
      (tester) async {
        await tester.runAsync(() async {
          // The widest solid row of the drawn steam: the burst reaches no
          // further than the hit box plus the bird's own radius plus a hand
          // (.05 + .038 + .035 h); the billow, which never hurts, no further
          // than .16 h either side.
          for (final (name, v) in _designs) {
            for (final (tau, limit, least) in const [
              (.14, .125, .06),
              (.3, .125, .08),
              (.4, .125, .08),
              (.95, .16, .12),
              (1.3, .16, .12),
            ]) {
              final px = await _pixels((c) => _vent(c, v, tau, reduced: true));
              final cx = (v.x * _h).round();
              final vent = makeVent((
                x: v.x,
                top: v.top,
                kind: v.kind,
                tau: tau,
                slot: v.slot,
              ), 50);
              final lip = SteamEmitterArt.lipY(vent, _h);
              var widest = 0;
              for (var y = ((v.top - .02) * _h).round(); y < lip - 12; y++) {
                var l = 0, r = 0;
                while (px[(y * _w.toInt() + cx - l - 1) * 4 + 3] > 200 &&
                    l < 150) {
                  l++;
                }
                while (px[(y * _w.toInt() + cx + r) * 4 + 3] > 200 && r < 150) {
                  r++;
                }
                widest = math.max(widest, math.max(l, r));
              }
              expect(
                widest,
                lessThanOrEqualTo((limit * _h).ceil()),
                reason: '$name tau $tau is too wide',
              );
              if (tau >= .3) {
                expect(
                  widest,
                  greaterThanOrEqualTo((least * _h).floor()),
                  reason: '$name tau $tau reads as a prop',
                );
              }
            }
          }
        });
      },
    );

    testWidgets('the burst hands over to the billow with no empty lid', (
      tester,
    ) async {
      await tester.runAsync(() async {
        for (final (name, v) in _designs) {
          final cx = (v.x * _h).round();
          var previous = 0;
          for (var i = 0; i <= 18; i++) {
            final tau = .36 + i * .02;
            final vent = makeVent((
              x: v.x,
              top: v.top,
              kind: v.kind,
              tau: tau,
              slot: v.slot,
            ), 50);
            final lip = SteamEmitterArt.lipY(vent, _h).round();
            final px = await _pixels((c) => _vent(c, v, tau, reduced: true));
            final n = solid(
              px,
              cx,
              ((v.top - .02) * _h).round(),
              lip - 4,
              (.16 * _h).round(),
            );
            // From the first frame to the last something stands over the
            // lid, and it never collapses between two frames.
            expect(
              n,
              greaterThan(900),
              reason: '$name tau ${tau.toStringAsFixed(2)}: an empty lid',
            );
            expect(
              n,
              greaterThan(previous * .55),
              reason: '$name tau ${tau.toStringAsFixed(2)}: a hole opens',
            );
            previous = n;
          }
        }
      });
    });

    testWidgets('the cloud still sinks back into the vent as the lift dies', (
      tester,
    ) async {
      await tester.runAsync(() async {
        for (final (name, v) in _designs) {
          final cx = (v.x * _h).round();
          Future<int> cloud(double tau) async {
            final vent = makeVent((
              x: v.x,
              top: v.top,
              kind: v.kind,
              tau: tau,
              slot: v.slot,
            ), 50);
            final px = await _pixels((c) => _vent(c, v, tau, reduced: true));
            return solid(
              px,
              cx,
              ((v.top - .02) * _h).round(),
              SteamEmitterArt.lipY(vent, _h).round() - 4,
              (.16 * _h).round(),
            );
          }

          final full = await cloud(1.0),
              going = await cloud(1.6),
              gone = await cloud(1.72);
          expect(
            going,
            lessThan(full * .8),
            reason: '$name: the cloud thins as the lift dies',
          );
          expect(gone, lessThan(going), reason: '$name: and goes on shrinking');
        }
      });
    });

    testWidgets(
      'the hiss column fills from the lid: the foot is washed first, the top follows',
      (tester) async {
        await tester.runAsync(() async {
          for (final (name, v) in _designs) {
            Future<(int, int)> wash(double tau) async {
              final px = await _pixels((c) => _vent(c, v, tau, reduced: true));
              final vent = makeVent((
                x: v.x,
                top: v.top,
                kind: v.kind,
                tau: tau,
                slot: v.slot,
              ), 50);
              final lip = SteamEmitterArt.lipY(vent, _h);
              final cx = (v.x * _h).round();
              // Between the walls (.03 h off centre), a third up and near the
              // top of the reach.
              int alphaAt(double y) =>
                  px[((y).round() * _w.toInt() + cx + (.03 * _h).round()) * 4 +
                      3];
              final reach = v.top * _h;
              return (
                alphaAt(lip - (lip - reach) * .30),
                alphaAt(reach + (lip - reach) * .20),
              );
            }

            final (lowEarly, highEarly) = await wash(-1.0);
            final (_, highLate) = await wash(-.1);
            // Hop vents fill with a visible wash; a ride vent's funnel is a
            // fainter mist, but it climbs the same way.
            expect(
              lowEarly,
              greaterThan(24),
              reason: '$name: foot washed early',
            );
            expect(
              lowEarly,
              greaterThan(highEarly),
              reason: '$name: early, the foot is fuller than the top',
            );
            expect(
              highLate,
              greaterThan(highEarly),
              reason: '$name: the top fills as the burst nears',
            );
          }
        });
      },
    );

    testWidgets(
      'a light pool sits at the lid in the hiss, warm for a hop and cool for a ride',
      (tester) async {
        await tester.runAsync(() async {
          for (final (name, v) in [_designs[0], _designs[1]]) {
            final px = await _pixels((c) => _vent(c, v, -.2, reduced: true));
            final cx = (v.x * _h).round();
            // Beside the lid, above the roof, outside the capsule and the puffs.
            final x = cx + (.115 * _h).round(),
                y = (_h * (SteamEmitterArt.slab - .075)).round();
            final i = (y * _w.toInt() + x) * 4;
            expect(px[i + 3], greaterThan(45), reason: '$name: pool alpha');
            if (v.kind == SteamKind.hop) {
              expect(px[i], greaterThan(px[i + 2]), reason: '$name: amber');
            } else {
              expect(px[i + 2], greaterThan(px[i]), reason: '$name: teal');
            }
          }
        });
      },
    );
  });
}
