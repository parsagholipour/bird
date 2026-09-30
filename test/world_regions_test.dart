// Scenery tests render every region's crossing frame by frame, so their work
// grows with the tour.
@Timeout(Duration(minutes: 2))
library;

import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/obstacle.dart';
import 'package:push_up_bird/game/obstacle_art.dart';
import 'package:push_up_bird/game/sky_scenery.dart';

const _extent = 200;

Future<Uint8List> _raster(void Function(Canvas canvas) draw) async {
  final recorder = ui.PictureRecorder();
  draw(Canvas(recorder));
  final picture = recorder.endRecording();
  final image = await picture.toImage(_extent, _extent);
  final bytes = (await image.toByteData())!.buffer.asUint8List();
  image.dispose();
  picture.dispose();
  return bytes;
}

/// A second in the middle of [region]'s hold on the first lap.
double _hold(WorldRegion region) => region.index * WorldTour.leg + 8;

Obstacle _obstacle(
  ObstacleKind kind,
  WorldRegion region, {
  double center = .5,
  double amplitude = .065,
  int appearance = 0,
}) => Obstacle(
  x: .3,
  center: center,
  gap: .36,
  width: kind.width,
  kind: kind,
  amplitude: amplitude,
  appearance: appearance,
  bornAt: _hold(region) - 2,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('world tour schedule', () {
    test('visits every region in order, holding then crossing', () {
      for (final region in WorldRegion.values) {
        final start = region.index * WorldTour.leg;
        final hold = WorldTour.at(start + 1);
        expect(hold.from, region);
        expect(hold.to, region.next);
        expect(hold.t, 0);
        expect(hold.crossing, isFalse);
        expect(WorldTour.at(start + WorldTour.hold - .01).t, 0);
        final mid = WorldTour.at(
          start + WorldTour.hold + WorldTour.crossing / 2,
        );
        expect(mid.t, closeTo(.5, 1e-9));
        expect(mid.crossing, isTrue);
      }
      expect(WorldRegion.values.first, WorldRegion.jungle);
      expect(WorldRegion.jungle.next, WorldRegion.antarctica);
      expect(WorldRegion.antarctica.next, WorldRegion.aztec);
      expect(WorldRegion.paris.next, WorldRegion.egypt);
      // Egypt's hot noon hands over to the neon night of Cyberpunk City,
      // which gives way to China's pastel dusk.
      expect(WorldRegion.egypt.next, WorldRegion.cyberpunk);
      expect(WorldRegion.cyberpunk.next, WorldRegion.china);
      expect(WorldRegion.sea.next, WorldRegion.jungle);
      expect(
        WorldRegion.values,
        containsAll([
          WorldRegion.egypt,
          WorldRegion.cyberpunk,
          WorldRegion.aztec,
          WorldRegion.mexico,
          WorldRegion.paris,
          WorldRegion.brazil,
          WorldRegion.arabia,
          WorldRegion.rome,
        ]),
      );
      expect(WorldTour.loop, WorldTour.leg * WorldRegion.values.length);
    });

    test('first hand-off comes early enough for short flights', () {
      // A first Classic flight often lasts half a minute; it should still see
      // the jungle hand over to Antarctica, and a minute should show three
      // regions.
      expect(
        WorldTour.at(WorldTour.hold + WorldTour.crossing).from,
        WorldRegion.antarctica,
      );
      expect(WorldTour.hold + WorldTour.crossing, lessThanOrEqualTo(25));
      expect(WorldTour.at(60).from, WorldRegion.aztec);
      expect(WorldTour.at(WorldTour.loop + 1).from, WorldRegion.jungle);
    });

    test('bad clocks fall back to the first region', () {
      for (final second in [-5.0, double.nan, double.infinity]) {
        final blend = WorldTour.at(second);
        expect(blend.from, WorldRegion.jungle);
        expect(blend.t, 0);
      }
    });

    test('weights and palettes blend continuously and sum to one', () {
      for (var second = 0.0; second <= WorldTour.loop + 1; second += .1) {
        final blend = WorldTour.at(second);
        final next = WorldTour.at(second + 1e-5);
        var total = 0.0;
        for (final region in WorldRegion.values) {
          total += blend.weight(region);
          expect(next.weight(region), closeTo(blend.weight(region), 1e-3));
        }
        expect(total, closeTo(1, 1e-9));
        final a = SkyPalette.at(second), b = SkyPalette.at(second + 1e-5);
        for (final (x, y) in [
          (a.top, b.top),
          (a.horizon, b.horizon),
          (a.land, b.land),
        ]) {
          expect(
            (x.r - y.r).abs() + (x.g - y.g).abs() + (x.b - y.b).abs(),
            lessThan(.01),
          );
        }
      }
    });

    test('obstacles keep the region they spawned in', () {
      for (final region in WorldRegion.values) {
        final start = region.index * WorldTour.leg;
        final early = Obstacle(x: 1, center: .5, gap: .4, bornAt: start + 3);
        final crossing = start + WorldTour.hold;
        final late = Obstacle(
          x: 1,
          center: .5,
          gap: .4,
          bornAt: crossing + WorldTour.crossing * (RegionBlend.handOff + .05),
        );
        expect(WorldTour.of(early), region);
        expect(WorldTour.of(late), region.next);
        // The hand-off happens inside the crossing, never at its edges.
        final before = Obstacle(
          x: 1,
          center: .5,
          gap: .4,
          bornAt: crossing + WorldTour.crossing * (RegionBlend.handOff - .05),
        );
        expect(WorldTour.of(before), region);
        expect(RegionBlend.handOff, inExclusiveRange(0, 1));
      }
    });
  });

  group('regional obstacles', () {
    test(
      'solids are opaque inside their collision rectangles and clear outside',
      () async {
        for (final region in WorldRegion.values) {
          for (final kind in ObstacleKind.values.where((k) => !k.floating)) {
            for (final appearance in [0, 1, 2]) {
              final o = _obstacle(
                kind,
                region,
                amplitude: 0,
                appearance: appearance,
              )..advance(_hold(region));
              final rects = [
                for (final p in o.passages)
                  for (final top in [true, false])
                    Rect.fromLTRB(
                      p.x * _extent,
                      top ? -10 : p.bottom * _extent,
                      (p.x + p.width) * _extent,
                      top ? p.top * _extent : _extent + 10.0,
                    ),
              ];
              final bytes = await _raster(
                (c) => ObstacleArt.paint(
                  c,
                  o,
                  _extent.toDouble(),
                  seconds: _hold(region),
                  reducedMotion: false,
                  cleared: appearance == 1,
                  perfect: appearance == 2,
                ),
              );
              for (var y = 0; y < _extent; y += 2) {
                for (var x = 0; x < _extent; x += 2) {
                  final px = x + .5, py = y + .5;
                  final inside = rects.any(
                    (r) =>
                        px >= r.left + 1.5 &&
                        px < r.right - 1.5 &&
                        py >= r.top + 1.5 &&
                        py < r.bottom - 1.5,
                  );
                  final outside = rects.every(
                    (r) =>
                        px < r.left - 1.5 ||
                        px >= r.right + 1.5 ||
                        py < r.top - 1.5 ||
                        py >= r.bottom + 1.5,
                  );
                  final alpha = bytes[(y * _extent + x) * 4 + 3];
                  final label =
                      '${region.name} ${kind.name} #$appearance at ($x, $y)';
                  if (inside) expect(alpha, 255, reason: '$label interior');
                  if (outside) expect(alpha, 0, reason: '$label exterior');
                }
              }
            }
          }
        }
      },
    );

    test('nothing is drawn in the moving flight lane', () async {
      for (final region in WorldRegion.values) {
        for (final kind in ObstacleKind.values) {
          for (final center in [.3, .7]) {
            final o = _obstacle(kind, region, center: center);
            for (final dt in [0.0, 1.75, 5.25]) {
              final seconds = _hold(region) + dt;
              o.advance(seconds);
              final bytes = await _raster(
                (c) => ObstacleArt.paint(
                  c,
                  o,
                  _extent.toDouble(),
                  seconds: seconds,
                  reducedMotion: false,
                  cleared: false,
                  perfect: false,
                ),
              );
              final passages = o.passages.toList();
              final upper = kind.floating
                  ? o.top
                  : passages.map((p) => p.top).reduce(math.max);
              final lower = kind.floating
                  ? o.bottom
                  : passages.map((p) => p.bottom).reduce(math.min);
              for (
                var y = (upper * _extent).ceil() + 2;
                y < (lower * _extent).floor() - 2;
                y++
              ) {
                for (
                  var x = (o.x * _extent).ceil();
                  x < ((o.x + o.width) * _extent).floor();
                  x++
                ) {
                  expect(
                    bytes[(y * _extent + x) * 4 + 3],
                    0,
                    reason:
                        '${region.name} ${kind.name} drew in the lane at $x, $y',
                  );
                }
              }
            }
          }
        }
      }
    });

    test(
      'floating bodies are filled with a drawn edge in every region',
      () async {
        for (final region in WorldRegion.values) {
          for (final kind in [
            ObstacleKind.lanternDrift,
            ObstacleKind.sunWheels,
          ]) {
            for (final state in [(false, false), (true, false), (true, true)]) {
              final o = _obstacle(kind, region, amplitude: 0)
                ..advance(_hold(region));
              final bytes = await _raster(
                (c) => ObstacleArt.paint(
                  c,
                  o,
                  _extent.toDouble(),
                  seconds: _hold(region),
                  reducedMotion: true,
                  cleared: state.$1,
                  perfect: state.$2,
                ),
              );
              for (final orb in o.orbs) {
                final cx = orb.x * _extent, cy = orb.y * _extent;
                final radius = orb.radius * _extent;
                int alpha(double x, double y) =>
                    bytes[(y.round() * _extent + x.round()) * 4 + 3];
                var edges = 0;
                for (var step = 0; step < 8; step++) {
                  final a = step * math.pi / 4;
                  final ix = cx + math.cos(a) * (radius - 1.6),
                      iy = cy + math.sin(a) * (radius - 1.6);
                  expect(
                    alpha(ix, iy),
                    255,
                    reason: '${region.name} ${kind.name} fill',
                  );
                  final tether =
                      kind == ObstacleKind.lanternDrift &&
                      (step == 2 || step == 6);
                  if (!tether) {
                    expect(
                      alpha(
                        cx + math.cos(a) * (radius + 3),
                        cy + math.sin(a) * (radius + 3),
                      ),
                      0,
                      reason: '${region.name} ${kind.name} edge',
                    );
                  }
                  // The outline must contrast with the body just inside it.
                  final i = (iy.round() * _extent + ix.round()) * 4;
                  final e =
                      ((cy + math.sin(a) * (radius - .6)).round() * _extent +
                          (cx + math.cos(a) * (radius - .6)).round()) *
                      4;
                  var gap = 0;
                  for (var ch = 0; ch < 3; ch++) {
                    gap = math.max(gap, (bytes[i + ch] - bytes[e + ch]).abs());
                  }
                  if (gap >= 12) edges++;
                }
                expect(
                  edges,
                  greaterThanOrEqualTo(4),
                  reason: '${region.name} ${kind.name} rim',
                );
              }
            }
          }
        }
      },
    );

    test('cleared and perfect states are distinct in every region', () async {
      for (final region in WorldRegion.values) {
        for (final kind in ObstacleKind.values) {
          Future<Uint8List> paint(bool cleared, bool perfect) {
            final o = _obstacle(kind, region, amplitude: 0)
              ..advance(_hold(region));
            return _raster(
              (c) => ObstacleArt.paint(
                c,
                o,
                _extent.toDouble(),
                seconds: _hold(region),
                reducedMotion: true,
                cleared: cleared,
                perfect: perfect,
              ),
            );
          }

          final waiting = await paint(false, false);
          final cleared = await paint(true, false);
          final perfect = await paint(true, true);
          expect(
            cleared,
            isNot(equals(waiting)),
            reason: '${region.name} ${kind.name} cleared',
          );
          expect(
            perfect,
            isNot(equals(cleared)),
            reason: '${region.name} ${kind.name} perfect',
          );
        }
      }
    });

    test('Reduced Motion freezes every regional obstacle', () async {
      for (final region in WorldRegion.values) {
        for (final kind in ObstacleKind.values) {
          Future<Uint8List> at(double dt, bool reduced) {
            final o = _obstacle(kind, region, amplitude: 0)
              ..advance(_hold(region));
            return _raster(
              (c) => ObstacleArt.paint(
                c,
                o,
                _extent.toDouble(),
                seconds: _hold(region) + dt,
                reducedMotion: reduced,
                cleared: false,
                perfect: false,
              ),
            );
          }

          expect(
            await at(0, true),
            await at(3.3, true),
            reason: '${region.name} ${kind.name}',
          );
          expect(
            await at(1, false),
            await at(1, false),
            reason: '${region.name} ${kind.name} replay',
          );
        }
      }
    });
  });

  group('scenery', () {
    Future<Uint8List> scene(
      double seconds, {
      double? distance,
      bool reduced = false,
    }) => _raster(
      (c) => SkyScenery.paint(
        c,
        const Size(200, 200),
        seconds: seconds,
        distance: distance ?? seconds * .36,
        reducedMotion: reduced,
      ),
    );

    double difference(Uint8List a, Uint8List b) {
      var total = 0;
      for (var i = 0; i < a.length; i++) {
        total += (a[i] - b[i]).abs();
      }
      return total / a.length;
    }

    test('regions look distinct and crossings change without pops', () async {
      final holds = [for (final r in WorldRegion.values) await scene(_hold(r))];
      for (var i = 0; i < holds.length; i++) {
        for (var j = i + 1; j < holds.length; j++) {
          expect(
            difference(holds[i], holds[j]),
            greaterThan(8),
            reason: '$i vs $j',
          );
        }
      }
      for (final region in WorldRegion.values) {
        final start = region.index * WorldTour.leg + WorldTour.hold;
        Uint8List? previous;
        for (var k = 0; k <= 60; k++) {
          final frame = await scene(
            start + WorldTour.crossing * k / 60,
            reduced: true,
          );
          if (previous != null) {
            // A tenth of a second of Reduced Motion crossing is a gentle step.
            expect(
              difference(previous, frame),
              lessThan(4),
              reason: '${region.name} step $k',
            );
          }
          previous = frame;
        }
      }
    });

    test(
      'crossings freeze in Reduced Motion apart from the hand-off itself',
      () async {
        final mid = WorldTour.leg + WorldTour.hold + WorldTour.crossing / 2;
        expect(
          await scene(mid, distance: 1, reduced: true),
          await scene(mid, distance: 9, reduced: true),
          reason: 'no parallax travel',
        );
        expect(await scene(mid), await scene(mid), reason: 'replays exactly');
      },
    );
  });
}
